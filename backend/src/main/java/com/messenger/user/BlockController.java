package com.messenger.user;

import com.messenger.user.dto.BlockedUserResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@Tag(name = "Block", description = "Блокировка пользователей")
public class BlockController {

    private final BlockService blockService;

    public BlockController(BlockService blockService) {
        this.blockService = blockService;
    }

    @Operation(summary = "Заблокировать пользователя")
    @PostMapping("/{id}/block")
    public ResponseEntity<Map<String, Boolean>> blockUser(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = UUID.fromString((String) authentication.getPrincipal());
        blockService.blockUser(userId, id);
        return ResponseEntity.ok(Map.of("success", true));
    }

    @Operation(summary = "Разблокировать пользователя")
    @DeleteMapping("/{id}/block")
    public ResponseEntity<Map<String, Boolean>> unblockUser(
            @PathVariable UUID id,
            Authentication authentication) {
        UUID userId = UUID.fromString((String) authentication.getPrincipal());
        blockService.unblockUser(userId, id);
        return ResponseEntity.ok(Map.of("success", true));
    }

    @Operation(summary = "Список заблокированных")
    @GetMapping("/me/blocked")
    public ResponseEntity<List<BlockedUserResponse>> getBlockedUsers(Authentication authentication) {
        UUID userId = UUID.fromString((String) authentication.getPrincipal());
        return ResponseEntity.ok(blockService.getBlockedUsers(userId));
    }
}
