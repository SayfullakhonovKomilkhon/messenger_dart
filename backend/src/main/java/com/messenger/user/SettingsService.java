package com.messenger.user;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.messenger.common.exception.AppException;
import com.messenger.user.entity.User;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class SettingsService {

    private final UserRepository userRepository;
    private final ObjectMapper objectMapper;

    public SettingsService(UserRepository userRepository, ObjectMapper objectMapper) {
        this.userRepository = userRepository;
        this.objectMapper = objectMapper;
    }

    public Map<String, Object> getSettings(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException("User not found", HttpStatus.NOT_FOUND));
        return parseSettings(user.getSettings());
    }

    @Transactional
    public Map<String, Object> updateSettings(UUID userId, Map<String, Object> patch) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException("User not found", HttpStatus.NOT_FOUND));

        Map<String, Object> current = parseSettings(user.getSettings());
        deepMerge(current, patch);

        try {
            user.setSettings(objectMapper.writeValueAsString(current));
        } catch (JsonProcessingException e) {
            throw new AppException("Invalid settings format");
        }
        userRepository.save(user);
        return current;
    }

    private Map<String, Object> parseSettings(String json) {
        if (json == null || json.isBlank()) return new HashMap<>();
        try {
            return objectMapper.readValue(json, new TypeReference<>() {});
        } catch (JsonProcessingException e) {
            return new HashMap<>();
        }
    }

    @SuppressWarnings("unchecked")
    private void deepMerge(Map<String, Object> target, Map<String, Object> source) {
        for (Map.Entry<String, Object> entry : source.entrySet()) {
            if (entry.getValue() instanceof Map && target.get(entry.getKey()) instanceof Map) {
                deepMerge((Map<String, Object>) target.get(entry.getKey()),
                        (Map<String, Object>) entry.getValue());
            } else {
                target.put(entry.getKey(), entry.getValue());
            }
        }
    }
}
