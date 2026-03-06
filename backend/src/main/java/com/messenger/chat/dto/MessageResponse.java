package com.messenger.chat.dto;

import java.time.LocalDateTime;

public record MessageResponse(
        String id,
        String conversationId,
        String senderId,
        String text,
        String fileUrl,
        String mimeType,
        String clientMessageId,
        String status,
        LocalDateTime createdAt
) {}
