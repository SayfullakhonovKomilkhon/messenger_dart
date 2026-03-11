package com.messenger.user;

import com.messenger.common.exception.AppException;
import com.messenger.user.dto.BlockedUserResponse;
import com.messenger.user.entity.BlockedUser;
import com.messenger.user.entity.User;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class BlockService {

    private final BlockedUserRepository blockedUserRepository;
    private final UserRepository userRepository;

    public BlockService(BlockedUserRepository blockedUserRepository, UserRepository userRepository) {
        this.blockedUserRepository = blockedUserRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public void blockUser(UUID blockerId, UUID blockedId) {
        if (blockerId.equals(blockedId)) {
            throw new AppException("Cannot block yourself");
        }
        if (!userRepository.existsById(blockedId)) {
            throw new AppException("User not found", HttpStatus.NOT_FOUND);
        }
        if (blockedUserRepository.existsByBlockerIdAndBlockedId(blockerId, blockedId)) {
            throw new AppException("User already blocked", HttpStatus.CONFLICT);
        }

        BlockedUser blocked = new BlockedUser();
        blocked.setBlockerId(blockerId);
        blocked.setBlockedId(blockedId);
        blockedUserRepository.save(blocked);
    }

    @Transactional
    public void unblockUser(UUID blockerId, UUID blockedId) {
        BlockedUser blocked = blockedUserRepository
                .findByBlockerIdAndBlockedId(blockerId, blockedId)
                .orElseThrow(() -> new AppException("User not blocked", HttpStatus.NOT_FOUND));
        blockedUserRepository.delete(blocked);
    }

    public List<BlockedUserResponse> getBlockedUsers(UUID blockerId) {
        List<BlockedUser> blocked = blockedUserRepository.findAllByBlockerId(blockerId);
        if (blocked.isEmpty()) return List.of();

        Set<UUID> blockedIds = blocked.stream()
                .map(BlockedUser::getBlockedId)
                .collect(Collectors.toSet());

        Map<UUID, User> usersMap = userRepository.findAllById(blockedIds).stream()
                .collect(Collectors.toMap(User::getId, u -> u));

        return blocked.stream()
                .map(b -> {
                    User user = usersMap.get(b.getBlockedId());
                    return new BlockedUserResponse(
                            b.getBlockedId().toString(),
                            user != null ? user.getName() : "Deleted User",
                            user != null ? user.getAvatarUrl() : null,
                            b.getCreatedAt()
                    );
                })
                .toList();
    }

    public boolean isBlocked(UUID blockerId, UUID blockedId) {
        return blockedUserRepository.existsByBlockerIdAndBlockedId(blockerId, blockedId);
    }
}
