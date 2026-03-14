# SHAMCRM Mobile
## Technical Specification: Full Light/Dark Theme Architecture and Migration

Version: 1.0
Date: 2026-03-14
Authoring level: Distinguished Engineer / Fellow
Language of execution: Russian

---

## 1. Executive Summary

Необходимо внедрить в `shamcrm_mobile` полноценную двухрежимную тему: `Light` и `Dark`, где dark mode является не стандартным Material dark, а брендовой, визуально противоположной версией текущего светлого интерфейса с сохранением идентичности SHAMCRM.

Задача не сводится к добавлению `darkTheme` в `MaterialApp`. По результатам аудита проект находится в состоянии высокой визуальной децентрализации: стили, цвета, типографика, тени, границы, состояния контролов, иконки, диалоги, фильтры, дропдауны и графики оформлены локально в сотнях файлов. Следовательно, работа должна выполняться как архитектурная миграция UI-платформы приложения, а не как набор точечных правок.

---

## 2. Audit Summary of Current State

### 2.1 Key facts discovered during repository audit

- В проекте `~1340` Dart-файлов.
- Прямые визуальные литералы (`Color(...)`, `Colors.*`, `BoxDecoration`, `TextStyle`, `LinearGradient`, `BorderSide`, `BoxShadow` и смежные) встречаются `~19029` раз.
- Минимум `601` Dart-файл напрямую используют цветовые литералы.
- `Theme.of(context)` / `ColorScheme.of(context)` / `ThemeExtension` / даже ограниченное использование `AppColors` встречается только примерно в `8` файлах, то есть тема почти не централизована.
- Прямые указания `fontFamily: 'Gilroy'` / `fontFamily: 'Golos'` встречаются `~3737` раз.
- В проекте `~1955` вызовов/вхождений, связанных с `SnackBar`, `AlertDialog`, `showDialog`, `showModalBottomSheet` и смежными overlay-элементами.
- В проекте `~412` индикаторов/refresh/loading surfaces (`CircularProgressIndicator`, `LinearProgressIndicator`, `RefreshIndicator`).
- `CustomDropdownDecoration(...)` встречается `~131` раз.
- `ColorScheme.light(...)` зашит как минимум `24` раза.
- `showDatePicker(...)` / `showTimePicker(...)` встречается `11` раз и сейчас завязан на светлые локальные обёртки.
- Визуальные ассеты загружены не только как tintable SVG, а в основном как фиксированные PNG/JPG:
  - `152` PNG
  - `8` SVG
  - `8` JPG
- Существуют baked-in цветовые наборы ассетов вида `*_ON`, `*_OFF`, `add_black`, `star_on`, `star_off`, что усложняет тему и требует asset strategy.

### 2.2 Current architectural state

- Корневой `MaterialApp` фактически живёт только на одной светлой теме.
- В `main.dart` отсутствуют:
  - production `darkTheme`
  - `themeMode`
  - persistence пользовательского выбора темы
  - реакция системных UI overlays на смену темы
- Существует `ThemeController`, но он находится в debug-секции и не интегрирован в production app shell.
- `AppColors` содержит только плоский набор цветовых констант и не моделирует dual-theme semantics.
- Большая часть экранов, фильтров, карточек и overlay-компонентов стилизуется локально через inline `TextStyle`, `BoxDecoration`, `Color`, `BorderSide`, `BoxShadow`.

### 2.3 Highest-risk thematic hotspots by folder

- `lib/page_2/warehouse` -> около `1800` цветовых вхождений
- `lib/custom_widget/filter` -> около `1464`
- `lib/page_2/money` -> около `1079`
- `lib/screens/analytics` -> около `868`
- `lib/screens/lead` -> около `813`
- `lib/page_2/dashboard` -> около `728`
- `lib/screens/deal` -> около `576`
- `lib/screens/task` -> около `552`
- `lib/screens/chats` -> около `538`
- `lib/page_2/order` -> около `486`

