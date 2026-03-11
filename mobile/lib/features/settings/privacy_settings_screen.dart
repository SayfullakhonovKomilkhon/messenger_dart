import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
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
      _settings['privacy'] =
          Map<String, dynamic>.from(_settings['privacy'] ?? {});
      (_settings['privacy'] as Map<String, dynamic>)[key] = value;
    });
    try {
      await ApiClient().dio.patch('/users/me/settings', data: {
        'privacy': {key: value},
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить настройку')),
        );
      }
    }
  }

  bool _getBool(String key, {bool defaultValue = false}) {
    final privacy = _settings['privacy'];
    if (privacy is Map && privacy.containsKey(key)) {
      return privacy[key] == true;
    }
    return defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Конфиденциальность'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _PrivacySection(
                  header: 'Голос и видео (Бета)',
                  children: [
                    SwitchListTile(
                      title: const Text('Голосовые и видеозвонки'),
                      subtitle: const Text(
                        'Разрешить входящие и исходящие звонки',
                      ),
                      value: _getBool('voiceVideoCalls', defaultValue: true),
                      onChanged: (v) => _updateSetting('voiceVideoCalls', v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                _PrivacySection(
                  header: 'Безопасность экрана',
                  children: [
                    SwitchListTile(
                      title: const Text('Заблокировать приложение'),
                      subtitle: const Text(
                        'Использовать Touch ID, Face ID или пароль устройства для входа в Demos',
                      ),
                      value: _getBool('blockApp'),
                      onChanged: (v) => _updateSetting('blockApp', v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                _PrivacySection(
                  children: [
                    ListTile(
                      title: const Text('Запросы сообщений'),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => context.push('/settings/message-requests'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                _PrivacySection(
                  children: [
                    SwitchListTile(
                      title: const Text('Отчеты о прочтении'),
                      subtitle: const Text(
                        'Отправлять отчеты о прочтении в личных чатах',
                      ),
                      value: _getBool('readReceipts', defaultValue: true),
                      onChanged: (v) => _updateSetting('readReceipts', v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                _PrivacySection(
                  children: [
                    SwitchListTile(
                      title: const Text('Индикаторы набора текста'),
                      subtitle: const Text(
                        'Видеть и показывать, когда кто-то печатает',
                      ),
                      value: _getBool('typingIndicators', defaultValue: true),
                      onChanged: (v) => _updateSetting('typingIndicators', v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                _PrivacySection(
                  children: [
                    SwitchListTile(
                      title: const Text('Предпросмотр ссылок'),
                      subtitle: const Text(
                        'Создавать превью для поддерживаемых ссылок',
                      ),
                      value: _getBool('linkPreview', defaultValue: true),
                      onChanged: (v) => _updateSetting('linkPreview', v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                _PrivacySection(
                  children: [
                    SwitchListTile(
                      title: const Text('Инкогнито-клавиатура'),
                      subtitle: const Text(
                        'Запретить клавиатуре запоминать вводимые слова',
                      ),
                      value: _getBool('incognitoKeyboard', defaultValue: true),
                      onChanged: (v) =>
                          _updateSetting('incognitoKeyboard', v),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final String? header;
  final List<Widget> children;

  const _PrivacySection({
    this.header,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                header!,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}
