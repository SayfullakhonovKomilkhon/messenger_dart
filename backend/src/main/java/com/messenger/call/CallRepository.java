package com.messenger.call;

import com.messenger.call.entity.CallRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CallRepository extends JpaRepository<CallRecord, UUID> {

    @Query("SELECT c FROM CallRecord c WHERE c.callerId = :userId OR c.calleeId = :userId " +
            "ORDER BY c.startedAt DESC LIMIT 50")
    List<CallRecord> findRecentByUserId(@Param("userId") UUID userId);
}