### 2.4 Existing reusable leverage points

Ниже точки, которые можно и нужно использовать как рычаг массовой миграции:

- `CustomTextField` используется около `203` раз
- `CustomButton` используется около `279` раз
- семейство `CustomAppBar*` используется около `39` раз
- `showCustomSnackBar(...)` используется около `219` раз

Это означает: сначала должен быть создан theme-aware foundation layer, затем миграция должна идти через переиспользуемые primitives, а не через хаотичную правку каждого экрана вручную.

---

## 3. Problem Statement

Приложение построено как large Flutter app со значительным количеством продуктовых доменов:

- Auth / PIN / profile / onboarding
- CRM: leads, deals, tasks, events, notifications
- Chats / messaging / media / reactions
- Dashboard / analytics / charts
- Order / goods / category / warehouse / money / accounting flows
- Filters, dialogs, dropdowns, date pickers, custom app bars, tab systems, navigation bars

Текущая реализация визуального слоя:

- рассчитана практически только на светлый режим
- использует большое количество жёстко зашитых светлых поверхностей
- содержит inline-типографику и inline-цвета
- опирается на ассеты с заранее запечённым цветом
- не имеет системной семантики цвета, состояния, elevation, overlays и графиков

В таком состоянии попытка "быстро добавить dark mode" приведёт к:

- неполному покрытию
- визуальной фрагментации
- конфликтам между старым и новым стилями
- неконсистентным состояниям контролов
- плохому контрасту
- деградации в графиках, фильтрах, диалогах и нижних листах
- постоянному возврату hardcoded colors в кодовую базу

---

## 4. Product Goal

Результатом работы должно стать приложение, в котором:

- каждый экран, диалог, bottom sheet, snackbar, popup, dropdown, chart, banner, loader, shimmer, file preview, empty state, error state, tab, navigation element, form control и вспомогательный overlay корректно отображаются и в light, и в dark режиме
- dark theme визуально ощущается как полноценная брендовая тема SHAMCRM, а не просто "чёрный фон вместо белого"
- пользователь может переключать режим темы явно
- выбранный режим сохраняется между перезапусками приложения
- интерфейс не "вспыхивает" светлой темой при старте, если сохранён dark
- новые экраны и компоненты не могут возвращаться к hardcoded-color подходу

---

## 5. Scope

### 5.1 In Scope

- Полная архитектура light/dark theme
- Введение централизованных design tokens
- Введение production theme controller/state
- Введение `theme`, `darkTheme`, `themeMode` на уровне app shell
- Миграция существующих reusable UI primitives
- Миграция всех продуктовых поверхностей
- Миграция системных overlays и системных picker wrappers
- Миграция chart palette
- Миграция ассетов и icon strategy
- Введение quality gates, lint/grep guardrails и acceptance criteria

### 5.2 Explicitly Out of Scope

Следующее не является целью данного ТЗ, если не требуется для поддержки темы:

- переписывание бизнес-логики BLoC/Cubit/API
- изменение навигационной архитектуры
- изменение продуктовых сценариев
- редизайн информационной архитектуры экранов
- замена Flutter на другой UI framework

---

## 6. UX and Design Principles

### 6.1 Core design intent

Dark theme должна быть:

- визуально противоположной светлой теме
- брендовой
- контрастной
- премиальной
- стабильной по иерархии
- консистентной во всех доменах

Dark theme не должна быть:

- generic Material dark
- pure black everywhere
- набором случайных инверсий `white -> black`
- локальным исключением только для некоторых экранов

### 6.2 Brand preservation requirements

Нужно сохранить узнаваемость текущего дизайна:

- фирменный тёмно-синий характер бренда
- CTA-акценты и product emphasis
- структуру плотности интерфейса
- привычные визуальные уровни карточек, фильтров и шапок

Но при этом:

