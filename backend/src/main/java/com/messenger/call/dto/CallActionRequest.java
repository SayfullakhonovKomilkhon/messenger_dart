package com.messenger.call.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record CallActionRequest(
        @NotNull UUID callId
) {}
