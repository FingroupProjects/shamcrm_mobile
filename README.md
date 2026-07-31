# 📱 ShamCRM Mobile

> **Мобильное приложение CRM-системы с полным функционалом управления продажами, складом, финансами и коммуникациями**

[![Flutter Version](https://img.shields.io/badge/Flutter-3.5.3-02569B?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.5.3-0175C2?logo=dart)](https://dart.dev)
[![Version](https://img.shields.io/badge/version-2.1.160-green)]()
[![Build](https://img.shields.io/badge/build-220-blue)]()

> **Актуальный baseline документации:** ветка `color_schema_3`, версия
> `2.1.160+220`, август 2026. README опубликован в `main` для общего доступа.
> Перед разработкой проверьте текущую ветку: публикация документации сама по
> себе не означает автоматический перенос всего кода `color_schema_3` в `main`.

---

## 📑 Содержание

1. [О проекте](#-о-проекте)
2. [Ключевые возможности](#-ключевые-возможности)
3. [Технологический стек](#-технологический-стек)
4. [Архитектура проекта](#-архитектура-проекта)
5. [Требования](#-требования)
6. [Установка и настройка](#-установка-и-настройка)
7. [Структура проекта](#-структура-проекта)
8. [Модули приложения](#-модули-приложения)
9. [Работа с API](#-работа-с-api)
10. [Управление состоянием (BLoC)](#-управление-состоянием-bloc)
11. [Локализация](#-локализация)
12. [Firebase интеграция](#-firebase-интеграция)
13. [Аутентификация и безопасность](#-аутентификация-и-безопасность)
14. [Сборка приложения](#-сборка-приложения)
15. [Troubleshooting](#-troubleshooting)
16. [Code Style и Best Practices](#-code-style-и-best-practices)
17. [Contributing](#-contributing)
18. [Контакты и поддержка](#-контакты-и-поддержка)
19. [Статус разработки на август 2026](#-статус-разработки-на-август-2026)
20. [Roadmap](#-roadmap-что-осталось)

---

## 🎯 О проекте

**ShamCRM Mobile** — это комплексное мобильное приложение для управления взаимоотношениями с клиентами (CRM), разработанное на Flutter. Приложение предоставляет полный функционал для:

- 📊 Управления продажами и лидами
- 📦 Складского учета и документооборота
- 💰 Финансового менеджмента
- 💬 Корпоративных коммуникаций
- 📞 Управления call-центром
- 📈 Аналитики и отчетности

### Целевая аудитория

- Менеджеры по продажам
- Руководители отделов
- Складские работники
- Операторы call-центра
- Финансовые менеджеры
- Руководство компании

---

## ⭐ Ключевые возможности

### 🔹 Управление продажами

- **Лиды (Leads)**: полный lifecycle от создания до конвертации
- **Сделки (Deals)**: управление воронкой продаж с канбан-доской
- **Задачи (Tasks)**: постановка и отслеживание задач
- **Календарь событий**: планирование встреч и звонков
- **История изменений**: полный аудит всех действий

### 🔹 Коммуникации

- **Корпоративный чат**: групповые и личные чаты
- **Voice сообщения**: запись и воспроизведение аудио
- **Файлы и медиа**: обмен документами и изображениями
- **Шаблоны сообщений**: быстрые ответы
- **Push-уведомления**: мгновенные оповещения

### 🔹 Склад и документооборот

- **Приход товара**: оформление поступлений
- **Продажа клиенту**: создание накладных
- **Возвраты**: от клиентов и поставщикам
- **Перемещения**: между складами
- **Списания**: учет потерь
- **Остатки**: real-time отчеты

### 🔹 Финансы

- **Касса**: учет наличных операций
- **Доходы/Расходы**: категоризация и аналитика
- **Дебиторы/Кредиторы**: контроль задолженностей
- **Отчеты**: финансовые показатели

### 🔹 Аналитика

- **Dashboard**: визуализация KPI
- **Графики и диаграммы**: конверсия, скорость обработки
- **Отчеты по сотрудникам**: эффективность работы
- **Воронка продаж**: анализ этапов

---

## 🛠 Технологический стек

### Frontend Framework

- **Flutter**: `3.5.3` - UI фреймворк
- **Dart**: `3.5.3` - язык программирования

### Архитектура и State Management

- **flutter_bloc**: `^8.1.6` - BLoC паттерн для управления состоянием
- **equatable**: `^2.0.5` - сравнение объектов
- **provider**: для dependency injection

### Сетевое взаимодействие

- **http**: `^1.2.2` - HTTP клиент
- **dio**: `^5.7.0` - продвинутый HTTP клиент с interceptors
- **dart_pusher_channels**: `^1.2.3` - WebSocket для real-time

### Backend интеграция

- **firebase_core**: `^3.6.0` - Firebase SDK
- **firebase_messaging**: `^15.2.9` - Push-уведомления
- **shared_preferences**: `^2.3.5` - локальное хранилище
- **flutter_secure_storage**: `^9.2.2` - защищенное хранилище

### UI/UX компоненты

- **dropdown_search**: `^6.0.2` - расширенные выпадающие списки
- **fl_chart**: `^0.69.0` - графики и диаграммы
- **chat_bubbles**: `^1.6.0` - UI для чатов
- **table_calendar**: `^3.2.0` - календарь
- **cached_network_image**: `^3.4.1` - кэширование изображений
- **photo_view**: `^0.15.0` - просмотр изображений
- **infinite_scroll_pagination**: `^4.0.0` - бесконечная прокрутка
- **modal_bottom_sheet**: `^3.0.0` - модальные окна
- **flutter_slidable**: `^4.0.1` - swipe actions

### Медиа и файлы

- **just_audio**: `^0.9.18` - аудио плеер
- **audioplayers**: `^6.1.0` - дополнительный плеер
- **audio_service**: `^0.18.18` - фоновое воспроизведение
- **social_media_recorder**: `^1.2.1` - запись голоса
- **file_picker**: `^10.3.3` - выбор файлов
- **image_picker**: `^1.2.0` - выбор изображений
- **image_gallery_saver_plus**: `^4.0.1` - сохранение в галерею

### Безопасность и аутентификация

- **local_auth**: `^2.3.0` - биометрическая аутентификация
- **app_tracking_transparency**: `^2.0.6+1` - разрешения iOS
- **permission_handler**: `^11.4.0` - управление разрешениями

### Дополнительные возможности

- **mobile_scanner**: `^7.0.1` - QR/Barcode сканер
- **connectivity_plus**: `^6.1.4` - мониторинг соединения
- **device_info_plus**: `^11.1.1` - информация об устройстве
- **package_info_plus**: `^8.1.1` - версия приложения
- **url_launcher**: `^6.3.1` - открытие URL
- **flutter_localization**: `^0.3.1` - локализация
- **intl**: `^0.20.2` - интернационализация
- **flutter_contacts**: `^1.1.9+2` - доступ к контактам
- **vibration**: `^2.0.1` - вибрация

### Development Tools

- **flutter_lints**: `^5.0.0` - линтер
- **json_annotation**: `^4.9.0` - JSON сериализация
- **json_serializable**: `^6.11.1` - генерация JSON кода
- **build_runner**: `^2.8.0` - code generation

---

## 🏗 Архитектура проекта

### Архитектурный паттерн: Clean Architecture + BLoC

```
┌─────────────────────────────────────────┐
│          Presentation Layer             │
│  (Screens, Widgets, BLoC State)         │
├─────────────────────────────────────────┤
│          Business Logic Layer           │
│     (BLoC, Events, States, Cubits)      │
├─────────────────────────────────────────┤
│          Data Layer                     │
│  (API Services, Models, Repositories)   │
├─────────────────────────────────────────┤
│          External Services              │
│  (Firebase, REST API, WebSocket)        │
└─────────────────────────────────────────┘
```

### Принципы архитектуры

1. **Separation of Concerns**: четкое разделение на слои
2. **Single Responsibility**: каждый модуль имеет одну ответственность
3. **Dependency Injection**: через Provider/BlocProvider
4. **Reactive Programming**: BLoC streams для состояний
5. **Immutable State**: неизменяемые состояния с Equatable

---

## 📋 Требования

### Системные требования

#### Для разработки:

- **macOS**: 12.0+ (для iOS разработки)
- **Windows**: 10+ / **Linux**: Ubuntu 20.04+
- **RAM**: минимум 8GB (рекомендуется 16GB)
- **Disk**: 10GB свободного места

#### SDK и инструменты:

- **Flutter SDK**: `3.5.3` или выше
- **Dart SDK**: `3.5.3` (входит в Flutter)
- **Android Studio**: последняя версия
  - Android SDK: API 21-35
  - Gradle: 8.x
  - Kotlin: 1.9+
- **Xcode**: 15+ (только macOS, для iOS)
- **VS Code** (опционально): с Flutter/Dart плагинами

#### Устройства для тестирования:

- **Android**: 5.0 (API 21) и выше
- **iOS**: 12.0 и выше

### Firebase настройки

Проект использует Firebase. Необходимы файлы конфигурации:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

---

## 🚀 Установка и настройка

### 1. Клонирование репозитория

```bash
git clone <repository-url>
cd shamcrm_mobile
```

### 2. Установка Flutter

Если Flutter еще не установлен:

```bash
# macOS/Linux
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Проверка установки
flutter doctor
```

**Важно**: убедитесь, что `flutter doctor` не показывает критических ошибок.

### 3. Установка зависимостей

```bash
# Получение всех пакетов
flutter pub get

# Генерация кода (для JSON сериализации и локализации)
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Настройка Firebase

#### Вариант A: Использование существующего проекта

Файлы конфигурации уже в проекте:
- `android/app/google-services.json` ✅
- `ios/Runner/GoogleService-Info.plist` ✅
- `lib/firebase_options.dart` ✅

#### Вариант B: Новый Firebase проект

```bash
# Установка Firebase CLI
npm install -g firebase-tools

# Вход в Firebase
firebase login

# Инициализация FlutterFire
dart pub global activate flutterfire_cli
flutterfire configure
```

### 5. Настройка Android

#### android/local.properties

Создайте файл, если его нет:

```properties
sdk.dir=/Users/YOUR_USERNAME/Library/Android/sdk
flutter.sdk=/Users/YOUR_USERNAME/flutter
```

#### Signing ключ (для релиза)

Ключ уже настроен в `android/app/build.gradle`:

```gradle
signingConfigs {
    release {
        storeFile file("key.keystore")
        storePassword "123456"
        keyAlias "keyalias"
        keyPassword "123456"
    }
}
```

⚠️ **ВАЖНО**: Для production используйте надежные пароли и храните ключи в безопасности!

### 6. Настройка iOS

```bash
cd ios
pod install
cd ..
```

**Требования для iOS:**
- macOS с Xcode 15+
- Активная учетная запись Apple Developer (для физических устройств)
- Настроенные Signing Certificates в Xcode

### 7. Настройка окружения (Environment)

#### API базовый URL

Настраивается в `lib/api/service/api_service.dart`. По умолчанию домен вводится пользователем при первом запуске через:
- QR-код сканирование
- Ручной ввод домена

#### Переменные окружения (опционально)

Создайте файл `.env` (если требуется):

```env
API_BASE_URL=https://your-api-domain.com
PUSHER_KEY=your_pusher_key
PUSHER_CLUSTER=your_cluster
```

---

## 📁 Структура проекта

```
shamcrm_mobile/
├── android/                      # Android нативный код
│   ├── app/
│   │   ├── src/main/kotlin/     # Kotlin код
│   │   ├── build.gradle         # Конфигурация сборки
│   │   ├── key.keystore         # Signing ключ
│   │   └── google-services.json # Firebase конфиг
│   └── build.gradle             # Gradle корневой
├── ios/                         # iOS нативный код
│   ├── Runner/
│   │   ├── Info.plist           # iOS конфигурация
│   │   └── GoogleService-Info.plist
│   ├── Podfile                  # CocoaPods зависимости
│   └── Runner.xcworkspace       # Xcode workspace
├── assets/                      # Ресурсы приложения
│   ├── icons/                   # Иконки
│   │   ├── MyNavBar/           # Навигация
│   │   ├── AppBar/             # AppBar иконки
│   │   ├── chats/              # Чаты
│   │   └── files/              # Типы файлов
│   ├── fonts/                   # Шрифты (Gilroy, Golos)
│   ├── images/                  # Изображения
│   ├── audio/                   # Аудио файлы
│   └── langs/                   # Переводы (ru, en, uz)
│       ├── ru.json
│       ├── en.json
│       └── uz.json
├── lib/                         # Dart исходный код
│   ├── main.dart                # Точка входа
│   ├── api/                     # API слой
│   │   └── service/
│   │       ├── api_service.dart          # Основной API клиент
│   │       ├── api_service_chats.dart    # Чаты API
│   │       ├── firebase_api.dart         # Firebase сервис
│   │       ├── secure_storage_service.dart
│   │       ├── biometric_service.dart
│   │       ├── gps_tracker_service.dart
│   │       ├── widget_service.dart
│   │       └── internet_monitor_service.dart
│   ├── bloc/                    # BLoC state management
│   │   ├── auth_domain/         # Аутентификация домена
│   │   ├── login/               # Логин
│   │   ├── lead/                # Лиды
│   │   ├── deal/                # Сделки
│   │   ├── task/                # Задачи
│   │   ├── my-task/             # Мои задачи
│   │   ├── chats/               # Чаты
│   │   ├── dashboard/           # Дашборд
│   │   ├── notifications/       # Уведомления
│   │   ├── organization/        # Организации
│   │   ├── profile/             # Профиль
│   │   ├── page_2_BLOC/         # Склад и товары BLoCs
│   │   │   ├── goods/
│   │   │   ├── category/
│   │   │   ├── order/
│   │   │   ├── document/
│   │   │   └── dashboard/
│   │   └── ...                  # Другие BLoCs
│   ├── models/                  # Модели данных
│   │   ├── lead_model.dart
│   │   ├── deal_model.dart
│   │   ├── task_model.dart
│   │   ├── chats_model.dart
│   │   ├── user_model.dart
│   │   ├── money/               # Финансовые модели
│   │   ├── page_2/              # Склад модели
│   │   └── dashboard_charts_models/
│   ├── screens/                 # UI экраны
│   │   ├── auth/                # Аутентификация
│   │   │   ├── auth_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── pin_screen.dart
│   │   │   ├── pin_setup_screen.dart
│   │   │   └── qr_scanner_screen.dart
│   │   ├── home_screen.dart     # Главный экран
│   │   ├── lead/                # Экраны лидов
│   │   ├── deal/                # Экраны сделок
│   │   ├── task/                # Экраны задач
│   │   ├── my-task/             # Мои задачи
│   │   ├── chats/               # Чаты
│   │   ├── dashboard/           # Дашборд
│   │   ├── event/               # События
│   │   ├── profile/             # Профиль
│   │   └── MyNavBar.dart        # Нижняя навигация
│   ├── page_2/                  # Модуль склада/товаров
│   │   ├── main_screen.dart
│   │   ├── goods/               # Товары
│   │   ├── category/            # Категории
│   │   ├── order/               # Заказы
│   │   ├── warehouse/           # Склад
│   │   │   ├── incoming/        # Приход
│   │   │   ├── client_sale/     # Продажа
│   │   │   ├── movement/        # Перемещение
│   │   │   ├── write_off/       # Списание
│   │   │   └── ...
│   │   ├── money/               # Финансы
│   │   ├── call_center/         # Колл-центр
│   │   └── dashboard/           # Аналитика склада
│   ├── custom_widget/           # Переиспользуемые виджеты
│   │   ├── custom_app_bar.dart
│   │   ├── custom_button.dart
│   │   ├── custom_textfield.dart
│   │   ├── filter/              # Фильтры
│   │   └── calendar/            # Календарь компоненты
│   ├── widgets/                 # Общие виджеты
│   │   ├── bottom_navy_bar.dart
│   │   └── ...
│   ├── utils/                   # Утилиты
│   │   ├── app_colors.dart
│   │   ├── global_fun.dart
│   │   ├── global_value.dart
│   │   └── parser.dart
│   ├── generated/               # Автоматически генерированный код
│   │   ├── l10n.dart
│   │   └── intl/
│   ├── firebase_options.dart    # Firebase конфигурация
│   ├── error_interceptor.dart   # Перехват ошибок API
│   └── update_dialog.dart       # Диалог обновления
├── test/                        # Тесты
│   └── widget_test.dart
├── pubspec.yaml                 # Зависимости проекта
├── pubspec.lock                 # Locked версии
├── analysis_options.yaml        # Настройки анализатора
├── firebase.json                # Firebase конфигурация
└── README.md                    # Этот файл
```

### Ключевые файлы и их назначение

| Файл/Папка | Описание |
|-----------|----------|
| `lib/main.dart` | Точка входа, инициализация Firebase, проверка сессии |
| `lib/api/service/api_service.dart` | Основной HTTP клиент, все API endpoints |
| `lib/screens/home_screen.dart` | Главный экран с навигацией и permissions |
| `lib/models/` | Data Transfer Objects (DTO) и модели |
| `lib/bloc/` | BLoC файлы для каждого модуля |
| `assets/langs/` | JSON файлы локализации |
| `pubspec.yaml` | Конфигурация проекта и зависимости |

---

## 🧩 Модули приложения

### 1. Модуль аутентификации (Auth)

**Файлы:**
- `lib/screens/auth/`
- `lib/bloc/auth_domain/`
- `lib/bloc/login/`
- `lib/bloc/auth_bloc_pin/`

**Функционал:**
- ✅ Вход по QR-коду
- ✅ Ручной ввод домена
- ✅ Логин/пароль
- ✅ PIN-код (4-6 цифр)
- ✅ Биометрическая аутентификация (Face ID, Touch ID, Fingerprint)
- ✅ Восстановление PIN через email
- ✅ Мультиорганизация

**Процесс авторизации:**

```
1. Проверка домена → 2. Вход (логин/пароль) → 3. Выбор организации →
4. Настройка PIN → 5. Настройка биометрии → 6. Главный экран
```

### 2. Модуль лидов (Leads)

**Файлы:**
- `lib/screens/lead/`
- `lib/bloc/lead/`
- `lib/models/lead_model.dart`

**Функционал:**
- ✅ Канбан-доска с колонками по статусам
- ✅ Создание/редактирование лидов
- ✅ Кастомные поля (динамическая конфигурация)
- ✅ Фильтрация и поиск
- ✅ История изменений
- ✅ Заметки и файлы
- ✅ Конвертация в сделку
- ✅ Назначение менеджеров
- ✅ Источники лидов
- ✅ Экспорт в контакты

**Статусы лидов:** настраиваются на бэкенде

### 3. Модуль сделок (Deals)

**Файлы:**
- `lib/screens/deal/`
- `lib/bloc/deal/`
- `lib/models/deal_model.dart`

**Функционал:**
- ✅ Воронка продаж (визуализация)
- ✅ Этапы сделки
- ✅ Связанные задачи
- ✅ Документы и файлы
- ✅ История коммуникаций
- ✅ Прогноз сделки
- ✅ Связь с лидом

### 4. Модуль задач (Tasks)

**Файлы:**
- `lib/screens/task/` - Задачи для всех
- `lib/screens/my-task/` - Мои задачи
- `lib/bloc/task/`, `lib/bloc/my-task/`

**Функционал:**
- ✅ Создание задач
- ✅ Назначение исполнителей
- ✅ Приоритеты (высокий, средний, низкий)
- ✅ Дедлайны
- ✅ Статусы задач
- ✅ Подзадачи
- ✅ Комментарии
- ✅ Прикрепление файлов
- ✅ Связь с лидами/сделками
- ✅ Уведомления о просрочке

### 5. Модуль чатов (Chats)

**Файлы:**
- `lib/screens/chats/`
- `lib/bloc/chats/`
- `lib/api/service/api_service_chats.dart`

**Функционал:**
- ✅ Личные чаты (1-на-1)
- ✅ Групповые чаты
- ✅ Корпоративные чаты
- ✅ Текстовые сообщения (с rich text)
- ✅ Voice сообщения (запись и воспроизведение)
- ✅ Файлы и изображения
- ✅ Закрепленные сообщения
- ✅ Редактирование сообщений
- ✅ Удаление сообщений
- ✅ Шаблоны сообщений
- ✅ Поиск по чатам
- ✅ Непрочитанные счетчики
- ✅ Typing indicators
- ✅ Real-time через Pusher

**Интеграция:**
- Pusher Channels для WebSocket
- Firebase Messaging для push-уведомлений

### 6. Модуль Dashboard

**Файлы:**
- `lib/screens/dashboard/`
- `lib/screens/dashboard_for_manager/`
- `lib/bloc/dashboard/`

**Метрики:**
- 📊 График лидов (по датам)
- 📈 Конверсия (лиды → сделки)
- ⏱ Скорость обработки
- 📉 Статистика сделок
- 👥 Задачи по пользователям
- 🎯 Воронка продаж

**Графики:** fl_chart с интерактивностью

### 7. Модуль склада (Warehouse/Page 2)

**Файлы:**
- `lib/page_2/warehouse/`
- `lib/bloc/page_2_BLOC/document/`

#### Документы:

**Приход (Incoming)**
```dart
lib/page_2/warehouse/incoming/
```
- Создание поступлений
- Выбор поставщика
- Добавление товаров
- Цены закупки
- История документов

**Продажа клиенту (Client Sale)**
```dart
lib/page_2/warehouse/client_sale/
```
- Оформление продажи
- Выбор клиента (лида)
- Товары и количество
- Типы цен
- Способ оплаты

**Возвраты**
- Возврат от клиента
- Возврат поставщику

**Перемещения (Movement)**
- Между складами
- Количество и причина

**Списание (Write-off)**
- Причина списания
- Количество

### 8. Модуль товаров (Goods)

**Файлы:**
- `lib/page_2/goods/`
- `lib/bloc/page_2_BLOC/goods/`

**Функционал:**
- ✅ Каталог товаров
- ✅ Категории и подкатегории
- ✅ Характеристики товаров
- ✅ Варианты (размеры, цвета)
- ✅ Множественные цены
- ✅ Остатки по складам
- ✅ Изображения товаров
- ✅ Штрих-коды
- ✅ Единицы измерения

### 9. Модуль финансов (Money)

**Файлы:**
- `lib/page_2/money/`
- `lib/bloc/cash_desk/`, `lib/bloc/income/`, `lib/bloc/expense/`

**Компоненты:**

**Касса (Cash Desk)**
- Список касс
- Остатки
- Операции

**Доходы (Income)**
- Категории доходов
- Документы поступления
- Привязка к клиентам

**Расходы (Expense)**
- Категории расходов
- Документы расхода
- Поставщики

### 10. Модуль Call-центр

**Файлы:**
- `lib/page_2/call_center/`
- `lib/bloc/call_bloc/`

**Функционал:**
- 📞 Статистика звонков
- 👤 Операторы
- 📊 Аналитика по периодам
- ⏱ Среднее время разговора
- 📈 Конверсия звонков

### 11. Модуль событий (Events)

**Файлы:**
- `lib/screens/event/`
- `lib/bloc/event/`

**Функционал:**
- 📅 Календарь событий
- ✅ Встречи, звонки, задачи
- 👥 Участники
- 📍 Локации
- 🔔 Напоминания

### 12. Модуль профиля (Profile)

**Файлы:**
- `lib/screens/profile/`
- `lib/bloc/profile/`

**Настройки:**
- 👤 Данные профиля
- 🌐 Язык интерфейса
- 🏢 Смена организации
- 🔐 Изменение PIN
- 🆔 Биометрия
- 🔄 Обновление данных 1С
- 📤 Выход из аккаунта

---

## 🌐 Работа с API

### Базовая структура API Service

**Файл:** `lib/api/service/api_service.dart`

### Основные концепции

1. **Dynamic Domain**: домен вводится пользователем
2. **Token-based Auth**: Bearer токены
3. **Organization Context**: каждый запрос с ID организации
4. **Error Handling**: централизованный перехват ошибок
5. **Interceptors**: логирование, refresh token

### Пример API запроса

```dart
// Получение лидов
Future<LeadResponse> getLeads({
  required int page,
  required int limit,
  String? search,
  List<int>? statusIds,
}) async {
  final response = await http.get(
    Uri.parse('$baseUrl/leads?page=$page&limit=$limit'),
    headers: await _getHeaders(),
  );

  if (response.statusCode == 200) {
    return LeadResponse.fromJson(jsonDecode(response.body));
  } else {
    throw ApiException.fromResponse(response);
  }
}
```

### Основные endpoints

| Endpoint | Метод | Описание |
|----------|-------|----------|
| `/auth/login` | POST | Логин |
| `/leads` | GET | Список лидов |
| `/leads/{id}` | GET | Детали лида |
| `/leads` | POST | Создание лида |
| `/deals` | GET | Список сделок |
| `/tasks` | GET | Список задач |
| `/chats` | GET | Список чатов |
| `/chats/{id}/messages` | GET | Сообщения чата |
| `/goods` | GET | Товары |
| `/documents/incoming` | POST | Создание прихода |
| `/dashboard/charts` | GET | Данные графиков |

### Обработка ошибок

```dart
try {
  final leads = await apiService.getLeads();
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    // Токен истек, перенаправить на логин
    Navigator.pushReplacementNamed(context, '/login');
  } else {
    // Показать ошибку пользователю
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  }
} catch (e) {
  // Общая ошибка
  print('Unexpected error: $e');
}
```

### Pagination

Большинство списков поддерживают пагинацию:

```dart
PaginationDto({
  required this.currentPage,
  required this.totalPages,
  required this.totalCount,
  required this.data,
});
```

Используйте `infinite_scroll_pagination` для бесконечной прокрутки.

---

## 🔄 Управление состоянием (BLoC)

### Паттерн BLoC

**BLoC = Business Logic Component**

Каждый модуль имеет:
- **Bloc**: логика обработки
- **Event**: входящие события
- **State**: состояния UI

### Структура BLoC файла

**Пример:** `lib/bloc/lead/lead_bloc.dart`

```dart
// Events
abstract class LeadEvent extends Equatable {}

class FetchLeadsEvent extends LeadEvent {
  final int page;
  FetchLeadsEvent(this.page);

  @override
  List<Object> get props => [page];
}

// States
abstract class LeadState extends Equatable {}

class LeadInitial extends LeadState {
  @override
  List<Object> get props => [];
}

class LeadLoading extends LeadState {
  @override
  List<Object> get props => [];
}

class LeadLoaded extends LeadState {
  final List<Lead> leads;
  LeadLoaded(this.leads);

  @override
  List<Object> get props => [leads];
}

class LeadError extends LeadState {
  final String message;
  LeadError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class LeadBloc extends Bloc<LeadEvent, LeadState> {
  final ApiService apiService;

  LeadBloc(this.apiService) : super(LeadInitial()) {
    on<FetchLeadsEvent>(_onFetchLeads);
  }

  Future<void> _onFetchLeads(
    FetchLeadsEvent event,
    Emitter<LeadState> emit,
  ) async {
    emit(LeadLoading());
    try {
      final leads = await apiService.getLeads(page: event.page);
      emit(LeadLoaded(leads));
    } catch (e) {
      emit(LeadError(e.toString()));
    }
  }
}
```

### Использование BLoC в UI

```dart
class LeadScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, state) {
        if (state is LeadLoading) {
          return CircularProgressIndicator();
        } else if (state is LeadLoaded) {
          return ListView.builder(
            itemCount: state.leads.length,
            itemBuilder: (context, index) {
              return LeadCard(lead: state.leads[index]);
            },
          );
        } else if (state is LeadError) {
          return Text('Error: ${state.message}');
        }
        return Container();
      },
    );
  }
}

// Вызов события
context.read<LeadBloc>().add(FetchLeadsEvent(1));
```

### Основные BLoCs в проекте

| BLoC | Ответственность |
|------|----------------|
| `DomainBloc` | Проверка и сохранение домена |
| `LoginBloc` | Аутентификация |
| `LeadBloc` | Управление лидами |
| `DealBloc` | Управление сделками |
| `TaskBloc` | Задачи |
| `ChatsBloc` | Чаты и сообщения |
| `OrganizationBloc` | Организации |
| `NotificationBloc` | Уведомления |
| `ProfileBloc` | Профиль пользователя |
| `GoodsBloc` | Товары |
| `IncomingBloc` | Приходные документы |
| `ClientSaleBloc` | Документы продажи |

---

## 🌍 Локализация

### Поддерживаемые языки

- 🇷🇺 Русский (ru) - по умолчанию
- 🇺🇿 Узбекский (uz)
- 🇬🇧 Английский (en)

### Файлы переводов

**Расположение:** `assets/langs/`

- `ru.json` - русский (1900+ строк)
- `uz.json` - узбекский
- `en.json` - английский

### Структура JSON

```json
{
  "language": "Язык",
  "close": "Закрыть",
  "save": "Сохранить",
  "cancel": "Отмена",
  "leads": "Лиды",
  "deals": "Сделки",
  ...
}
```

### Использование в коде

```dart
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

// В виджете
Text(AppLocalizations.of(context)?.translate('leads') ?? 'Leads')

// Или короткая форма
final localizations = AppLocalizations.of(context);
Text(localizations?.translate('save') ?? 'Save')
```

### Смена языка

```dart
import 'package:crm_task_manager/main.dart';

// Установить новый язык
MyApp.setLocale(context, Locale('uz'));

// Сохраняется в SharedPreferences
await LanguageManager.setLanguage('uz');
```

### Добавление новых переводов

1. Откройте `assets/langs/ru.json` (или другой язык)
2. Добавьте новый ключ-значение:
   ```json
   "new_feature_title": "Новая функция"
   ```
3. Добавьте в другие языки (`uz.json`, `en.json`)
4. Используйте в коде:
   ```dart
   localizations?.translate('new_feature_title')
   ```

---

## 🔥 Firebase интеграция

### Используемые сервисы

1. **Firebase Core** - базовая инициализация
2. **Firebase Messaging (FCM)** - push-уведомления

### Конфигурационные файлы

- `lib/firebase_options.dart` - автогенерированный файл
- `android/app/google-services.json` - Android
- `ios/Runner/GoogleService-Info.plist` - iOS
- `firebase.json` - настройки проекта

### Инициализация (в main.dart)

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Push-уведомления

**Обработчики:**

```dart
// 1. Background handler (верхний уровень файла)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.data}');
}

// 2. Foreground messages
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Foreground message: ${message.data}');
  // Показать уведомление в приложении
});

// 3. Tap на уведомление (app in background)
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  print('Notification tapped: ${message.data}');
  // Навигация на нужный экран
  _handleNotificationNavigation(message.data);
});

// 4. Initial message (app opened from terminated state)
RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
if (initialMessage != null) {
  _handleNotificationNavigation(initialMessage.data);
}
```

### Навигация по типам уведомлений

**Файл:** `lib/api/service/firebase_api.dart`

```dart
void handleMessage(RemoteMessage message) {
  final String? type = message.data['type'];
  final String? id = message.data['id'];

  switch (type) {
    case 'lead':
      navigatorKey.currentState?.pushNamed('/lead_details', arguments: id);
      break;
    case 'deal':
      navigatorKey.currentState?.pushNamed('/deal_details', arguments: id);
      break;
    case 'task':
      navigatorKey.currentState?.pushNamed('/task_details', arguments: id);
      break;
    case 'chat':
      navigatorKey.currentState?.pushNamed('/chat', arguments: id);
      break;
  }
}
```

### Получение FCM токена

```dart
String? token = await FirebaseMessaging.instance.getToken();
// Отправить токен на сервер
await apiService.sendDeviceToken(token!);
```

### Разрешения (iOS)

```dart
NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);

if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  print('Permissions granted');
}
```

---

## 🔐 Аутентификация и безопасность

### Многоуровневая аутентификация

#### 1. Проверка домена

**Способы ввода:**
- QR-код (сканирование)
- Ручной ввод (URL)

**Хранение:**
```dart
// Secure Storage
await secureStorage.write(key: 'verified_domain', value: domain);
await secureStorage.write(key: 'main_domain', value: mainDomain);
```

#### 2. Логин и пароль

```dart
final response = await apiService.login(
  login: username,
  password: password,
);

// Сохранение токена
await apiService.saveToken(response.token);
```

#### 3. Выбор организации

Если пользователь имеет доступ к нескольким организациям:

```dart
await apiService.setSelectedOrganization(organizationId);
```

#### 4. PIN-код

**Настройка:** 4-6 цифр

```dart
// Сохранение PIN (хешированный)
await authService.setPin(pinCode);

// Проверка PIN
bool isValid = await authService.verifyPin(enteredPin);
```

**Файлы:**
- `lib/screens/auth/pin_setup_screen.dart` - настройка
- `lib/screens/auth/pin_screen.dart` - ввод
- `lib/screens/auth/pin_change_screen.dart` - изменение

#### 5. Биометрия (опционально)

**Типы:**
- Face ID (iOS)
- Touch ID (iOS)
- Fingerprint (Android)
- Face Unlock (Android)

```dart
import 'package:local_auth/local_auth.dart';

final LocalAuthentication auth = LocalAuthentication();

// Проверка доступности
bool canCheckBiometrics = await auth.canCheckBiometrics;

// Аутентификация
bool authenticated = await auth.authenticate(
  localizedReason: 'Подтвердите вход в ShamCRM',
  options: const AuthenticationOptions(
    biometricOnly: true,
    stickyAuth: true,
  ),
);
```

### Безопасное хранилище (Secure Storage)

**Используется для:**
- Токенов аутентификации
- PIN-кодов
- Доменов
- Приватных данных

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

// Запись
await storage.write(key: 'token', value: authToken);

// Чтение
String? token = await storage.read(key: 'token');

// Удаление
await storage.delete(key: 'token');

// Очистка всего
await storage.deleteAll();
```

### Session Management

**Проверка при старте:**

```dart
Future<SessionValidationResult> _validateApplicationSession() async {
  // 1. Проверка токена
  final token = await apiService.getToken();
  if (token == null) return SessionValidationResult(isValid: false);

  // 2. Проверка домена
  final domain = await apiService.getVerifiedDomain();
  if (domain == null) return SessionValidationResult(isValid: false);

  // 3. Проверка организации (опционально)
  final orgId = await apiService.getSelectedOrganization();

  return SessionValidationResult(isValid: true);
}
```

**Выход (Logout):**

```dart
Future<void> logout() async {
  await apiService.logout(); // Запрос на сервер
  await apiService.reset(); // Очистка локальных данных
  await authService.clearPin();
  await storage.deleteAll();

  Navigator.pushReplacementNamed(context, '/login');
}
```

### Refresh Token

Если API использует refresh tokens:

```dart
Future<void> refreshAccessToken() async {
  final refreshToken = await storage.read(key: 'refresh_token');
  final response = await http.post(
    Uri.parse('$baseUrl/auth/refresh'),
    body: {'refresh_token': refreshToken},
  );

  if (response.statusCode == 200) {
    final newToken = jsonDecode(response.body)['access_token'];
    await storage.write(key: 'token', value: newToken);
  } else {
    // Токен невалиден, выйти
    await logout();
  }
}
```

---

## 🔨 Сборка приложения

### Development сборка

#### Android

```bash
# Debug APK
flutter build apk --debug

# Установка на устройство
flutter install

# Или одной командой
flutter run
```

#### iOS

```bash
# Debug на симулятор
flutter run

# Debug на физическое устройство
flutter run --release
```

### Production сборка

#### Android (APK)

```bash
# Release APK (для всех архитектур)
flutter build apk --release

# Split APKs (по архитектурам, меньший размер)
flutter build apk --split-per-abi --release

# Вывод:
# build/app/outputs/flutter-apk/app-release.apk
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# build/app/outputs/flutter-apk/app-x86_64-release.apk
```

#### Android (App Bundle для Google Play)

```bash
# AAB файл
flutter build appbundle --release

# Вывод:
# build/app/outputs/bundle/release/app-release.aab
```

#### iOS (для App Store)

```bash
# Build
flutter build ios --release

# Или через Xcode:
# 1. Открыть ios/Runner.xcworkspace
# 2. Product → Archive
# 3. Distribute App → App Store Connect
```

### Версионирование

**Файл:** `pubspec.yaml`

```yaml
version: 2.1.160+220
#        │ │ │   └── Build number (220)
#        │ │ └────── Patch version
#        │ └──────── Minor version
#        └────────── Major version
```

**Изменение версии:**

```bash
# Автоматическое увеличение build number
flutter build apk --build-number=221 --build-name=2.1.161
```

### Signing (подпись)

#### Android

**Уже настроено в:** `android/app/build.gradle`

```gradle
signingConfigs {
    release {
        storeFile file("key.keystore")
        storePassword "123456"  // ⚠️ Изменить для production
        keyAlias "keyalias"
        keyPassword "123456"    // ⚠️ Изменить для production
    }
}
```

**Создание нового keystore:**

```bash
keytool -genkey -v -keystore android/app/key.keystore \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias keyalias
```

#### iOS

Настраивается через Xcode:
1. Signing & Capabilities
2. Выбрать Team
3. Automatic Signing

### Обфускация (опционально)

```bash
# С обфускацией кода
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Для iOS
flutter build ios --release --obfuscate --split-debug-info=build/ios/outputs/symbols
```

### Размер приложения

**Анализ размера:**

```bash
flutter build apk --analyze-size
flutter build appbundle --analyze-size
```

**Оптимизация:**

- Используйте `--split-per-abi` для APK
- Используйте App Bundle для Google Play
- Оптимизируйте изображения (WebP формат)
- Удалите неиспользуемые ресурсы

---

## 🐛 Troubleshooting

### Частые проблемы и решения

#### 1. Firebase initialization error

**Ошибка:**
```
[core/duplicate-app] A Firebase App named "[DEFAULT]" already exists
```

**Решение:**
```dart
if (Firebase.apps.isEmpty) {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
```

#### 2. Gradle build fails (Android)

**Ошибка:**
```
FAILURE: Build failed with an exception.
```

**Решения:**
```bash
# 1. Очистка
cd android
./gradlew clean
cd ..

# 2. Обновление Gradle wrapper
cd android
./gradlew wrapper --gradle-version 8.0
cd ..

# 3. Инвалидация кэшей
flutter clean
flutter pub get
```

#### 3. CocoaPods issues (iOS)

**Ошибка:**
```
[!] CocoaPods could not find compatible versions for pod
```

**Решение:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod repo update
pod install
cd ..
```

#### 4. BLoC не обновляет UI

**Проблема:** Изменения состояния не отражаются

**Решение:**
```dart
// Убедитесь, что State extends Equatable
class MyState extends Equatable {
  final List<Item> items;

  MyState(this.items);

  @override
  List<Object> get props => [items]; // ⚠️ Важно!
}

// Для списков создавайте новые экземпляры
emit(MyState([...items, newItem])); // ✅
emit(MyState(items..add(newItem))); // ❌ Не сработает
```

#### 5. API Connection issues

**Ошибка:**
```
SocketException: Failed host lookup
```

**Проверки:**
1. Правильность домена
2. Интернет соединение
3. Permissions в AndroidManifest.xml:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```

#### 6. Изображения не загружаются

**Проблема:** Assets не найдены

**Решение:**
```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/icons/
    - assets/images/
    # Добавьте недостающие пути
```

Затем:
```bash
flutter clean
flutter pub get
```

#### 7. Hot Reload не работает

**Решение:**
```bash
# 1. Restart (R в консоли)
# 2. Hot Restart (Shift+R)
# 3. Полная пересборка
flutter run
```

#### 8. Memory leaks

**Проблема:** Приложение тормозит со временем

**Решение:**
```dart
// Dispose контроллеров
@override
void dispose() {
  _textController.dispose();
  _scrollController.dispose();
  super.dispose();
}

// Отписка от стримов
StreamSubscription? _subscription;

@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

#### 9. Push notifications не приходят (iOS)

**Чеклист:**
1. ✅ Capabilities: Push Notifications включены
2. ✅ APNs ключ настроен в Firebase Console
3. ✅ Разрешения запрошены
4. ✅ Реальное устройство (не симулятор)

#### 10. Build failed: Signing error (iOS)

**Решение:**
1. Xcode → Preferences → Accounts → Download Manual Profiles
2. Runner → Signing & Capabilities → Team (выбрать)
3. Очистить: Product → Clean Build Folder

---

## 📝 Code Style и Best Practices

### Dart Style Guide

Следуйте официальному [Effective Dart](https://dart.dev/guides/language/effective-dart):

#### Именование

```dart
// ✅ Правильно
class LeadBloc {} // PascalCase для классов
const int maxRetries = 3; // camelCase для переменных
void fetchLeads() {} // camelCase для функций
enum LeadStatus { active, closed } // PascalCase для enum, camelCase для значений

// ❌ Неправильно
class lead_bloc {}
const int MAX_RETRIES = 3;
void FetchLeads() {}
```

#### Форматирование

```bash
# Автоформатирование
flutter format lib/

# Проверка
flutter analyze
```

#### Imports

```dart
// Порядок:
// 1. Dart SDK
import 'dart:async';
import 'dart:convert';

// 2. Flutter SDK
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Сторонние пакеты
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// 4. Относительные импорты проекта
import '../../models/lead_model.dart';
import '../../bloc/lead/lead_bloc.dart';
```

### Flutter Best Practices

#### 1. Const конструкторы

```dart
// ✅ Используйте const где возможно
const Text('Hello');
const SizedBox(height: 16);
const EdgeInsets.all(8);

// ❌ Избегайте
Text('Hello');
```

#### 2. Extract widgets

```dart
// ✅ Вынесите в отдельные виджеты
class LeadCard extends StatelessWidget {
  final Lead lead;
  const LeadCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Card(...);
  }
}

// ❌ Не создавайте методы для виджетов
Widget _buildLeadCard(Lead lead) { // Плохая практика
  return Card(...);
}
```

#### 3. Null safety

```dart
// ✅ Используйте null safety
String? nullableName;
String nonNullableName = 'John';

// Проверки
if (nullableName != null) {
  print(nullableName.length);
}

// Операторы
final length = nullableName?.length ?? 0;
final upperCase = nullableName?.toUpperCase() ?? '';
```

#### 4. Async/Await

```dart
// ✅ Правильно
Future<void> loadData() async {
  try {
    final data = await apiService.fetchData();
    setState(() => _data = data);
  } catch (e) {
    print('Error: $e');
  }
}

// ❌ Неправильно
Future<void> loadData() {
  apiService.fetchData().then((data) {
    setState(() => _data = data);
  }).catchError((e) {
    print('Error: $e');
  });
}
```

#### 5. Build method

```dart
// ✅ Делайте build метод простым
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _buildAppBar(),
    body: _buildBody(),
  );
}

Widget _buildAppBar() => AppBar(title: Text('Title'));
Widget _buildBody() => ListView(...);

// ❌ Не делайте всю логику в build
@override
Widget build(BuildContext context) {
  final data = fetchData(); // ❌ Не делайте здесь
  // 300 строк кода... ❌
}
```

### BLoC Best Practices

#### 1. Один BLoC = одна ответственность

```dart
// ✅ Правильно
class LeadBloc {} // Только лиды
class DealBloc {} // Только сделки

// ❌ Неправильно
class LeadAndDealBloc {} // Слишком много ответственности
```

#### 2. Используйте Equatable

```dart
// ✅ States с Equatable
class LeadLoaded extends LeadState {
  final List<Lead> leads;

  LeadLoaded(this.leads);

  @override
  List<Object> get props => [leads];
}
```

#### 3. Обработка ошибок

```dart
on<FetchLeadsEvent>((event, emit) async {
  emit(LeadLoading());
  try {
    final leads = await apiService.getLeads();
    emit(LeadLoaded(leads));
  } on ApiException catch (e) {
    emit(LeadError(e.message));
  } catch (e) {
    emit(LeadError('Unexpected error'));
  }
});
```

### Git Best Practices

#### Commit messages

```bash
# Формат: <type>: <description>

# Типы:
feat: добавление новой функции
fix: исправление бага
refactor: рефакторинг без изменения функциональности
docs: изменения в документации
style: форматирование кода
test: добавление тестов
chore: обновление зависимостей, конфигурации

# Примеры:
git commit -m "feat: добавлен экран создания лида"
git commit -m "fix: исправлена ошибка загрузки чатов"
git commit -m "refactor: оптимизирован LeadBloc"
```

#### Branching

```bash
# Структура веток:
main / master - production
develop - development
feature/<name> - новые фичи
bugfix/<name> - исправления
hotfix/<name> - срочные исправления

# Пример:
git checkout -b feature/add-lead-filters
git checkout -b bugfix/fix-chat-crash
```

---

## 🤝 Contributing

### Процесс добавления изменений

1. **Создайте ветку**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Внесите изменения**
   - Следуйте code style
   - Добавьте комментарии для сложной логики
   - Обновите документацию при необходимости

3. **Тестирование**
   ```bash
   flutter test
   flutter analyze
   ```

4. **Commit**
   ```bash
   git add .
   git commit -m "feat: описание изменений"
   ```

5. **Push**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Pull Request**
   - Опишите изменения
   - Прикрепите скриншоты (для UI)
   - Упомяните связанные issues

### Code Review Guidelines

**Для ревьюеров:**
- ✅ Проверьте code style
- ✅ Убедитесь в наличии обработки ошибок
- ✅ Проверьте null safety
- ✅ Оцените производительность
- ✅ Проверьте UX/UI

**Для авторов:**
- ✅ Маленькие, сфокусированные PR
- ✅ Описательные commit messages
- ✅ Тесты для новой функциональности
- ✅ Обновленная документация

---

## 📞 Контакты и поддержка

### Команда разработки

**Company:** Softtech / Fingroup
**Project:** ShamCRM Mobile

### Полезные ссылки

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [Flutter BLoC Package](https://bloclibrary.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)

### Сообщения об ошибках

При обнаружении бага предоставьте:
1. **Описание проблемы**
2. **Шаги воспроизведения**
3. **Ожидаемое поведение**
4. **Фактическое поведение**
5. **Скриншоты/видео** (если применимо)
6. **Логи** (`flutter run --verbose`)
7. **Версия приложения**
8. **Устройство и ОС**

---

## 📄 Лицензия

Proprietary - Все права защищены.
Проект разработан для внутреннего использования.

---

## 🎓 Для новых разработчиков

### Первые шаги

1. **Изучите структуру**
   - Начните с `lib/main.dart`
   - Посмотрите `lib/screens/home_screen.dart`
   - Изучите один модуль (например, Leads)

2. **Запустите приложение**
   - Настройте окружение
   - Запустите на эмуляторе
   - Пройдитесь по основным экранам

3. **Изучите BLoC**
   - Документация: [bloclibrary.dev](https://bloclibrary.dev)
   - Посмотрите `lib/bloc/lead/`
   - Поймите паттерн Event → BLoC → State

4. **Сделайте простую задачу**
   - Исправьте опечатку
   - Добавьте новый перевод
   - Измените цвет кнопки

### Рекомендуемое чтение

- 📖 [Effective Dart](https://dart.dev/guides/language/effective-dart)
- 📖 [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- 📖 [BLoC Pattern Tutorial](https://bloclibrary.dev/#/gettingstarted)

### Часто используемые команды

```bash
# Запуск
flutter run

# Очистка
flutter clean

# Получение зависимостей
flutter pub get

# Генерация кода
flutter pub run build_runner build --delete-conflicting-outputs

# Анализ кода
flutter analyze

# Форматирование
flutter format lib/

# Сборка APK
flutter build apk --release

# Логи
flutter logs

# Устройства
flutter devices
```

---

## ✅ Статус разработки на август 2026

Этот раздел дополняет исходную документацию декабря 2025 и фиксирует состояние
функционального baseline `color_schema_3`. Для новых разработчиков это главная
точка входа: здесь перечислены реализованные цели, частично завершённые задачи,
оставшаяся работа и границы ответственности mobile/backend/PBX.

### Обозначения статусов

- ✅ — реализовано в кодовой базе baseline и прошло целевые статические/build-проверки.
- 🟡 — реализована основная часть, но остаётся интеграционная, серверная или
  device-проверка.
- ⬜ — цель ещё не завершена или не внедрена системно.

### Сводка целей проекта

| Направление | Статус | Что сделано | Что осталось |
| --- | --- | --- | --- |
| CRM: лиды, сделки, задачи, события | ✅ | Основные CRUD-сценарии, воронки, история, фильтры и исправления first-load состояний | Расширять тесты и унифицировать обработку ошибок |
| Заказы, склад, товары, финансы, РМК | ✅ | Основные рабочие экраны и tenant-specific сценарии | Регрессионные тесты полного документооборота |
| Новый дизайн и темы | 🟡 | Новая цветовая схема, light/dark tokens, обновлённые auth/CRM/SIP элементы, skeleton/navigation continuity | Завершить аудит всех старых экранов и убрать оставшиеся hardcoded цвета |
| Корпоративный чат | ✅ | Сообщения, медиа, голос, реакции, push, Android/iOS quick reply и группировка | End-to-end тесты payload и прав доступа на production backend |
| Offline-first | 🟡 | Drift/SQLite, cache, outbox, scheduler, network profile и telemetry foundation | Подключить все нужные домены, определить conflict resolution и покрыть sync тестами |
| SIP/VoIP Android | 🟡 | Native SIP bridge, foreground service, full-screen incoming UI, Answer/Decline, audio routes, DTMF | Реальные тесты Android 14+, lock screen и OEM battery restrictions |
| SIP/VoIP iOS | 🟡 | CallKit, native SIP manager, входящий flow, app DTMF, mute/audio route | Реальный iPhone test: foreground/background/terminated и серверная корреляция |
| Защита от запоздалых звонков | 🟡 | Client TTL/timestamp guard и отмена по `call_id` | Обязательный backend/PBX контракт: origin timestamp, TTL, cancellation, `sip_ready` state validation |
| PIN и биометрия | ✅ | PIN setup/change, biometric flow, startup timeouts и диагностические checkpoints | Проверка на поддерживаемых реальных устройствах и редких native timeout сценариях |
| Локализация RU/EN/UZ | ✅ | Три JSON-словаря и обновлённые переводы нового интерфейса | Постоянный parity-аудит при добавлении новых строк |
| Unit/widget/integration tests | 🟡 | Есть точечные тесты моделей и критичных parser/util сценариев | Увеличить покрытие бизнес-логики и добавить критические integration flows |
| CI/CD | ⬜ | Локальные команды анализа и сборки документированы | Внедрить автоматические analyze/test/build/signing checks |
| Crash/analytics monitoring | 🟡 | В проекте есть Firebase-интеграция и локальная telemetry инфраструктура | Утвердить production Crashlytics/Analytics события и dashboards |
| Web-версия | ⬜ | Не является завершённым baseline | Отдельно оценить продуктовую необходимость и совместимость native/SIP функций |

### Что реализовано после документации декабря 2025

#### 1. Новый дизайн и цветовая схема

- Ветка `color_schema_3` содержит актуальную визуальную систему приложения.
- Основные экраны используют semantic theme tokens через `context.appColors`.
- Добавлены/обновлены light и dark варианты auth/welcome интерфейса.
- PIN → Home переходы и загрузочные состояния согласованы с финальной геометрией
  экранов, чтобы нижняя навигация и контент не прыгали при старте.
- Модальное объединение лидов, radio controls, кнопки и навигация приведены к
  общей теме; строки добавлены в русский, английский и узбекский словари.
- SIP-кнопки используют визуальное active-состояние для mute без изменения
  функциональной логики звонка.

Оставшаяся цель нового дизайна — пройти полный экранный аудит. Старые модули,
особенно большие формы склада/финансов/заказов, нужно проверять отдельно в
light/dark режимах, на малых экранах и при увеличенном системном шрифте.

#### 2. Устойчивость загрузки CRM-экранов

- **Leads:** успешный `LeadLoaded` формирует статусы, tabs и `TabController`
  независимо от завершения проверки action-permissions. Permissions управляют
  действиями пользователя, но не должны скрывать уже полученные данные.
- **Events:** запрос списка ждёт выбранную воронку и не отправляется преждевременно
  из `didChangeDependencies`.
- **Orders:** success и error состояния сбрасывают начальные loading-флаги;
  экран не остаётся на бесконечном spinner до ручного refresh.
- **Deals:** проверен на аналогичный race; патч применяется только при
  подтверждённом совпадении причины, а не массово по похожему UI.
- **Calendar:** nullable `name` и другие необязательные поля парсятся defensive;
  одна аномальная запись не ломает весь список событий.
- **Deal by ID:** отсутствие вложенного `entry` не трактуется автоматически как
  удалённая сделка. Текст «Сделка была удалена» используется только для
  подтверждённого 404/серверного маркера.

#### 3. Заказы и tenant-specific логика

- Для `stomatrade.shamcrm.com` цена позиции заказа редактируется вручную и в
  создании, и в редактировании заказа.
- Новая цена участвует в итоговой сумме и отправляется в существующем payload.
- Ввод нормализует пробелы и запятую/точку, убирает лишние ведущие нули, но
  сохраняет корректное десятичное значение вроде `0,5`.
- Поведение закрыто явным tenant gate и не должно менять остальные организации.

#### 4. Авторизация, PIN и startup

- Реализованы PIN setup/change и опциональная биометрия.
- Критические Firebase/SIP/biometric шаги startup ограничены timeout и снабжены
  диагностическими checkpoints.
- Бесконечный splash нельзя маскировать дополнительным loader: при проблеме
  нужно определить конкретный зависший шаг и показать контролируемое состояние.

#### 5. Chat push: быстрый ответ и группировка

- Android использует `RemoteInput` для быстрого ответа, action «прочитано»,
  `InboxStyle`, локальную историю и стабильный notification ID на один чат.
- iOS регистрирует `CHAT_MESSAGE_REPLY`, `UNTextInputNotificationAction` и
  группирует сообщения через `aps.thread-id`.
- Backend payload должен содержать согласованные `chat_id`, `message_id`,
  sender/message fields, а для iOS — `aps.category` и `aps.thread-id`.
- Native action не обходит backend authorization: endpoint обязан проверить
  пользователя, tenant и право доступа к чату.

#### 6. Offline-first foundation

В `lib/offline/` реализована базовая инфраструктура:

- Drift/SQLite database;
- local cache repositories;
- outbox и executors;
- request scheduler и priorities;
- network profile/policy;
- retry и offline telemetry;
- bootstrap/runtime integration.

Offline нельзя считать «готовым для всего приложения». Каждый новый домен должен
явно определить cache schema, mutation executor, idempotency, retry policy,
conflict resolution и пользовательское состояние синхронизации.

### Телефония: текущая реализация

Телефония состоит из четырёх связанных частей: Flutter UI/state, Android native,
iOS native и backend/PBX. Ошибка в одной части не должна автоматически
приписываться другой.

#### Flutter SIP

- Основной код находится в `lib/screens/sip/`.
- Реализованы dialer, contacts/search, journal, incoming/active call UI,
  DTMF, mute, speaker/earpiece и call overlay.
- Геометрия dialer стабилизирована: ввод первой цифры и панель подсказок не
  должны сдвигать клавиатуру.
- Вставка номера из clipboard очищает недопустимые символы, сохраняя `+`, `*`,
  `#` и цифры.

#### Android SIP

- `NativeSipManager.kt` управляет нативным SIP lifecycle.
- `NativeSipForegroundService.kt` отвечает за foreground/incoming presentation.
- `NativeSipBridge.kt` связывает Flutter и нативную часть.
- Native actions Answer/Decline работают через receivers.
- Для показа входящего поверх lock/background используется full-screen intent.
- На Android 14+ пользователь должен разрешить full-screen notifications;
  также проверяются notification permission/channel и OEM battery settings.
- Владельцем системного рингтона является notification/service path. SIP core
  не должен параллельно запускать второй рингтон.
- Изменение параметров существующего notification channel может не сработать,
  потому что Android сохраняет channel settings; нужна управляемая миграция ID.

#### iOS SIP и CallKit

- `IOSNativeSipManager.swift` управляет SIP и передаёт события Flutter.
- Входящие показываются через CallKit `reportNewIncomingCall`.
- App keypad отправляет DTMF через существующий `sendDtmf` путь.
- Если нет обработчика `CXPlayDTMFCallAction`, нельзя выставлять
  `supportsDTMF = true`: системная клавиатура воспроизведёт локальный tone без
  гарантированной отправки в SIP.
- После Swift/Pod изменений проверяется native build, но финальная приёмка
  выполняется только на реальном iPhone.

#### Защита от старых и отменённых звонков

Мобильный клиент принимает backend-origin timestamp (`call_started_at_ms` и
совместимые поля), отбрасывает слишком старые incoming push и завершает только
совпадающий вызов по `call_id` при `call_cancelled`/`call_ended`.

Backend/PBX обязан:

1. Передавать `call_started_at_ms` в UTC milliseconds на каждый incoming push.
2. Использовать короткий FCM TTL/APNs expiration — ориентир 30–60 секунд.
3. Останавливать retry после завершения звонка.
4. Отправлять cancellation с тем же `call_id` при сбросе вызывающей стороной.
5. После `sip_ready(call_id)` создавать INVITE только если состояние сервера всё
   ещё `ringing`; иначе вернуть `call_ended`.

`push_received` означает доставку push, а не живой SIP INVITE. Для диагностики
нужна единая временная линия: backend timestamp → push → native log → Flutter
state → CallKit/Android UI → SIP INVITE → cancellation/end.

### Разделение ответственности при ошибках

| Симптом | Основной владелец проверки | Что собрать |
| --- | --- | --- |
| API вернул ошибку/неполные данные | Backend + mobile parser | URL, status, response fragment, model error |
| Push не доставлен | Firebase/APNs + backend | token, message ID, send/delivery timestamps |
| Push доставлен, но нет SIP INVITE | PBX/backend SIP state | `call_id`, `sip_ready`, INVITE logs |
| Android звонит без UI | Android native/device | notification channel, full-screen permission, lock/background logs |
| iPhone не показывает звонок | iOS CallKit/push/PBX | PushKit/APNs, CallKit report, SIP logs, app state |
| Release не подписывается | Signing/account configuration | exact Gradle/Xcode error, key/profile identity |
| Работает после refresh | Mobile request/state race | request timeline, BLoC states, prerequisites |

### Минимальная проверка перед выпуском

- [ ] Cold start: login/PIN/biometric без бесконечного loader.
- [ ] Leads, Deals, Events и Orders открываются с первого раза без refresh.
- [ ] Создание и редактирование ключевых CRM-сущностей.
- [ ] Светлая/тёмная тема на auth, navigation, CRM, chat и SIP.
- [ ] RU/EN/UZ JSON валиден, новые ключи присутствуют во всех языках.
- [ ] Chat push: foreground/background, grouping, reply, mark-read.
- [ ] Android incoming SIP: foreground/background/locked, Answer/Decline,
  speaker/earpiece, mute, DTMF, завершение.
- [ ] iPhone incoming SIP: foreground/background/terminated, CallKit Answer,
  audio route, mute, app DTMF, завершение.
- [ ] Запоздалый push и cancellation не создают «призрачный» звонок.
- [ ] Offline mutation повторяется безопасно и не создаёт дубликат.
- [ ] `flutter analyze` для затронутых файлов, релевантные tests и native build.

## 🚀 Roadmap: что осталось

### P0 — обязательно для надёжной телефонии и release

- [ ] Внедрить backend-origin `call_started_at_ms` во всех incoming payload.
- [ ] Установить короткий TTL/APNs expiration и прекратить retries завершённых
  звонков.
- [ ] Реализовать единый `call_id` lifecycle: ringing → sip_ready → invite →
  answered/cancelled/ended.
- [ ] Провести матрицу реальных device-тестов на Android и iPhone во всех app
  states, включая слабую сеть и задержанный push.
- [ ] Добавить серверно-мобильную корреляцию логов по `call_id` и timestamp.

### P1 — качество и завершение нового дизайна

- [ ] Провести полный theme audit всех экранов и диалогов.
- [ ] Удалить оставшиеся hardcoded цвета там, где есть semantic token.
- [ ] Проверить compact layout на малых Android/iPhone экранах.
- [ ] Синхронизировать skeleton/loading геометрию с финальными экранами.
- [ ] Проверить create/edit parity для заказов, сделок, лидов и задач.
- [ ] Зафиксировать visual regression checklist для light/dark themes.

### P1 — offline и устойчивость данных

- [ ] Определить список доменов, официально поддерживающих offline mutations.
- [ ] Добавить idempotency keys и conflict resolution для каждого executor.
- [ ] Показывать пользователю pending/failed/synced состояния операций.
- [ ] Покрыть nullable/anomalous API payload parser-тестами.
- [ ] Провести тесты airplane mode, reconnect, duplicate retry и logout cleanup.

### P1 — автоматические проверки

- [ ] Увеличить unit-test покрытие моделей, parser и business rules.
- [ ] Добавить widget tests для auth, lead/deal/order и SIP critical UI.
- [ ] Добавить integration tests основных CRM flows.
- [ ] Настроить CI: format/diff check, analyze, tests, Android build и iOS build.
- [ ] Защитить release signing secrets и документировать ротацию ключей/profiles.

### P2 — наблюдаемость и развитие продукта

- [ ] Утвердить Crashlytics policy и исключить персональные/секретные данные.
- [ ] Добавить технические метрики startup, API errors, sync/outbox и SIP stages.
- [ ] Создать dashboards/alerts по crash-free sessions и call success rate.
- [ ] Продолжить оптимизацию больших файлов и разделить перегруженные сервисы,
  включая крупный API service, по доменам.
- [ ] Отдельно оценить web-версию: native SIP, push и background поведение не
  переносятся на web автоматически.

---

**Версия документации:** 2.0
**Последнее обновление:** Август 2026
**Актуально для версии приложения:** 2.1.160+220 (`color_schema_3`)

---

> 💡 **Совет:** Добавьте этот README в закладки и обращайтесь к нему при возникновении вопросов. Документация постоянно обновляется по мере развития проекта.

**Удачной разработки! 🚀**