- текущие несколько конкурирующих синих/фиолетовых оттенков должны быть рационализированы в компактную семантическую систему
- dark mode должен использовать глубокие фирменные navy/antracite поверхности, а не плоский `#121212`

### 6.3 Accessibility

Минимальные требования:

- body text и важные контролы должны обеспечивать контраст не ниже WCAG AA
- disabled / hint / tertiary text не должны теряться на dark surfaces
- status colors не должны терять читаемость на тёмных фонах
- focus / selected / active / pressed / error states должны быть различимы

---

## 7. Target Architecture

### 7.1 Mandatory production theming layer

Необходимо создать production-level theming package внутри приложения, например:

- `lib/theme/app_theme_mode.dart`
- `lib/theme/app_theme_controller.dart`
- `lib/theme/app_theme_storage.dart`
- `lib/theme/app_color_tokens.dart`
- `lib/theme/app_theme_extensions.dart`
- `lib/theme/app_theme_data.dart`
- `lib/theme/theme_context_extensions.dart`
- `lib/theme/system_ui_theme_sync.dart`

Точное именование может отличаться, но архитектурная роль этих сущностей обязательна.

### 7.2 Theme state model

Приложение обязано поддерживать минимум два явных режима:

- `light`
- `dark`

Архитектура должна не блокировать будущее расширение до `system`, но в рамках текущего продукта UI/настройки обязаны гарантировать явный выбор `Light`/`Dark`.

### 7.3 Persistence model

Режим темы должен:

- сохраняться в локальном storage
- быть считан до построения первого production кадра
- применяться до рендера основного `MaterialApp`
- использоваться для синхронизации system bars

### 7.4 Theming source of truth

Единственным источником правды для цветов и визуальных семантик должны быть:

- `ThemeData`
- `ColorScheme`
- strongly typed `ThemeExtension`(s)
- семантические токены, а не "палитра сырых hex-кодов"

Запрещённый подход после миграции:

- прямой `Color(0xff...)` в feature widgets
- прямой `Colors.white`, `Colors.black`, `Colors.red`, `Colors.green` в UI-слое, кроме строго оговорённых исключений в theming layer
- локальные `ColorScheme.light(...)` для отдельных экранов

### 7.5 Semantic token model

Нужно определить минимум следующие группы токенов.

#### Surfaces

- `appBackground`
- `screenBackground`
- `surfacePrimary`
- `surfaceSecondary`
- `surfaceElevated`
- `surfaceInteractive`
- `surfaceInverse`
- `surfaceDangerSubtle`
- `surfaceWarningSubtle`
- `surfaceSuccessSubtle`

#### Content

- `textPrimary`
- `textSecondary`
- `textTertiary`
- `textInverse`
- `textBrand`
- `iconPrimary`
- `iconSecondary`
- `iconInverse`
- `iconBrand`

#### Stroke and divider

- `borderPrimary`
- `borderSecondary`
- `borderFocused`
- `dividerPrimary`
- `dividerSubtle`

#### Actions and controls

- `buttonPrimaryBackground`
- `buttonPrimaryForeground`
- `buttonSecondaryBackground`
- `buttonSecondaryForeground`
- `buttonTertiaryForeground`
- `buttonDangerBackground`
- `buttonDangerForeground`
- `inputBackground`
- `inputBorder`
- `inputFocusedBorder`
- `inputErrorBorder`
- `selectionBackground`
- `selectionForeground`
- `toggleActive`
- `toggleInactive`

#### Status

- `success`
- `warning`
- `error`
- `info`
- `pending`
- `approved`
- `rejected`
- `archived`

#### Overlay and chrome

- `scrim`
- `dialogBackground`
- `bottomSheetBackground`
- `snackSuccessBackground`
- `snackErrorBackground`
- `tooltipBackground`
- `shadowColor`

#### Charts

- `chartAxis`
- `chartGrid`
- `chartTooltipBackground`
- `chartTooltipForeground`
- `chartSeries1..N`
- `chartPositive`
- `chartNegative`
- `chartNeutral`

