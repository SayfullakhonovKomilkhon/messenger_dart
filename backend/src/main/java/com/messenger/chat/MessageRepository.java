package com.messenger.chat;

import com.messenger.chat.entity.Message;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MessageRepository extends JpaRepository<Message, UUID> {

    Optional<Message> findByClientMessageId(String clientMessageId);

    @Query("SELECT m FROM Message m WHERE m.conversationId = :conversationId ORDER BY m.createdAt DESC")
    List<Message> findByConversationIdOrderByCreatedAtDesc(@Param("conversationId") UUID conversationId,
                                                            Pageable pageable);

    @Query("SELECT m FROM Message m WHERE m.conversationId = :conversationId " +
            "AND m.createdAt < :before ORDER BY m.createdAt DESC")
    List<Message> findByConversationIdBeforeCursor(@Param("conversationId") UUID conversationId,
                                                    @Param("before") LocalDateTime before,
                                                    Pageable pageable);

    @Query("SELECT m FROM Message m WHERE m.conversationId = :conversationId " +
            "ORDER BY m.createdAt DESC LIMIT 1")
    Optional<Message> findLastMessage(@Param("conversationId") UUID conversationId);

    @Query(value = "SELECT DISTINCT ON (m.conversation_id) m.* " +
            "FROM messages m " +
            "WHERE m.conversation_id IN :conversationIds " +
            "ORDER BY m.conversation_id, m.created_at DESC, m.id DESC",
            nativeQuery = true)
    List<Message> findLastMessagesByConversationIds(@Param("conversationIds") Collection<UUID> conversationIds);

    @Query("SELECT m FROM Message m WHERE m.conversationId = :conversationId AND m.isPinned = true ORDER BY m.createdAt DESC")
    List<Message> findPinnedMessages(@Param("conversationId") UUID conversationId);

    void deleteAllByConversationId(UUID conversationId);
}
