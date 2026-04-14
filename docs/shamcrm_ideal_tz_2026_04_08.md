# shamCRM: Идеальное ТЗ по развитию продукта

Дата: 2026-04-08
Статус: стратегический продуктовый и технический документ
Цель: определить, как вывести `shamCRM` в более сильную конкурентную позицию для клиентов в 2026-2027 году

## 1. Резюме

`shamCRM` уже не выглядит как “просто CRM”. По коду это уже `mobile-first` платформа с сильным операционным контуром: `лиды + сделки + задачи + чаты + документы + склад + деньги + call-center + аналитика + роли + офлайн-задел`.

Главная возможность роста не в том, чтобы копировать один конкретный продукт, а в том, чтобы закрепить позиционирование:

> `shamCRM` = мобильная операционная система для продаж, сервиса и внутренних операций компании.

Чтобы продукт стал реально сильнее конкурентов, нужно довести его до пяти уровней зрелости:

1. Сделать единый `Customer 360`.
2. Построить настоящий `omnichannel inbox` и автоматизацию клиентского пути.
3. Добавить `AI-слой` для менеджеров, операторов и руководителей.
4. Усилить `self-service`, документы, оплаты, SLA и сервисный контур.
5. Закрыть технический фундамент: модульность, тесты, офлайн-фаза 2/3, наблюдаемость и стабильность.

## 2. На чем основан анализ

### 2.1. Что было проанализировано в проекте

По состоянию репозитория на `2026-04-08`:

- `lib/api/service/api_service.dart` содержит около `21 138` строк.
- В проекте около `487` файлов BLoC, `281` файла в `page_2`, `279` экранов в `screens`, `178` моделей.
- Есть текущий `offline-first phase 1` для лидов, сделок, задач и чатов.
- Есть мобильные виджеты, deep-link/navigation callbacks, push, QR-flow, PIN, биометрия, локализация, гибкие права доступа, tutorial/onboarding.
- Есть большой контур `CRM + склад + деньги + заказы + аналитика + call-center`.
- Тестовое покрытие очень ограничено: фактически видно только точечные тесты для messaging и базовый widget test.

### 2.2. Какие конкуренты взяты в benchmark

По официальным публичным страницам, доступным на `2026-04-08`, были сверены ключевые прямые и косвенные конкуренты:

- `Bitrix24`
- `Odoo`
- `Zoho CRM`
- `HubSpot`
- `Pipedrive`
- `Kommo`
- `Salesforce`

Важно: это не “все CRM мира”, а репрезентативный набор сильнейших ориентиров по направлениям:

- `CRM + омниканал`
- `mobile CRM`
- `AI и автоматизация`
- `service/helpdesk`
- `склад/заказы/финансы`
- `field sales`
- `self-service / portal`

## 3. Что уже есть в shamCRM

## 3.1. Сильные текущие модули

- `CRM-контур`: лиды, сделки, задачи, мои задачи, заметки, история, календарь, события.
- `Коммуникации`: корпоративные чаты, групповые чаты, файлы, voice, шаблоны, push.
- `Аналитика`: CRM-дашборд, аналитические графики, KPI, конверсия, источники лидов, telephony/events, ROI, connected accounts, task statistics.
- `Операционный контур`: заказы, товары, категории, склады, поставщики, единицы измерения, типы цен.
- `Документы`: приход, продажа клиенту, возврат клиента, возврат поставщику, перемещение, списание, производство.
- `Финансы`: кассы, статьи доходов/расходов, приход/расход денег, дебиторы, кредиторы, cash balance.
- `Call-center`: список звонков, фильтры, детали звонка, рейтинг, дашборд оператора.
- `Платформа`: роли и права, выбор организации и воронки, локализация, in-app update, widgets, background preloading.
- `Офлайн`: локальный кэш, outbox, scheduler, network profile, SQLite/Drift.

## 3.2. Что особенно ценно

