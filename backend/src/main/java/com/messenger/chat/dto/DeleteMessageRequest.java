package com.messenger.chat.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record DeleteMessageRequest(
        @NotNull UUID messageId
) {}
