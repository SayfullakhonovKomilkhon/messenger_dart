package com.messenger.call;

import com.messenger.call.dto.CallHistoryResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/calls")
@Tag(name = "Calls", description = "История звонков (signaling через WebSocket)")
public class CallController {

    private final CallService callService;

    public CallController(CallService callService) {
        this.callService = callService;
    }

    @Operation(summary = "История звонков", description = "Получить список всех звонков текущего пользователя.")
    @GetMapping("/history")
    public ResponseEntity<List<CallHistoryResponse>> getCallHistory(Authentication authentication) {
        UUID userId = UUID.fromString((String) authentication.getPrincipal());
        return ResponseEntity.ok(callService.getCallHistory(userId));
    }
}
