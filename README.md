# ShamCRM Mobile

Мобильное приложение ShamCRM на Flutter для CRM-процессов, задач, чатов,
склада, финансов, аналитики, SIP/VoIP и push-уведомлений.

Последнее обновление README: 2026-05-25.

## Кратко

- Текущая версия приложения: `2.1.105+133`
- Flutter SDK в локальной среде: `3.44.0`
- Dart SDK в локальной среде: `3.12.0`
- Минимальное ограничение SDK в проекте: `^3.5.3`
- Основная ветка разработки в текущем checkout: `zoiper_2`
- State management: `flutter_bloc`, `bloc`, `provider`
- Backend integration: REST API, WebSocket/Pusher, Firebase Messaging
- Offline layer: Drift/SQLite и outbox runtime
- SIP/VoIP: кастомный `third_party/sip_ua`, `flutter_webrtc`, native bridges

## Назначение

ShamCRM Mobile закрывает основные мобильные сценарии CRM:

- работа с лидами, сделками, задачами и событиями;
- корпоративные чаты, файлы, голосовые сообщения и реакции;
- push-уведомления через Firebase;
- SIP/VoIP звонки и call-center функции;
- складской учет, товары, заказы и документы;
- финансы, кассы, доходы, расходы, дебиторы и кредиторы;
- аналитика, dashboards и отчеты;
- локализация и переключение языка;
- offline-first инфраструктура для части пользовательских действий.

## Технологии

### Основной стек

| Область | Используется |
| --- | --- |
| UI | Flutter, Material, кастомные widgets |
| State management | `flutter_bloc`, `bloc`, `provider`, `equatable` |
| HTTP | `http`, `dio` |
| Realtime | `dart_pusher_channels` |
| Push | `firebase_core`, `firebase_messaging` |
| Storage | `shared_preferences`, `flutter_secure_storage`, Drift, SQLite |
| Media | `just_audio`, `audioplayers`, `audio_service`, `file_picker`, `image_picker` |
| SIP/VoIP | `sip_ua`, `flutter_webrtc`, native Android/iOS integration |
| Maps/location | `geolocator`, `flutter_map`, `latlong2` |
| QR/scanner | `mobile_scanner` |
| Localization | `intl`, `flutter_localizations`, `flutter_localization` |
| Code generation | `json_serializable`, `build_runner`, `drift_dev` |

### Локальные и fork-зависимости

Проект использует локальные пакеты:

- `third_party/animated_custom_dropdown`
- `third_party/sip_ua`

Также используется git-зависимость:

- `voice_message_package` из `https://github.com/noolfj/voice_message_playerCustom.git`

## Требования

### Flutter и Dart

В `pubspec.yaml` задано:

```yaml
environment:
  sdk: ^3.5.3
```

На момент обновления README проект проверялся локально на:

```text
Flutter 3.44.0
Dart 3.12.0
```

### Android

- Android Studio
- Android SDK
- Gradle/Android Gradle Plugin, совместимые с текущей Flutter stable
- Устройство или эмулятор Android
- Firebase config: `android/app/google-services.json`

### iOS

- macOS
- Xcode
- CocoaPods
- iOS Simulator или физическое устройство
- Firebase config: `ios/Runner/GoogleService-Info.plist`

Для SIP/VoIP и push на iOS дополнительно важны provisioning profiles,
capabilities, background modes и push/VoIP настройки.

## Быстрый старт

```bash
git clone <repository-url>
cd shamcrm_mobile
flutter doctor
flutter pub get
flutter run
```

Запуск на конкретном устройстве:

```bash
flutter devices
flutter run -d <device-id>
```

Запуск release-сборки локально:

```bash
flutter run --release -d <device-id>
```

## Конфигурация Firebase

В проекте используются следующие файлы:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

Если Firebase-проект меняется, обновите конфиги через FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

После обновления Firebase-конфигов проверьте:

```bash
flutter clean
flutter pub get
flutter run
```

## Структура проекта

```text
.
├── android/                  # Android native project
├── ios/                      # iOS native project
├── assets/                   # изображения, иконки, аудио, шрифты, языки
├── docs/                     # техническая документация
├── lib/
│   ├── api/service/          # API, Dio, Firebase, storage, network services
│   ├── bloc/                 # BLoC/Cubit слои по доменам
│   ├── custom_widget/        # переиспользуемые кастомные виджеты
│   ├── data/                 # data helpers
│   ├── generated/            # generated localization/code
│   ├── l10n/                 # localization resources
│   ├── models/               # DTO/domain models
│   ├── offline/              # Drift DB, repositories, outbox
│   ├── page_2/               # склад, заказы, товары, деньги, РМК
│   ├── screens/              # экраны приложения
│   ├── services/             # application services
│   ├── utils/                # утилиты
│   └── widgets/              # общие widgets
├── test/                     # unit/widget tests
├── third_party/              # локальные зависимости и forks
├── pubspec.yaml              # зависимости и assets
└── analysis_options.yaml     # настройки analyzer/lints
```

