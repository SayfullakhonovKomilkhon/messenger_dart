package com.messenger.auth;

import com.messenger.auth.dto.*;
import com.messenger.auth.entity.RefreshToken;
import com.messenger.common.cache.CacheService;
import com.messenger.common.exception.AppException;
import com.messenger.common.security.JwtService;
import com.messenger.user.UserRepository;
import com.messenger.user.entity.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Map;

@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);
    private static final String BLACKLIST_PREFIX = "blacklist:";

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;
    private final CacheService cacheService;

    public AuthService(UserRepository userRepository,
                       RefreshTokenRepository refreshTokenRepository,
                       JwtService jwtService,
                       PasswordEncoder passwordEncoder,
                       CacheService cacheService) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.jwtService = jwtService;
        this.passwordEncoder = passwordEncoder;
        this.cacheService = cacheService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByPhone(request.phone())) {
            throw new AppException("Phone number already registered", HttpStatus.CONFLICT);
        }

        User user = new User();
        user.setPhone(request.phone());
        user.setName(request.name());
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user = userRepository.save(user);

        log.info("User registered: {}", user.getId());
        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByPhone(request.phone())
                .orElseThrow(() -> new AppException("Invalid credentials", HttpStatus.UNAUTHORIZED));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new AppException("Invalid credentials", HttpStatus.UNAUTHORIZED);
        }

        log.info("User logged in: {}", user.getId());
        return buildAuthResponse(user);
    }

    @Transactional
    public TokenResponse refresh(RefreshRequest request) {
        String token = request.refreshToken();

        if (!jwtService.isTokenValid(token)) {
            throw new AppException("Invalid refresh token", HttpStatus.UNAUTHORIZED);
        }

        if (cacheService.exists(BLACKLIST_PREFIX + token)) {
            throw new AppException("Token has been revoked", HttpStatus.UNAUTHORIZED);
        }

        RefreshToken stored = refreshTokenRepository.findByToken(token)
                .orElseThrow(() -> new AppException("Refresh token not found", HttpStatus.UNAUTHORIZED));

        String userId = jwtService.extractUserId(token);

        refreshTokenRepository.deleteByToken(token);

        String newAccess = jwtService.generateAccessToken(userId);
        String newRefresh = jwtService.generateRefreshToken(userId);
        saveRefreshToken(stored.getUser(), newRefresh);

        log.info("Tokens refreshed for user: {}", userId);
        return new TokenResponse(newAccess, newRefresh);
    }

    @Transactional
    public Map<String, Boolean> logout(String accessToken, LogoutRequest request) {
        String refreshToken = request.refreshToken();

        long ttl = jwtService.getRemainingTtlSeconds(refreshToken);
        if (ttl > 0) {
            cacheService.set(BLACKLIST_PREFIX + refreshToken, "revoked", Duration.ofSeconds(ttl));
        }

        refreshTokenRepository.deleteByToken(refreshToken);

        if (accessToken != null) {
            long accessTtl = jwtService.getRemainingTtlSeconds(accessToken);
            if (accessTtl > 0) {
                cacheService.set(BLACKLIST_PREFIX + accessToken, "revoked", Duration.ofSeconds(accessTtl));
            }
        }

        log.info("User logged out");
        return Map.of("success", true);
    }

    private AuthResponse buildAuthResponse(User user) {
        String userId = user.getId().toString();
        String accessToken = jwtService.generateAccessToken(userId);
        String refreshToken = jwtService.generateRefreshToken(userId);
        saveRefreshToken(user, refreshToken);

        AuthResponse.UserInfo userInfo = new AuthResponse.UserInfo(
                userId,
                user.getName(),
                user.getPhone(),
                user.getAvatarUrl()
        );
        return new AuthResponse(accessToken, refreshToken, userInfo);
    }

    private void saveRefreshToken(User user, String tokenStr) {
        RefreshToken rt = new RefreshToken();
        rt.setUser(user);
        rt.setToken(tokenStr);
        rt.setExpiresAt(LocalDateTime.now().plusSeconds(jwtService.getRefreshExpiresSeconds()));
        refreshTokenRepository.save(rt);
    }
}
