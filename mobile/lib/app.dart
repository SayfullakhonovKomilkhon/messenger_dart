import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/providers.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/home_screen.dart';
import 'features/conversation/conversation_screen.dart';
import 'features/call/call_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/privacy_settings_screen.dart';
import 'features/settings/notifications_settings_screen.dart';
import 'features/settings/conversations_settings_screen.dart';
import 'features/settings/appearance_settings_screen.dart';
import 'features/settings/blocked_contacts_screen.dart';
import 'features/settings/message_requests_screen.dart';
import 'features/settings/edit_profile_screen.dart';
import 'features/profile/user_profile_screen.dart';
import 'features/placeholders/telepathy_screen.dart';
import 'features/placeholders/path_screen.dart';

class MessengerApp extends ConsumerWidget {
  const MessengerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final authState = ref.watch(authStateProvider);
    final systemBrightness = MediaQuery.platformBrightnessOf(context);
    final effectiveType = themeState.followSystemTheme
        ? (systemBrightness == Brightness.light
            ? AppThemeType.light
            : AppThemeType.dark)
        : themeState.type;
    final themeData = AppTheme.getTheme(
      effectiveType,
      AppColors.accentColors[themeState.accentIndex],
    );

    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        if (authState.isLoading) return null;
        final isAuth = authState.isAuthenticated;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!isAuth && !isAuthRoute) return '/login';
        if (isAuth && isAuthRoute) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const HomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (_, _) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/conversation/:id',
          builder: (_, state) => ConversationScreen(
            conversationId: state.pathParameters['id']!,
            participantName: state.uri.queryParameters['name'] ?? '',
            participantAvatar: state.uri.queryParameters['avatar'],
            participantId: state.uri.queryParameters['participantId'] ?? '',
          ),
        ),
        GoRoute(
          path: '/call',
          builder: (_, state) => CallScreen(
            callId: state.uri.queryParameters['callId'] ?? '',
            calleeId: state.uri.queryParameters['calleeId'] ?? '',
            calleeName: state.uri.queryParameters['calleeName'] ?? '',
            callType: state.uri.queryParameters['callType'] ?? 'AUDIO',
            isIncoming: state.uri.queryParameters['incoming'] == 'true',
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, _) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/settings/privacy',
          builder: (_, _) => const PrivacySettingsScreen(),
        ),
        GoRoute(
          path: '/settings/notifications',
          builder: (_, _) => const NotificationsSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/conversations',
          builder: (_, _) => const ConversationsSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/appearance',
          builder: (_, _) => const AppearanceSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/blocked',
          builder: (_, _) => const BlockedContactsScreen(),
        ),
        GoRoute(
          path: '/settings/edit-profile',
          builder: (_, _) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/settings/message-requests',
          builder: (_, _) => const MessageRequestsScreen(),
        ),
        GoRoute(
          path: '/profile/:id',
          builder: (_, state) => UserProfileScreen(
            userId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/telepathy',
          builder: (_, _) => const TelepathyScreen(),
        ),
        GoRoute(
          path: '/path',
          builder: (_, _) => const PathScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Messenger',
      theme: themeData,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
