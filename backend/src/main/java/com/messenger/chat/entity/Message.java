package com.messenger.chat.entity;

import jakarta.persistence.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "messages")
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "conversation_id", nullable = false)
    private UUID conversationId;

    @Column(name = "sender_id", nullable = false)
    private UUID senderId;

    private String text;

    @Column(name = "file_url")
    private String fileUrl;

    @Column(name = "mime_type", length = 100)
    private String mimeType;

    @Column(name = "client_message_id", nullable = false, unique = true, length = 36)
    private String clientMessageId;

    @Column(length = 20)
    private String status = "SENT";

    @Column(name = "is_voice_message")
    private Boolean isVoiceMessage = false;

    @Column(name = "voice_duration")
    private Integer voiceDuration;

    @Column(name = "voice_waveform")
    private String voiceWaveform;

    @Column(name = "reply_to_id")
    private UUID replyToId;

    @Column(name = "forwarded_from_id")
    private UUID forwardedFromId;

    @Column(name = "is_pinned")
    private Boolean isPinned = false;

    @Column(name = "is_edited")
    private Boolean isEdited = false;

    @Column(name = "is_deleted")
    private Boolean isDeleted = false;

    @Column(name = "edited_at")
    private LocalDateTime editedAt;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getConversationId() { return conversationId; }
    public void setConversationId(UUID conversationId) { this.conversationId = conversationId; }

    public UUID getSenderId() { return senderId; }
    public void setSenderId(UUID senderId) { this.senderId = senderId; }

    public String getText() { return text; }
    public void setText(String text) { this.text = text; }

    public String getFileUrl() { return fileUrl; }
    public void setFileUrl(String fileUrl) { this.fileUrl = fileUrl; }

    public String getMimeType() { return mimeType; }
    public void setMimeType(String mimeType) { this.mimeType = mimeType; }

    public String getClientMessageId() { return clientMessageId; }
    public void setClientMessageId(String clientMessageId) { this.clientMessageId = clientMessageId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Boolean getIsVoiceMessage() { return isVoiceMessage; }
    public void setIsVoiceMessage(Boolean isVoiceMessage) { this.isVoiceMessage = isVoiceMessage; }

    public Integer getVoiceDuration() { return voiceDuration; }
    public void setVoiceDuration(Integer voiceDuration) { this.voiceDuration = voiceDuration; }

    public String getVoiceWaveform() { return voiceWaveform; }
    public void setVoiceWaveform(String voiceWaveform) { this.voiceWaveform = voiceWaveform; }

    public UUID getReplyToId() { return replyToId; }
    public void setReplyToId(UUID replyToId) { this.replyToId = replyToId; }

    public UUID getForwardedFromId() { return forwardedFromId; }
    public void setForwardedFromId(UUID forwardedFromId) { this.forwardedFromId = forwardedFromId; }

    public Boolean getIsPinned() { return isPinned; }
    public void setIsPinned(Boolean isPinned) { this.isPinned = isPinned; }

    public Boolean getIsEdited() { return isEdited; }
    public void setIsEdited(Boolean isEdited) { this.isEdited = isEdited; }

    public Boolean getIsDeleted() { return isDeleted; }
    public void setIsDeleted(Boolean isDeleted) { this.isDeleted = isDeleted; }

    public LocalDateTime getEditedAt() { return editedAt; }
    public void setEditedAt(LocalDateTime editedAt) { this.editedAt = editedAt; }

    public LocalDateTime getCreatedAt() { return createdAt; }
}
