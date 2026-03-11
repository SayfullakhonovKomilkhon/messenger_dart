import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/user_model.dart';
import '../../core/network/api_client.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  UserModel? _user;
  bool _loading = true;
  bool _isBlocked = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient().dio.get('/users/${widget.userId}');
      setState(() {
        _user = UserModel.fromJson(res.data);
        _loading = false;
      });
      _checkBlocked();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkBlocked() async {
    try {
      final res = await ApiClient().dio.get('/users/me/blocked');
      final blocked = (res.data as List).cast<Map<String, dynamic>>();
      setState(() {
        _isBlocked = blocked.any((b) => b['id'] == widget.userId);
      });
    } catch (_) {}
  }

  Future<void> _toggleBlock() async {
    try {
      if (_isBlocked) {
        await ApiClient().dio.delete('/users/${widget.userId}/block');
      } else {
        await ApiClient().dio.post('/users/${widget.userId}/block');
      }
      setState(() => _isBlocked = !_isBlocked);
    } catch (_) {}
  }

  Future<void> _startChat() async {
    try {
      final res = await ApiClient().dio.post('/conversations', data: {
        'participantId': widget.userId,
      });
      final convId = res.data['id'] as String;
      if (mounted) {
        context.push(
          '/conversation/$convId?name=${Uri.encodeComponent(_user?.name ?? '')}'
          '&participantId=${widget.userId}',
        );
      }
    } catch (_) {}
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Заблокировать этого пользователя?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _toggleBlock();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Заблокировать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Информация'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Информация'),
          centerTitle: true,
        ),
        body: const Center(child: Text('Пользователь не найден')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Информация'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          // Profile Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundImage: _user!.avatarUrl != null
                      ? NetworkImage(_user!.avatarUrl!)
                      : null,
                  child: _user!.avatarUrl == null
                      ? Text(
                          _user!.name.isNotEmpty
                              ? _user!.name[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  _user!.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user!.id,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontFamilyFallback: const ['monospace'],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Action Row (3 buttons)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _startChat,
                    icon: const Icon(Icons.chat),
                    label: const Text('Написать'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push(
                      '/call?calleeId=${widget.userId}'
                      '&calleeName=${Uri.encodeComponent(_user!.name)}'
                      '&callType=AUDIO',
                    ),
                    icon: const Icon(Icons.phone),
                    label: const Text('Позвонить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _isMuted = !_isMuted),
                    icon: Icon(_isMuted ? Icons.notifications_off : Icons.notifications),
                    label: Text(_isMuted ? 'Вкл' : 'Без звука'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Disappearing Messages Section
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Исчезающие сообщения'),
            trailing: const Text('Выкл'),
          ),
          const Divider(height: 1),
          // Settings Section
          ListTile(
            title: const Text('Уведомления'),
            trailing: const Text('По умолчанию'),
          ),
          ListTile(
            title: const Text('Исчезающие сообщения'),
            trailing: const Text('Выкл'),
          ),
          const SizedBox(height: 16),
          // Media Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Медиафайлы',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                  children: List.generate(4, (_) => _MediaPlaceholder()),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text('Все медиа'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          // Privacy Section
          ListTile(
            title: const Text('Настройки конфиденциальности'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/privacy'),
          ),
          const Divider(height: 1),
          // Danger Section
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text(
              'Заблокировать',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
            onTap: _isBlocked ? _toggleBlock : _showBlockDialog,
          ),
        ],
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.image, size: 48, color: Colors.grey),
    );
  }
}
