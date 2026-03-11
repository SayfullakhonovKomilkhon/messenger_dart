import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

class ConversationsSettingsScreen extends ConsumerStatefulWidget {
  const ConversationsSettingsScreen({super.key});

  @override
  ConsumerState<ConversationsSettingsScreen> createState() =>
      _ConversationsSettingsScreenState();
}

class _ConversationsSettingsScreenState
    extends ConsumerState<ConversationsSettingsScreen> {
  Map<String, dynamic> _settings = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final res = await ApiClient().dio.get('/users/me/settings');
      setState(() {
        _settings = res.data is Map<String, dynamic>
            ? Map<String, dynamic>.from(res.data)
            : {};
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    setState(() {
      _settings['conversations'] =
          Map<String, dynamic>.from(_settings['conversations'] ?? {});
      (_settings['conversations'] as Map<String, dynamic>)[key] = value;
    });
    try {
      await ApiClient().dio.patch('/users/me/settings', data: {
        'conversations': {key: value},
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить настройку')),
        );
      }
    }
  }

  bool _getBool(String key) {
    final conv = _settings['conversations'];
    if (conv is Map && conv.containsKey(key)) return conv[key] == true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Беседы'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 8),

                _SectionHeader(title: 'Очистка сообщений'),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    title: const Text('Очистка сообществ'),
                    subtitle: const Text(
                      'Удалять сообщения из сообществ старше 6 месяцев или если их более 2000',
                    ),
                    value: _getBool('communityCleanup'),
                    onChanged: (v) => _updateSetting('communityCleanup', v),
                  ),
                ),

                const SizedBox(height: 16),
                _SectionHeader(title: 'Клавиша Enter'),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    title: const Text('Отправка клавишей Enter'),
                    subtitle: const Text(
                      'Нажатие клавиши Enter отправит ваше сообщение',
                    ),
                    value: _getBool('enterSends'),
                    onChanged: (v) => _updateSetting('enterSends', v),
                  ),
                ),

                const SizedBox(height: 16),
                _SectionHeader(title: 'Голосовые сообщения'),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    title: const Text('Автовоспроизведение'),
                    subtitle: const Text(
                      'Автоматически воспроизводить сообщения по очереди',
                    ),
                    value: _getBool('autoPlayVoice'),
                    onChanged: (v) => _updateSetting('autoPlayVoice', v),
                  ),
                ),

                const SizedBox(height: 16),
                _SectionHeader(title: 'Заблокированные контакты'),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text('Заблокированные контакты'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => context.push('/settings/blocked'),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
