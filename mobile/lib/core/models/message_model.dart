class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? text;
  final String? fileUrl;
  final String? mimeType;
  final String clientMessageId;
  final String status;
  final String createdAt;
  final bool isVoiceMessage;
  final int? voiceDuration;
  final String? voiceWaveform;
  final String? replyToId;
  final String? forwardedFromId;
  final bool isPinned;
  final bool isEdited;
  final bool isDeleted;
  final String? editedAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.text,
    this.fileUrl,
    this.mimeType,
    required this.clientMessageId,
    this.status = 'SENT',
    required this.createdAt,
    this.isVoiceMessage = false,
    this.voiceDuration,
    this.voiceWaveform,
    this.replyToId,
    this.forwardedFromId,
    this.isPinned = false,
    this.isEdited = false,
    this.isDeleted = false,
    this.editedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String?,
      fileUrl: json['fileUrl'] as String?,
      mimeType: json['mimeType'] as String?,
      clientMessageId: json['clientMessageId'] as String,
      status: json['status'] as String? ?? 'SENT',
      createdAt: json['createdAt'] as String,
      isVoiceMessage: json['isVoiceMessage'] as bool? ?? false,
      voiceDuration: json['voiceDuration'] as int?,
      voiceWaveform: json['voiceWaveform'] as String?,
      replyToId: json['replyToId'] as String?,
      forwardedFromId: json['forwardedFromId'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      isEdited: json['isEdited'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      editedAt: json['editedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'text': text,
    'fileUrl': fileUrl,
    'mimeType': mimeType,
    'clientMessageId': clientMessageId,
    'status': status,
    'createdAt': createdAt,
    'isVoiceMessage': isVoiceMessage,
    'voiceDuration': voiceDuration,
    'voiceWaveform': voiceWaveform,
    'replyToId': replyToId,
    'forwardedFromId': forwardedFromId,
    'isPinned': isPinned,
    'isEdited': isEdited,
    'isDeleted': isDeleted,
    'editedAt': editedAt,
  };

  bool get isImage =>
      mimeType != null && mimeType!.startsWith('image/') && !isVoiceMessage;

  bool get isVideo =>
      mimeType != null && mimeType!.startsWith('video/') && !isVoiceMessage;

  bool get isFile => fileUrl != null && !isImage && !isVideo && !isVoiceMessage;
}
