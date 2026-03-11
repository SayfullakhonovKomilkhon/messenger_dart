package com.messenger.user;

import com.messenger.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByPhone(String phone);

    Optional<User> findByUsername(String username);

    boolean existsByPhone(String phone);

    @Query("SELECT u FROM User u WHERE (LOWER(u.name) LIKE LOWER(CONCAT('%', :query, '%')) " +
            "OR LOWER(u.username) LIKE LOWER(CONCAT('%', :query, '%')) " +
            "OR u.phone LIKE CONCAT('%', :query, '%')) AND u.id <> :excludeId")
    List<User> searchByNameOrUsername(@Param("query") String query, @Param("excludeId") UUID excludeId);
}
