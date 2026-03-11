import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  ConsumerState<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState
    extends ConsumerState<AppearanceSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Внешний вид')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section (2x2 grid)
          Text('Тема', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: AppThemeType.values.map((type) {
              final isSelected = themeState.type == type;
              return _ThemePreviewCard(
                themeType: type,
                label: _themeName(type),
                isSelected: isSelected,
                onTap: () => themeNotifier.setTheme(type),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Accent Color Section (7 circles in a row)
          Text('Акцентный цвет', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              AppColors.accentColors.length,
              (i) => GestureDetector(
                onTap: () => themeNotifier.setAccent(i),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentColors[i],
                    shape: BoxShape.circle,
                    border: themeState.accentIndex == i
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: themeState.accentIndex == i
                      ? const Icon(Icons.check, color: Colors.white, size: 22)
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // System Theme Toggle
          Text('Системная тема', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.light_mode),
            title: const Text('Как в системе'),
            trailing: Switch(
              value: themeState.followSystemTheme,
              onChanged: (v) => themeNotifier.setFollowSystemTheme(v),
            ),
          ),
        ],
      ),
    );
  }

  String _themeName(AppThemeType type) {
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
}

class _ThemePreviewData {
  final Color bg;
  final Color sentBubble;
  final Color sentText;
  final Color receivedBubble;
  final Color receivedText;

  const _ThemePreviewData({
    required this.bg,
    required this.sentBubble,
    required this.sentText,
    required this.receivedBubble,
    required this.receivedText,
  });
}

class _ThemePreviewCard extends StatelessWidget {
  final AppThemeType themeType;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemePreviewCard({
    required this.themeType,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  static const _previewData = {
    AppThemeType.light: _ThemePreviewData(
      bg: Color(0xFFf6f7fb),
      sentBubble: Color(0xFF7c8cff),
      sentText: Colors.white,
      receivedBubble: Color(0xFFFFFFFF),
      receivedText: Color(0xFF1f2242),
    ),
    AppThemeType.dark: _ThemePreviewData(
      bg: Color(0xFF1A1A2E),
      sentBubble: Color(0xFF31F196),
      sentText: Colors.black,
      receivedBubble: Color(0xFF2E3142),
      receivedText: Colors.white,
    ),
    AppThemeType.midnight: _ThemePreviewData(
      bg: Color(0xFF252735),
      sentBubble: Color(0xFF57C9FA),
      sentText: Colors.black,
      receivedBubble: Color(0xFF3D4A5D),
      receivedText: Colors.white,
    ),
    AppThemeType.amoled: _ThemePreviewData(
      bg: Color(0xFFFCFFFF),
      sentBubble: Color(0xFF57C9FA),
      sentText: Color(0xFF19345D),
      receivedBubble: Color(0xFFB3EDF2),
      receivedText: Color(0xFF19345D),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final data = _previewData[themeType]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: data.bg,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Received: "Привет!"
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _MessageBubble(
                        text: 'Привет!',
                        bg: data.receivedBubble,
                        textColor: data.receivedText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Received: "Как дела?"
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _MessageBubble(
                        text: 'Как дела?',
                        bg: data.receivedBubble,
                        textColor: data.receivedText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Sent: "Все отлично!"
                    Align(
                      alignment: Alignment.centerRight,
                      child: _MessageBubble(
                        text: 'Все отлично!',
                        bg: data.sentBubble,
                        textColor: data.sentText,
                        isSent: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: data.receivedText,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;
  final bool isSent;

  const _MessageBubble({
    required this.text,
    required this.bg,
    required this.textColor,
    this.isSent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isSent ? 16 : 4),
          bottomRight: Radius.circular(isSent ? 4 : 16),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: textColor),
      ),
    );
  }
}
