package com.messenger.chat.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record EditMessageRequest(
        @NotNull UUID messageId,
        @NotBlank String text
) {}
