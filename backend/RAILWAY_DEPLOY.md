# Деплой backend на Railway

Пошаговая инструкция по развёртыванию Spring Boot backend мессенджера на Railway.

## Предварительные требования

- Аккаунт на [Railway](https://railway.app)
- GitHub репозиторий с проектом (или Railway CLI)
- Cloudflare R2 (для хранения файлов)
- Firebase проект (для push-уведомлений, опционально)

---

## Шаг 1: Создание проекта на Railway

1. Перейдите на [railway.app/new](https://railway.app/new)
2. Выберите **Deploy from GitHub repo**
3. Подключите GitHub и выберите репозиторий
4. Укажите **Root Directory**: `messenger/backend` (если backend в подпапке)

---

## Шаг 2: Добавление PostgreSQL

1. В проекте нажмите **+ New** → **Database** → **PostgreSQL**
2. Railway создаст базу и автоматически добавит переменные: `DATABASE_URL`, `PGHOST`, `PGUSER`, `PGPASSWORD`, `PGPORT`, `PGDATABASE`

---

## Шаг 3: Добавление Redis

1. Нажмите **+ New** → **Database** → **Redis**
2. Railway добавит переменные: `REDIS_URL`, `REDISHOST`, `REDISPORT`, `REDISPASSWORD`

---

## Шаг 4: Настройка переменных окружения

В настройках **вашего backend-сервиса** → **Variables** добавьте:

### Обязательные (из PostgreSQL и Redis)

| Переменная | Значение | Описание |
|------------|----------|----------|
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | Ссылка на PostgreSQL |
| `POSTGRES_USER` | `${{Postgres.PGUSER}}` | Пользователь БД |
| `POSTGRES_PASSWORD` | `${{Postgres.PGPASSWORD}}` | Пароль БД |
| `REDIS_URL` | `${{Redis.REDIS_URL}}` | Ссылка на Redis |

> **Важно:** Замените `Postgres` и `Redis` на фактические имена ваших сервисов в проекте.

### JWT

| Переменная | Значение | Описание |
|------------|----------|----------|
| `JWT_SECRET` | `ваш-секретный-ключ-минимум-256-бит` | Секрет для подписи токенов |
| `JWT_ACCESS_EXPIRES` | `3600` | (опционально) Время жизни access-токена в секундах |
| `JWT_REFRESH_EXPIRES` | `2592000` | (опционально) Время жизни refresh-токена |

### Cloudflare R2 (хранилище файлов)

| Переменная | Значение |
|------------|----------|
| `R2_ENDPOINT` | `https://<account_id>.r2.cloudflarestorage.com` |
| `R2_ACCESS_KEY_ID` | Ваш Access Key ID |
| `R2_SECRET_ACCESS_KEY` | Ваш Secret Access Key |
| `R2_BUCKET_NAME` | Имя bucket |
| `R2_PUBLIC_URL` | Публичный URL для доступа к файлам |

### Firebase (push-уведомления, опционально)

| Переменная | Значение |
|------------|----------|
| `FCM_PROJECT_ID` | ID проекта Firebase |
| `FCM_CLIENT_EMAIL` | Email сервисного аккаунта |
| `FCM_PRIVATE_KEY` | Приватный ключ (в кавычках, с `\n` для переносов) |

### Опциональные

| Переменная | Значение по умолчанию |
|------------|----------------------|
| `PORT` | Railway задаёт автоматически |
| `FILE_MAX_SIZE_BYTES` | `104857600` (100 MB) |

---

## Шаг 5: Связывание сервисов

1. Выберите backend-сервис
2. В **Variables** нажмите **Add Variable** → **Add Reference**
3. Добавьте ссылки на `Postgres` и `Redis` (как в таблице выше)

---

## Шаг 6: Публичный домен

1. Выберите backend-сервис
2. Вкладка **Settings** → **Networking**
3. Нажмите **Generate Domain**
4. Railway выдаст URL вида `your-app.up.railway.app`

---

## Шаг 7: Деплой

### Через GitHub

При каждом push в ветку Railway автоматически пересоберёт и задеплоит приложение.

### Через Railway CLI

```bash
# Установка
npm i -g @railway/cli

# Авторизация
railway login

# В папке messenger/backend
cd messenger/backend
railway init   # привязка к проекту
railway up    # деплой
```

---

## Проверка

После деплоя откройте:

- `https://your-app.up.railway.app/swagger-ui.html` — Swagger UI
- `https://your-app.up.railway.app/actuator/health` — health check (если добавлен)

---

## Возможные проблемы

### Ошибка подключения к БД

- Убедитесь, что переменные `DATABASE_URL`, `POSTGRES_USER`, `POSTGRES_PASSWORD` заданы и ссылаются на Postgres
- Проверьте, что Postgres и backend в одном проекте Railway

### Ошибка Redis

- Проверьте `REDIS_URL` и что Redis запущен

### WebSocket не работает

- Railway поддерживает WebSocket по умолчанию
- Убедитесь, что фронтенд использует `wss://` для production

### Ошибка R2 / файлы

- Проверьте все переменные `R2_*`
- Убедитесь, что CORS настроен в Cloudflare R2 для вашего домена

---

## Стоимость

- Railway: бесплатный план ~$5 в месяц кредитов
- PostgreSQL и Redis считаются как отдельные сервисы
- Подробнее: [railway.app/pricing](https://railway.app/pricing)