## Основные модули

### Auth и профиль

- вход по домену, логину и паролю;
- PIN/biometric flow;
- хранение токена и доменных настроек;
- профиль, язык, настройки пользователя.

Ключевые директории:

- `lib/screens/auth`
- `lib/screens/profile`
- `lib/bloc/login`
- `lib/bloc/auth_domain`
- `lib/api/service/secure_storage_service.dart`

### CRM

- лиды;
- сделки;
- задачи;
- события;
- история;
- статусы, фильтры, менеджеры, источники.

Ключевые директории:

- `lib/screens/lead`
- `lib/screens/deal`
- `lib/screens/task`
- `lib/screens/event`
- `lib/bloc/lead*`
- `lib/bloc/deal*`
- `lib/bloc/task*`

### Чаты

- список чатов;
- сообщения;
- файлы;
- voice messages;
- закрепление, редактирование, удаление;
- реакции;
- unread counters.

Ключевые директории:

- `lib/screens/chats`
- `lib/bloc/chats`
- `lib/bloc/messaging`
- `lib/services/chat_unread_counter_service.dart`
- `lib/api/service/message_reaction_api_service.dart`

### SIP/VoIP

- SIP service;
- native Android bridge;
- iOS VoIP integration;
- call overlay;
- call-center screens.

Ключевые директории:

- `lib/screens/sip`
- `lib/bloc/call_bloc`
- `android/app/src/main/kotlin`
- `ios/`
- `third_party/sip_ua`

Дополнительная документация:

- `SIP_IOS_ANDROID_AUDIT.md`
- `docs/ios_voip_backend_pbx_contract.md`

### Склад, товары, заказы и финансы

Ключевые директории:

- `lib/page_2/goods`
- `lib/page_2/order`
- `lib/page_2/warehouse`
- `lib/page_2/money`
- `lib/page_2/dashboard`
- `lib/bloc/page_2_BLOC`

### Offline layer

Offline-инфраструктура находится в:

- `lib/offline/core`
- `lib/offline/db`
- `lib/offline/repositories`

Дополнительная документация:

- `docs/offline_first_phase1.md`

## API

Основной API-клиент находится в:

- `lib/api/service/api_service.dart`

Важные связанные сервисы:

- `lib/api/service/dio_client.dart`
- `lib/api/service/firebase_api.dart`
- `lib/api/service/http_logger.dart`
- `lib/api/service/internet_monitor_service.dart`
- `lib/api/service/localization_service.dart`
- `lib/api/service/gps_tracker_service.dart`

Базовые URL формируются динамически на основе домена пользователя.
Токены и доменные настройки хранятся локально через `SharedPreferences` и
secure storage.

## Локализация

В проекте используются:

- `flutter_localizations`
- `intl`
- `flutter_localization`
- локальные файлы в `assets/langs/`
- generated-код в `lib/generated/`

При изменении локалей проверьте:

```bash
flutter pub get
flutter analyze
flutter test
```

## Assets и шрифты

Assets объявлены в `pubspec.yaml`.

Основные директории:

- `assets/icons`
- `assets/images`
- `assets/audio`
- `assets/fonts`
- `assets/langs`
- `assets/page_2`

Шрифты:

- `Gilroy`
- `Golos`

После добавления assets обязательно проверьте отступы в `pubspec.yaml` и
запустите:

```bash
flutter pub get
```

## Code generation

Для JSON/Drift генерации:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Для watch-режима:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Проверки качества

Рекомендуемый минимальный набор перед pull request:

```bash
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Дополнительно для dependency-аудита:

```bash
flutter pub outdated
```

## Текущее состояние проверок

На момент обновления README:

- `flutter pub get` проходит;
- `flutter analyze` проходит без compile errors, но показывает много warnings/info;
- `flutter test` не проходит.

Известные проблемы тестов:

- `test/widget_test.dart` не содержит рабочий `main`;
- тест `mergeIncomingMessage replaces fresh local temp message when socket mislabels it`
  падает из-за дедупликации optimistic chat message.

Это нужно исправить до того, как считать CI здоровым.

## Сборка

### Android APK

```bash
flutter build apk --release
```

Результат:

```text
build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle

```bash
flutter build appbundle --release
```

Результат:

```text
build/app/outputs/bundle/release/app-release.aab
```

### iOS

```bash
flutter build ios --release
```

