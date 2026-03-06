# Active Context

## Current State
Этап 1 backend полностью реализован. Все модули созданы.

## Completed
- Инфраструктура монорепо (docker-compose, .env, .gitignore, README)
- Common layer (CacheService, GlobalExceptionHandler, JWT, Security)
- Auth module (register, login, refresh, logout + rate limiting)
- User module (search, FCM token)
- File module (R2 upload с Tika MIME detection)
- Chat module (conversations, messages, WebSocket STOMP)
- Call module (WebRTC signaling, history)
- Tests (AuthControllerTest, ChatServiceTest)

## Next Steps
- Тестирование через docker-compose up
- Этап 2: Flutter мобильное приложение (mobile/)
- Этап 2 документа: настройки, профиль, группы, боты
