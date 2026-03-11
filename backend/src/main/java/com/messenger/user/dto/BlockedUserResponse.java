package com.messenger.user.dto;

import java.time.LocalDateTime;

public record BlockedUserResponse(
        String id,
        String name,
        String avatarUrl,
        LocalDateTime blockedAt
) {}
