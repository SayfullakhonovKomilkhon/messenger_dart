package com.messenger.user;

import com.messenger.user.dto.ProfileResponse;
import com.messenger.user.dto.UpdateProfileRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@Tag(name = "Profile", description = "Профиль пользователя")
public class ProfileController {

    private final ProfileService profileService;

    public ProfileController(ProfileService profileService) {
        this.profileService = profileService;
    }

    @Operation(summary = "Мой профиль")
    @GetMapping("/me")
    public ResponseEntity<ProfileResponse> getMyProfile(Authentication authentication) {
        UUID userId = UUID.fromString((String) authentication.getPrincipal());
        return ResponseEntity.ok(profileService.getProfile(userId));
    }

    @Operation(summary = "Обновить профиль")
    @PatchMapping("/me")
    public ResponseEntity<ProfileResponse> updateProfile(
            @RequestBody @Valid UpdateProfileRequest request,
            Authentication authentication) {
        UUID userId = UUID.fromString((String) authentication.getPrincipal());
        return ResponseEntity.ok(profileService.updateProfile(userId, request));
    }

    @Operation(summary = "Профиль другого пользователя")
    @GetMapping("/{id}")
    public ResponseEntity<ProfileResponse> getUserProfile(@PathVariable UUID id) {
        return ResponseEntity.ok(profileService.getProfile(id));
    }

    @Operation(summary = "Удалить аккаунт")
    @DeleteMapping("/me")
    public ResponseEntity<Map<String, Boolean>> deleteAccount(Authentication authentication) {
        UUID userId = UUID.fromString((String) authentication.getPrincipal());
        profileService.deleteAccount(userId);
        return ResponseEntity.ok(Map.of("success", true));
    }
}
