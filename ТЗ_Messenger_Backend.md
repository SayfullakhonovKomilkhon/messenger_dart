# Техническое задание: Messenger Backend API

**Версия:** 1.0.0  
**Дата:** 04.03.2026  
**Этап:** 1 — Backend API

---

## 1. Общее описание

REST API бэкенд мессенджера для личного общения. Поддерживает текстовые сообщения в реальном времени через WebSocket, обмен файлами (фото, видео, аудио, PDF) и аудио/видеозвонки через WebRTC.

### Что входит в Этап 1 (текущий)

- JWT-авторизация (Access + Refresh Token)
- Личные чаты через WebSocket STOMP
- WebRTC-звонки (аудио/видео) с signaling через STOMP
- Загрузка файлов в облачное хранилище (Cloudflare R2)
- Поиск пользователей по имени/username
- Сохранение FCM-токена для push-уведомлений

### Что НЕ входит в Этап 1

- Мобильное приложение (Flutter — Этап 2)
- Групповые чаты
- Настройки профиля / аватар
- Боты

---

## 2. Технологический стек

| Компонент | Технология |
|---|---|
| Язык | Java 17 |
| Фреймворк | Spring Boot 3.2.5, Spring Security 6 |
| ORM | Spring Data JPA (Hibernate) |
| БД | PostgreSQL 16 |
| Кэш | Redis 7 |
| Миграции | Flyway |
| WebSocket | Spring WebSocket (STOMP) |
| Сборка | Gradle |
| JWT | jjwt 0.12.5 (алгоритм HS256) |
| Rate Limiting | Bucket4j 8.10.1 |
| MIME-детекция | Apache Tika 2.9.2 |
| Файловое хранилище | Cloudflare R2 (через AWS SDK v2) |
| Push-уведомления | Firebase Admin SDK 9.2.0 |
| API-документация | springdoc-openapi 2.5.0 (Swagger UI) |
| TURN-сервер | coturn (для WebRTC) |
| Контейнеризация | Docker + Docker Compose |

---

## 3. Архитектура

### 3.1. Общая структура

```
messenger/
├── docker-compose.yml      # PostgreSQL, Redis, coturn, backend
├── .env / .env.example     # Переменные окружения
├── openapi.json            # Экспортированная OpenAPI-спецификация
├── backend/
│   ├── build.gradle
│   ├── Dockerfile.dev
│   └── src/main/java/com/messenger/
│       ├── MessengerApplication.java
│       ├── auth/           # Модуль авторизации
│       ├── user/           # Модуль пользователей
│       ├── chat/           # Модуль чатов
│       ├── call/           # Модуль звонков
│       ├── file/           # Модуль файлов
│       └── common/         # Общие компоненты
│           ├── security/   # JWT, фильтры, конфиг безопасности
│           ├── exception/  # Обработка ошибок
│           ├── cache/      # Абстракция кэша (Redis)
│           └── notification/ # FCM push-уведомления
└── mobile/                 # Flutter (Этап 2)
```

### 3.2. Слоистая архитектура

Строго: **Controller → Service → Repository**

- Controller — принимает HTTP/WebSocket запросы, валидация
- Service — бизнес-логика, конвертация Entity ↔ DTO
- Repository — доступ к данным (Spring Data JPA)

### 3.3. Ключевые паттерны

1. **DI через конструктор** (не `@Autowired` на поле)
2. **DTO отделены от Entity** — конвертация только в Service-слое
3. **CacheService** — интерфейсная абстракция над Redis (единая точка доступа)
4. **Idempotency** — `clientMessageId` с UNIQUE constraint в БД для защиты от дублей
5. **Cursor-based пагинация** — для сообщений (параметр `before`)
6. **Единый формат ответов** — через `ResponseWrapperAdvice` (`@ControllerAdvice`)
7. **Rate limiting** — 5 запросов/мин на IP для auth-эндпоинтов
8. **JWT blacklist** — в Redis с TTL (при logout)

---

## 4. База данных

### 4.1. Схема (6 таблиц)

Миграция: `V1__init.sql` (Flyway), расширение `pgcrypto` для UUID.

#### Таблица `users`

