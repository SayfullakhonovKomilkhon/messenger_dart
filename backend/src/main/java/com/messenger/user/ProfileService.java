package com.messenger.user;

import com.messenger.common.exception.AppException;
import com.messenger.user.dto.ProfileResponse;
import com.messenger.user.dto.UpdateProfileRequest;
import com.messenger.user.entity.User;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class ProfileService {

    private final UserRepository userRepository;

    public ProfileService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public ProfileResponse getProfile(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException("User not found", HttpStatus.NOT_FOUND));
        return toResponse(user);
    }

    @Transactional
    public ProfileResponse updateProfile(UUID userId, UpdateProfileRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException("User not found", HttpStatus.NOT_FOUND));

        if (request.name() != null && !request.name().isBlank()) {
            user.setName(request.name());
        }
        if (request.username() != null) {
            if (!request.username().isBlank()) {
                userRepository.findByUsername(request.username()).ifPresent(existing -> {
                    if (!existing.getId().equals(userId)) {
                        throw new AppException("Username already taken", HttpStatus.CONFLICT);
                    }
                });
            }
            user.setUsername(request.username().isBlank() ? null : request.username());
        }
        if (request.bio() != null) {
            user.setBio(request.bio());
        }
        if (request.avatarUrl() != null) {
            user.setAvatarUrl(request.avatarUrl());
        }

        userRepository.save(user);
        return toResponse(user);
    }

    @Transactional
    public void deleteAccount(UUID userId) {
        if (!userRepository.existsById(userId)) {
            throw new AppException("User not found", HttpStatus.NOT_FOUND);
        }
        userRepository.deleteById(userId);
    }

    private ProfileResponse toResponse(User user) {
        return new ProfileResponse(
                user.getId().toString(),
                user.getName(),
                user.getPhone(),
                user.getUsername(),
                user.getAvatarUrl(),
                user.getBio(),
                user.getIsOnline(),
                user.getLastSeenAt() != null ? user.getLastSeenAt().toString() : null
        );
    }
}
