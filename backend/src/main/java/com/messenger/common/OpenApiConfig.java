package com.messenger.common;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI messengerOpenAPI() {
        String schemeName = "bearerAuth";

        return new OpenAPI()
                .info(new Info()
                        .title("Messenger API")
                        .description(
                                "REST API мессенджера.\n\n" +
                                "## Авторизация\n" +
                                "1. Вызовите `/api/v1/auth/register` или `/api/v1/auth/login`\n" +
                                "2. Скопируйте `accessToken` из ответа\n" +
                                "3. Нажмите кнопку **Authorize** выше и вставьте токен\n" +
                                "4. Все запросы будут отправляться с авторизацией\n\n" +
                                "## WebSocket (STOMP)\n" +
                                "Подключение: `ws://HOST:3000/ws`\n\n" +
                                "| Destination | Описание |\n" +
                                "|---|---|\n" +
                                "| `/app/chat.send` | Отправить сообщение |\n" +
                                "| `/app/chat.read` | Отметить прочитанным |\n" +
                                "| `/app/chat.typing` | Индикатор набора |\n" +
                                "| `/app/call.init` | Начать звонок |\n" +
                                "| `/app/call.accept` | Принять звонок |\n" +
                                "| `/app/call.reject` | Отклонить звонок |\n" +
                                "| `/app/call.end` | Завершить звонок |\n" +
                                "| `/app/call.sdpOffer` | SDP offer |\n" +
                                "| `/app/call.sdpAnswer` | SDP answer |\n" +
                                "| `/app/call.ice` | ICE candidate |"
                        )
                        .version("1.0.0")
                        .contact(new Contact().name("Messenger Team")))
                .addSecurityItem(new SecurityRequirement().addList(schemeName))
                .schemaRequirement(schemeName, new SecurityScheme()
                        .name(schemeName)
                        .type(SecurityScheme.Type.HTTP)
                        .scheme("bearer")
                        .bearerFormat("JWT")
                        .description("Вставьте accessToken, полученный из /auth/login или /auth/register"));
    }
}
