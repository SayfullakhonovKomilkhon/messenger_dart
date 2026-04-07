import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messenger/core/services/firebase_service.dart';
import 'e2ee/key_manager.dart';
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
      final res = await _api.get('/users/me').timeout(const Duration(seconds: 5));
      final user = UserModel.fromJson(res.data);
      state = state.copyWith(isAuthenticated: true, isLoading: false, user: user);
      FirebaseService().registerToken();
      E2eeKeyManager().initialize();
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
      FirebaseService().registerToken();
      E2eeKeyManager().initialize();
    } catch (e) {
      debugPrint('[AUTH] login error: $e');
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
    await E2eeKeyManager().reset();
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
    this.type = AppThemeType.light,
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
      orElse: () => AppThemeType.light,
    );
    state = ThemeState(
      type: type,
      accentIndex: accentIdx,
      followSystemTheme: followSystem,
    );
  }

  void toggle() {
    final next = state.type == AppThemeType.dark
        ? AppThemeType.light
        : AppThemeType.dark;
    setTheme(next);
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

// Locale
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(Locale(LocalStorage.getLocale())) ;

  void setLocale(String langCode) {
    LocalStorage.setLocale(langCode);
    state = Locale(langCode);
  }
}

// User settings (privacy, etc.)
final userSettingsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final res = await ApiClient().dio.get('/users/me/settings');
    final raw = res.data;
    return raw is Map
        ? Map<String, dynamic>.from(raw.map((k, v) => MapEntry(k.toString(), v)))
        : <String, dynamic>{};
  } catch (_) {
    return <String, dynamic>{};
  }
});

// Wallpaper
final wallpaperProvider = StateNotifierProvider<WallpaperNotifier, String>((ref) {
  return WallpaperNotifier();
});

class WallpaperNotifier extends StateNotifier<String> {
  WallpaperNotifier() : super(LocalStorage.getChatWallpaper());

  void set(String id) {
    LocalStorage.setChatWallpaper(id);
    state = id;
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

  Set<String> _blockedIds = {};

  Future<Set<String>> _loadBlockedIds() async {
    try {
      final res = await _api.get('/users/me/blocked');
      return (res.data as List)
          .cast<Map<String, dynamic>>()
          .map((b) => b['id'] as String)
          .toSet();
    } catch (_) {
      return _blockedIds;
    }
  }

  List<ConversationModel> _filterBlocked(List<ConversationModel> list) {
    if (_blockedIds.isEmpty) return list;
    return list.where((c) {
      if (c.type == 'GROUP') return true;
      final pid = c.participant?.id;
      return pid == null || !_blockedIds.contains(pid);
    }).toList();
  }

  static DateTime? _parseTime(String? s) {
    if (s == null) return null;
    return DateTime.tryParse(s);
  }

  List<ConversationModel> _sorted(List<ConversationModel> list) {
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      final ta = _parseTime(a.lastMessage?.createdAt) ??
          _parseTime(a.updatedAt) ??
          DateTime(2000);
      final tb = _parseTime(b.lastMessage?.createdAt) ??
          _parseTime(b.updatedAt) ??
          DateTime(2000);
      return tb.compareTo(ta);
    });
    return list;
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final results = await Future.wait([
        _api.get('/conversations'),
        _loadBlockedIds(),
      ]);
      _blockedIds = results[1] as Set<String>;
      final list = ((results[0] as dynamic).data as List)
          .map((e) => ConversationModel.fromJson(e))
          .toList();
      state = AsyncValue.data(_sorted(_filterBlocked(list)));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadSilently() async {
    try {
      final results = await Future.wait([
        _api.get('/conversations'),
        _loadBlockedIds(),
      ]);
      _blockedIds = results[1] as Set<String>;
      final serverList = ((results[0] as dynamic).data as List)
          .map((e) => ConversationModel.fromJson(e))
          .toList();

      final localList = state.valueOrNull ?? [];
      final merged = _mergeWithLocal(serverList, localList);
      state = AsyncValue.data(_sorted(_filterBlocked(merged)));
    } catch (_) {}
  }

  /// Merge server data with local, keeping whichever lastMessage is newer.
  List<ConversationModel> _mergeWithLocal(
      List<ConversationModel> server, List<ConversationModel> local) {
    final localMap = {for (final c in local) c.id: c};
    final result = <ConversationModel>[];
    final seenIds = <String>{};
    for (final sc in server) {
      seenIds.add(sc.id);
      final lc = localMap[sc.id];
      if (lc != null) {
        final serverTime = _parseTime(sc.lastMessage?.createdAt);
        final localTime = _parseTime(lc.lastMessage?.createdAt);
        if (localTime != null &&
            serverTime != null &&
            localTime.isAfter(serverTime)) {
          result.add(lc.copyWith(
            unreadCount: sc.unreadCount,
            isPinned: sc.isPinned,
            isMuted: sc.isMuted,
          ));
        } else {
          result.add(sc);
        }
      } else {
        result.add(sc);
      }
    }
    for (final lc in local) {
      if (!seenIds.contains(lc.id)) {
        result.add(lc);
      }
    }
    return result;
  }

