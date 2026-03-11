import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/api_client.dart';
import '../storage/secure_storage.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // НЕ инициализируем здесь — FirebaseMessaging.instance нельзя вызывать
  // до Firebase.initializeApp()
  FirebaseMessaging? _messaging;
  bool _initialized = false;

  /// Initialize Firebase and set up FCM handlers
  /// Бросает исключение если Firebase не настроен — main.dart перехватывает
  Future<void> init() async {
    if (_initialized) return;

    // Если нет google-services.json / GoogleService-Info.plist — упадёт тут
    await Firebase.initializeApp();

    // Теперь safe вызывать FirebaseMessaging.instance
    _messaging = FirebaseMessaging.instance;

    // Запрос разрешения на уведомления
    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Разрешение: ${settings.authorizationStatus}');

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Сообщение (foreground): ${message.data}');
    });

    // Нажатие на уведомление (приложение было в фоне)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Нажатие на уведомление: ${message.data}');
    });

    // Приложение открыто через уведомление (было убито)
    final initialMessage = await _messaging!.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] Открыто из уведомления: ${initialMessage.data}');
    }

    _initialized = true;
    debugPrint('[FCM] Firebase service инициализирован');
  }

  /// Регистрация FCM-токена на бекенде
  Future<void> registerToken() async {
    if (_messaging == null) return;
    try {
      final token = await _messaging!.getToken();
      if (token == null) return;
      debugPrint('[FCM] Токен: $token');

      final hasAuth = await SecureStorage.hasTokens();
      if (!hasAuth) return;

      await ApiClient().dio.patch('/users/me/fcm-token', data: {
        'fcmToken': token,
      });
      debugPrint('[FCM] Токен зарегистрирован на бекенде');
    } catch (e) {
      debugPrint('[FCM] Ошибка регистрации токена: $e');
    }

    // Слушать обновление токена
    _messaging!.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] Токен обновлён: $newToken');
      try {
        final hasAuth = await SecureStorage.hasTokens();
        if (!hasAuth) return;
        await ApiClient().dio.patch('/users/me/fcm-token', data: {
          'fcmToken': newToken,
        });
      } catch (e) {
        debugPrint('[FCM] Ошибка обновления токена: $e');
      }
    });
  }
}
