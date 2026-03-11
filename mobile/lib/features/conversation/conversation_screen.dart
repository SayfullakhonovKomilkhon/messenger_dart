import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/providers.dart';
import '../../core/models/message_model.dart';
import '../../core/network/api_client.dart';
import '../../core/network/ws_client.dart';
import 'message_bubble.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String participantName;
  final String? participantAvatar;
  final String participantId;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.participantName,
    this.participantAvatar,
    required this.participantId,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();
  MessageModel? _replyTo;
  bool _isSearching = false;
  final _searchMsgController = TextEditingController();
  String _searchMsgQuery = '';
  bool _hasText = false;
  bool _participantTyping = false;
  Timer? _typingTimer;
  bool _notificationsMuted = false;

  // Voice recording
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _recordPath;

  static const _ruMonths = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _textController.addListener(_onTextChanged);
    _initRecorder();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messagesProvider(widget.conversationId).notifier).load();
      _subscribeToMessages();
      _loadMuteState();
      _markAsRead();
    });
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  Future<void> _markAsRead() async {
    try {
      await ApiClient().dio.post('/conversations/${widget.conversationId}/read');
      ref.read(conversationsProvider.notifier).markRead(widget.conversationId);

      // Also send chat.read via WebSocket for real-time notification to sender
      final messages = ref.read(messagesProvider(widget.conversationId)).valueOrNull;
      if (messages != null && messages.isNotEmpty) {
        WsClient().send('/app/chat.read', body: jsonEncode({
          'conversationId': widget.conversationId,
          'messageId': messages.first.id,
        }));
      }
    } catch (_) {}
  }

  void _loadMuteState() {
    final convState = ref.read(conversationsProvider);
    convState.whenData((conversations) {
      final conv = conversations
          .where((c) => c.id == widget.conversationId)
          .firstOrNull;
      if (conv != null && mounted) {
        setState(() => _notificationsMuted = conv.isMuted);
      }
    });
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    if (hasText) _notifyTyping();
  }

  void _subscribeToMessages() {
    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) return;

    final ws = WsClient();
    ws.subscribe('/user/$userId/queue/messages', (frame) {
      if (frame.body == null) return;
      final data = jsonDecode(frame.body!);
      if (data is Map<String, dynamic>) {
        final type = data['type'] as String?;
        if (type == 'typing') {
          _handleTypingEvent(data);
        } else if (type == 'message_edited') {
          _handleMessageEdited(data);
        } else if (type == 'message_deleted') {
          _handleMessageDeleted(data);
        } else if (type == 'message_pinned' || type == 'message_unpinned') {
          ref.read(messagesProvider(widget.conversationId).notifier).load();
        } else if (data.containsKey('clientMessageId') &&
            data['conversationId'] == widget.conversationId) {
          final msg = MessageModel.fromJson(data);
          ref
              .read(messagesProvider(widget.conversationId).notifier)
              .addMessage(msg);
          _markAsRead();
        }
      }
    });

    // Subscribe to status updates (DELIVERED, READ)
    ws.subscribe('/user/$userId/queue/status', (frame) {
      if (frame.body == null) return;
      final data = jsonDecode(frame.body!);
      if (data is Map<String, dynamic>) {
        final messageId = data['messageId'] as String?;
        final status = data['status'] as String?;
        final convId = data['conversationId'] as String?;
        if (messageId != null && status != null && convId == widget.conversationId) {
          final messages = ref.read(messagesProvider(widget.conversationId)).valueOrNull ?? [];
          final msgIdx = messages.indexWhere((m) => m.id == messageId);
          if (msgIdx >= 0) {
            final msg = messages[msgIdx];
            final updated = MessageModel(
              id: msg.id,
              conversationId: msg.conversationId,
              senderId: msg.senderId,
              text: msg.text,
              fileUrl: msg.fileUrl,
              mimeType: msg.mimeType,
              clientMessageId: msg.clientMessageId,
              status: status,
              createdAt: msg.createdAt,
              isVoiceMessage: msg.isVoiceMessage,
              voiceDuration: msg.voiceDuration,
              voiceWaveform: msg.voiceWaveform,
              replyToId: msg.replyToId,
              forwardedFromId: msg.forwardedFromId,
              isPinned: msg.isPinned,
              isEdited: msg.isEdited,
              isDeleted: msg.isDeleted,
              editedAt: msg.editedAt,
            );
            ref
                .read(messagesProvider(widget.conversationId).notifier)
                .updateMessage(messageId, updated);
          }
        }
      }
    });
  }

  void _handleTypingEvent(Map<String, dynamic> data) {
    if (data['conversationId'] != widget.conversationId) return;
    if (data['userId'] == ref.read(authStateProvider).user?.id) return;
    if (!mounted) return;
    setState(() => _participantTyping = true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _participantTyping = false);
    });
  }

  void _handleMessageEdited(Map<String, dynamic> data) {
    if (data['conversationId'] != widget.conversationId) return;
    ref.read(messagesProvider(widget.conversationId).notifier).load();
  }

  void _handleMessageDeleted(Map<String, dynamic> data) {
    if (data['conversationId'] != widget.conversationId) return;
    final msgId = data['messageId'] as String;
    ref
        .read(messagesProvider(widget.conversationId).notifier)
        .removeMessage(msgId);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(messagesProvider(widget.conversationId).notifier).loadMore();
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final clientMsgId = _uuid.v4();
    final body = {
      'conversationId': widget.conversationId,
      'text': text,
      'clientMessageId': clientMsgId,
      if (_replyTo != null) 'replyToId': _replyTo!.id,
    };

    _textController.clear();
    setState(() => _replyTo = null);

    await WsClient().send('/app/chat.send', body: jsonEncode(body));
    _notifyTyping(false);
  }

  void _notifyTyping([bool typing = true]) {
    if (!typing) return;
    WsClient().send(
      '/app/chat.typing',
      body: jsonEncode({'conversationId': widget.conversationId}),
    );
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null) return;

    try {
      final api = ApiClient().dio;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(xFile.path, filename: xFile.name),
      });
      final uploadRes = await api.post('/files/upload', data: formData);
      final fileUrl = uploadRes.data['fileUrl'] as String;
      final mimeType = uploadRes.data['mimeType'] as String?;

      final clientMsgId = _uuid.v4();
      WsClient().send(
        '/app/chat.send',
        body: jsonEncode({
          'conversationId': widget.conversationId,
          'fileUrl': fileUrl,
          'mimeType': mimeType,
          'clientMessageId': clientMsgId,
        }),
      );
    } catch (_) {}
  }

  // ── Date divider helpers ──────────────────────────────────────────────

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) return 'Сегодня';
    if (messageDay == today.subtract(const Duration(days: 1))) return 'Вчера';
    return '${date.day} ${_ruMonths[date.month - 1]} ${date.year}';
  }

  bool _shouldShowDateDivider(List<MessageModel> messages, int index) {
    if (index == messages.length - 1) return true;
    try {
      final current = DateTime.parse(messages[index].createdAt);
      final next = DateTime.parse(messages[index + 1].createdAt);
      return current.year != next.year ||
          current.month != next.month ||
          current.day != next.day;
    } catch (_) {
      return false;
    }
  }

  // ── Context menu ──────────────────────────────────────────────────────

  void _showMessageContextMenu(MessageModel msg) {
    final userId = ref.read(authStateProvider).user?.id;
    final isMine = msg.senderId == userId;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Ответить'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _replyTo = msg);
              },
            ),
            if (msg.text != null)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Копировать'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: msg.text!));
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Скопировано'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Переслать'),
              onTap: () {
                Navigator.pop(context);
                _forwardMessage(msg);
              },
            ),
            ListTile(
              leading: Icon(
                msg.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(msg.isPinned ? 'Открепить' : 'Закрепить'),
              onTap: () {
                Navigator.pop(context);
                final dest =
                    msg.isPinned ? '/app/chat.unpin' : '/app/chat.pin';
                WsClient()
                    .send(dest, body: jsonEncode({'messageId': msg.id}));
              },
            ),
            if (isMine) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Редактировать'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(msg);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Удалить',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  WsClient().send('/app/chat.delete',
                      body: jsonEncode({'messageId': msg.id}));
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Edit ───────────────────────────────────────────────────────────────

  void _editMessage(MessageModel msg) {
    final editController = TextEditingController(text: msg.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Редактировать сообщение'),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != msg.text) {
                WsClient().send('/app/chat.edit',
                    body: jsonEncode({'messageId': msg.id, 'text': newText}));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  // ── Forward (bottom sheet with multi-select) ──────────────────────────

  void _forwardMessage(MessageModel msg) {
    final convState = ref.read(conversationsProvider);
    convState.whenData((conversations) {
      final selected = <String>{};

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (ctx, scrollCtrl) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Переслать сообщение',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      itemCount: conversations.length,
                      itemBuilder: (_, i) {
                        final c = conversations[i];
                        final isSelected = selected.contains(c.id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setSheetState(() {
                              if (val == true) {
                                selected.add(c.id);
                              } else {
                                selected.remove(c.id);
                              }
                            });
                          },
                          secondary: CircleAvatar(
                            backgroundImage: c.participant.avatarUrl != null
                                ? NetworkImage(c.participant.avatarUrl!)
                                : null,
                            child: c.participant.avatarUrl == null
                                ? Text(c.participant.name[0].toUpperCase())
                                : null,
                          ),
                          title: Text(c.participant.name),
                        );
                      },
                    ),
                  ),
                  if (selected.isNotEmpty) ...[
                    const Divider(height: 1),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Text(
                              'Выбрано: ${selected.length}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                WsClient().send(
                                  '/app/chat.forward',
                                  body: jsonEncode({
                                    'messageId': msg.id,
                                    'toConversationIds': selected.toList(),
                                  }),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Сообщение переслано'),
                                  ),
                                );
                              },
                              child: const Text('Переслать'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      );
    });
  }

  // ── Chat menu actions ─────────────────────────────────────────────────

  void _toggleNotifications() {
    setState(() => _notificationsMuted = !_notificationsMuted);
    final dest = _notificationsMuted
        ? '/app/conversation.mute'
        : '/app/conversation.unmute';
    WsClient().send(
      dest,
      body: jsonEncode({'conversationId': widget.conversationId}),
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить историю'),
        content: const Text('Вы уверены, что хотите очистить историю чата?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ApiClient()
                  .dio
                  .delete(
                      '/conversations/${widget.conversationId}/messages')
                  .then((_) {
                ref
                    .read(messagesProvider(widget.conversationId).notifier)
                    .load();
              }).catchError((_) {});
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить чат'),
        content: const Text('Вы уверены, что хотите удалить этот чат?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ApiClient()
                  .dio
                  .delete('/conversations/${widget.conversationId}')
                  .then((_) {
                ref.read(conversationsProvider.notifier).load();
                if (mounted) context.go('/');
              }).catchError((_) {});
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _searchMsgController.dispose();
    _typingTimer?.cancel();
    _recordTimer?.cancel();
    _recorder.closeRecorder();
    super.dispose();
  }

  // ── Voice recording ──────────────────────────────────────────────────

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет доступа к микрофону')),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    _recordPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder.startRecorder(
      toFile: _recordPath,
      codec: Codec.aacADTS,
    );
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSeconds++);
    });
  }

  Future<void> _stopAndSendVoice() async {
    _recordTimer?.cancel();
    await _recorder.stopRecorder();
    if (!mounted) return;
    setState(() => _isRecording = false);

    final path = _recordPath;
    if (path == null) return;

    final file = File(path);
    if (!file.existsSync()) return;

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: 'voice.aac'),
      });
      final uploadRes = await ApiClient().dio.post('/files/upload', data: formData);
      final fileUrl = uploadRes.data is Map ? (uploadRes.data['url'] ?? uploadRes.data['fileUrl'] ?? '') : '';
      if (fileUrl.toString().isEmpty) return;

      final body = {
        'conversationId': widget.conversationId,
        'content': '',
        'clientMessageId': _uuid.v4(),
        'fileUrl': fileUrl,
        'mimeType': 'audio/aac',
        'isVoiceMessage': true,
        'voiceDuration': _recordSeconds,
      };
      await WsClient().send('/app/chat.send', body: jsonEncode(body));
    } catch (e) {
      debugPrint('[VOICE] upload/send error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка отправки голосового')),
        );
      }
    } finally {
      try { file.deleteSync(); } catch (_) {}
    }
  }

  void _cancelRecording() {
    _recordTimer?.cancel();
    _recorder.stopRecorder();
    setState(() => _isRecording = false);
    if (_recordPath != null) {
      try { File(_recordPath!).deleteSync(); } catch (_) {}
    }
  }

  String _formatRecordTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(messagesProvider(widget.conversationId));
    final userId = ref.watch(authStateProvider).user?.id;
    final theme = Theme.of(context);

    final isOnline = ref.watch(conversationsProvider).whenOrNull(
          data: (convs) => convs
              .where((c) => c.id == widget.conversationId)
              .firstOrNull
              ?.participant
              .isOnline,
        );

    final statusText = _participantTyping
        ? 'печатает...'
        : (isOnline == true ? 'в сети' : 'не в сети');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchMsgController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Поиск по чату...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) =>
                    setState(() => _searchMsgQuery = v.toLowerCase()),
              )
            : InkWell(
                onTap: () => context.push('/profile/${widget.participantId}'),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: widget.participantAvatar != null
                          ? NetworkImage(widget.participantAvatar!)
                          : null,
                      child: widget.participantAvatar == null
                          ? Text(widget.participantName.isNotEmpty
                              ? widget.participantName[0].toUpperCase()
                              : '?')
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.participantName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: _participantTyping
                                  ? theme.colorScheme.primary
                                  : (isOnline == true
                                      ? Colors.greenAccent
                                      : Colors.white54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        actions: _isSearching
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchMsgController.clear();
                      _searchMsgQuery = '';
                    });
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.videocam),
                  tooltip: 'Видеозвонок',
                  onPressed: () => context.push(
                    '/call?calleeId=${widget.participantId}'
                    '&calleeName=${Uri.encodeComponent(widget.participantName)}'
                    '&callType=VIDEO',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone),
                  tooltip: 'Аудиозвонок',
                  onPressed: () => context.push(
                    '/call?calleeId=${widget.participantId}'
                    '&calleeName=${Uri.encodeComponent(widget.participantName)}'
                    '&callType=AUDIO',
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'mute':
                        _toggleNotifications();
                      case 'search':
                        setState(() => _isSearching = true);
                      case 'clear':
                        _confirmClearHistory();
                      case 'delete':
                        _confirmDeleteChat();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'mute',
                      child: Row(
                        children: [
                          Icon(
                            _notificationsMuted
                                ? Icons.notifications_off
                                : Icons.notifications,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(_notificationsMuted
                              ? 'Включить уведомления'
                              : 'Выключить уведомления'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'search',
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 20),
                          SizedBox(width: 12),
                          Text('Поиск по чату'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.cleaning_services,
                              size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Очистить историю',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Удалить чат',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  const Center(child: Text('Ошибка загрузки сообщений')),
              data: (messages) {
                var filtered = messages;
                if (_searchMsgQuery.isNotEmpty) {
                  filtered = messages
                      .where((m) =>
                          m.text?.toLowerCase().contains(_searchMsgQuery) ==
                          true)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Сообщений пока нет',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final msg = filtered[index];
                    final isMine = msg.senderId == userId;
                    final showDivider =
                        _shouldShowDateDivider(filtered, index);

                    Widget bubble = GestureDetector(
                      onLongPress: () => _showMessageContextMenu(msg),
                      child: MessageBubble(
                        message: msg,
                        isMine: isMine,
                      ),
                    );

                    if (showDivider) {
                      DateTime? date;
                      try {
                        date = DateTime.parse(msg.createdAt);
                      } catch (_) {}

                      return Column(
                        children: [
                          if (date != null) _buildDateDivider(date),
                          bubble,
                        ],
                      );
                    }

                    return bubble;
                  },
                );
              },
            ),
          ),

          // ── Reply bar ───────────────────────────────────────────────
          if (_replyTo != null)
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.reply,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Container(
                    width: 3,
                    height: 30,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _replyTo!.senderId == userId
                              ? 'Вы'
                              : widget.participantName,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _replyTo!.text ?? 'Вложение',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ],
              ),
            ),

          // ── Input bar ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: theme.appBarTheme.backgroundColor,
            ),
            child: SafeArea(
              top: false,
              child: _isRecording
                  ? Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: _cancelRecording,
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.circle, color: Colors.red, size: 10),
                        const SizedBox(width: 6),
                        Text(
                          _formatRecordTime(_recordSeconds),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _stopAndSendVoice,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.attach_file, color: Colors.white70),
                          onPressed: _pickAndSendImage,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Сообщение...',
                              hintStyle: const TextStyle(color: Colors.white38),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            _hasText ? Icons.send : Icons.mic,
                            color: Colors.white,
                          ),
                          onPressed: _hasText ? _sendMessage : _startRecording,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDateLabel(date),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
