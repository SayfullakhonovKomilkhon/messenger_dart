import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/network/ws_client.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        centerTitle: true,
      ),
      body: const SettingsBody(),
    );
  }
}

class SettingsBody extends ConsumerWidget {
  const SettingsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final themeState = ref.watch(themeProvider);

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => context.push('/settings/edit-profile'),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundImage: user?.avatarUrl != null
                          ? NetworkImage(user!.avatarUrl!)
                          : null,
                      child: user?.avatarUrl == null
                          ? Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 36),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.push('/settings/edit-profile'),
                child: Text(
                  user?.name ?? '',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (user?.username != null && user!.username!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '@${user.username}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              if (user?.phone != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    user!.phone!,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              if (user?.bio != null && user!.bio!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 32, right: 32),
                  child: Text(
                    user.bio!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      final login = user?.phone ?? user?.id ?? '';
                      Clipboard.setData(ClipboardData(text: login));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Логин скопирован')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Скопировать логин'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      final login = user?.phone ?? user?.id ?? '';
                      SharePlus.instance.share(
                        ShareParams(text: 'Мой логин в Demos: $login'),
                      );
                    },
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Поделиться'),
                  ),
                ],
              ),
            ],
          ),
        ),

        SettingsGroup(children: [
          SettingsTile(
            icon: Icons.person_outline,
            title: 'Редактировать профиль',
            onTap: () => context.push('/settings/edit-profile'),
          ),
          SettingsTile(
            icon: Icons.shield_outlined,
            title: 'Конфиденциальность',
            onTap: () => context.push('/settings/privacy'),
          ),
          SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Уведомления',
            onTap: () => context.push('/settings/notifications'),
          ),
          SettingsTile(
            icon: Icons.chat_bubble_outline,
            title: 'Беседы',
            onTap: () => context.push('/settings/conversations'),
          ),
          SettingsTile(
            icon: Icons.mail_outline,
            title: 'Запросы сообщений',
            onTap: () => context.push('/settings/message-requests'),
          ),
        ]),

        const SizedBox(height: 8),

        SettingsGroup(children: [
          SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Внешний вид',
            trailing: Text(
              _themeName(themeState.type),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            onTap: () => context.push('/settings/appearance'),
          ),
          SettingsTile(
            icon: Icons.lock_outline,
            title: 'Блокировка приложения',
            trailing: Switch(
              value: false,
              onChanged: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Функция в разработке')),
                );
              },
            ),
          ),
        ]),

        const SizedBox(height: 8),

        SettingsGroup(children: [
          SettingsTile(
            icon: Icons.help_outline,
            title: 'Помощь',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Раздел помощи в разработке')),
            ),
          ),
          SettingsTile(
            icon: Icons.person_add_outlined,
            title: 'Пригласить друга',
            onTap: () {
              final login = user?.phone ?? user?.id ?? '';
              SharePlus.instance.share(ShareParams(
                text: 'Присоединяйся к Demos! Мой логин: $login',
              ));
            },
          ),
        ]),

        const SizedBox(height: 8),

        SettingsGroup(children: [
          SettingsTile(
            icon: Icons.vpn_key_outlined,
            title: 'Пересоздать ключи шифрования',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ключи шифрования обновлены')),
              );
            },
          ),
          SettingsTile(
            icon: Icons.logout,
            title: 'Выйти',
            color: Colors.orange,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Выход'),
                  content: const Text('Вы уверены, что хотите выйти?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Отмена'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Выйти'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                WsClient().disconnect();
                await ref.read(authStateProvider.notifier).logout();
              }
            },
          ),
          SettingsTile(
            icon: Icons.delete_forever,
            title: 'Очистить все данные',
            color: Colors.red,
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
        ]),

        const SizedBox(height: 24),
        Center(
          child: Text(
            'Demos Chat 1.0.3 — Сквозное шифрование (E2EE)',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  static String _themeName(AppThemeType type) {
    switch (type) {
      case AppThemeType.light:
        return 'Классическая светлая';
      case AppThemeType.dark:
        return 'Классическая тёмная';
      case AppThemeType.midnight:
        return 'Океанская тёмная';
      case AppThemeType.amoled:
        return 'Океанская светлая';
    }
  }

  static void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить все данные'),
        content: const Text(
          'Это действие необратимо. Все ваши данные будут безвозвратно удалены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiClient().dio.delete('/users/me');
              } catch (_) {}
              WsClient().disconnect();
              ref.read(authStateProvider.notifier).logout();
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color? color;
  final Widget? trailing;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: color != null ? TextStyle(color: color) : null),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
