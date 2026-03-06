package com.messenger.call.dto;

import java.util.Map;

public record CallEventResponse(
        String type,
        String callId,
        String callType,
        String callerId,
        String calleeId,
        Map<String, Object> data
) {
    public static CallEventResponse of(String type, String callId, String callType,
                                        String callerId, String calleeId) {
        return new CallEventResponse(type, callId, callType, callerId, calleeId, null);
    }

    public static CallEventResponse withData(String type, String callId, Map<String, Object> data) {
        return new CallEventResponse(type, callId, null, null, null, data);
    }
}
