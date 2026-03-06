package com.messenger.user.dto;

import jakarta.validation.constraints.NotBlank;

public record FcmTokenRequest(
        @NotBlank String fcmToken
) {}