### 7.6 Typography centralization

Theme migration обязана включать перенос typography semantics в `TextTheme` и/или shared text style tokens.

После миграции запрещается массовое дублирование:

- `fontFamily: 'Gilroy'`
- `fontFamily: 'Golos'`
- повторяющихся inline `fontSize`, `fontWeight`, `letterSpacing`

Допустимы только редкие точечные исключения, если это специальный компонент.

### 7.7 Reference token direction for dark theme

Ниже пример стартового визуального направления. Это не догма по конкретным hex, но это обязательный характер темы:

- Light base:
  - background -> светлые холодные бело-голубые поверхности
  - text primary -> глубокий navy
  - stroke -> мягкий серо-голубой
  - CTA -> брендовый синий / индиго accent
- Dark base:
  - background -> глубокий navy/antracite
  - elevated surfaces -> чуть светлее background, но не серые Material slabs
  - text primary -> холодный off-white
  - secondary text -> desaturated blue-gray
  - borders -> мягкие холодные темно-синие strokes
  - CTA -> более яркий brand accent, читаемый на dark surfaces

Dark theme должна ощущаться как "ночная версия SHAMCRM", а не как "нейтральный тёмный режим Android".

---

## 8. Mandatory App-Shell Changes

### 8.1 Root integration

Необходимо:

- добавить production theme controller/state в app startup
- подключить `theme`, `darkTheme`, `themeMode` в корневой `MaterialApp`
- синхронизировать `scaffoldBackgroundColor`, `canvasColor`, `dialogTheme`, `bottomSheetTheme`, `snackBarTheme`, `dividerTheme`, `appBarTheme`, `tabBarTheme`, `inputDecorationTheme`, `progressIndicatorTheme`, `popupMenuTheme`, `switchTheme`, `checkboxTheme`, `radioTheme`, `chipTheme`, `navigationBarTheme`/`bottomNavigationBarTheme`

### 8.2 System UI overlays

Нужно убрать статически зашитую светлую системную хрому и сделать динамическую синхронизацию:

- status bar icons
- status bar brightness
- navigation bar color
- navigation bar icon brightness
- page-level override only when действительно нужно

### 8.3 Theme persistence

Обязательное поведение:

- пользователь выбирает тему в настройках
- тема сохраняется
- при следующем запуске выбранный режим поднимается до render
- при переключении темы интерфейс меняется целиком без перезапуска

### 8.4 Theme transition behavior

Переключение темы должно сопровождаться лёгким и дешёвым по производительности transition-поведением.

Обязательные требования:

- переход между темами должен быть визуально мягким, но быстрым
- целевая длительность перехода: `120-180ms`
- допускаются только лёгкие implicit animations уровня opacity/color/elevation/position refinement
- анимация не должна вызывать frame drops на средних Android-устройствах
- смена темы не должна сопровождаться тяжёлыми blur/mask/rebuild-эффектами по всему дереву
- animation policy должна быть централизована, а не реализована вручную на каждом экране по-разному

---

## 9. Required Settings UX

### 9.1 Primary settings entry

В `Profile` / `Settings` должен появиться явный пользовательский пункт управления темой.

Рекомендуемое название:

- `Тема`

Допустимый запасной вариант:

- `Оформление`

Не рекомендуется название:

- `Фон`

Внутри этого пункта должны быть доступны ровно три варианта:

- `Системная`
- `Светлая`
- `Тёмная`

Требования:

- пункт должен быть доступен без debug build
- состояние должно быть персистентным
- UI самого экрана выбора темы должен быть theme-aware
- активный вариант должен быть явно подсвечен
- при выборе `Системная` приложение должно корректно следовать platform brightness

### 9.2 Quick access via overflow menu

В приложении должен существовать быстрый доступ к смене темы через unified overflow menu (`три точки`) на тех ключевых экранах/шардах навигации, где такой menu уже является частью основного chrome.

