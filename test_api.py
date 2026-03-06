#!/usr/bin/env python3
"""
Тестовый скрипт для проверки всех критериев мессенджера.
Запуск: python3 test_api.py

Перед запуском убедитесь что Docker Desktop запущен и контейнеры работают:
  cd messenger
  docker compose up --build
"""

import subprocess
import json
import time
import urllib.parse
import struct
import zlib
import sys
import os

BASE = "http://localhost:3000/api/v1"
WS_BASE = "http://localhost:3000"

PASSED = 0
FAILED = 0
RESULTS = []

# ─────────────────────────────────────────────
# Утилиты
# ─────────────────────────────────────────────

def curl_json(method, url, headers=None, data=None, form_files=None):
    cmd = ["curl", "-s", "-X", method, url]
    if headers:
        for h in headers:
            cmd += ["-H", h]
    if data:
        cmd += ["-H", "Content-Type: application/json", "-d", data]
    if form_files:
        for f in form_files:
            cmd += ["-F", f]
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        return json.loads(r.stdout) if r.stdout.strip().startswith(("{", "[")) else {"_raw": r.stdout, "_code": r.returncode}
    except Exception as e:
        return {"_error": str(e)}


def curl_status(method, url, headers=None, data=None):
    cmd = ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "-X", method, url]
    if headers:
        for h in headers:
            cmd += ["-H", h]
    if data:
        cmd += ["-H", "Content-Type: application/json", "-d", data]
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        return int(r.stdout.strip())
    except:
        return 0


def header(text):
    print(f"\n{'─' * 60}")
    print(f"  {text}")
    print(f"{'─' * 60}")


def test(name, passed, detail=""):
    global PASSED, FAILED
    if passed:
        PASSED += 1
        icon = "✅"
    else:
        FAILED += 1
        icon = "❌"
    RESULTS.append((name, passed, detail))
    print(f"  {icon} {name}")
    if detail:
        for line in detail.split("\n"):
            print(f"     {line}")
    print()


def wait_for_server():
    print("Проверяю доступность сервера...", end=" ", flush=True)
    for _ in range(30):
        code = curl_status("GET", f"{BASE}/auth/login")
        if code > 0:
            print(f"OK (HTTP {code})")
            return True
        time.sleep(2)
    print("СЕРВЕР НЕ ОТВЕЧАЕТ!")
    return False


def create_test_png(path):
    sig = b'\x89PNG\r\n\x1a\n'
    def chunk(ct, d):
        c = ct + d
        return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    ihdr = struct.pack('>IIBBBBB', 1, 1, 8, 2, 0, 0, 0)
    raw = zlib.compress(b'\x00\xff\x00\x00')
    with open(path, 'wb') as f:
        f.write(sig + chunk(b'IHDR', ihdr) + chunk(b'IDAT', raw) + chunk(b'IEND', b''))


# ─────────────────────────────────────────────
# ТЕСТЫ
# ─────────────────────────────────────────────

