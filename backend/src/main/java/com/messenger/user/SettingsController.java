package com.messenger.user;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users/me/settings")
@Tag(name = "Settings", description = "Настройки пользователя")
public class SettingsController {

    private final SettingsService settingsService;

    public SettingsController(SettingsService settingsService) {
        this.settingsService = settingsService;
    }

    @Operation(summary = "Получить все настройки")
    @GetMapping
    public ResponseEntity<Map<String, Object>> getSettings(Authentication authentication) {
        UUID userId = UUID.fromString((String) authentication.getPrincipal());
        return ResponseEntity.ok(settingsService.getSettings(userId));
    }

    @Operation(summary = "Обновить настройки", description = "JSON merge patch — передавайте только изменяемые поля")
    @PatchMapping
    public ResponseEntity<Map<String, Object>> updateSettings(
            @RequestBody Map<String, Object> patch,
            Authentication authentication) {
        UUID userId = UUID.fromString((String) authentication.getPrincipal());
        return ResponseEntity.ok(settingsService.updateSettings(userId, patch));
    }
}