Требования:

- quick action должна вести себя одинаково и предсказуемо
- quick action не должна быть случайно раскидана по разным feature menus разными способами
- допустимы два UX-паттерна:
  - отдельный пункт `Тема`
  - inline quick toggle/shortcut внутри overflow menu
- если в конкретном экране overflow menu относится только к локальным действиям сущности, запрещено засорять его темой; тема должна идти через общий app-level overflow

### 9.3 Selection model

Primary model выбора темы обязан быть трёхсостоянием:

- `system`
- `light`
- `dark`

Требования:

- изменение должно применяться мгновенно
- текущее значение должно быть единым источником правды для всего приложения
- quick switch из overflow menu и выбор в `Settings` должны работать поверх одного и того же persisted state

### 9.4 Animation requirements for theme switch

Анимация смены темы должна быть минималистичной и производительной.

Обязательные требования:

- использовать преимущественно `AnimatedTheme`, `AnimatedSwitcher`, `TweenAnimationBuilder` или аналогичные cheap implicit transitions
- не использовать тяжёлые full-screen custom painters, сложные reveal-маски и дорогие clip-path анимации как основной механизм переключения темы
- анимация должна улучшать восприятие, а не быть отдельным шоу-эффектом
- UI после переключения должен оставаться мгновенно интерактивным
- при scroll, chart rendering, lists and dialogs не должно появляться visibly janky behavior

Рекомендуемый visual behavior:

- лёгкий cross-fade цвета поверхностей и текста
- мягкая перестройка elevation/shadow
- без длинных spring-анимаций
- без "театральных" эффектов

### 9.5 Not acceptable

Не допускается:

- скрытый debug-only toggle
- отсутствие режима `Системная`
- локальное переключение только на одном экране
- разные наборы опций в `Settings` и в overflow menu
- тяжёлая анимация, ухудшающая FPS
- тема как пункт только в одном случайном `PopupMenuButton`, но без системного места в настройках

---

## 10. UI Component Migration Requirements

Следующие категории обязаны получить полное dual-theme покрытие.

### 10.1 Foundation primitives

- `Scaffold`
- `SafeArea` surfaces
- `AppBar`
- `Bottom navigation`
- `TabBar`
- `TabBarView` containers
- `Drawer` / side menus если используются
- page backgrounds

### 10.2 Input and form controls

- text fields
- multi-line fields
- password fields
- edit buttons inside inputs
- date/time fields
- dropdowns
- custom dropdowns
- multi-select dropdowns
- radio groups
- switches
- checkboxes
- chips
- segmented controls
- search bars
- inline field validation states

### 10.3 Feedback and overlay layer

- `SnackBar`
- `AlertDialog`
- `Dialog`
- `showDialog` custom layouts
- `BottomSheet`
- `showModalBottomSheet`
- `PopupMenuButton`
- context menus
- emoji/reaction panels
- confirmation dialogs
- destructive action dialogs
- loading dialogs

### 10.4 Content surfaces

- cards
- list items
- grouped sections
- headers/subheaders
- avatars and placeholders
- badges
- status pills
- dividers
- banners
- tooltips

### 10.5 Async and state views

- loading spinners
- refresh indicators
- skeletons
- shimmer
- empty states
- error states
- retry blocks
- offline/internet overlays

### 10.6 Charts and analytics

Все графики и аналитические поверхности обязаны адаптироваться:

- оси
- сетка
- legends
- tooltips
- labels
- highlighted points
- zero/neutral lines
- positive/negative values
- chart cards and filter sheets

### 10.7 Media and file-related surfaces

- image viewers
- attachment bubbles
- file type icons
- previews
- download states
- upload states

---

## 11. Product Domain Coverage Matrix

Полный rollout обязан включать минимум следующие домены:

- Auth / QR / PIN / forgot PIN / setup screens
- Home shell / navigation / permissions surfaces
- Profile / settings / organizations / support
- Notifications
- Dashboard
- Dashboard for manager
- Analytics
- Chats / chat details / message bubbles / input / media / reactions / user lists / templates
- Leads
- Deals
- Tasks
- My Tasks
- Events
- Call center
- Orders
- Goods
- Category
- Warehouse:
  - openings
  - incoming
  - movement
  - write-off
  - supplier return
  - client return
  - client sale
  - references
  - price types
  - warehouses
  - measure units
- Money:
  - income
  - outcome
  - references
  - salary payment
  - error dialogs
- Common filters
- Calendar flows
- GPS / special overlays
- Internet monitor / network overlays
- Update dialog

Definition of Done не может быть достигнут, если хотя бы один из перечисленных продуктовых доменов остался в single-theme состоянии.

---

## 12. Asset Strategy Requirements

### 12.1 Current issue

Проект сильно опирается на PNG/JPG-иконки и ассеты с зафиксированным цветом:

- `*_ON`
- `*_OFF`
- `*_black`
- звёзды on/off
- nav icons
- chat/menu icons

Это несовместимо с устойчивой архитектурой dual-theme, если не сформулировать явную asset strategy.

### 12.2 Required strategy

Для каждого визуального ассета агент обязан определить один из трёх путей:

1. `Tintable`
   - перевод в SVG или монохромный PNG, который можно красить theme token-ом

2. `Dual asset set`
   - отдельные ассеты для light/dark, если иконка или иллюстрация не поддаются tint

3. `Keep as-is`
   - только если ассет нейтрален и одинаково читаем в обеих темах

### 12.3 Mandatory rules

- Нельзя оставлять цветные ассеты в critical UI просто "как получилось"
- Для навигационных и action-иконок приоритет должен быть за tintable strategy
- Для брендовых иллюстраций допустим dual-set
- Нужно минимизировать количество пар `ON/OFF` ассетов, если их можно заменить на один tintable asset

---

## 13. Migration Strategy

### 13.1 Implementation principle

Запрещено начинать с массового ручного редактирования сотен экранов без foundation layer.

Правильный порядок:

1. Построить theme platform
2. Подключить app shell
3. Перевести reusable primitives
4. Перевести product domains батчами
5. Включить guardrails против возврата hardcoded colors

### 13.2 Required phases

#### Phase 0. Inventory and foundation design

- Зафиксировать все визуальные токены
- Утвердить semantic token map
- Зафиксировать исключения
- Спроектировать theme storage/state

#### Phase 1. App shell and theme engine

- production theme controller
- persistence
- `MaterialApp.theme/darkTheme/themeMode`
- system UI sync
- base `ColorScheme`
- theme extensions

#### Phase 2. Reusable UI kit migration

- buttons
- text fields
- snackbars
- common app bars
- dialog shells
- bottom sheet shells
- common cards
- loaders/skeletons
- status chips
- custom dropdown decoration

#### Phase 3. Domain migration by vertical slices

Recommended order:

1. Auth / Profile / Notifications / Home shell
2. Dashboard / Analytics / charts
3. Chats
4. Leads / Deals / Tasks / Events
5. Orders / Goods / Category
6. Warehouse
7. Money
8. Remaining overlays / utilities / debug-safe compatibility

#### Phase 4. Asset migration

- nav icons
- action icons
- state icons
- illustration compatibility

#### Phase 5. QA hardening and cleanup

- remove stale hardcoded colors
- remove obsolete light-only helper code
- deprecate old `AppColors` access patterns where needed
- add regression checks

---

## 14. Agent Execution Contract

Агент, реализующий задачу, обязан действовать по следующим правилам.

### 14.1 Non-negotiable rules

- Не редактировать хаотично feature files до создания theme foundation
- Не добавлять новые hardcoded colors в процессе миграции
- Не оставлять mixed-mode screens, где часть интерфейса theme-aware, а часть использует старые светлые константы
- Не создавать новый визуальный долг ради "быстрого завершения"

