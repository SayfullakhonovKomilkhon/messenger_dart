package com.messenger.user.dto;

public record UserSearchResponse(
        String id,
        String name,
        String username,
        String avatarUrl,
        Boolean isOnline
) {}