| Поле | Тип | Описание |
|---|---|---|
| id | UUID (PK) | gen_random_uuid() |
| phone | VARCHAR(20), UNIQUE, NOT NULL | Номер телефона |
| name | VARCHAR(100), NOT NULL | Имя пользователя |
| username | VARCHAR(50), UNIQUE | Уникальный username |
| avatar_url | TEXT | Ссылка на аватар |
| password_hash | VARCHAR(255), NOT NULL | BCrypt(12) хэш |
| fcm_token | TEXT | Токен Firebase Cloud Messaging |
| is_online | BOOLEAN, default FALSE | Статус онлайн |
| last_seen_at | TIMESTAMP | Последний раз онлайн |
| created_at | TIMESTAMP, default NOW() | Дата регистрации |
| updated_at | TIMESTAMP, default NOW() | Дата обновления |

#### Таблица `refresh_tokens`

| Поле | Тип | Описание |
|---|---|---|
| id | UUID (PK) | |
| user_id | UUID (FK → users) | ON DELETE CASCADE |
| token | TEXT, UNIQUE, NOT NULL | Refresh-токен |
| expires_at | TIMESTAMP, NOT NULL | Срок действия |
| created_at | TIMESTAMP | |

#### Таблица `conversations`

| Поле | Тип | Описание |
|---|---|---|
| id | UUID (PK) | |
| created_at | TIMESTAMP | |
| updated_at | TIMESTAMP | Обновляется при новом сообщении |

#### Таблица `conversation_participants`

| Поле | Тип | Описание |
|---|---|---|
| id | UUID (PK) | |
| conversation_id | UUID (FK → conversations) | ON DELETE CASCADE |
| user_id | UUID (FK → users) | ON DELETE CASCADE |
| unread_count | INT, default 0 | Кол-во непрочитанных |
| last_read_at | TIMESTAMP | |
| | UNIQUE(conversation_id, user_id) | |

#### Таблица `messages`

| Поле | Тип | Описание |
|---|---|---|
| id | UUID (PK) | |
| conversation_id | UUID (FK → conversations) | ON DELETE CASCADE |
| sender_id | UUID (FK → users) | |
| text | TEXT | Текст сообщения |
| file_url | TEXT | URL файла (если есть) |
| mime_type | VARCHAR(100) | MIME-тип файла |
| client_message_id | VARCHAR(36), UNIQUE, NOT NULL | Для идемпотентности |
| status | VARCHAR(20), default 'SENT' | SENT / DELIVERED / READ |
| created_at | TIMESTAMP | |

#### Таблица `call_records`

| Поле | Тип | Описание |
|---|---|---|
| id | UUID (PK) | |
| caller_id | UUID (FK → users) | Кто звонил |
| callee_id | UUID (FK → users) | Кому звонили |
| call_type | VARCHAR(10), NOT NULL | AUDIO / VIDEO |
| status | VARCHAR(20), NOT NULL | INITIATED / ACCEPTED / REJECTED / ENDED / MISSED |
| started_at | TIMESTAMP | Момент принятия звонка (обновляется в acceptCall) |
| ended_at | TIMESTAMP | Момент завершения звонка |
| duration | INT | Чистое время разговора в секундах (endedAt − startedAt) |

### 4.2. Индексы (8 штук)

| Индекс | Таблица | Поля |
|---|---|---|
| idx_messages_conv | messages | conversation_id, created_at DESC |
| idx_messages_sender | messages | sender_id |
| idx_participants_user | conversation_participants | user_id |
| idx_users_name | users | name |
| idx_users_username | users | username |
| idx_refresh_token | refresh_tokens | token |
| idx_calls_caller | call_records | caller_id |
| idx_calls_callee | call_records | callee_id |

---

## 5. REST API

**Базовый URL:** `http://HOST:3000/api/v1`  
**Формат:** JSON  
**Авторизация:** Bearer JWT (заголовок `Authorization: Bearer <accessToken>`)

### 5.1. Единый формат ответа

Все успешные ответы оборачиваются в:

```json
{
  "data": <тело ответа>
}
```

Ошибки возвращаются в формате:

```json
{
  "statusCode": 401,
  "error": "UNAUTHORIZED",
  "message": "Authentication required",
  "timestamp": "2026-03-04T12:00:00Z"
}
```

---

### 5.2. Модуль Auth

**Rate limiting:** 5 запросов/мин на IP для всех auth-эндпоинтов.

