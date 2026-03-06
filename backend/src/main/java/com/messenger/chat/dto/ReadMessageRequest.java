package com.messenger.chat.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record ReadMessageRequest(
        @NotNull UUID messageId,
        @NotNull UUID conversationId
) {}
