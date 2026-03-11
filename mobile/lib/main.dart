import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/local_storage.dart';
import 'core/providers.dart';
import 'core/services/firebase_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();

  // Firebase — опционально, работает только при наличии google-services.json
  bool firebaseReady = false;
  final firebaseService = FirebaseService();
  try {
    await firebaseService.init();
    firebaseReady = true;
  } catch (e) {
    debugPrint('[Main] Firebase недоступен (нет google-services.json?): $e');
  }

  final container = ProviderContainer();
  await container.read(authStateProvider.notifier).checkAuth();

  // Регистрируем FCM-токен только если Firebase инициализирован и пользователь авторизован
  if (firebaseReady && container.read(authStateProvider).isAuthenticated) {
    firebaseService.registerToken();
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MessengerApp(),
    ),
  );
}