- У продукта уже есть хорошая база для `операционного super-app`.
- Есть логика показа разделов по правам, а значит продукт можно глубоко персонализировать по ролям.
- Есть фундамент для `offline-first`, а это реальное конкурентное преимущество для мобильных пользователей.
- Есть задел под `mini app`, delivery address, widgets и омниканальные сценарии.
- Есть мощная аналитическая часть, что редко встречается у мобильных CRM такого типа.

## 3.3. Главные ограничения текущей версии

- Продукт очень широкий по функциям, но не везде доведен до единой продуктовой логики.
- В коде высокая сложность поддержки: слишком крупные экраны и сверхбольшой `ApiService`.
- Нет единого слоя `Customer 360`, который свяжет продажи, сервис, коммуникации, документы и деньги.
- Нет полноценного `journey orchestration` и визуального конструктора автоматизаций.
- Нет полноценного `customer portal / self-service кабинета`.
- Нет зрелого `service/helpdesk` слоя с SLA, очередями, порталом и knowledge base.
- Нет сильного прикладного `AI` слоя.
- Офлайн охватывает только часть продукта; склад, тяжелые документы и часть аналитики остаются вне зрелого offline-first.
- Низкое тестовое покрытие и слабая формализация quality gates.

## 4. Позиционирование, которое нужно закрепить

### Целевое позиционирование

`shamCRM` должен позиционироваться не как “очередная CRM”, а как:

> `Mobile-first CRM + operations platform` для компаний, где продажи, склад, деньги, документы, чат и сервис должны жить в одном мобильном приложении.

### Для кого продукт должен быть идеален

- дистрибуция
- оптовая и розничная торговля
- сервисные команды
- call-center и отделы продаж
- компании с выездными менеджерами и региональными командами
- бизнесы, которым важны WhatsApp/Telegram/телефония/быстрые коммуникации

### Чем надо отличаться

Не пытаться быть “маленьким Salesforce”.

Нужно стать лучшими в связке:

- `скорость мобильной работы`
- `операционный контур внутри CRM`
- `омниканал + чат + телефония`
- `offline-first`
- `быстрое внедрение без тяжелой enterprise-сложности`

## 5. Выводы по конкурентам

## 5.1. Что рынок уже считает стандартом

По состоянию на `2026-04-08` сильные игроки рынка уже считают стандартом:

- омниканальные коммуникации в одном окне
- workflow automation / triggers / journey builder
- AI-summary, AI-assistant, next best action, прогнозы
- мобильную работу не как “просмотр”, а как полноценный рабочий режим
- customer portal / self-service
- service/helpdesk + knowledge base + SLA
- встроенные документы, оплаты, quoting, invoicing
- прогнозирование и BI для руководителя

## 5.2. Что именно показывают конкуренты

| Конкурент | Сильная сторона | Что нужно взять в shamCRM |
| --- | --- | --- |
| `Bitrix24` | Омниканал, телефония, e-sign, AI CoPilot, mobile CRM | Единый контакт-центр, AI-summary звонков, мобильная телефония, встроенные документы/оплаты |
| `Odoo` | Глубокая связка CRM + inventory + accounting + portal + helpdesk | Сквозной операционный контур, клиентский портал, SLA/тикеты, возвраты и сервис после продажи |
| `Zoho CRM` | AI Zia, mobile offline, field sales, customer journeys | Мобильный AI-ассистент, field mode, route/visit planning, visual journey orchestration |
| `HubSpot` | Сильный mobile UX для sales/service, shared inbox, tickets, SLA, dashboards | Быстрые мобильные сценарии, сервисный контур, shared inbox, руководительские виджеты |
| `Pipedrive` | AI Sales Assistant, template-based automation, forecasting | Подсказки менеджеру, next best action, revenue forecast, готовые шаблоны автоматизаций |
| `Kommo` | Messenger-first CRM, WhatsApp AI, Salesbot, invoice/NPS в чатах | Конверсия мессенджеров в продажи, no-code bot, AI replies, templates, invoices in chat |
| `Salesforce` | AI agents, omnichannel routing, self-service, field service | Маршрутизация обращений, knowledge base, портал, field service, AI-агенты для типовых задач |

