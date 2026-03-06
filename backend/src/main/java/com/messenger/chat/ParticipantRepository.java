package com.messenger.chat;

import com.messenger.chat.entity.ConversationParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ParticipantRepository extends JpaRepository<ConversationParticipant, UUID> {
}
