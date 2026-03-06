package com.messenger.chat;

import com.messenger.chat.dto.ReadMessageRequest;
import com.messenger.chat.dto.SendMessageRequest;
import com.messenger.chat.dto.TypingRequest;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.stereotype.Controller;

import java.security.Principal;
import java.util.UUID;

@Controller
public class ChatWebSocketHandler {

    private final ChatService chatService;

    public ChatWebSocketHandler(ChatService chatService) {
        this.chatService = chatService;
    }

    @MessageMapping("/chat.send")
    public void sendMessage(SendMessageRequest request, Principal principal) {
        UUID senderId = UUID.fromString(principal.getName());
        chatService.sendAndNotify(senderId, request);
    }

    @MessageMapping("/chat.read")
    public void readMessage(ReadMessageRequest request, Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        chatService.markAsReadAndNotify(userId, request);
    }

    @MessageMapping("/chat.typing")
    public void typing(TypingRequest request, Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        chatService.notifyTyping(userId, request);
    }
}