## 5.3. Ключевой вывод

Если упростить, конкуренты выигрывают сегодня не списком сущностей, а качеством трех вещей:

1. `Единая клиентская история`
2. `Автоматизация и AI`
3. `Омниканальный сервис и самообслуживание`

Именно тут `shamCRM` должен усиливаться в первую очередь.

## 6. Целевая модель продукта shamCRM 2.0

## 6.1. Модуль 1. Customer 360

### Цель

Сделать единый профиль клиента, где в одном месте видны:

- лиды
- сделки
- заказы
- документы
- платежи
- задолженность
- чаты
- звонки
- задачи
- обращения в сервис
- NPS/CSAT
- история коммуникаций

### Требования

- единый `customer card`
- таймлайн всех событий клиента
- статусы клиента по жизненному циклу
- сегменты клиента: новый / активный / VIP / проблемный / отток
- автоматический health score клиента
- quick actions из карточки: написать, позвонить, создать заказ, выставить счет, поставить задачу, открыть сервисный тикет

## 6.2. Модуль 2. Omnichannel Inbox 2.0

### Цель

Свести все каналы клиента в один рабочий inbox.

### Каналы

- WhatsApp
- Telegram
- Instagram Direct
- Facebook Messenger
- email
- web chat / site widget
- телефония
- mini app / bot-каналы

### Требования

- один диалог = один клиент, даже если каналов несколько
- общий inbox команды
- распределение по очередям и менеджерам
- SLA по первому ответу и по закрытию
- приватные комментарии внутри диалога
- шаблоны и быстрые ответы
- вложения, voice, изображения, документы
- статусы диалога: новый / в работе / ждет клиента / закрыт / эскалация
- автоназначение по правилам: канал, регион, товар, pipeline, приоритет

## 6.3. Модуль 3. AI-ассистент

### Цель

Снять рутину с менеджеров, операторов и руководителей.

### Обязательные AI-функции

- summary звонка
- summary чата
- summary встречи
- auto-fill полей после коммуникации
- next best action
- подсказка вероятности сделки / риска оттока
- генерация follow-up сообщения
- извлечение задач и дедлайнов из переписки
- AI-помощник руководителя: “что просело”, “какие сделки в риске”, “кто перегружен”

### Дополнительно

- AI-коуч для операторов call-center
- автооценка качества диалога
- AI-классификация обращений
- AI-рекомендации товаров и cross-sell

## 6.4. Модуль 4. Workflow Builder / Journey Builder

### Цель

Дать бизнесу визуальный конструктор автоматизаций без разработчика.

### Требования

- триггеры: новый лид, смена статуса, входящее сообщение, неответ, просрочка, оплата, возврат, негативный рейтинг
- условия: канал, менеджер, регион, сумма, SKU, причина отказа, сегмент клиента
- действия: создать задачу, отправить шаблон, поменять статус, назначить менеджера, создать документ, уведомить руководителя, создать тикет, запустить бота
- визуальный `flow builder`
- библиотека готовых сценариев:
  - повторный контакт
  - abandoned cart / брошенный заказ
  - no response follow-up
  - контроль просроченной оплаты
  - эскалация негативного обращения
  - post-sale onboarding

## 6.5. Модуль 5. Customer Portal / Self-Service

### Цель

Дать клиенту прозрачный личный кабинет и снизить нагрузку на менеджеров и call-center.

### Что должно быть в портале

- заказы и статусы
- счета и оплаты
- документы на отгрузку
- задолженность
- возвраты
- сервисные заявки
- история сообщений
- knowledge base / FAQ
- подтверждение документов
- онлайн-оплата

### Дополнительно

- e-signature для документов
- повторный заказ из истории
- отслеживание доставки

## 6.6. Модуль 6. Service Desk / Helpdesk

