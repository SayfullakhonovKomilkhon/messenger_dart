package com.messenger.user.dto;

import jakarta.validation.constraints.Size;

public record UpdateProfileRequest(
        @Size(max = 100) String name,
        @Size(max = 50) String username,
        String bio,
        String avatarUrl
) {}
