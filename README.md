<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
<img src="https://img.shields.io/badge/Firebase-FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=black"/>
<img src="https://img.shields.io/badge/WebRTC-Video_Calls-333333?style=for-the-badge&logo=webrtc&logoColor=white"/>
<img src="https://img.shields.io/badge/Platform-Android_|_iOS_|_Web-lightgrey?style=for-the-badge"/>

# 💬 Messenger

### Кроссплатформенный мессенджер с видеозвонками и E2EE шифрованием

*Полнофункциональный мессенджер на Flutter с реальным временем, WebRTC видеозвонками и сквозным шифрованием Signal Protocol*

[Сообщить об ошибке](https://github.com/SayfullakhonovKomilkhon/messenger_dart/issues)

</div>

---

## ✨ Возможности

| Функция | Описание |
|---|---|
| 💬 **Мессенджер в реальном времени** | WebSocket-соединение через STOMP протокол |
| 📹 **Видеозвонки** | P2P звонки через flutter_webrtc |
| 🔐 **E2EE шифрование** | Сквозное шифрование по протоколу Signal (libsignal_protocol_dart) |
| 🔔 **Push-уведомления** | Firebase Cloud Messaging + локальные уведомления |
| 🖼️ **Медиафайлы** | Отправка изображений, видео и файлов |
| 🔒 **Биометрическая защита** | Вход по Face ID / отпечатку пальца |
| 🌍 **Локализация** | Поддержка нескольких языков |
| 🎙️ **Голосовые сообщения** | Запись и воспроизведение аудио через flutter_sound |
| 🔗 **Превью ссылок** | Автоматическое превью URL в сообщениях |
| 📌 **Безопасное хранилище** | Зашифрованное хранение данных через flutter_secure_storage |

---

## 🚀 Быстрый старт

### Требования

- Flutter SDK >= 3.x (Dart >= 3.11)
- Android Studio / Xcode
- Firebase проект

### Установка

```bash
# 1. Клонируйте репозиторий
git clone https://github.com/SayfullakhonovKomilkhon/messenger_dart.git
cd messenger_dart

# 2. Установите зависимости
flutter pub get

# 3. Настройте Firebase
# Следуйте инструкциям в FIREBASE_SETUP.md
```

### Настройка Firebase

```bash
# Установите Firebase CLI
npm install -g firebase-tools

# Войдите в аккаунт
firebase login

# Инициализируйте проект
firebase init

# Подробнее — в FIREBASE_SETUP.md
```

### Запуск

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Конкретное устройство
flutter devices
flutter run -d <device-id>
```

---

## 🛠️ Технологический стек

| Категория | Пакет / Технология |
|---|---|
| **Фреймворк** | Flutter 3.x + Dart 3.x |
| **Состояние** | Riverpod 2.x + riverpod_annotation |
| **Сеть** | Dio 5.x |
| **WebSocket** | stomp_dart_client + web_socket_channel |
| **Видеозвонки** | flutter_webrtc |
| **Шифрование** | libsignal_protocol_dart + cryptography |
| **Push-уведомления** | Firebase Messaging + flutter_local_notifications |
| **Аутентификация** | local_auth (биометрия) + flutter_secure_storage |
| **Навигация** | go_router |
| **Медиа** | image_picker + video_player + file_picker |
| **Аудио** | flutter_sound + audio_session |
| **Кэш изображений** | cached_network_image |
| **Локализация** | flutter_localizations + intl |

---

## 🏗️ Архитектура проекта

```
lib/
├── core/
│   ├── network/            # Dio HTTP клиент
│   ├── websocket/          # STOMP WebSocket
│   ├── security/           # Signal Protocol E2EE
│   └── storage/            # Безопасное хранилище
├── features/
│   ├── auth/               # Аутентификация
│   ├── chats/              # Список чатов
│   ├── messages/           # Сообщения и медиа
│   ├── calls/              # WebRTC видеозвонки
│   ├── profile/            # Профиль пользователя
│   └── settings/           # Настройки приложения
├── shared/
│   ├── widgets/            # Переиспользуемые виджеты
│   └── providers/          # Глобальные провайдеры
└── main.dart

assets/
├── images/                 # Изображения и иконки
└── fonts/
    └── Magneto-Bold.ttf    # Кастомный шрифт
```

---

## 🔒 Безопасность

- **E2EE**: каждый чат защищён сквозным шифрованием по протоколу Signal
- **Биометрия**: опциональная блокировка приложения по Face ID / Touch ID
- **Безопасное хранилище**: токены и ключи хранятся в зашифрованном хранилище устройства
- **HTTPS/WSS**: все соединения только по зашифрованным каналам

---

## 📋 Поддерживаемые платформы

| Платформа | Статус |
|---|---|
| Android | ✅ Поддерживается |
| iOS | ✅ Поддерживается |
| Web | ✅ Поддерживается |
| Linux | ✅ Поддерживается |
| macOS | ✅ Поддерживается |
| Windows | ✅ Поддерживается |

---

## 🤝 Вклад в проект

1. Fork репозитория
2. Создайте ветку: `git checkout -b feature/your-feature`
3. Сделайте коммит: `git commit -m 'feat: add your feature'`
4. Запушьте: `git push origin feature/your-feature`
5. Откройте Pull Request

---

<div align="center">

Кроссплатформенный мессенджер · Powered by [Flutter](https://flutter.dev/) & [Firebase](https://firebase.google.com/)

</div>
