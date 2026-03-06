package com.messenger.call;

import com.messenger.call.dto.CallActionRequest;
import com.messenger.call.dto.CallInitRequest;
import com.messenger.call.dto.IceCandidateRequest;
import com.messenger.call.dto.SdpRequest;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.stereotype.Controller;

import java.security.Principal;
import java.util.UUID;

@Controller
public class CallWebSocketHandler {

    private final CallService callService;

    public CallWebSocketHandler(CallService callService) {
        this.callService = callService;
    }

    @MessageMapping("/call.init")
    public void initCall(CallInitRequest request, Principal principal) {
        UUID callerId = UUID.fromString(principal.getName());
        callService.initCallAndNotify(callerId, request);
    }

    @MessageMapping("/call.accept")
    public void acceptCall(CallActionRequest request, Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        callService.acceptCallAndNotify(userId, request.callId());
    }

    @MessageMapping("/call.reject")
    public void rejectCall(CallActionRequest request, Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        callService.rejectCallAndNotify(userId, request.callId());
    }

    @MessageMapping("/call.end")
    public void endCall(CallActionRequest request, Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        callService.endCallAndNotify(userId, request.callId());
    }

    @MessageMapping("/call.sdpOffer")
    public void sdpOffer(SdpRequest request, Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        callService.sendSdpOffer(userId, request);
    }

    @MessageMapping("/call.sdpAnswer")
    public void sdpAnswer(SdpRequest request, Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        callService.sendSdpAnswer(userId, request);
    }

    @MessageMapping("/call.ice")
    public void iceCandidate(IceCandidateRequest request, Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        callService.sendIceCandidate(userId, request);
    }
}
