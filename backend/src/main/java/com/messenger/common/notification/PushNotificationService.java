package com.messenger.common.notification;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.messenger.user.UserRepository;
import com.messenger.user.entity.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.lang.Nullable;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.UUID;

@Service
public class PushNotificationService {

    private static final Logger log = LoggerFactory.getLogger(PushNotificationService.class);

    private final FirebaseMessaging firebaseMessaging;
    private final UserRepository userRepository;

    public PushNotificationService(@Nullable FirebaseMessaging firebaseMessaging,
                                    UserRepository userRepository) {
        this.firebaseMessaging = firebaseMessaging;
        this.userRepository = userRepository;
    }

    public void sendPush(UUID userId, String title, String body, Map<String, String> data) {
        if (firebaseMessaging == null) {
            log.debug("FCM not configured, skipping push for user {}", userId);
            return;
        }

        User user = userRepository.findById(userId).orElse(null);
        if (user == null || user.getFcmToken() == null || user.getFcmToken().isBlank()) {
            log.debug("No FCM token for user {}, skipping push", userId);
            return;
        }

        Message.Builder messageBuilder = Message.builder()
                .setToken(user.getFcmToken())
                .setNotification(Notification.builder()
                        .setTitle(title)
                        .setBody(body)
                        .build());

        if (data != null) {
            messageBuilder.putAllData(data);
        }

        try {
            String messageId = firebaseMessaging.send(messageBuilder.build());
            log.debug("Push sent to user {}: {}", userId, messageId);
        } catch (FirebaseMessagingException e) {
            log.warn("Failed to send push to user {}: {}", userId, e.getMessage());
        }
    }
}
