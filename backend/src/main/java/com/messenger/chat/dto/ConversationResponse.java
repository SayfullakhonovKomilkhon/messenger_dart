package com.messenger.chat.dto;

import java.time.LocalDateTime;

public record ConversationResponse(
        String id,
        LocalDateTime updatedAt,
        ParticipantInfo participant,
        LastMessageInfo lastMessage,
        int unreadCount
) {
    public record ParticipantInfo(
            String id,
            String name,
            String avatarUrl,
            Boolean isOnline
    ) {}

    public record LastMessageInfo(
            String text,
            LocalDateTime createdAt,
            String status
    ) {}
}