def main():
    print("=" * 60)
    print("   ТЕСТИРОВАНИЕ МЕССЕНДЖЕРА — ВСЕ КРИТЕРИИ")
    print("=" * 60)

    if not wait_for_server():
        print("\n⚠️  Сервер не доступен. Убедитесь что Docker контейнеры запущены:")
        print("   cd messenger && docker compose up --build")
        sys.exit(1)

    phone1 = f"+7{int(time.time()) % 10000000000:010d}"
    phone2 = f"+7{(int(time.time()) + 1) % 10000000000:010d}"

    # ═══════════════════════════════════════════
    #  РАЗДЕЛ 1: АВТОРИЗАЦИЯ
    # ═══════════════════════════════════════════

    header("РАЗДЕЛ 1: АВТОРИЗАЦИЯ")

    # --- Тест 1.1: Регистрация ---
    print("  📝 Регистрация пользователя 1...")
    print(f"     Телефон: {phone1}")
    print(f"     Запрос: POST {BASE}/auth/register")
    print(f'     Тело: {{"phone":"{phone1}","password":"Test1234!","name":"Иван Петров"}}')
    print()

    reg1 = curl_json("POST", f"{BASE}/auth/register",
        data=json.dumps({"phone": phone1, "password": "Test1234!", "name": "Иван Петров"}))

    has_tokens = "accessToken" in reg1 and "refreshToken" in reg1
    user1_id = reg1.get("user", {}).get("id", "")

    test("1.1 Регистрация пользователя", has_tokens,
         f"ID: {user1_id}\n"
         f"Access token: {reg1.get('accessToken', 'НЕТ')[:50]}...\n"
         f"Refresh token: {reg1.get('refreshToken', 'НЕТ')[:50]}...\n"
         f"Имя: {reg1.get('user', {}).get('name', 'НЕТ')}"
         if has_tokens else f"Ошибка: {reg1}")

    print("  📝 Регистрация пользователя 2...")
    print(f"     Телефон: {phone2}")
    reg2 = curl_json("POST", f"{BASE}/auth/register",
        data=json.dumps({"phone": phone2, "password": "Test1234!", "name": "Мария Сидорова"}))

    user2_id = reg2.get("user", {}).get("id", "")
    test("1.2 Регистрация второго пользователя", "accessToken" in reg2,
         f"ID: {user2_id}" if user2_id else f"Ошибка: {reg2}")

    # --- Тест 1.3: Дублирование телефона ---
    print("  📝 Повторная регистрация с тем же телефоном (должна быть ошибка)...")
    reg_dup = curl_json("POST", f"{BASE}/auth/register",
        data=json.dumps({"phone": phone1, "password": "Test1234!", "name": "Дубликат"}))

    test("1.3 Защита от дублирования телефона", reg_dup.get("statusCode") == 409,
         f"Ответ: {reg_dup.get('message', reg_dup)}")

    # --- Тест 1.4: Логин ---
    print("  📝 Логин пользователя 1...")
    print(f"     Запрос: POST {BASE}/auth/login")
    print(f'     Тело: {{"phone":"{phone1}","password":"Test1234!"}}')
    print()

    login = curl_json("POST", f"{BASE}/auth/login",
        data=json.dumps({"phone": phone1, "password": "Test1234!"}))

    access = login.get("accessToken", "")
    refresh = login.get("refreshToken", "")
    auth_header = f"Authorization: Bearer {access}"

    test("1.4 Логин (JWT access + refresh)", bool(access) and bool(refresh),
         f"Access: {access[:50]}...\nRefresh: {refresh[:50]}..."
         if access else f"Ошибка: {login}")

    # --- Тест 1.5: Неверный пароль ---
    print("  📝 Логин с неверным паролем (должна быть ошибка 401)...")
    bad_login = curl_json("POST", f"{BASE}/auth/login",
        data=json.dumps({"phone": phone1, "password": "WrongPassword"}))

    test("1.5 Отклонение неверного пароля", bad_login.get("statusCode") == 401,
         f"Ответ: {bad_login.get('message', bad_login)}")

    # --- Тест 1.6: Refresh Token ---
    print("  📝 Обновление токена (refresh)...")
    print(f"     Запрос: POST {BASE}/auth/refresh")
    print(f'     Тело: {{"refreshToken":"<refresh_token>"}}')
    print()

    time.sleep(1)  # гарантия уникального jti
    ref_resp = curl_json("POST", f"{BASE}/auth/refresh",
        data=json.dumps({"refreshToken": refresh}))

    new_access = ref_resp.get("accessToken", "")
    new_refresh = ref_resp.get("refreshToken", "")

    test("1.6 Refresh token", bool(new_access) and bool(new_refresh),
         f"Новый access: {new_access[:50]}...\nНовый refresh: {new_refresh[:50]}..."
         if new_access else f"Ошибка: {ref_resp}")

    if new_access:
        access = new_access
        refresh = new_refresh
        auth_header = f"Authorization: Bearer {access}"

    # --- Тест 1.7: Старый refresh не работает ---
    print("  📝 Повторное использование старого refresh (должна быть ошибка)...")
    old_ref = curl_json("POST", f"{BASE}/auth/refresh",
        data=json.dumps({"refreshToken": login.get("refreshToken", "")}))

    test("1.7 Старый refresh token инвалидирован",
         old_ref.get("statusCode") in (401, 400),
         f"Ответ: {old_ref.get('message', old_ref)}")

    # --- Тест 1.8: Rate Limiting ---
    header("РАЗДЕЛ 2: RATE LIMITING")

    print("  📝 Отправляю 7 запросов подряд (лимит: 5/мин)...")
    print("     Ожидание: первые запросы — 200/401, потом — 429")
    print()

    # Ждём сброса rate limit от предыдущих тестов
    print("     ⏳ Ожидание сброса rate limit (65 сек)...")
    time.sleep(65)

    codes = []
    for i in range(7):
        code = curl_status("POST", f"{BASE}/auth/login",
            data=json.dumps({"phone": "+70000000000", "password": "wrong"}))
        codes.append(code)
        print(f"     Запрос {i+1}: HTTP {code} {'← заблокирован!' if code == 429 else ''}")

    has_429 = 429 in codes
    test("2.1 Rate limiting (5 req/min)", has_429,
         f"Коды ответов: {codes}\n"
         f"{'Блокировка с запроса №' + str(codes.index(429) + 1) if has_429 else 'Блокировка не сработала!'}")

    # Ждём сброса для дальнейших тестов
    print("     ⏳ Ожидание сброса rate limit (65 сек)...")
    time.sleep(65)

    # Перелогиниваемся
    login2 = curl_json("POST", f"{BASE}/auth/login",
        data=json.dumps({"phone": phone1, "password": "Test1234!"}))
    access = login2.get("accessToken", access)
    refresh = login2.get("refreshToken", refresh)
    auth_header = f"Authorization: Bearer {access}"

    # ═══════════════════════════════════════════
    #  РАЗДЕЛ 3: ПОИСК ПОЛЬЗОВАТЕЛЕЙ
    # ═══════════════════════════════════════════

    header("РАЗДЕЛ 3: ПОИСК ПОЛЬЗОВАТЕЛЕЙ")

    print("  📝 Поиск по имени 'Мария'...")
    print(f"     Запрос: GET {BASE}/users/search?query=Мария")
    print(f"     Заголовок: Authorization: Bearer <token>")
    print()

    query = urllib.parse.quote("Мария")
    search = curl_json("GET", f"{BASE}/users/search?query={query}",
        headers=[auth_header])

    if isinstance(search, list):
        test("3.1 Поиск пользователей по имени", len(search) >= 1,
             f"Найдено: {len(search)} результат(ов)\n" +
             "\n".join(f"  - {u.get('name', '?')} (id: {u.get('id', '?')[:8]}...)" for u in search[:5]))
    else:
        test("3.1 Поиск пользователей по имени", False, f"Ошибка: {search}")

    # Поиск по латинице
    print("  📝 Поиск по короткому запросу 'А' (должна быть ошибка — мин. 2 символа)...")
    q_short = urllib.parse.quote("А")
    search_short = curl_json("GET", f"{BASE}/users/search?query={q_short}",
        headers=[auth_header])

    test("3.2 Валидация: минимум 2 символа для поиска",
         isinstance(search_short, dict) and search_short.get("statusCode") == 400,
         f"Ответ: {search_short.get('message', search_short)}")

    # ═══════════════════════════════════════════
    #  РАЗДЕЛ 4: ЧАТ (HTTP API)
    # ═══════════════════════════════════════════

    header("РАЗДЕЛ 4: ЧАТ")

    print("  📝 Создание диалога с пользователем 2...")
    print(f"     Запрос: POST {BASE}/conversations")
    print(f'     Тело: {{"participantId":"{user2_id[:8]}..."}}')
    print()

    conv = curl_json("POST", f"{BASE}/conversations",
        headers=[auth_header],
        data=json.dumps({"participantId": user2_id}))
    conv_id = conv.get("id", "")

    test("4.1 Создание диалога", bool(conv_id),
         f"Conversation ID: {conv_id}\n"
         f"Участники: {conv.get('participant', {}).get('name', '?')}"
         if conv_id else f"Ошибка: {conv}")

    # Список диалогов
    print("  📝 Получение списка диалогов...")
    print(f"     Запрос: GET {BASE}/conversations")
    print()

    convs = curl_json("GET", f"{BASE}/conversations", headers=[auth_header])

    if isinstance(convs, list):
        test("4.2 Список диалогов", len(convs) >= 1,
             f"Всего диалогов: {len(convs)}")
    else:
        test("4.2 Список диалогов", False, f"Ошибка: {convs}")

    # Сообщения в диалоге
    if conv_id:
        print("  📝 Получение сообщений диалога...")
        print(f"     Запрос: GET {BASE}/conversations/{conv_id[:8]}../messages")
        print()

        msgs = curl_json("GET", f"{BASE}/conversations/{conv_id}/messages",
            headers=[auth_header])

        test("4.3 Получение сообщений (пустой диалог)", isinstance(msgs, list),
             f"Сообщений: {len(msgs) if isinstance(msgs, list) else 'ошибка'}")

    # ═══════════════════════════════════════════
    #  РАЗДЕЛ 5: WEBSOCKET
    # ═══════════════════════════════════════════

    header("РАЗДЕЛ 5: WEBSOCKET")

    print("  📝 Проверка WebSocket endpoint...")
    print(f"     Запрос: GET {WS_BASE}/ws")
    print()

    ws_code = curl_status("GET", f"{WS_BASE}/ws")
    test("5.1 WebSocket endpoint доступен",
         ws_code == 400,
         f"HTTP {ws_code} — ожидаемо (требуется WebSocket Upgrade, а не HTTP GET)\n"
         "WebSocket destinations:\n"
         "  Чат:    /app/chat.send, /app/chat.read, /app/chat.typing\n"
         "  Звонки: /app/call.init, /app/call.accept, /app/call.reject,\n"
         "          /app/call.end, /app/call.sdpOffer, /app/call.sdpAnswer,\n"
         "          /app/call.ice")

    # ═══════════════════════════════════════════
    #  РАЗДЕЛ 6: ЗАГРУЗКА ФАЙЛОВ
    # ═══════════════════════════════════════════

    header("РАЗДЕЛ 6: ЗАГРУЗКА ФАЙЛОВ")

    # Невалидный MIME
    print("  📝 Загрузка текстового файла (должен быть отклонён)...")
    print(f"     Запрос: POST {BASE}/files/upload")
    print(f"     Файл: fake.jpg (на самом деле текст)")
    print()

    with open("/tmp/test_fake.jpg", "w") as f:
        f.write("this is not a real image, just text")
    bad_upload = curl_json("POST", f"{BASE}/files/upload",
        headers=[auth_header], form_files=["file=@/tmp/test_fake.jpg"])
    bad_msg = bad_upload.get("message", str(bad_upload))

    test("6.1 Отклонение невалидного MIME type",
         "unsupported" in bad_msg.lower() or "mime" in bad_msg.lower() or "type" in bad_msg.lower(),
         f"Ответ сервера: {bad_msg}")

    # Валидный PNG
    print("  📝 Загрузка валидного PNG файла...")
    print(f"     Запрос: POST {BASE}/files/upload")
    print(f"     Файл: valid.png (настоящий 1×1 PNG)")
    print()

    create_test_png("/tmp/test_valid.png")
    good_upload = curl_json("POST", f"{BASE}/files/upload",
        headers=[auth_header], form_files=["file=@/tmp/test_valid.png"])
    good_msg = good_upload.get("message", str(good_upload))

    mime_passed = "unsupported" not in good_msg.lower() and "mime" not in good_msg.lower()
    test("6.2 PNG проходит MIME валидацию",
         mime_passed,
         f"Ответ: {good_msg[:100]}\n"
         "⚠️  Ошибка R2 (Cloudflare) ожидаема — в .env фейковые credentials.\n"
         "    Главное — файл прошёл проверку MIME типа и размера."
         if mime_passed else f"Ответ: {good_msg}")

    # Большой файл
    print("  📝 Загрузка слишком большого файла (>100MB)...")
    huge_path = "/tmp/test_huge.bin"
    try:
        with open(huge_path, "wb") as f:
            f.write(b'\x89PNG\r\n\x1a\n')  # PNG header
            f.seek(105 * 1024 * 1024)
            f.write(b'\x00')
        huge_upload = curl_json("POST", f"{BASE}/files/upload",
            headers=[auth_header], form_files=[f"file=@{huge_path}"])
        huge_msg = huge_upload.get("message", str(huge_upload))

        test("6.3 Отклонение файла > 100MB",
             huge_upload.get("statusCode") in (400, 413) or "size" in huge_msg.lower() or "large" in huge_msg.lower(),
             f"Ответ: {huge_msg[:100]}")
    except Exception as e:
        test("6.3 Отклонение файла > 100MB", False, f"Ошибка создания файла: {e}")
    finally:
        if os.path.exists(huge_path):
            os.remove(huge_path)

    # ═══════════════════════════════════════════
    #  РАЗДЕЛ 7: FCM PUSH TOKEN
    # ═══════════════════════════════════════════

    header("РАЗДЕЛ 7: FCM PUSH TOKEN")

    print("  📝 Обновление FCM токена...")
    print(f"     Запрос: PATCH {BASE}/users/me/fcm-token")
    print(f'     Тело: {{"fcmToken":"test-fcm-device-token"}}')
    print()

    fcm = curl_json("PATCH", f"{BASE}/users/me/fcm-token",
        headers=[auth_header],
        data='{"fcmToken":"test-fcm-device-token-12345"}')

    test("7.1 Обновление FCM токена",
         fcm.get("success") == True,
         f"Ответ: {fcm}")

    # ═══════════════════════════════════════════
    #  РАЗДЕЛ 8: ИСТОРИЯ ЗВОНКОВ
    # ═══════════════════════════════════════════

    header("РАЗДЕЛ 8: ЗВОНКИ (WebRTC)")

    print("  📝 Получение истории звонков...")
    print(f"     Запрос: GET {BASE}/calls/history")
    print()

    calls = curl_json("GET", f"{BASE}/calls/history", headers=[auth_header])

    test("8.1 История звонков", isinstance(calls, list),
         f"Звонков в истории: {len(calls) if isinstance(calls, list) else 'ошибка'}\n"
         "⚠️  WebRTC signaling (/app/call.*) тестируется только через WebSocket клиент")

    # ═══════════════════════════════════════════
    #  РАЗДЕЛ 9: LOGOUT + ИНВАЛИДАЦИЯ
    # ═══════════════════════════════════════════

    header("РАЗДЕЛ 9: LOGOUT + ИНВАЛИДАЦИЯ ТОКЕНА")

    print("  📝 Logout...")
    print(f"     Запрос: POST {BASE}/auth/logout")
    print(f"     Заголовок: Authorization: Bearer <access_token>")
    print(f'     Тело: {{"refreshToken":"<refresh_token>"}}')
    print()

    logout_code = curl_status("POST", f"{BASE}/auth/logout",
        headers=[auth_header],
        data=json.dumps({"refreshToken": refresh}))

    test("9.1 Logout", logout_code == 200, f"HTTP {logout_code}")

    time.sleep(0.5)

    print("  📝 Запрос со старым токеном после logout (должен быть отклонён)...")
    after_code = curl_status("GET", f"{BASE}/users/search?query=test",
        headers=[auth_header])

    test("9.2 Токен инвалидирован после logout",
         after_code in (401, 403),
         f"HTTP {after_code} — {'токен отклонён' if after_code in (401, 403) else 'ТОКЕН ВСЁ ЕЩЁ РАБОТАЕТ!'}")

    # ═══════════════════════════════════════════
    #  РАЗДЕЛ 10: ОБРАБОТКА ОШИБОК
    # ═══════════════════════════════════════════

    header("РАЗДЕЛ 10: ОБРАБОТКА ОШИБОК")

    print("  📝 Запрос без авторизации...")
    no_auth = curl_status("GET", f"{BASE}/conversations")
    test("10.1 Запрос без токена → 401/403",
         no_auth in (401, 403),
         f"HTTP {no_auth}")

    print("  📝 Невалидный JSON...")
    bad_json = curl_json("POST", f"{BASE}/auth/login", data="not json")
    test("10.2 Невалидный JSON → 400",
         bad_json.get("statusCode") == 400 or "error" in bad_json,
         f"Ответ: {bad_json.get('message', str(bad_json))[:80]}")

    # ═══════════════════════════════════════════
    #  ИТОГИ
    # ═══════════════════════════════════════════

    print("\n" + "=" * 60)
    print("   ИТОГИ ТЕСТИРОВАНИЯ")
    print("=" * 60)
    print(f"\n   ✅ Пройдено: {PASSED}")
    print(f"   ❌ Не пройдено: {FAILED}")
    print(f"   📊 Всего тестов: {PASSED + FAILED}")
    print(f"   📈 Результат: {PASSED}/{PASSED+FAILED} ({100*PASSED//(PASSED+FAILED)}%)")
    print()

    if FAILED > 0:
        print("   Не прошли:")
        for name, ok, detail in RESULTS:
            if not ok:
                print(f"   ❌ {name}")
        print()

    print("   Что не тестируется автоматически:")
    print("   • WebSocket чат в реальном времени (нужен STOMP клиент)")
    print("   • WebRTC signaling (нужны 2 мобильных клиента)")
    print("   • Push уведомления (нужен реальный Firebase)")
    print("   • Загрузка файлов в R2 (нужны реальные credentials)")
    print()
    print("=" * 60)

    # Уборка временных файлов
    for f in ["/tmp/test_fake.jpg", "/tmp/test_valid.png"]:
        if os.path.exists(f):
            os.remove(f)

    sys.exit(0 if FAILED == 0 else 1)


if __name__ == "__main__":
    main()
