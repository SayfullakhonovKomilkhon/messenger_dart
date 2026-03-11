import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/user_model.dart';
import 'models/conversation_model.dart';
import 'models/message_model.dart';
import 'models/call_model.dart';
import 'network/api_client.dart';
import 'storage/local_storage.dart';
import 'storage/secure_storage.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

// Auth state
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.user,
    this.error,
  });

  AuthState copyWith({bool? isAuthenticated, bool? isLoading, UserModel? user, String? error}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final _api = ApiClient().dio;

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true);
    final hasTokens = await SecureStorage.hasTokens();
    if (!hasTokens) {
      state = state.copyWith(isAuthenticated: false, isLoading: false);
      return;
    }
    try {
      final res = await _api.get('/users/me');
      final user = UserModel.fromJson(res.data);
      state = state.copyWith(isAuthenticated: true, isLoading: false, user: user);
    } catch (_) {
      await SecureStorage.clearTokens();
      state = state.copyWith(isAuthenticated: false, isLoading: false);
    }
  }

  Future<void> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      debugPrint('[AUTH] login attempt: phone=$phone');
      final res = await _api.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });
      final body = res.data;
      debugPrint('[AUTH] login response: $body');
      await SecureStorage.saveTokens(
        body['accessToken'],
        body['refreshToken'],
      );
      final user = UserModel.fromJson(body['user']);
      state = state.copyWith(isAuthenticated: true, isLoading: false, user: user);
    } catch (e) {
      debugPrint('[AUTH] login error: $e');
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    }
  }

  Future<void> register(String phone, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.post('/auth/register', data: {
        'phone': phone,
        'password': password,
        'name': name,
      });
      final body = res.data;
      await SecureStorage.saveTokens(
        body['accessToken'],
        body['refreshToken'],
      );
      final user = UserModel.fromJson(body['user']);
      state = state.copyWith(isAuthenticated: true, isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken != null) {
        await _api.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (_) {}
    await SecureStorage.clearTokens();
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }

  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  Future<void> refreshUser() async {
    try {
      final res = await _api.get('/users/me');
      final user = UserModel.fromJson(res.data);
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data is Map) {
      return (e.response!.data as Map)['message']?.toString() ?? 'Unknown error';
    }
    return 'Connection error';
  }
}

// Theme
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

class ThemeState {
  final AppThemeType type;
  final int accentIndex;
  final bool followSystemTheme;

  const ThemeState({
    this.type = AppThemeType.dark,
    this.accentIndex = 0,
    this.followSystemTheme = false,
  });

  ThemeData get themeData =>
      AppTheme.getTheme(type, AppColors.accentColors[accentIndex]);
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _load();
  }

  void _load() {
    final themeName = LocalStorage.getTheme();
    final accentIdx = LocalStorage.getAccentIndex();
    final followSystem = LocalStorage.getFollowSystemTheme();
    final type = AppThemeType.values.firstWhere(
      (t) => t.name == themeName,
      orElse: () => AppThemeType.dark,
    );
    state = ThemeState(
      type: type,
      accentIndex: accentIdx,
      followSystemTheme: followSystem,
    );
  }

  void setTheme(AppThemeType type) {
    LocalStorage.setTheme(type.name);
    state = ThemeState(
      type: type,
      accentIndex: state.accentIndex,
      followSystemTheme: state.followSystemTheme,
    );
  }

  void setAccent(int index) {
    LocalStorage.setAccentIndex(index);
    state = ThemeState(
      type: state.type,
      accentIndex: index,
      followSystemTheme: state.followSystemTheme,
    );
  }

  void setFollowSystemTheme(bool value) {
    LocalStorage.setFollowSystemTheme(value);
    state = ThemeState(
      type: state.type,
      accentIndex: state.accentIndex,
      followSystemTheme: value,
    );
  }
}

// Conversations
final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, AsyncValue<List<ConversationModel>>>((ref) {
  return ConversationsNotifier();
});

class ConversationsNotifier extends StateNotifier<AsyncValue<List<ConversationModel>>> {
  ConversationsNotifier() : super(const AsyncValue.loading());

  final _api = ApiClient().dio;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.get('/conversations');
      final list = (res.data as List)
          .map((e) => ConversationModel.fromJson(e))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updateConversation(ConversationModel updated) {
    state.whenData((list) {
      final newList = list.map((c) => c.id == updated.id ? updated : c).toList();
      state = AsyncValue.data(newList);
    });
  }

  void markRead(String conversationId) {
    state.whenData((list) {
      final newList = list.map((c) {
        if (c.id == conversationId) return c.copyWith(unreadCount: 0);
        return c;
      }).toList();
      state = AsyncValue.data(newList);
    });
  }

  void addOrUpdateFromMessage(MessageModel msg) {
    state.whenData((list) {
      final idx = list.indexWhere((c) => c.id == msg.conversationId);
      if (idx >= 0) {
        final conv = list[idx];
        final updated = conv.copyWith(
          lastMessage: LastMessageInfo(
            text: msg.text,
            createdAt: msg.createdAt,
            status: msg.status,
          ),
        );
        final newList = [...list];
        newList[idx] = updated;
        state = AsyncValue.data(newList);
      }
    });
  }
}

// Messages for a conversation
final messagesProvider = StateNotifierProvider.family<
    MessagesNotifier, AsyncValue<List<MessageModel>>, String>((ref, conversationId) {
  return MessagesNotifier(conversationId);
});

class MessagesNotifier extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final String conversationId;
  bool hasMore = true;
  bool _loading = false;

  MessagesNotifier(this.conversationId) : super(const AsyncValue.loading());

  final _api = ApiClient().dio;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    state = const AsyncValue.loading();
    try {
      final res = await _api.get('/conversations/$conversationId/messages', queryParameters: {
        'limit': 30,
      });
      final list = (res.data as List)
          .map((e) => MessageModel.fromJson(e))
          .toList();
      hasMore = list.length >= 30;
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _loading = false;
    }
  }

  Future<void> loadMore() async {
    if (_loading || !hasMore) return;
    final current = state.valueOrNull ?? [];
    if (current.isEmpty) return;

    _loading = true;
    try {
      final lastId = current.last.id;
      final res = await _api.get('/conversations/$conversationId/messages', queryParameters: {
        'before': lastId,
        'limit': 30,
      });
      final list = (res.data as List)
          .map((e) => MessageModel.fromJson(e))
          .toList();
      hasMore = list.length >= 30;
      state = AsyncValue.data([...current, ...list]);
    } catch (_) {
    } finally {
      _loading = false;
    }
  }

  void addMessage(MessageModel msg) {
    final current = state.valueOrNull ?? [];
    if (current.any((m) => m.clientMessageId == msg.clientMessageId)) return;
    state = AsyncValue.data([msg, ...current]);
  }

  void updateMessage(String messageId, MessageModel updated) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((m) => m.id == messageId ? updated : m).toList(),
    );
  }

  void removeMessage(String messageId) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((m) => m.id != messageId).toList());
  }
}

// Call history
final callHistoryProvider =
    StateNotifierProvider<CallHistoryNotifier, AsyncValue<List<CallHistoryModel>>>((ref) {
  return CallHistoryNotifier();
});

class CallHistoryNotifier extends StateNotifier<AsyncValue<List<CallHistoryModel>>> {
  CallHistoryNotifier() : super(const AsyncValue.loading());

  final _api = ApiClient().dio;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.get('/calls/history');
      final list = (res.data as List)
          .map((e) => CallHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

