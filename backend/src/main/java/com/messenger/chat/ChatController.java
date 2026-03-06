package com.messenger.chat;

import com.messenger.chat.dto.ConversationResponse;
import com.messenger.chat.dto.CreateConversationRequest;
import com.messenger.chat.dto.MessageResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/conversations")
@Tag(name = "Chat", description = "Диалоги и сообщения")
public class ChatController {

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @Operation(summary = "Список диалогов", description = "Возвращает все диалоги текущего пользователя.")
    @GetMapping
    public ResponseEntity<List<ConversationResponse>> getConversations(Authentication authentication) {
        UUID userId = UUID.fromString((String) authentication.getPrincipal());
        return ResponseEntity.ok(chatService.getConversations(userId));
    }

    @Operation(summary = "Сообщения диалога", description = "Получить сообщения. Поддержка cursor-пагинации через параметр before.")
    @GetMapping("/{id}/messages")
    public ResponseEntity<List<MessageResponse>> getMessages(
            @PathVariable UUID id,
            @RequestParam(required = false) UUID before,
            @RequestParam(defaultValue = "30") int limit,
            Authentication authentication) {
        UUID userId = UUID.fromString((String) authentication.getPrincipal());
        return ResponseEntity.ok(chatService.getMessages(id, before, limit, userId));
    }

    @Operation(summary = "Создать диалог", description = "Создать новый диалог с пользователем или вернуть существующий.")
    @PostMapping
    public ResponseEntity<ConversationResponse> createConversation(
            @RequestBody @Valid CreateConversationRequest request,
            Authentication authentication) {
        UUID userId = UUID.fromString((String) authentication.getPrincipal());
        return ResponseEntity.ok(chatService.createOrGetConversation(userId, request.participantId()));
    }
}
