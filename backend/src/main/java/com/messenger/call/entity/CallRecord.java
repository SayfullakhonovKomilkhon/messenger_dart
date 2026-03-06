package com.messenger.call.entity;

import jakarta.persistence.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "call_records")
public class CallRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "caller_id", nullable = false)
    private UUID callerId;

    @Column(name = "callee_id", nullable = false)
    private UUID calleeId;

    @Column(name = "call_type", nullable = false, length = 10)
    private String callType;

    @Column(nullable = false, length = 20)
    private String status;

    @Column(name = "started_at")
    private LocalDateTime startedAt;

    @Column(name = "ended_at")
    private LocalDateTime endedAt;

    private Integer duration;

    @PrePersist
    protected void onCreate() {
        startedAt = LocalDateTime.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getCallerId() { return callerId; }
    public void setCallerId(UUID callerId) { this.callerId = callerId; }

    public UUID getCalleeId() { return calleeId; }
    public void setCalleeId(UUID calleeId) { this.calleeId = calleeId; }

    public String getCallType() { return callType; }
    public void setCallType(String callType) { this.callType = callType; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public LocalDateTime getStartedAt() { return startedAt; }
    public void setStartedAt(LocalDateTime startedAt) { this.startedAt = startedAt; }

    public LocalDateTime getEndedAt() { return endedAt; }
    public void setEndedAt(LocalDateTime endedAt) { this.endedAt = endedAt; }

    public Integer getDuration() { return duration; }
    public void setDuration(Integer duration) { this.duration = duration; }
}
