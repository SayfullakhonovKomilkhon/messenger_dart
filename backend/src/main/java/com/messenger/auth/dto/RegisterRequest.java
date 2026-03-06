package com.messenger.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank @Size(max = 20) String phone,
        @NotBlank @Size(min = 6, max = 128) String password,
        @NotBlank @Size(max = 100) String name
) {}
