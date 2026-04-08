class ConversationModel {
  final String id;
  final String type;
  final String? updatedAt;
  final ParticipantInfo? participant;
  final GroupInfo? groupInfo;
  final LastMessageInfo? lastMessage;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final String? myTrustStatus;
  final String? otherTrustStatus;
  final String? searchMethod;

  bool get isGroup => type == 'GROUP';
  bool get isMutualTrust =>
      myTrustStatus == 'TRUSTED' && otherTrustStatus == 'TRUSTED';

  String get displayName {
    if (isGroup) return groupInfo?.title ?? 'Группа';
    if (isMutualTrust) {
      return participant?.name ?? participant?.aiName ?? participant?.publicId ?? '';
    }
    if (searchMethod == 'publicId') return participant?.publicId ?? '';
    if (searchMethod == 'aiName') return participant?.aiName ?? '';
    return participant?.name ?? participant?.publicId ?? '';
  }

  String? get displayAvatar {
    if (isGroup) return groupInfo?.avatarUrl;
    if (isMutualTrust) return participant?.avatarUrl;
    return null;
  }

  const ConversationModel({
    required this.id,
    this.type = 'DIRECT',
    this.participant,
    this.groupInfo,
    this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.myTrustStatus,
    this.otherTrustStatus,
    this.searchMethod,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'DIRECT',
      updatedAt: json['updatedAt'] as String?,
      participant: json['participant'] != null
          ? ParticipantInfo.fromJson(json['participant'])
          : null,
      groupInfo: json['groupInfo'] != null
          ? GroupInfo.fromJson(json['groupInfo'])
          : null,
      lastMessage: json['lastMessage'] != null
          ? LastMessageInfo.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      isMuted: json['isMuted'] as bool? ?? false,
      myTrustStatus: json['myTrustStatus'] as String?,
      otherTrustStatus: json['otherTrustStatus'] as String?,
      searchMethod: json['searchMethod'] as String?,
    );
  }

  ConversationModel copyWith({
    ParticipantInfo? participant,
    GroupInfo? groupInfo,
    LastMessageInfo? lastMessage,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
    String? myTrustStatus,
    String? otherTrustStatus,
    String? searchMethod,
  }) {
    return ConversationModel(
      id: id,
      type: type,
      updatedAt: updatedAt,
      participant: participant ?? this.participant,
      groupInfo: groupInfo ?? this.groupInfo,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      myTrustStatus: myTrustStatus ?? this.myTrustStatus,
      otherTrustStatus: otherTrustStatus ?? this.otherTrustStatus,
      searchMethod: searchMethod ?? this.searchMethod,
    );
  }
}

class ParticipantInfo {
  final String id;
  final String? name;
  final String? publicId;
  final String? aiName;
  final String? avatarUrl;
  final bool? isOnline;
  final bool? isBot;

  const ParticipantInfo({
    required this.id,
    this.name,
    this.publicId,
    this.aiName,
    this.avatarUrl,
    this.isOnline,
    this.isBot,
  });

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantInfo(
      id: json['id'] as String,
      name: json['name'] as String?,
      publicId: json['publicId'] as String?,
      aiName: json['aiName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isOnline: json['isOnline'] as bool?,
      isBot: json['isBot'] as bool?,
    );
  }

  ParticipantInfo copyWith({bool? isOnline}) {
    return ParticipantInfo(
      id: id,
      name: name,
      publicId: publicId,
      aiName: aiName,
      avatarUrl: avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      isBot: isBot,
    );
  }
}

class GroupInfo {
  final String? title;
  final String? description;
  final String? avatarUrl;
  final int memberCount;
  final String? myRole;
  final String? createdBy;
  final List<GroupMemberInfo> members;

  const GroupInfo({
    this.title,
    this.description,
    this.avatarUrl,
    this.memberCount = 0,
    this.myRole,
    this.createdBy,
    this.members = const [],
  });

  factory GroupInfo.fromJson(Map<String, dynamic> json) {
    return GroupInfo(
      title: json['title'] as String?,
      description: json['description'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      memberCount: json['memberCount'] as int? ?? 0,
      myRole: json['myRole'] as String?,
      createdBy: json['createdBy'] as String?,
      members: (json['members'] as List?)
              ?.map((e) => GroupMemberInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class GroupMemberInfo {
  final String userId;
  final String name;
  final String? avatarUrl;
  final bool? isOnline;
  final String role;
  final String? joinedAt;

  const GroupMemberInfo({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.isOnline,
    this.role = 'MEMBER',
    this.joinedAt,
  });

  factory GroupMemberInfo.fromJson(Map<String, dynamic> json) {
    return GroupMemberInfo(
      userId: json['userId'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isOnline: json['isOnline'] as bool?,
      role: json['role'] as String? ?? 'MEMBER',
      joinedAt: json['joinedAt'] as String?,
    );
  }
}

class LastMessageInfo {
  final String? id;
  final String? text;
  final String? createdAt;
  final String? status;
  final String? fileUrl;
  final String? mimeType;
  final bool? isVoiceMessage;
  final bool? encrypted;

  const LastMessageInfo({
    this.id,
    this.text,
    this.createdAt,
    this.status,
    this.fileUrl,
    this.mimeType,
    this.isVoiceMessage,
    this.encrypted,
  });

  factory LastMessageInfo.fromJson(Map<String, dynamic> json) {
    return LastMessageInfo(
      id: json['id'] as String?,
      text: json['text'] as String?,
      createdAt: json['createdAt'] as String?,
      status: json['status'] as String?,
      fileUrl: json['fileUrl'] as String?,
      mimeType: json['mimeType'] as String?,
      isVoiceMessage: json['isVoiceMessage'] as bool?,
      encrypted: json['encrypted'] as bool?,
    );
  }
}
