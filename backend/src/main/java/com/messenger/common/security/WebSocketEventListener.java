package com.messenger.common.security;

import com.messenger.user.UserService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionConnectedEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

import java.util.UUID;

@Component
public class WebSocketEventListener {

    private static final Logger log = LoggerFactory.getLogger(WebSocketEventListener.class);

    private final UserService userService;

    public WebSocketEventListener(UserService userService) {
        this.userService = userService;
    }

    @EventListener
    public void handleWebSocketConnectListener(SessionConnectedEvent event) {
        StompHeaderAccessor accessor = StompHeaderAccessor.wrap(event.getMessage());
        if (accessor.getUser() != null) {
            String userId = accessor.getUser().getName();
            try {
                userService.setOnline(UUID.fromString(userId), true);
                log.info("User connected: {}", userId);
            } catch (Exception e) {
                log.warn("Failed to set user online: {}", userId, e);
            }
        }
    }

    @EventListener
    public void handleWebSocketDisconnectListener(SessionDisconnectEvent event) {
        StompHeaderAccessor accessor = StompHeaderAccessor.wrap(event.getMessage());
        if (accessor.getUser() != null) {
            String userId = accessor.getUser().getName();
            try {
                userService.setOnline(UUID.fromString(userId), false);
                log.info("User disconnected: {}", userId);
            } catch (Exception e) {
                log.warn("Failed to set user offline: {}", userId, e);
            }
        }
    }
}
