package com.messenger.common.exception;

import java.time.Instant;

public record ErrorResponse(
        int statusCode,
        String error,
        String message,
        Instant timestamp
) {
    public static ErrorResponse of(int statusCode, String error, String message) {
        return new ErrorResponse(statusCode, error, message, Instant.now());
    }
}
