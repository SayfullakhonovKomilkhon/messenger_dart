package com.messenger.common.notification;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

@Configuration
public class FirebaseConfig {

    private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);

    @Value("${fcm.project-id:}")
    private String projectId;

    @Value("${fcm.client-email:}")
    private String clientEmail;

    @Value("${fcm.private-key:}")
    private String privateKey;

    @Bean
    public FirebaseMessaging firebaseMessaging() {
        if (projectId.isBlank() || clientEmail.isBlank() || privateKey.isBlank()) {
            log.warn("FCM credentials not configured — push notifications disabled");
            return null;
        }

        try {
            String serviceAccountJson = """
                    {
                      "type": "service_account",
                      "project_id": "%s",
                      "client_email": "%s",
                      "private_key": "%s",
                      "token_uri": "https://oauth2.googleapis.com/token"
                    }
                    """.formatted(projectId, clientEmail, privateKey.replace("\\n", "\n"));

            GoogleCredentials credentials = GoogleCredentials.fromStream(
                    new ByteArrayInputStream(serviceAccountJson.getBytes(StandardCharsets.UTF_8))
            );

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(credentials)
                    .setProjectId(projectId)
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
            }

            log.info("Firebase initialized for project: {}", projectId);
            return FirebaseMessaging.getInstance();
        } catch (IOException e) {
            log.error("Failed to initialize Firebase: {}", e.getMessage());
            return null;
        }
    }
}