#### POST `/api/v1/auth/register` (без авторизации)

Регистрация нового пользователя.

**Request:**
```json
{
  "phone": "+79991234567",
  "password": "mypassword",
  "name": "Иван Петров"
}
```

**Валидация:**
- `phone` — обязательно, max 20 символов
- `password` — обязательно, 6–128 символов
- `name` — обязательно, max 100 символов

**Response (201 Created):**
```json
{
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiJ9...",
    "user": {
      "id": "uuid",
      "name": "Иван Петров",
      "phone": "+79991234567",
      "avatarUrl": null
    }
  }
}
```

**Ошибки:**
- `409 CONFLICT` — телефон уже зарегистрирован
- `429 TOO_MANY_REQUESTS` — превышен лимит запросов

---

#### POST `/api/v1/auth/login` (без авторизации)

Вход по телефону и паролю.

**Request:**
```json
{
  "phone": "+79991234567",
  "password": "mypassword"
}
```

**Response (200 OK):**
```json
{
  "data": {
    "accessToken": "...",
    "refreshToken": "...",
    "user": {
      "id": "uuid",
      "name": "Иван Петров",
      "phone": "+79991234567",
      "avatarUrl": null
    }
  }
}
```

**Ошибки:**
- `401 UNAUTHORIZED` — неверный телефон или пароль

---

#### POST `/api/v1/auth/refresh` (без авторизации)

Обмен refresh-токена на новую пару access + refresh.

**Request:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiJ9..."
}
```

**Response (200 OK):**
```json
{
  "data": {
    "accessToken": "новый access token",
    "refreshToken": "новый refresh token"
  }
}
```

**Ошибки:**
- `401 UNAUTHORIZED` — невалидный или истекший refresh-токен

---

#### POST `/api/v1/auth/logout` (требуется авторизация)

Инвалидирует оба токена. Access-токен добавляется в blacklist Redis с TTL.

**Headers:** `Authorization: Bearer <accessToken>`

**Request:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiJ9..."
}
```

**Response (200 OK):**
```json
{
  "data": {
    "success": true
  }
}
```

---

### 5.3. Модуль Users

Все эндпоинты требуют авторизации.

#### GET `/api/v1/users/search?query=<текст>`

Поиск пользователей по имени или username.

**Параметры:**
- `query` (string, обязательно) — поисковый запрос, минимум 2 символа

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Анна Сидорова",
      "username": "anna_s",
      "avatarUrl": "https://...",
      "isOnline": true
    }
  ]
}
```

**Важно:** Текущий пользователь исключается из результатов.

---

#### PATCH `/api/v1/users/me/fcm-token`

Сохранение FCM-токена для push-уведомлений.

**Request:**
```json
{
  "fcmToken": "firebase-cloud-messaging-token"
}
```

**Response (200 OK):**
```json
{
  "data": {
    "success": true
  }
}
```

---

### 5.4. Модуль Chat

Все эндпоинты требуют авторизации.

#### GET `/api/v1/conversations`

Список всех диалогов текущего пользователя.

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "conversation-uuid",
      "updatedAt": "2026-03-04T10:30:00Z",
      "participant": {
        "id": "user-uuid",
        "name": "Анна Сидорова",
        "avatarUrl": "https://...",
        "isOnline": true
      },
      "lastMessage": {
        "text": "Привет!",
        "createdAt": "2026-03-04T10:30:00Z",
        "status": "SENT"
      },
      "unreadCount": 3
    }
  ]
}
```

---

#### POST `/api/v1/conversations`

Создать новый диалог (или вернуть существующий, если уже есть диалог с этим пользователем).

**Request:**
```json
{
  "participantId": "user-uuid"
}
```

**Response (200 OK):** Объект `ConversationResponse` (см. выше).

---

#### GET `/api/v1/conversations/{id}/messages`

Получить сообщения диалога с cursor-based пагинацией.

