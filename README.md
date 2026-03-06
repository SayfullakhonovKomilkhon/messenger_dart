# Messenger

Монорепозиторий мессенджера.

## Структура
- `backend/` — Java 17 + Spring Boot 3 (API сервер)
- `mobile/`  — Flutter (мобильное приложение, реализуется отдельно)

## Быстрый старт (локальная разработка)

1. Скопировать конфиг:
   ```bash
   cp .env.example .env
   ```
   Заполнить все значения в `.env`

2. Запустить все сервисы:
   ```bash
   docker-compose up --build
   ```

3. Сервер доступен:
   - HTTP API:  http://localhost:3000/api/v1
   - WebSocket: ws://localhost:3000/ws

4. Flutter подключается (Android эмулятор):
   ```
   http://10.0.2.2:3000/api/v1
   ```

## Сервисы в Docker

| Сервис   | Порт | Описание             |
|----------|------|----------------------|
| backend  | 3000 | Spring Boot API      |
| postgres | 5432 | База данных          |
| redis    | 6379 | Кеш и сессии         |
| coturn   | 3478 | TURN сервер (WebRTC) |
# messenger_beckend
