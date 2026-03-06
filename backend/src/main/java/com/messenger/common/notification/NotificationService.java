package com.messenger.common.notification;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final SimpMessagingTemplate messagingTemplate;
    private final PushNotificationService pushService;

    public NotificationService(SimpMessagingTemplate messagingTemplate,
                                PushNotificationService pushService) {
        this.messagingTemplate = messagingTemplate;
        this.pushService = pushService;
    }

    public void sendToUser(UUID userId, String destination, Object payload) {
        messagingTemplate.convertAndSendToUser(userId.toString(), destination, payload);
    }

    public void sendToUsers(List<UUID> userIds, String destination, Object payload) {
        for (UUID userId : userIds) {
            sendToUser(userId, destination, payload);
        }
    }

    public void sendMessageNotification(UUID recipientId, UUID senderId,
                                         String senderName, String messageText,
                                         Object wsPayload) {
        sendToUser(recipientId, "/queue/messages", wsPayload);

        String body = messageText != null ? messageText : "Sent an attachment";
        if (body.length() > 100) {
            body = body.substring(0, 97) + "...";
        }

        pushService.sendPush(recipientId, senderName, body, Map.of(
                "type", "NEW_MESSAGE",
                "senderId", senderId.toString()
        ));
    }

    public void sendCallNotification(UUID recipientId, String callerName,
                                      String callType, String callId,
                                      Object wsPayload) {
        sendToUser(recipientId, "/queue/call", wsPayload);

        String body = "VIDEO".equals(callType) ? "Incoming video call" : "Incoming audio call";
        pushService.sendPush(recipientId, callerName, body, Map.of(
                "type", "INCOMING_CALL",
                "callId", callId,
                "callType", callType
        ));
    }

    public void sendStatusEvent(UUID userId, Object statusPayload) {
        sendToUser(userId, "/queue/status", statusPayload);
    }

    public void sendTypingEvent(UUID userId, Object typingPayload) {
        sendToUser(userId, "/queue/typing", typingPayload);
    }

    public void sendCallEvent(UUID userId, Object callPayload) {
        sendToUser(userId, "/queue/call", callPayload);
    }
}