**Параметры:**
- `id` (UUID, path) — ID диалога
- `before` (UUID, query, опционально) — загрузить сообщения до этого ID
- `limit` (int, query, default=30) — кол-во сообщений

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "message-uuid",
      "conversationId": "conversation-uuid",
      "senderId": "user-uuid",
      "text": "Привет!",
      "fileUrl": null,
      "mimeType": null,
      "clientMessageId": "client-generated-uuid",
      "status": "SENT",
      "createdAt": "2026-03-04T10:30:00Z"
    }
  ]
}
```

---

### 5.5. Модуль Files

Требуется авторизация.

#### POST `/api/v1/files/upload`

Загрузка файла. Content-Type: `multipart/form-data`.

**Ограничения:**
- Макс. размер файла: **100 MB**
- Допустимые MIME-типы: JPEG, PNG, GIF, WebP, MP4, WebM, MP3, OGG, PDF
- MIME-тип проверяется через Apache Tika (по содержимому файла, не по расширению)

**Request:** `multipart/form-data`, поле `file`

**Response (200 OK):**
```json
{
  "data": {
    "fileId": "unique-file-id",
    "fileUrl": "https://pub-xxx.r2.dev/unique-file-id",
    "mimeType": "image/jpeg",
    "size": 1048576
  }
}
```

**Ошибки:**
- `400 BAD_REQUEST` — недопустимый MIME-тип или файл слишком большой

---

### 5.6. Модуль Calls

Требуется авторизация. Signaling происходит через WebSocket (см. раздел 6), но история доступна через REST.

#### GET `/api/v1/calls/history`

Получить историю всех звонков текущего пользователя.

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "call-uuid",
      "callType": "VIDEO",
      "status": "ENDED",
      "duration": 120,
      "startedAt": "2026-03-04T10:00:00Z",
      "participant": {
        "id": "user-uuid",
        "name": "Иван Петров",
        "avatarUrl": "https://...",
        "isOnline": false
      }
    }
  ]
}
```

---

## 6. WebSocket (STOMP)

### 6.1. Подключение

- **URL:** `ws://HOST:3000/ws`
- **Протокол:** STOMP over WebSocket
- **Авторизация:** JWT-токен передается в STOMP CONNECT headers

### 6.2. Пользовательские очереди (подписка)

Клиент должен подписаться на свои очереди для получения событий:

| Очередь | Описание |
|---|---|
| `/user/{userId}/queue/messages` | Новые сообщения |
| `/user/{userId}/queue/status` | Статусы прочтения (DELIVERED, READ) |
| `/user/{userId}/queue/typing` | Индикатор набора |
| `/user/{userId}/queue/call` | Звонковые события |

### 6.3. Chat destinations (отправка)

#### `/app/chat.send` — Отправить сообщение

```json
{
  "conversationId": "conversation-uuid",
  "text": "Привет!",
  "fileUrl": null,
  "mimeType": null,
  "clientMessageId": "client-generated-uuid-v4"
}
```

- `clientMessageId` обязателен, UUID v4, генерируется на клиенте
- Обеспечивает **идемпотентность** — повторная отправка с тем же clientMessageId не создаст дубль
- `text` и/или `fileUrl` должны быть заполнены

#### `/app/chat.read` — Отметить прочитанным

```json
{
  "conversationId": "conversation-uuid",
  "messageId": "message-uuid"
}
```

Обнуляет `unreadCount` у получателя. Отправляет событие статуса READ отправителю.

#### `/app/chat.typing` — Индикатор набора

```json
{
  "conversationId": "conversation-uuid"
}
```

Уведомляет собеседника о том, что пользователь печатает.

### 6.4. Call destinations (отправка)

#### `/app/call.init` — Инициировать звонок

```json
{
  "calleeId": "user-uuid",
  "callType": "VIDEO"
}
```

`callType`: `AUDIO` или `VIDEO`.

#### `/app/call.accept` — Принять звонок

```json
{
  "callId": "call-uuid"
}
```

#### `/app/call.reject` — Отклонить звонок

```json
{
  "callId": "call-uuid"
}
```

#### `/app/call.end` — Завершить звонок

```json
{
  "callId": "call-uuid"
}
```

#### `/app/call.sdpOffer` — WebRTC SDP Offer

```json
{
  "callId": "call-uuid",
  "sdp": "v=0\r\no=- ..."
}
```

#### `/app/call.sdpAnswer` — WebRTC SDP Answer

```json
{
  "callId": "call-uuid",
  "sdp": "v=0\r\no=- ..."
}
```

#### `/app/call.ice` — ICE Candidate