### 14.2 Required working style

- Работать батчами
- После каждого батча запускать compile/analyze/tests
- После каждой крупной области фиксировать покрытие
- Поддерживать список мигрированных общих компонентов и доменов
- При обнаружении baked-in assets сразу классифицировать их по стратегии из Section 12

### 14.3 Expected implementation artifacts

Результатом реализации должны стать:

- новая theming architecture
- migrated reusable component layer
- migrated product screens
- settings toggle for theme mode
- cleaned hardcoded-style hotspots
- test coverage / golden coverage / visual verification evidence

---

## 15. Code Quality Guardrails

После миграции должны действовать следующие guardrails.

### 15.1 Hard rule

Вне theming layer запрещены новые:

- `Color(0x...)`
- `Color(0xff...)`
- `Colors.white`
- `Colors.black`
- `Colors.red`
- `Colors.green`
- `Colors.orange`
- `ColorScheme.light(...)`

Исключения:

- data-driven visualization palettes внутри централизованного chart token provider
- очень редкие технические случаи, документированные в комментарии и согласованные с архитектурой темы

### 15.2 Typography rule

Вне typography/theme layer должно быть минимизировано прямое использование:

- `fontFamily`
- `fontWeight`
- повторяющихся `TextStyle` без `copyWith` от theme semantics

### 15.3 Suggested enforcement

Обязателен хотя бы один механизм контроля:

- CI grep checks
- custom lint rule
- scripted audit command, который валит pipeline при появлении новых hardcoded colors

---

## 16. Acceptance Criteria

Работа считается выполненной только если соблюдены все критерии ниже.

### 16.1 Functional

- Пользователь может переключать `Системная` / `Светлая` / `Тёмная`
- Выбор сохраняется после restart
- Тема применяется на всём приложении, а не только на части экранов
- Все overlays открываются в корректной теме
- System bars соответствуют активной теме
- В `Settings` существует отдельный пункт управления темой
- В unified overflow menu существует быстрый доступ к смене темы

### 16.2 Visual

- Нет светлых "пробоев" в dark mode
- Нет тёмных "пробоев" в light mode
- Нет unreadable text/icon states
- Графики, tooltips, filters, dialogs и sheets читаемы и консистентны
- Навигация, app bars, cards, forms и banners визуально едины
- Переключение темы выглядит плавно, но не вызывает заметных лагов
- На средних Android-устройствах отсутствуют ощутимые frame drops при смене темы

### 16.3 Codebase

- Theme architecture централизована
- Повторное использование визуальных primitives увеличено
- Количество hardcoded colors в feature layer радикально сокращено
- Старые light-only local wrappers удалены или переведены на semantic theme tokens

### 16.4 Coverage

- Все перечисленные в Section 11 домены визуально проверены в обеих темах

---

## 17. Testing Requirements

### 17.1 Mandatory technical validation

- `flutter analyze`
- целевой smoke test запуска приложения
- widget tests для theme controller/storage
- widget tests для ключевых reusable components в `light` и `dark`

### 17.2 Mandatory visual validation

Нужно сделать golden/screenshot coverage минимум для:

- auth screen
- home shell with navigation
- profile/settings
- notifications
- dashboard
- analytics screen
- chat list
- chat screen
- lead details
- deal details
- task details
- order create/edit
- warehouse document create/details
- money form
- representative dialog
- representative bottom sheet
- representative filter sheet

### 17.3 Manual QA checklist

Проверить:

- iOS и Android
- app cold start in dark mode
- переключение темы во время работы
- overlays поверх уже открытых экранов
- pull-to-refresh
- tabbed pages
- list swipe actions
- charts with tooltip
- disabled / loading / empty / error states
- keyboard accessory / date picker / time picker

---

## 18. Risks and Mitigations

### Risk 1. Hardcoded visual explosion

Симптом:

- inline colors and styles everywhere

Mitigation:

