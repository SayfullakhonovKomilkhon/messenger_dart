import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../core/models/conversation_model.dart';
import '../../core/models/message_model.dart';
import '../../core/network/api_client.dart';
import '../../core/network/ws_client.dart';
import '../../core/theme/app_colors.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String _searchQuery = '';
  bool _isSearching = false;
  final _searchController = TextEditingController();

  // Multi-select
  final Set<String> _selectedIds = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  // Connection
  bool _isConnected = false;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationsProvider.notifier).load();
      _connectWebSocket();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      ref.read(conversationsProvider.notifier).load();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(conversationsProvider.notifier).load();
    }
  }

  Future<void> _connectWebSocket() async {
    final ws = WsClient();
    try {
      await ws.connect();
      if (!mounted) return;
      setState(() => _isConnected = true);
      final userId = ref.read(authStateProvider).user?.id;
      ws.subscribe('/user/$userId/queue/messages', (frame) {
        if (frame.body == null) return;
        final data = jsonDecode(frame.body!);
        if (data is Map<String, dynamic>) {
          if (data.containsKey('clientMessageId')) {
            final msg = MessageModel.fromJson(data);
            ref.read(conversationsProvider.notifier).addOrUpdateFromMessage(msg);
          }
        }
      });

      // Subscribe to incoming call events
      ws.subscribe('/user/$userId/queue/call', (frame) {
        if (frame.body == null) return;
        final data = jsonDecode(frame.body!);
        if (data is Map<String, dynamic>) {
          final type = data['type'] as String?;
          if (type == 'CALL_INCOMING') {
            final callId = data['callId'] as String? ?? '';
            final callerId = data['callerId'] as String? ?? '';
            final callType = data['callType'] as String? ?? 'AUDIO';
            final eventData = data['data'] as Map<String, dynamic>?;
            String callerName = eventData?['callerName'] as String? ??
                data['callerName'] as String? ?? '';
            if (callerName.isEmpty) {
              callerName = 'Неизвестный';
            }
            if (mounted && callId.isNotEmpty && callerId != userId) {
              context.push(
                '/call?callId=$callId'
                '&calleeId=$callerId'
                '&calleeName=${Uri.encodeComponent(callerName)}'
                '&callType=$callType'
                '&incoming=true',
              );
            }
          }
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isConnected = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() => setState(() => _selectedIds.clear());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).user;

    return Scaffold(
      appBar: _currentIndex == 3
          ? AppBar(title: const Text('Настройки'), centerTitle: true)
          : (_isSelecting
              ? _buildSelectionAppBar(theme)
              : _buildNormalAppBar(theme, user)),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildChatList(),
          _buildCallHistoryTab(),
          _buildTelepathyTab(),
          const SettingsBody(),
        ],
      ),
      floatingActionButton: _currentIndex == 0 && !_isSelecting
          ? FloatingActionButton(
              onPressed: () => _showNewChatSheet(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          _clearSelection();
          setState(() => _currentIndex = i);
          if (i == 1) {
            ref.read(callHistoryProvider.notifier).load();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Сообщения',
          ),
          NavigationDestination(
            icon: Icon(Icons.phone_outlined),
            selectedIcon: Icon(Icons.phone),
            label: 'Звонки',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'Телепатия',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar(ThemeData theme, dynamic user) {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() {
            _isSearching = false;
            _searchController.clear();
            _searchQuery = '';
          }),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Поиск...',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _searchController.clear();
                _searchQuery = '';
              }),
            ),
        ],
      );
    }

    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: GestureDetector(
          onTap: () => setState(() => _currentIndex = 2),
          child: Center(
            child: _buildUserAvatar(user, 18),
          ),
        ),
      ),
      title: const _BrandedD(),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _isSearching = true),
        ),
        if (!_isConnected)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(ThemeData theme) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _clearSelection,
      ),
      title: Text('${_selectedIds.length}'),
      actions: [
        IconButton(
          icon: const Icon(Icons.push_pin_outlined),
          tooltip: 'Закрепить',
          onPressed: () => _bulkAction('pin'),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_off_outlined),
          tooltip: 'Без звука',
          onPressed: () => _bulkAction('mute'),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Удалить',
          onPressed: () => _bulkAction('delete'),
        ),
        PopupMenuButton<String>(
          onSelected: (v) => _bulkAction(v),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'read', child: Row(children: [Icon(Icons.visibility_outlined, size: 20), SizedBox(width: 12), Text('Пометить прочитанным')])),
            const PopupMenuItem(value: 'clear', child: Row(children: [Icon(Icons.history, size: 20, color: Colors.red), SizedBox(width: 12), Text('Очистить историю', style: TextStyle(color: Colors.red))])),
          ],
        ),
      ],
    );
  }

  Future<void> _bulkAction(String action) async {
    final api = ApiClient().dio;
    final ids = Set<String>.from(_selectedIds);
    _clearSelection();

    for (final id in ids) {
      try {
        switch (action) {
          case 'pin':
            await api.patch('/conversations/$id/pin?pinned=true');
            break;
          case 'mute':
            await api.patch('/conversations/$id/mute?muted=true');
            break;
          case 'delete':
            await api.delete('/conversations/$id');
            break;
          case 'clear':
            await api.delete('/conversations/$id/messages');
            break;
          case 'read':
            break;
        }
      } catch (_) {}
    }
    ref.read(conversationsProvider.notifier).load();
  }

  Widget _buildUserAvatar(dynamic user, double radius) {
    final name = user?.name ?? '';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.accentColors[0].withValues(alpha: 0.2),
      backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
      child: user?.avatarUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(fontSize: radius * 0.9, fontWeight: FontWeight.w600),
            )
          : null,
    );
  }

  Widget _buildChatList() {
    final convState = ref.watch(conversationsProvider);

    return convState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Не удалось загрузить чаты'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.read(conversationsProvider.notifier).load(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
      data: (conversations) {
        var filtered = conversations;
        if (_searchQuery.isNotEmpty) {
          filtered = conversations
              .where((c) => c.participant.name.toLowerCase().contains(_searchQuery))
              .toList();
        }

        final pinned = filtered.where((c) => c.isPinned).toList();
        final unpinned = filtered.where((c) => !c.isPinned).toList();
        final sorted = [...pinned, ...unpinned];

        if (sorted.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('Чатов пока нет',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Начните беседу, чтобы отправить первое сообщение',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(conversationsProvider.notifier).load(),
          child: ListView.builder(
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final conv = sorted[index];
              final isSelected = _selectedIds.contains(conv.id);
              return _ConversationTile(
                conversation: conv,
                isSelected: isSelected,
                isSelecting: _isSelecting,
                onTap: () {
                  if (_isSelecting) {
                    _toggleSelect(conv.id);
                  } else {
                    _openConversation(conv);
                  }
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  if (_isSelecting) {
                    _toggleSelect(conv.id);
                  } else {
                    _toggleSelect(conv.id);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCallHistoryTab() {
    final callsState = ref.watch(callHistoryProvider);

    return callsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Не удалось загрузить историю звонков'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.read(callHistoryProvider.notifier).load(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
      data: (calls) {
        if (calls.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('Звонков пока нет',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Здесь будет история ваших звонков',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(callHistoryProvider.notifier).load(),
          child: ListView.builder(
            itemCount: calls.length,
            itemBuilder: (context, index) {
              final call = calls[index];
              final isVideo = call.callType == 'VIDEO';
              final isMissed = call.status == 'MISSED' || call.status == 'REJECTED';

              String timeStr = '';
              if (call.startedAt != null) {
                try {
                  final dt = DateTime.parse(call.startedAt!);
                  final now = DateTime.now();
                  if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
                    timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                  } else {
                    timeStr = '${dt.day}.${dt.month.toString().padLeft(2, '0')}';
                  }
                } catch (_) {}
              }

              String durationStr = '';
              if (call.duration != null && call.duration! > 0) {
                final m = call.duration! ~/ 60;
                final s = call.duration! % 60;
                durationStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: call.participant.avatarUrl != null
                      ? NetworkImage(call.participant.avatarUrl!)
                      : null,
                  child: call.participant.avatarUrl == null
                      ? Text(
                          call.participant.name.isNotEmpty
                              ? call.participant.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 20),
                        )
                      : null,
                ),
                title: Text(
                  call.participant.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isMissed ? Colors.red : null,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Icon(
                      isMissed ? Icons.call_missed : Icons.call_made,
                      size: 14,
                      color: isMissed ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVideo ? 'Видеозвонок' : 'Аудиозвонок',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                    if (durationStr.isNotEmpty) ...[
                      Text(' • ', style: TextStyle(color: Colors.grey.shade500)),
                      Text(durationStr, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (timeStr.isNotEmpty)
                      Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(isVideo ? Icons.videocam : Icons.phone, size: 20),
                      onPressed: () => context.push(
                        '/call?calleeId=${call.participant.id}'
                        '&calleeName=${Uri.encodeComponent(call.participant.name)}'
                        '&callType=${call.callType}',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTelepathyTab() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingIcon(
            icon: Icons.psychology_outlined,
            size: 100,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 20),
          Text('Телепатия', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }


  void _openConversation(ConversationModel conv) {
    context.push(
      '/conversation/${conv.id}?name=${Uri.encodeComponent(conv.participant.name)}'
      '&participantId=${conv.participant.id}'
      '${conv.participant.avatarUrl != null ? '&avatar=${Uri.encodeComponent(conv.participant.avatarUrl!)}' : ''}',
    );
  }

  void _showNewChatSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, controller) => _NewChatSheet(scrollController: controller),
      ),
    );
  }
}

class _BrandedD extends StatelessWidget {
  const _BrandedD();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const SweepGradient(
        colors: [
          Color(0xFFFF6B6B),
          Color(0xFFE4AD3C),
          Color(0xFF28A745),
          Color(0xFF3B59FF),
          Color(0xFFFF6B6B),
        ],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(bounds),
      child: const Text(
        'D',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;

  const _PulsingIcon({required this.icon, required this.size, required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.scale(
        scale: 1.0 + _ctrl.value * 0.1,
        child: Opacity(
          opacity: 0.6 + _ctrl.value * 0.4,
          child: child,
        ),
      ),
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final bool isSelected;
  final bool isSelecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.isSelecting,
    required this.onTap,
    required this.onLongPress,
  });

  String _messagePreview(LastMessageInfo? lm) {
    if (lm == null) return 'Сообщений пока нет';
    final text = lm.text;
    if (text == null || text.isEmpty) return 'Сообщений пока нет';
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = conversation.participant;
    final lm = conversation.lastMessage;

    String timeStr = '';
    if (lm?.createdAt != null) {
      try {
        final dt = DateTime.parse(lm!.createdAt!);
        final now = DateTime.now();
        if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
          timeStr = DateFormat.Hm().format(dt);
        } else {
          timeStr = DateFormat.MMMd().format(dt);
        }
      } catch (_) {}
    }

    return Container(
      color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
      child: ListTile(
        leading: Stack(
          children: [
            if (isSelecting)
              CircleAvatar(
                radius: 24,
                backgroundColor: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : _buildAvatarContent(p),
              )
            else ...[
              CircleAvatar(
                radius: 24,
                backgroundImage: p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
                child: p.avatarUrl == null ? _buildAvatarContent(p) : null,
              ),
              if (p.isOnline == true)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.onlineGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                    ),
                  ),
                ),
            ],
          ],
        ),
        title: Row(
          children: [
            if (conversation.isPinned)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.push_pin, size: 14, color: theme.colorScheme.primary),
              ),
            Expanded(
              child: Text(
                p.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (conversation.isMuted)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.notifications_off, size: 14, color: Colors.grey.shade500),
              ),
            if (timeStr.isNotEmpty)
              Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                _messagePreview(lm),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
            if (conversation.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: conversation.isMuted ? Colors.grey : theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  conversation.unreadCount > 99 ? '99+' : '${conversation.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  Widget _buildAvatarContent(ParticipantInfo p) {
    return Text(
      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
      style: const TextStyle(fontSize: 20),
    );
  }
}

class _NewChatSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const _NewChatSheet({required this.scrollController});

  @override
  ConsumerState<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends ConsumerState<_NewChatSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/users/search', queryParameters: {'query': query});
      setState(() {
        _results = (res.data as List).cast<Map<String, dynamic>>();
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _createConversation(String participantId, String name, String? avatar) async {
    try {
      final res = await ApiClient().dio.post('/conversations', data: {
        'participantId': participantId,
      });
      final convId = res.data['id'] as String;
      ref.read(conversationsProvider.notifier).load();
      if (mounted) {
        Navigator.pop(context);
        context.push(
          '/conversation/$convId?name=${Uri.encodeComponent(name)}'
          '&participantId=$participantId'
          '${avatar != null ? '&avatar=${Uri.encodeComponent(avatar)}' : ''}',
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Text('Новый чат', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Введите логин пользователя',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: _search,
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final user = _results[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user['avatarUrl'] != null ? NetworkImage(user['avatarUrl']) : null,
                  child: user['avatarUrl'] == null
                      ? Text((user['name'] as String).isNotEmpty ? (user['name'] as String)[0].toUpperCase() : '?')
                      : null,
                ),
                title: Text(user['name'] as String),
                subtitle: user['username'] != null ? Text('@${user['username']}') : null,
                trailing: user['isOnline'] == true
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppColors.onlineGreen, shape: BoxShape.circle),
                      )
                    : null,
                onTap: () => _createConversation(
                  user['id'] as String,
                  user['name'] as String,
                  user['avatarUrl'] as String?,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