```json
{
  "callId": "call-uuid",
  "candidate": "candidate:...",
  "sdpMid": "0",
  "sdpMLineIndex": 0
}
```

---

## 7. Безопасность

### 7.1. JWT-токены

| Параметр | Значение |
|---|---|
| Алгоритм | HS256 |
| Access Token TTL | 3600 сек (1 час, настраивается) |
| Refresh Token TTL | 2592000 сек (30 дней, настраивается) |
| Хранение Refresh | В таблице `refresh_tokens` |
| Blacklist Access | В Redis с TTL = оставшееся время жизни токена |
| Хэширование паролей | BCrypt с cost factor 12 |

### 7.2. Публичные эндпоинты (без авторизации)

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `GET /swagger-ui/**`, `/v3/api-docs/**`
- `ws://HOST:3000/ws/**` (авторизация на уровне STOMP)

### 7.3. CORS

- Разрешены все origins (`*`) — для мобильных клиентов
- Разрешены методы: GET, POST, PUT, PATCH, DELETE, OPTIONS
- Credentials: true

### 7.4. Rate Limiting

- Только auth-эндпоинты: 5 запросов/мин на IP
- Реализация: in-memory через Bucket4j (`ConcurrentHashMap<IP, Bucket>`)
- При превышении: `429 Too Many Requests`

---

## 8. Инфраструктура

### 8.1. Docker Compose

4 сервиса:

| Сервис | Образ | Порт | Описание |
|---|---|---|---|
| postgres | postgres:16-alpine | 5432 | База данных |
| redis | redis:7-alpine | 6379 | Кэш, JWT blacklist |
| coturn | coturn/coturn:latest | host mode | TURN-сервер для WebRTC |
| backend | Dockerfile.dev | 3000 | Spring Boot приложение |

### 8.2. Переменные окружения (.env)

| Переменная | Описание |
|---|---|
| `POSTGRES_DB` | Имя БД (messenger) |
| `POSTGRES_USER` | Пользователь БД |
| `POSTGRES_PASSWORD` | Пароль БД |
| `REDIS_PASSWORD` | Пароль Redis |
| `JWT_SECRET` | Секрет для подписи JWT |
| `JWT_ACCESS_EXPIRES` | TTL access-токена (сек) |
| `JWT_REFRESH_EXPIRES` | TTL refresh-токена (сек) |
| `R2_ENDPOINT` | URL эндпоинта Cloudflare R2 |
| `R2_ACCESS_KEY_ID` | Access Key для R2 |
| `R2_SECRET_ACCESS_KEY` | Secret Key для R2 |
| `R2_BUCKET_NAME` | Имя бакета |
| `R2_PUBLIC_URL` | Публичный URL для доступа к файлам |
| `FILE_MAX_SIZE_BYTES` | Макс. размер файла (default: 104857600) |
| `FCM_PROJECT_ID` | Firebase Project ID |
| `FCM_CLIENT_EMAIL` | Firebase Client Email |
| `FCM_PRIVATE_KEY` | Firebase Private Key |
| `TURN_USERNAME` | Логин TURN-сервера |
| `TURN_PASSWORD` | Пароль TURN-сервера |
| `TURN_REALM` | Realm TURN-сервера |

### 8.3. Запуск

```bash
cd messenger
cp .env.example .env
# Заполнить .env значениями

docker compose up -d
```

Backend стартует на порту 3000. Swagger UI: `http://localhost:3000/swagger-ui.html`.

---

## 9. Чеклист для проверки

### 9.1. Структура и код

- [ ] Архитектура Controller → Service → Repository соблюдается
- [ ] DI через конструктор (нет `@Autowired` на полях)
- [ ] DTO и Entity разделены, конвертация только в Service
- [ ] Все секреты вынесены в переменные окружения
- [ ] `.env` не коммитится (есть `.env.example`)
- [ ] Flyway-миграция корректна, таблицы создаются

### 9.2. Авторизация

- [ ] Регистрация: создает пользователя, возвращает токены
- [ ] Логин: проверяет пароль BCrypt(12), возвращает токены
- [ ] Refresh: обменивает refresh на новую пару, старый инвалидируется
- [ ] Logout: access добавляется в Redis blacklist, refresh удаляется из БД
- [ ] Rate limiting: 5 req/min per IP на все auth-эндпоинты
- [ ] JWT blacklist проверяется в JwtFilter при каждом запросе

