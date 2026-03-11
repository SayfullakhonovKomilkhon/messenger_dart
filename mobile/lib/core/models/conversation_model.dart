class ConversationModel {
  final String id;
  final String? updatedAt;
  final ParticipantInfo participant;
  final LastMessageInfo? lastMessage;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;

  const ConversationModel({
    required this.id,
    required this.participant,
    this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      updatedAt: json['updatedAt'] as String?,
      participant: ParticipantInfo.fromJson(json['participant']),
      lastMessage: json['lastMessage'] != null
          ? LastMessageInfo.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      isMuted: json['isMuted'] as bool? ?? false,
    );
  }

  ConversationModel copyWith({
    LastMessageInfo? lastMessage,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
  }) {
    return ConversationModel(
      id: id,
      updatedAt: updatedAt,
      participant: participant,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

class ParticipantInfo {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool? isOnline;

  const ParticipantInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOnline,
  });

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isOnline: json['isOnline'] as bool?,
    );
  }
}

class LastMessageInfo {
  final String? text;
  final String? createdAt;
  final String? status;

  const LastMessageInfo({this.text, this.createdAt, this.status});

  factory LastMessageInfo.fromJson(Map<String, dynamic> json) {
    return LastMessageInfo(
      text: json['text'] as String?,
      createdAt: json['createdAt'] as String?,
      status: json['status'] as String?,
    );
  }
}
