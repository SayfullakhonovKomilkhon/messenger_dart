package com.messenger.user;

import com.messenger.user.dto.FcmTokenRequest;
import com.messenger.user.dto.UserSearchResponse;
import jakarta.validation.Valid;
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
@Tag(name = "Users", description = "Поиск пользователей и управление FCM токеном")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @Operation(summary = "Поиск пользователей", description = "Поиск по имени или username. Минимум 2 символа.")
    @GetMapping("/search")
    public ResponseEntity<List<UserSearchResponse>> search(
            @RequestParam String query,
            Authentication authentication) {
        UUID currentUserId = UUID.fromString((String) authentication.getPrincipal());
        return ResponseEntity.ok(userService.search(query, currentUserId));
    }

    @Operation(summary = "Обновить FCM токен", description = "Сохраняет токен Firebase Cloud Messaging для push-уведомлений.")
    @PatchMapping("/me/fcm-token")
    public ResponseEntity<Map<String, Boolean>> updateFcmToken(
            @RequestBody @Valid FcmTokenRequest request,
            Authentication authentication) {
        UUID userId = UUID.fromString((String) authentication.getPrincipal());
        userService.updateFcmToken(userId, request.fcmToken());
        return ResponseEntity.ok(Map.of("success", true));
    }
}