### 9.3. Чат

- [ ] Создание диалога: возвращает существующий если уже есть
- [ ] Список диалогов: показывает lastMessage, unreadCount, participant info
- [ ] Список диалогов: последние сообщения загружаются одним batch-запросом (`DISTINCT ON`), а не по одному на диалог
- [ ] Сообщения: cursor-based пагинация (before + limit)
- [ ] WebSocket отправка: clientMessageId обеспечивает идемпотентность (UNIQUE constraint)
- [ ] Прочтение: обнуляет unreadCount, меняет статус на READ
- [ ] Typing: уведомляет собеседника в реальном времени
- [ ] Проверка: пользователь видит только свои диалоги

### 9.4. Звонки

- [ ] Инициация: создается CallRecord со статусом RINGING
- [ ] Принятие: статус → ACTIVE, `startedAt` обновляется на момент принятия
- [ ] Отклонение: статус → REJECTED
- [ ] Завершение: статус → ENDED, `duration` = чистое время разговора (endedAt − startedAt)
- [ ] SDP Offer/Answer и ICE Candidate корректно пересылаются через WebSocket
- [ ] История звонков: показывает все звонки пользователя (до 50 последних)
- [ ] История звонков: пользователи-собеседники загружаются одним batch-запросом, а не по одному на звонок

### 9.5. Файлы

- [ ] Загрузка multipart/form-data в Cloudflare R2
- [ ] MIME-тип определяется Apache Tika (по содержимому, не расширению)
- [ ] Whitelist типов: JPEG, PNG, GIF, WebP, MP4, WebM, MP3, OGG, PDF
- [ ] Макс. размер: 100 MB
- [ ] Возвращает публичный URL

### 9.6. Обработка ошибок

- [ ] Единый формат `ErrorResponse` (statusCode, error, message, timestamp)
- [ ] GlobalExceptionHandler ловит все исключения
- [ ] 401 и 403 обрабатываются в SecurityConfig
- [ ] AppException используется для бизнес-ошибок
- [ ] ResponseWrapperAdvice оборачивает ответы в `{ "data": ... }`

### 9.7. Инфраструктура

- [ ] `docker compose up` запускает все 4 сервиса
- [ ] Healthcheck для PostgreSQL и Redis работает
- [ ] Flyway-миграции применяются при старте
- [ ] Swagger UI доступен на `/swagger-ui.html`

---

## 10. Оптимизации производительности

### 10.1. Список диалогов (N+1 → 2 запроса)

Загрузка списка диалогов выполняется за **2 SQL-запроса** независимо от количества диалогов:

1. **Запрос 1** — все участники диалогов пользователя (`JOIN FETCH` participants + users)
2. **Запрос 2** — последнее сообщение каждого диалога через `DISTINCT ON` (PostgreSQL native query)

```sql
SELECT DISTINCT ON (m.conversation_id) m.*
FROM messages m
WHERE m.conversation_id IN (...)
ORDER BY m.conversation_id, m.created_at DESC, m.id DESC
```

Используется существующий индекс `idx_messages_conv (conversation_id, created_at DESC)`.

### 10.2. История звонков (N+1 → 2 запроса)

Загрузка истории звонков выполняется за **2 SQL-запроса**:

1. **Запрос 1** — последние 50 звонков пользователя
2. **Запрос 2** — все уникальные собеседники одним `findAllById`

Данные собеседников кэшируются в `Map<UUID, User>` и переиспользуются (если один собеседник звонил 10 раз — загрузка из БД 1 раз).

---

## 11. Известные ограничения

1. **FCM push-уведомления** — реализовано только сохранение токена. Отправка push через Firebase Admin SDK подготовлена, но полная интеграция зависит от настройки Firebase-проекта.
2. **Rate Limiting** — хранится in-memory (`ConcurrentHashMap`), не персистентный. При рестарте сервера счетчики сбрасываются.
3. **Тесты** — интеграционные тесты (`AuthControllerTest`, `ChatServiceTest`) требуют запущенных PostgreSQL и Redis.
4. **CORS** — открыт для всех origins (для этапа разработки). На продакшене рекомендуется ограничить.
