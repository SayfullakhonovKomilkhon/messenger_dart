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
        LocalDateTime createdAt,
        Boolean isVoiceMessage,
        Integer voiceDuration,
        String voiceWaveform,
        String replyToId,
        String forwardedFromId,
        Boolean isPinned,
        Boolean isEdited,
        Boolean isDeleted,
        LocalDateTime editedAt
) {}