### Цель

Закрыть сервис после продажи, претензии, возвраты и внутренние обращения.

### Требования

- тикеты и очереди
- категории обращений
- приоритеты
- SLA
- база знаний
- шаблоны решений
- эскалация на вторую линию
- связка обращения с клиентом, заказом, товаром и документом
- оценка качества закрытого обращения

## 6.7. Модуль 7. Field Sales / Mobile Field Mode

### Цель

Сделать приложение идеальным для выездных сотрудников.

### Требования

- план визитов на день
- карта клиентов и точек
- маршрутный лист
- check-in/check-out
- фотоотчет визита
- геометки
- сбор заказа на месте
- подписание документа у клиента
- быстрый повтор заказа
- офлайн-режим для выездной работы

### Важно

В коде есть следы GPS-направления, но как продуктовый модуль это нужно переосмыслить и довести до реального бизнес-сценария, а не держать как полуготовую функцию.

## 6.8. Модуль 8. Orders + Warehouse + Finance 2.0

### Цель

Усилить уже сильный операционный контур и сделать его редким конкурентным преимуществом.

### Что добавить

- reservation / allocation товара под заказ
- promised date / expected delivery
- контроль дефицита и автозакупка
- возвраты с причинами и аналитикой
- пакетные операции
- approval flows для скидок, возвратов, списаний, ручных корректировок
- коммерческие предложения / quotes
- invoice links / payment links
- customer balance и лимиты
- margin / profitability по заказу и клиенту

## 6.9. Модуль 9. Analytics OS

### Цель

Сделать аналитику главным инструментом руководителя, а не просто набором графиков.

### Что нужно

- unit-экономика по клиенту / менеджеру / каналу
- cohort analysis
- прогноз выручки и cash-flow
- pipeline risk board
- workload board
- conversion leakage analysis
- SLA compliance dashboard
- reasons of loss / churn dashboard
- SKU and stock intelligence
- attribution по каналам и кампаниям

### Формат

- executive dashboard
- manager dashboard
- operator dashboard
- warehouse dashboard
- finance dashboard

## 6.10. Модуль 10. Admin Platform / Integrations

### Цель

Сделать `shamCRM` платформой, а не набором жестко зашитых экранов.

### Требования

- каталог интеграций
- webhooks
- публичные события домена
- настройка полей, форм и обязательности по ролям
- настройка status machine
- настройка layout по ролям
- audit log
- approvals and delegation
- versioned API contracts
- импорт/экспорт

## 7. UX/UI требования

## 7.1. Главный принцип

Любое частое действие должно занимать `минимум тапов` и быть доступно прямо в контексте клиента, сделки, заказа или диалога.

## 7.2. Что нужно улучшить обязательно

- единый глобальный поиск по всем сущностям
- `command center` на главном экране: задачи, риски, сообщения без ответа, сделки под угрозой, просроченные оплаты
- быстрые сценарии `+`: лид, заказ, задача, звонок, сообщение, документ
- сохраненные фильтры и представления
- редактируемые списки колонок
- smart defaults при создании сущностей
- массовые действия
- единый дизайн карточек и таймлайнов
- лучшее состояние пустых экранов, ошибок, офлайна и медленного интернета
- role-based home screen
- onboarding 2.0: не только туториалы, но и “что делать сегодня”

## 7.3. Мобильные UX-детали

- sticky actions в карточке клиента
- offline badges
- optimistic UI для частых действий
- сканирование визитки / QR / штрихкода
- быстрый переход из push в нужную сущность
- action sheet для звонка / сообщения / оплаты / документа
- voice-to-note и photo-to-record

## 8. Техническое ТЗ

## 8.1. Архитектура

### Обязательные изменения

- разрезать `ApiService` на доменные сервисы:
  - `crm_api`
  - `chat_api`
  - `analytics_api`
  - `warehouse_api`
  - `finance_api`
  - `settings_api`
