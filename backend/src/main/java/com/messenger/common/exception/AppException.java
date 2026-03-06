package com.messenger.common.exception;

import org.springframework.http.HttpStatus;

public class AppException extends RuntimeException {

    private final HttpStatus status;

    public AppException(String message, HttpStatus status) {
        super(message);
        this.status = status;
    }

    public AppException(String message) {
        this(message, HttpStatus.BAD_REQUEST);
    }

    public HttpStatus getStatus() {
        return status;
    }
}
