package com.messenger.call.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record CallInitRequest(
        @NotNull UUID calleeId,
        @NotBlank String callType
) {}