- ввести слой `repositories/use-cases`
- зафиксировать единый `error model`
- унифицировать pagination, filters, retry, caching
- убрать дублирование сущностей и naming drift

## 8.2. Модульность

- feature-first структура
- отдельные bounded contexts: `crm`, `messaging`, `orders`, `warehouse`, `finance`, `service`, `analytics`, `platform`
- минимизация cross-imports между unrelated modules
- дизайн системных UI-компонентов и дизайн-токены

## 8.3. Качество

- unit tests для domain/use-cases
- widget tests для ключевых экранов
- integration tests для core flows
- smoke tests на login, leads, deals, tasks, chat, order, warehouse docs
- CI pipeline с lint + tests + build sanity

## 8.4. Offline-first phase 2/3

### Phase 2

- offline для order list/details
- offline для warehouse references
- offline draft creation для документов
- upload queue для файлов и медиа

### Phase 3

- delta sync для аналитики и dashboard settings
- conflict resolution UI
- background sync health monitor
- offline audit trail

## 8.5. Observability

- crash analytics
- feature usage analytics
- outbox metrics
- API latency dashboards
- push delivery metrics
- per-screen performance metrics

## 8.6. Security

- device binding при необходимости
- session policies
- granular permissions
- audit trail for sensitive actions
- document/download access control
- encryption for local sensitive cache

## 9. Требования к backend и API

Без этого мобильная часть не сможет стать действительно сильной.

### Нужны backend-capabilities

- единая customer entity
- omnichannel conversation entity
- event bus / domain events
- workflow engine
- AI service endpoints
- transcript + summary pipeline
- portal auth и portal APIs
- SLA engine
- assignment rules
- idempotency keys
- optimistic concurrency / versioning
- delta endpoints для sync
- attachment lifecycle API
- webhook subscriptions

## 10. Приоритеты MoSCoW

## Must Have

- `Customer 360`
- `Omnichannel Inbox 2.0`
- `AI summary + next best action`
- `Workflow Builder`
- `Customer Portal`
- `Analytics OS` с прогнозами и risk dashboards
- модульная архитектурная декомпозиция
- тесты и CI
- offline phase 2 для заказов и документов

## Should Have

- `Helpdesk / Service Desk`
- `Field sales mode`
- approvals / delegation
- NPS / CSAT / churn analytics
- embedded payments / invoice links
- marketplace / webhooks / integrations center

## Could Have

- voice assistant
- AI coaching для call-center
- recommendation engine
- partner portal
- partner mobile cabinet
- no-code form builder for field teams

## Won't Have In Current Wave

- полный ERP-ребилд
- глубокий MRP как у enterprise ERP
- слишком сложный desktop-only функционал, который разрушит мобильную скорость

## 11. План реализации

## Phase 0. Foundation

Срок: `4-6 недель`

- продуктовая карта сущностей и customer journey map
- декомпозиция `ApiService`
- unified design tokens
- test strategy
- observability baseline
- backend contracts for new modules

## Phase 1. Quick Wins

Срок: `6-8 недель`

- customer timeline
- global search
- shared inbox v1
- AI summaries for chat/calls
- faster mobile quick actions
- saved filters/views
- dashboard risk cards

## Phase 2. Competitive Parity

Срок: `10-14 недель`

- workflow builder
- portal v1
- SLA/tickets v1
- payment links / quote / invoice flow
- offline phase 2
- manager cockpit

## Phase 3. Differentiation

Срок: `12-16 недель`

- field sales mode
- AI coaching
- journey orchestration
- predictive revenue / churn / margin
- full omnichannel routing
- customer health scoring

## 12. KPI успеха

## Product KPI

- `DAU/WAU` активных сотрудников
- доля пользователей, работающих ежедневно из mobile
- доля действий, завершенных без перехода в desktop/web
- time-to-first-value после внедрения

## Sales KPI

- рост конверсии из первого контакта в сделку
- снижение `first response time`
- рост повторных покупок
- снижение просроченных follow-up
- рост win rate по приоритетным сегментам

