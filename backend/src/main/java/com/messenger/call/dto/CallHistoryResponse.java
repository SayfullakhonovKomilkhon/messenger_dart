package com.messenger.call.dto;

import java.time.LocalDateTime;

public record CallHistoryResponse(
        String id,
        String callType,
        String status,
        Integer duration,
        LocalDateTime startedAt,
        ParticipantInfo participant
) {
    public record ParticipantInfo(
            String id,
            String name,
            String avatarUrl
    ) {}
}