  void removeByParticipantId(String participantId) {
    _blockedIds.add(participantId);
    state.whenData((list) {
      final filtered = list.where((c) {
        if (c.type == 'GROUP') return true;
        return c.participant?.id != participantId;
      }).toList();
      state = AsyncValue.data(filtered);
    });
  }

  void unblockParticipant(String participantId) {
    _blockedIds.remove(participantId);
    loadSilently();
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

  /// [incrementUnread] — true, если сообщение от другого пользователя (мы получатель)
  void addOrUpdateFromMessage(MessageModel msg, {bool incrementUnread = false}) {
    state.whenData((list) {
      final idx = list.indexWhere((c) => c.id == msg.conversationId);
      if (idx >= 0) {
        final conv = list[idx];
        final currentTime = _parseTime(conv.lastMessage?.createdAt);
        final newTime = _parseTime(msg.createdAt);
        final currentId = conv.lastMessage?.id ?? '';
        final newId = msg.id;
        if (currentId.isNotEmpty &&
            newId.isNotEmpty &&
            currentTime != null &&
            newTime != null &&
            newTime.isBefore(currentTime)) {
          return;
        }
        final newUnread = incrementUnread ? conv.unreadCount + 1 : conv.unreadCount;
        final updated = conv.copyWith(
          lastMessage: LastMessageInfo(
            id: msg.id,
            text: msg.text,
            createdAt: msg.createdAt,
            status: msg.status,
            fileUrl: msg.fileUrl,
            mimeType: msg.mimeType,
            isVoiceMessage: msg.isVoiceMessage,
            encrypted: msg.encrypted,
          ),
          unreadCount: newUnread,
        );
        final newList = [...list];
        newList.removeAt(idx);

        int insertAt = 0;
        for (int i = 0; i < newList.length; i++) {
          if (newList[i].isPinned && !updated.isPinned) continue;
          if (!newList[i].isPinned && updated.isPinned) {
            insertAt = i;
            break;
          }
          final t = _parseTime(newList[i].lastMessage?.createdAt);
          if (newTime != null && t != null && newTime.isAfter(t)) {
            insertAt = i;
            break;
          }
          insertAt = i + 1;
        }
        newList.insert(insertAt, updated);
        state = AsyncValue.data(newList);
      }
    });
  }

  void updateLastMessageStatus(String conversationId, String status) {
    state.whenData((list) {
      final idx = list.indexWhere((c) => c.id == conversationId);
      if (idx >= 0) {
        final conv = list[idx];
        final lm = conv.lastMessage;
        if (lm != null) {
          final updated = conv.copyWith(
            lastMessage: LastMessageInfo(
              id: lm.id,
              text: lm.text,
              createdAt: lm.createdAt,
              status: status,
              fileUrl: lm.fileUrl,
              mimeType: lm.mimeType,
              isVoiceMessage: lm.isVoiceMessage,
              encrypted: lm.encrypted,
            ),
          );
          final newList = [...list];
          newList[idx] = updated;
          state = AsyncValue.data(newList);
        }
      }
    });
  }

  void updateParticipantOnline(String participantId, bool isOnline) {
    state.whenData((list) {
      final newList = list.map((c) {
        if (c.participant != null && c.participant!.id == participantId) {
          return c.copyWith(
            participant: c.participant!.copyWith(isOnline: isOnline),
          );
        }
        return c;
      }).toList();
      state = AsyncValue.data(newList);
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
    final idx = current.indexWhere((m) => m.clientMessageId == msg.clientMessageId);
    if (idx >= 0) {
      // Обновляем оптимистичное сообщение реальными данными с сервера
      final newList = [...current];
      newList[idx] = msg;
      state = AsyncValue.data(newList);
      return;
    }
    state = AsyncValue.data([msg, ...current]);
  }

  void updateMessage(String messageId, MessageModel updated) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((m) => m.id == messageId ? updated : m).toList(),
    );
  }

  void updateMessageByClientId(String clientMessageId, MessageModel updated) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((m) => m.clientMessageId == clientMessageId ? updated : m).toList(),
    );
  }

  void removeMessage(String messageId) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((m) => m.id != messageId).toList());
  }

  void removeByClientId(String clientMessageId) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.where((m) => m.clientMessageId != clientMessageId).toList(),
    );
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

