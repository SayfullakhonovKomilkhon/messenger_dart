package com.messenger.chat;

import com.messenger.chat.entity.Conversation;
import com.messenger.chat.entity.ConversationParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, UUID> {

    @Query("SELECT cp FROM ConversationParticipant cp " +
            "JOIN FETCH cp.conversation " +
            "JOIN FETCH cp.user " +
            "WHERE cp.conversation.id IN (" +
            "  SELECT cp2.conversation.id FROM ConversationParticipant cp2 WHERE cp2.user.id = :userId" +
            ")")
    List<ConversationParticipant> findAllParticipantsByUserConversations(@Param("userId") UUID userId);

    @Query("SELECT cp FROM ConversationParticipant cp WHERE cp.conversation.id = :conversationId AND cp.user.id = :userId")
    Optional<ConversationParticipant> findParticipant(@Param("conversationId") UUID conversationId,
                                                      @Param("userId") UUID userId);

    @Query("SELECT cp FROM ConversationParticipant cp WHERE cp.conversation.id = :conversationId")
    List<ConversationParticipant> findParticipants(@Param("conversationId") UUID conversationId);

    @Query("SELECT c FROM Conversation c WHERE c.id IN (" +
            "SELECT cp1.conversation.id FROM ConversationParticipant cp1 " +
            "WHERE cp1.user.id = :userId1 AND cp1.conversation.id IN (" +
            "  SELECT cp2.conversation.id FROM ConversationParticipant cp2 WHERE cp2.user.id = :userId2" +
            "))")
    Optional<Conversation> findDirectConversation(@Param("userId1") UUID userId1,
                                                   @Param("userId2") UUID userId2);
}
