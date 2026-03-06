package com.messenger.chat.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record SendMessageRequest(
        @NotNull UUID conversationId,
        String text,
        String fileUrl,
        @NotBlank String clientMessageId
) {}