Для публикации обычно используется Xcode Archive:

```bash
open ios/Runner.xcworkspace
```

## Работа с iOS Pods

Если iOS-зависимости сломались:

```bash
cd ios
pod install
cd ..
```

Если нужен полный пересбор:

```bash
flutter clean
flutter pub get
cd ios
pod deintegrate
pod install
cd ..
```

## Важные предупреждения по зависимостям

`flutter pub get` сообщает, что часть пакетов имеет новые major/minor версии,
несовместимые с текущими constraints. Также есть discontinued пакет:

- `flutter_unfocuser`

Flutter также предупреждает, что часть iOS/macOS plugins пока не поддерживает
Swift Package Manager. Сейчас это warning, но в будущих версиях Flutter может
стать ошибкой.

Перед массовым обновлением зависимостей обязательно прогоняйте:

```bash
flutter test
flutter analyze
flutter build apk --release
flutter build ios --release
```

## Git hygiene

В репозитории не должны появляться:

- `.DS_Store`
- временные `.backup` файлы
- zip-архивы исходников в `test/`
- локальные IDE/cache артефакты
- build outputs

Если такие файлы уже tracked, их нужно удалить из индекса отдельным cleanup
commit:

```bash
git rm --cached <file>
```

Не удаляйте пользовательские изменения без явного согласования.

## Известные технические долги

- `lib/api/service/api_service.dart` слишком большой и смешивает много зон
  ответственности.
- `lib/main.dart` содержит большой wiring BLoC/providers и startup logic.
- Analyzer показывает много nullability/style предупреждений.
- В `analysis_options.yaml` отключен `use_build_context_synchronously`.
- Тестовое покрытие недостаточно для размера проекта.
- В проекте есть устаревшие и потенциально проблемные зависимости.
- Некоторые state/event классы объявляют `props`, но не наследуются от
  `Equatable`, из-за чего analyzer показывает `override_on_non_overriding_member`.

## Рекомендуемый порядок стабилизации

1. Починить `flutter test`.
2. Удалить tracked `.DS_Store`, `.backup`, `.zip` артефакты.
3. Разобрать `override_on_non_overriding_member` в event/state классах.
4. Разобрать nullability warnings: `dead_null_aware_expression`,
   `invalid_null_aware_operator`, `unnecessary_null_comparison`.
5. Вернуть контроль над `use_build_context_synchronously`.
6. Постепенно декомпозировать `ApiService` по доменам.
7. Добавить тесты на критичные сценарии: auth, chats, offline outbox, SIP state.

## Troubleshooting

### После pull не запускается проект

```bash
flutter clean
flutter pub get
flutter run
```

### iOS не собирается

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run
```

### Ошибка assets

Проверьте:

- путь существует;
- файл объявлен в `pubspec.yaml`;
- отступы YAML корректны;
- регистр имени файла совпадает.

Затем:

```bash
flutter pub get
```

### Ошибка generated files

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Push-уведомления не приходят

Проверьте:

- Firebase config для нужной платформы;
- permissions;
- APNs setup для iOS;
- регистрацию FCM/VoIP token на backend;
- логи `FirebaseApi`.

### SIP/VoIP не работает

Проверьте:

- SIP credentials;
- native permissions;
- background modes;
- PBX/backend contract;
- `SIP_IOS_ANDROID_AUDIT.md`;
- `docs/ios_voip_backend_pbx_contract.md`.

## Документация в проекте

- `ANALYTICS_API.md`
- `LEAD_CHAT_LOGIC.md`
- `SIP_IOS_ANDROID_AUDIT.md`
- `city_region_fields_fix.md`
- `inactive_fields_fix.md`
- `task_status_loading_fix.md`
- `validation_border_fix.md`
- `docs/offline_first_phase1.md`
- `docs/ios_voip_backend_pbx_contract.md`
- `docs/shamcrm_ideal_tz_2026_04_08.md`

## Правила разработки

- Перед изменениями изучайте существующий BLoC/API pattern в модуле.
- Не добавляйте новый state manager без необходимости.
- Не смешивайте UI, API и storage logic в одном новом классе.
- Для новых API-ответов добавляйте модели и тестируйте parsing.
- Для новых assets обновляйте `pubspec.yaml`.
- Для новых offline-сценариев учитывайте sync/outbox behavior.
- Для изменений SIP/VoIP проверяйте Android и iOS отдельно.
- Перед PR запускайте `flutter analyze` и `flutter test`.

## Поддержка

Для внутренних вопросов по проекту используйте командные каналы ShamCRM/Softtech
и профильных владельцев модулей: mobile, backend, SIP/VoIP, Firebase, warehouse,
analytics.
