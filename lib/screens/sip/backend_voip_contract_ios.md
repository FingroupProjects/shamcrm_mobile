# Backend Contract iOS VoIP Push

## 1. Цель

Этот документ фиксирует обязательный контракт между iOS приложением и backend для входящих SIP-звонков через `APNs VoIP Push`.

Цель backend:

- доставлять входящий звонок на iPhone даже при `background` и `terminated state`
- не смешивать обычные push token и `VoIP push token`
- давать стабильный payload для `PushKit + CallKit + native SIP restore`

## 2. Обязательные правила

Backend обязан:

- хранить `apns_voip` token отдельно от обычного APNs/FCM token
- отправлять входящий звонок через `VoIP push`, а не через обычный push
- не переиспользовать обычный notification payload для SIP-звонков
- передавать одинаковую структуру payload для всех iOS вызовов
- использовать стабильный `call_uuid` на весь жизненный цикл звонка

## 3. Регистрация токена

### 3.1 Тип токена

iOS клиент отправляет отдельный токен:

- `provider`: `apns_voip`
- `push_type`: `voip`
- `platform`: `ios`

### 3.2 Что backend должен хранить

Для каждого пользователя или SIP account backend должен хранить:

- `user_id`
- `device_id` или эквивалент
- `platform = ios`
- `provider = apns_voip`
- `push_type = voip`
- `token`
- `updated_at`
- `is_active`

### 3.3 Обновление токена

Backend должен:

- перезаписывать токен при каждом обновлении
- деактивировать старый токен при необходимости
- не использовать устаревший token после `push token invalidated`

## 4. Событие входящего звонка

Когда на backend появляется входящий SIP-звонок для iPhone, сервер должен:

1. определить активный `apns_voip` token пользователя
2. сгенерировать или взять стабильный `call_uuid`
3. отправить `VoIP push`
4. затем ожидать native SIP registration/invite processing на клиенте

Важно:

- сначала должен прилететь `VoIP push`
- после этого iOS поднимает native слой и `CallKit`
- backend не должен надеяться, что Flutter уже открыт

## 5. Обязательный payload

Минимальный payload:

```json
{
  "call_uuid": "2d4b4a64-53c0-4c52-9df8-8d50dc0a1b51",
  "call_id": "pbx-call-987654",
  "caller_name": "John Smith",
  "from_uri": "sip:100@pbx.example.com",
  "to_uri": "sip:200@pbx.example.com",
  "sip_uri": "sip:100@pbx.example.com",
  "has_video": false
}
```

Допустимо также отправлять синонимы, потому что iOS parser уже умеет читать несколько вариантов, но backend должен выбрать один канонический формат и придерживаться его.

## 6. Поля payload

### 6.1 Обязательные поля

- `call_uuid`
  единый UUID звонка для `CallKit`
- `call_id`
  ID звонка на стороне PBX или backend
- `caller_name`
  имя для показа на системном экране вызова
- `from_uri`
  SIP identity звонящего
- `to_uri`
  SIP identity вызываемого
- `sip_uri`
  основной SIP URI для восстановления вызова

### 6.2 Необязательные поля

- `has_video`
- `phone_number`
- `display_name`
- `remote_identity`
- `handle`

Если есть и `caller_name`, и `phone_number`, iOS должен иметь возможность показать оба, но backend всё равно должен отправлять `caller_name`.

## 7. Канонический JSON

Рекомендуемый канонический формат:

```json
{
  "call_uuid": "uuid",
  "call_id": "string",
  "caller_name": "string",
  "from_uri": "sip:100@pbx.example.com",
  "to_uri": "sip:200@pbx.example.com",
  "sip_uri": "sip:100@pbx.example.com",
  "has_video": false,
  "timestamp": 1719999999
}
```

## 8. Что backend не должен делать

Backend не должен:

- отправлять обычный APNs push вместо `VoIP push`
- менять `call_uuid` в середине одного звонка
- отправлять пустой `caller_name`, если имя доступно
- отправлять payload без `sip_uri` или без SIP identity
- рассчитывать на открытый экран SIP в приложении

## 9. Ожидаемый жизненный цикл

Нормальный сценарий:

1. backend получает событие входящего звонка
2. backend отправляет `VoIP push`
3. iPhone получает `PushKit` payload
4. iPhone делает `restoreRegistrationIfNeeded()`
5. iPhone показывает `CallKit`
6. пользователь нажимает `Answer`
7. native SIP stack принимает INVITE
8. audio session подключается

## 10. Ошибки и поведение backend

Если токен невалиден:

- backend должен пометить token как неактивный
- backend не должен бесконечно ретраить этот token

Если `VoIP push` отправить не удалось:

- backend должен записать ошибку доставки
- backend должен логировать `user_id`, `call_id`, `call_uuid`, `token_id`

Если звонок отменён до ответа:

- backend должен завершить SIP-сессию стандартным серверным способом
- при необходимости отдельный cancel push можно проектировать позже, но базовый контракт от него не зависит

## 11. Логирование backend

Backend должен логировать минимум:

- `voip_push_prepare`
- `voip_push_sent`
- `voip_push_failed`
- `call_uuid`
- `call_id`
- `user_id`
- `device_id` или `token_id`
- `provider = apns_voip`

## 12. Критерии приёмки

Контракт считается выполненным, если:

- iPhone получает звонок в `foreground`
- iPhone получает звонок в `background`
- iPhone получает звонок в `terminated state`
- payload стабилен и не меняется между релизами без согласования
- backend хранит `apns_voip` token отдельно
- delivery ошибок достаточно для диагностики

## 13. Статус

Текущий статус для проекта:

- контракт зафиксирован
- backend реализация должна быть сверена с этим документом
- любые отклонения backend от этого формата должны считаться багом интеграции
