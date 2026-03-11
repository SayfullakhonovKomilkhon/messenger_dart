package com.messenger.user.entity;

import jakarta.persistence.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "blocked_users",
        uniqueConstraints = @UniqueConstraint(columnNames = {"blocker_id", "blocked_id"}))
public class BlockedUser {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "blocker_id", nullable = false)
    private UUID blockerId;

    @Column(name = "blocked_id", nullable = false)
    private UUID blockedId;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getBlockerId() { return blockerId; }
    public void setBlockerId(UUID blockerId) { this.blockerId = blockerId; }

    public UUID getBlockedId() { return blockedId; }
    public void setBlockedId(UUID blockedId) { this.blockedId = blockedId; }

    public LocalDateTime getCreatedAt() { return createdAt; }
}