## Service KPI

- SLA compliance
- снижение среднего времени решения обращения
- рост CSAT/NPS
- снижение повторных обращений

## Tech KPI

- crash-free sessions
- P50/P95 screen load time
- outbox success rate
- sync success rate
- test pass rate
- regression rate after release

## 13. Definition of Done для каждой крупной функции

- есть user story и бизнес-сценарий
- есть API contract
- есть analytics events
- есть empty/error/offline states
- есть permission model
- есть acceptance criteria
- есть unit/widget/integration tests на критический path
- есть документация для команды и support
- есть rollout plan и rollback plan

## 14. Что особенно важно не испортить

- не перегрузить мобильный интерфейс enterprise-сложностью
- не размножать новые сущности без единой customer model
- не строить AI “для галочки” без реальной экономии времени
- не добавлять сервисный модуль отдельно от заказов, документов и коммуникаций
- не продолжать масштабировать giant-files и giant-screens

## 15. Главная продуктовая рекомендация

Лучшая стратегия для `shamCRM`:

1. Усилить уже сильное ядро `операции + мобильность`.
2. Поверх него построить `omnichannel + AI + automation`.
3. Добавить `portal + service`, чтобы продукт закрывал не только продажу, но и полный клиентский цикл.

Если это сделать, `shamCRM` сможет конкурировать не только как CRM, но как более удобная мобильная альтернатива для компаний, которым нужен быстрый рабочий инструмент, а не тяжелая enterprise-платформа.

## 16. Список источников benchmark

Официальные страницы, проверенные `2026-04-08`:

- Bitrix24 CRM: https://www.bitrix24.com/tools/crm/
- Bitrix24 mobile telephony: https://helpdesk.bitrix24.com/open/17013730/
- Odoo CRM: https://www.odoo.com/app/crm-features
- Odoo Inventory: https://www.odoo.com/app/inventory-features
- Odoo Accounting: https://www.odoo.com/app/accounting-features
- Odoo Helpdesk: https://www.odoo.com/app/helpdesk-features
- Zoho Zia: https://www.zoho.com/crm/zia/
- Zoho CRM Mobility: https://www.zoho.com/crm/mobility.html
- Zoho Journey Orchestration / CommandCenter: https://www.zoho.com/crm/process-management/journey-orchestration.html
- Zoho Sales Force Automation: https://www.zoho.com/crm/sales-force-automation/
- HubSpot AI / Breeze: https://www.hubspot.com/products/artificial-intelligence
- HubSpot Mobile App: https://www.hubspot.com/products/mobile
- HubSpot Sales: https://www.hubspot.com/products/sales
- Pipedrive AI Sales Assistant: https://www.pipedrive.com/en/features/ai-sales-assistant
- Pipedrive Workflow Automation: https://www.pipedrive.com/en/features/workflow-automation
- Kommo WhatsApp CRM: https://www.kommo.com/whatsapp/
- Kommo Salesbot: https://www.kommo.com/salesbot/
- Kommo WhatsApp for Sales: https://www.kommo.com/whatsapp/whatsapp-for-sales/
- Salesforce Sales Cloud: https://www.salesforce.com/sales/cloud/
- Salesforce Agentforce: https://www.salesforce.com/agentforce/
- Salesforce Service Cloud: https://www.salesforce.com/service/cloud/guide/

## 17. Внутренние артефакты проекта, использованные как основа

- `README.md`
- `docs/offline_first_phase1.md`
- `lib/main.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/dashboard/dashboard_screen.dart`
- `lib/api/service/api_service.dart`
- `lib/page_2/warehouse/warehouse_screen.dart`
- `lib/page_2/order/order_screen.dart`
- `lib/page_2/call_center/call_center_screen.dart`
- `lib/screens/analytics/analytics_screen.dart`
- `lib/in_app_update_service.dart`
- `lib/api/service/widget_service.dart`
- `lib/api/service/biometric_service.dart`
