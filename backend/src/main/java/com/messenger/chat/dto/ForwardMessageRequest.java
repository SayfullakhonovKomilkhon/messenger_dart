package com.messenger.chat.dto;

import jakarta.validation.constraints.NotNull;

import java.util.List;
import java.util.UUID;

public record ForwardMessageRequest(
        @NotNull UUID messageId,
        @NotNull List<UUID> toConversationIds
) {}
