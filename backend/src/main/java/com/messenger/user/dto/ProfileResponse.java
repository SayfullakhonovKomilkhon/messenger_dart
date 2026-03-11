package com.messenger.user.dto;

public record ProfileResponse(
        String id,
        String name,
        String phone,
        String username,
        String avatarUrl,
        String bio,
        Boolean isOnline,
        String lastSeenAt
) {}