- foundation-first migration
- guardrails
- batch conversion through shared primitives

### Risk 2. Baked-in light assets

Симптом:

- PNG/JPG assets with fixed colors

Mitigation:

- tintable asset policy
- dual asset set only where unavoidable

### Risk 3. Local light-only pickers

Симптом:

- `ColorScheme.light(...)` wrappers in date/time pickers and filters

Mitigation:

- centralized picker theming wrappers
- remove per-screen local light wrappers

### Risk 4. Chart unreadability

Симптом:

- axes/tooltips/grid/legend disappear or overglow in dark

Mitigation:

- dedicated chart tokens
- chart-by-chart QA

### Risk 5. Overlay mismatch

Симптом:

- dialogs/sheets/snackbars open with wrong theme

Mitigation:

- migrate shell-level dialog/bottom sheet/snackbar theming
- audit every custom overlay entry point

### Risk 6. Theme flash on startup

Симптом:

- app opens white before switching to dark

Mitigation:

- preload theme mode before root app build

### Risk 7. Partial migration

Симптом:

- some folders remain old-style

Mitigation:

- domain checklist
- Definition of Done tied to Section 11

---

## 19. Recommended Deliverable Structure

Итоговая реализация должна оставить проект в состоянии, где:

- любой новый экран обязан брать цвета из theme semantics
- любой reusable component already supports both modes
- любой overlay automatically inherits current theme
- asset selection is deterministic and documented
- dark mode is a first-class product feature

---

## 20. Definition of Done

Тема считается внедрённой только если одновременно выполнено всё:

- production app supports both Light and Dark
- theme choice is persistent
- all product domains from Section 11 visually support both modes
- no critical hardcoded-color leftovers remain in feature layer
- charts, dialogs, sheets, snackbars, pickers, loaders, filters and navigation are all theme-aware
- asset strategy implemented for incompatible icons
- technical validation passed
- visual validation passed
- codebase now has enforceable theming architecture for future work

---

## 21. Final Directive to Implementing Agent

Реализовывать задачу как platform migration, а не как cosmetic patch.

Приоритеты реализации:

1. Сначала theming foundation
2. Затем shared UI primitives
3. Затем product domains
4. Затем asset cleanup and QA hardening

Ключевой принцип:

Если после внедрения хотя бы одна визуальная деталь в приложении остаётся существовать только в светлой логике, задача не завершена.

Дополнительная директива:

- primary source of truth для выбора темы: `system/light/dark`
- primary persistent control: `Settings -> Тема`
- secondary quick access: unified overflow menu (`три точки`) там, где он является частью общего app chrome
- transition policy: short, cheap, deterministic, no heavy animation experiments

---

## 22. Agent Handoff Protocol

### 22.1 How to provide this specification to another agent

Лучший способ передачи:

1. Передавать агенту весь документ целиком, а не по кускам.
2. Перед документом дать короткую команду в 3-5 строк:
   - цель
   - что это source of truth
   - что надо делать по фазам
   - что нельзя упрощать требования
3. Попросить агента сначала подтвердить implementation plan по фазам, а затем выполнять.

### 22.2 Recommended handoff message

Рекомендуемый формат:

- "Ниже полный source-of-truth ТЗ. Следуй ему как обязательной архитектурной спецификации."
- "Не упрощай задачу до добавления только `darkTheme`."
- "Сначала сделай foundation, затем shared components, затем product-domain migration."
- "Если видишь конфликт с существующим кодом, выбирай путь, который сохраняет требования этого ТЗ."

### 22.3 Should this be sent in parts or all at once

Правильный вариант:

- отправлять сразу весь документ целиком

Отправка по частям допустима только если:

- у инструмента есть жёсткий лимит контекста
- или нужно отдельно обсуждать спорный раздел

Но даже в этом случае сначала лучше отправить:

- executive summary
- target architecture
- settings/overflow requirements
- migration strategy
- definition of done

И только потом дополнительные приложения.
