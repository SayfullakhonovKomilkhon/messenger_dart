package com.messenger.auth.dto;

public record TokenResponse(
        String accessToken,
        String refreshToken
) {}
