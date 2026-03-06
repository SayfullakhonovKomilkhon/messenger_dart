package com.messenger.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.messenger.auth.dto.LoginRequest;
import com.messenger.auth.dto.RegisterRequest;
import com.messenger.common.cache.CacheService;
import com.messenger.common.security.JwtService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.bean.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void register_shouldReturnTokens() throws Exception {
        RegisterRequest request = new RegisterRequest("+79991234567", "password123", "Test User");

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.accessToken").exists())
                .andExpect(jsonPath("$.refreshToken").exists())
                .andExpect(jsonPath("$.user.name").value("Test User"))
                .andExpect(jsonPath("$.user.phone").value("+79991234567"));
    }

    @Test
    void register_duplicatePhone_shouldReturn409() throws Exception {
        RegisterRequest request = new RegisterRequest("+79990000001", "password123", "User One");

        mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)));

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict());
    }

    @Test
    void login_invalidCredentials_shouldReturn401() throws Exception {
        LoginRequest request = new LoginRequest("+70000000000", "wrongpassword");

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void register_invalidBody_shouldReturn400() throws Exception {
        String invalidBody = """
                {"phone": "", "password": "", "name": ""}
                """;

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidBody))
                .andExpect(status().isBadRequest());
    }
}
