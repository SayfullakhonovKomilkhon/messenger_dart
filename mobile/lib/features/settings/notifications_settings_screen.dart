import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends ConsumerState<NotificationsSettingsScreen> {
  Map<String, dynamic> _settings = {};
  bool _loading = true;

  static const _soundOptions = ['default', 'none', 'system'];
  static const _soundLabels = ['По умолчанию', 'Нет', 'Системный'];

  static const _contentOptions = ['name_and_text', 'name_only', 'hidden'];
  static const _contentLabels = [
    'Имя и текст',
    'Только имя',
    'Без имени и текста',
  ];

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
      _settings['notifications'] =
          Map<String, dynamic>.from(_settings['notifications'] ?? {});
      (_settings['notifications'] as Map<String, dynamic>)[key] = value;
    });
    try {
      await ApiClient().dio.patch('/users/me/settings', data: {
        'notifications': {key: value},
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
    final notif = _settings['notifications'];
    if (notif is Map && notif.containsKey(key)) return notif[key] == true;
    return defaultValue;
  }

  String _getString(String key, String defaultValue) {
    final notif = _settings['notifications'];
    if (notif is Map && notif[key] != null) return notif[key].toString();
    return defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Стратегия',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Быстрый режим'),
                        subtitle: const Text(
                          'Вы будете получать уведомления о новых сообщениях мгновенно через серверы Google',
                        ),
                        value: _getBool('fastMode', defaultValue: true),
                        onChanged: (v) => _updateSetting('fastMode', v),
                      ),
                      ListTile(
                        title:
                            const Text('Настройки уведомлений устройства'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Функция в разработке'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Стиль',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      ListTile(
                        title: const Text('Звук'),
                        trailing: DropdownButton<String>(
                          value: _soundOptions.contains(
                                  _getString('sound', 'default'))
                              ? _getString('sound', 'default')
                              : 'default',
                          items: List.generate(
                            _soundOptions.length,
                            (i) => DropdownMenuItem(
                              value: _soundOptions[i],
                              child: Text(_soundLabels[i]),
                            ),
                          ),
                          onChanged: (v) {
                            if (v != null) _updateSetting('sound', v);
                          },
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Звук при открытом приложении'),
                        value: _getBool('soundWhenAppOpen'),
                        onChanged: (v) =>
                            _updateSetting('soundWhenAppOpen', v),
                      ),
                      SwitchListTile(
                        title: const Text('Вибрация'),
                        value: _getBool('vibration', defaultValue: true),
                        onChanged: (v) => _updateSetting('vibration', v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Содержимое',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      ListTile(
                        title: const Text('Содержимое уведомлений'),
                        subtitle: const Text(
                          'Выберите, какая информация будет видна в уведомлениях',
                        ),
                        trailing: DropdownButton<String>(
                          value: _contentOptions.contains(_getString(
                                  'notificationContent', 'name_and_text'))
                              ? _getString(
                                  'notificationContent', 'name_and_text')
                              : 'name_and_text',
                          items: List.generate(
                            _contentOptions.length,
                            (i) => DropdownMenuItem(
                              value: _contentOptions[i],
                              child: Text(_contentLabels[i]),
                            ),
                          ),
                          onChanged: (v) {
                            if (v != null) {
                              _updateSetting('notificationContent', v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
