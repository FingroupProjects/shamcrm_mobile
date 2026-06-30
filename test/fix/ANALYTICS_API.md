## Аналитика: подключено в приложении

Ниже — графики и карточки, которые сейчас используются в разделе аналитики.

1. **Статистика (4 карточки вверху)**
   URL: `{{base_url}}/api/v2/dashboard/statistics?organization_id={{organization_id}}`
   Пример ответа:
   ```json
   {
     "result": {
       "leads": { "count": 2556, "procent": -89.83 },
       "deals": { "count": 86, "procent": -100 },
       "totalSum": { "count": "528621.80", "procent": -100 },
       "conversion": { "count": 3.36, "procent": -100 }
     },
     "errors": null
   }
   ```

2. **Конверсия лидов (по месяцам)**
   URL: `{{base_url}}/api/v2/dashboard/leadConversion-chart?organization_id={{organization_id}}`
   Пример ответа:
   ```json
   {
     "result": [0,0,0,0,0,0,0,0,0,0,0,0],
     "errors": null
   }
   ```

3. **Источники лидов**
   URL: `{{base_url}}/api/v2/dashboard/source-of-leads-chart?organization_id={{organization_id}}`
   Пример ответа:
   ```json
   {
     "result": {
       "sources": {
         "Демо версия из сайта": 105,
         "WhatsApp": 1777,
         "Телефон": 79
       },
       "best_source": "WhatsApp",
       "total_sources": 14
     },
     "errors": null
   }
   ```

4. **Сделки по менеджерам**
   URL: `{{base_url}}/api/v2/dashboard/deals-by-managers?organization_id={{organization_id}}`
   Пример ответа:
   ```json
   {
     "result": {
       "managers": [
         {
           "manager_name": "Махмуджон",
           "total_deals": 40,
           "successful_deals": 14,
           "total_sum": 24891833,
           "successful_sum": 24794484
         }
       ],
       "best_manager": "Махмуджон",
       "total_revenue": 25309696,
       "total_managers": 5
     },
     "errors": null
   }
   ```

5. **Скорость обработки лидов**
   URL: `{{base_url}}/api/v2/dashboard/lead-process-speed?organization_id={{organization_id}}`
   Пример ответа:
   ```json
   {
     "result": {
       "average_processing_speed": 2381.69,
       "leads_format": "hours",
       "deals_format": "days"
     },
     "errors": null
   }
   ```

6. **KPI задач**
   URL: `{{base_url}}/api/v2/dashboard/task-chart?organization_id={{organization_id}}`
   Пример ответа:
   ```json
   {
     "result": {
       "data": [35, 48, 129],
       "overall_kpi": 61,
       "completed_tasks": 129,
       "total_tasks": 212
     },
     "errors": null
   }
   ```

7. **Выполнение целей (по сотрудникам)**
   URL: `{{base_url}}/api/v2/dashboard/users-chart?organization_id={{organization_id}}`
   Пример ответа (сокращено):
   ```json
   {
     "result": {
       "users": [
         { "name": "Носиров", "user_id": 47, "finishedTasksprocent": 100, "status": "best" }
       ],
       "average_kpi": 48,
       "requires_attention_count": 12
     },
     "errors": null
   }
   ```

8. **Заказы интернет-магазина**
   URL: `{{base_url}}/api/v2/dashboard/online-store-orders-chart?organization_id={{organization_id}}`
   Пример ответа:
   ```json
   {
     "result": {
       "total_orders": 5,
       "successful_orders": 0,
       "success_rate": 0,
       "average_check": 24.4,
       "revenue": 122,
       "chart_data": [
         { "month": 10, "total_orders": 1, "successful_orders": 0, "canceled_orders": 0 }
       ]
     },
     "errors": null
   }
   ```

9. **ТОП продаваемых товаров**
   URL: `{{base_url}}/api/v2/dashboard/top-selling-products-chart?organization_id={{organization_id}}`
   Пример ответа (сокращено):
   ```json
   {
     "result": {
       "top": { "name": "Телевизор", "sales": 0, "revenue": 0, "revenue_formatted": "0 сум" },
       "list": [
         { "good_id": 23, "name": "Телевизор", "total_sold": 4, "successful": 0, "cancelled": 0 }
       ]
     },
     "errors": null
   }
   ```

## Аналитика: есть на сервере, но пока не используется в приложении

1. **Лиды по статусам (график)**
   URL: `{{base_url}}/api/dashboard/lead-chart?organization_id={{organization_id}}&fromDate=2025-01-01&toDate=2025-12-31`
   Пример ответа (сокращено):
   ```json
   [
     { "status": "Неизвестный", "color": "#4ae6b3", "data": [2, 20] }
   ]
   ```

2. **Сделки (статистика по месяцам)**
   URL: `{{base_url}}/api/dashboard/dealStats?organization_id={{organization_id}}`
   Пример ответа (сокращено):
   ```json
   { "result": { "data": [ { "total_sum": 179346, "successful_sum": 37080 } ] }, "errors": null }
   ```

3. **Детализация конверсии лидов**
   URL: `{{base_url}}/api/v2/dashboard/leadConversion-more-details?organization_id={{organization_id}}`
   Пример ответа (сокращено):
   ```json
   { "result": { "data": [ { "id": 654, "name": "Бобохони Шониёзиён" } ] } }
   ```

4. **Конверсия по статусам**
   URL: `{{base_url}}/api/v2/dashboard/leadConversion-by-statuses-chart?organization_id={{organization_id}}`
   Пример ответа (сокращено):
   ```json
   { "result": { "statuses": [ { "status_name": "Неизвестный", "total_leads": 215 } ] } }
   ```

5. **Скорость обработки лидов — детализация**
   URL: `{{base_url}}/api/v2/dashboard/lead-process-speed-more-details?organization_id={{organization_id}}`
   Пример ответа (сокращено):
   ```json
   { "result": { "data": [ { "id": 4705, "created_at": "2026-02-07 23:12:07" } ] } }
   ```

6. **Каналы лидов (старый эндпоинт)**
   URL: `{{base_url}}/api/dashboard/lead-channels?organization_id={{organization_id}}`
   Пример ответа (сокращено):
   ```json
   { "result": [ { "id": 1, "name": "WhatsApp", "count": 62 } ], "errors": null }
   ```

7. **Статистика сообщений**
   URL: `{{base_url}}/api/dashboard/message-stats?organization_id={{organization_id}}`
   Пример ответа (сокращено):
   ```json
   { "result": [ { "name": "WhatsApp", "received": 191, "sent": 134 } ], "errors": null }
   ```

8. **Пользователи — детализация**
   URL: `{{base_url}}/api/v2/dashboard/users-more-details?organization_id={{organization_id}}`
   Пример ответа (сокращено):
   ```json
   { "result": { "data": [ { "id": 1, "name": "Стратегия 2025 Душанбе/Худжанд/Ташкент" } ] } }
   ```

9. **Выполненные задачи (график)**
   URL: `{{base_url}}/api/v2/dashboard/completed-task-chart?organization_id={{organization_id}}`
   Пример ответа:
   ```json
   { "result": [0,0,0,0,0,0,0,0,0,0,0,0], "errors": null }
   ```

10. **Источники лидов — детализация**
    URL: `{{base_url}}/api/v2/dashboard/source-of-leads-more-details?organization_id={{organization_id}}`
    Пример ответа (сокращено):
    ```json
    { "result": [ { "id": 1, "name": "WhatsApp", "total_leads": 2237 } ], "errors": null }
    ```

11. **Сделки по менеджерам — детализация**
    URL: `{{base_url}}/api/v2/dashboard/deals-by-managers-more-details?organization_id={{organization_id}}`
    Пример ответа (сокращено):
    ```json
    { "result": [ { "id": 1, "total_deals": 69, "full_name": "Махмуджон Ахмедов" } ] }
    ```

12. **Телефония и события (график)**
    URL: `{{base_url}}/api/v2/dashboard/telephony-and-events-chart?organization_id={{organization_id}}`
    Пример ответа (сокращено):
    ```json
    { "result": { "chart": [ { "day": 1, "incoming": 0, "outgoing": 0 } ] } }
    ```

13. **Телефония и события — детализация**
    URL: `{{base_url}}/api/v2/dashboard/telephony-and-events-more-details?organization_id={{organization_id}}`
    Пример ответа:
    ```json
    { "result": { "allCalls": 2176, "allMissed": 1189 } }
    ```

14. **Ответы на сообщения (график)**
    URL: `{{base_url}}/api/v2/dashboard/replies-to-messages-chart?organization_id={{organization_id}}`
    Пример ответа (сокращено):
    ```json
    { "result": { "by_channel": [ { "channel_name": "whatsapp", "sent_messages": 3393 } ] } }
    ```

15. **Статистика задач по проектам**
    URL: `{{base_url}}/api/v2/dashboard/task-statistics-by-project-chart?organization_id={{organization_id}}`
    Пример ответа (сокращено):
    ```json
    { "result": [ { "project_name": "FIN-group", "total_tasks": 445 } ], "errors": null }
    ```

16. **Подключенные аккаунты**
    URL: `{{base_url}}/api/v2/dashboard/connected-accounts-chart?organization_id={{organization_id}}`
    Пример ответа (сокращено):
    ```json
    { "result": { "totals": { "total_accounts": 20, "active_accounts": 5 } } }
    ```

17. **ROI рекламы (график)**
    URL: `{{base_url}}/api/v2/dashboard/advertising-ROI-chart?organization_id={{organization_id}}`
    Пример ответа (сокращено):
    ```json
    { "result": { "summary": { "total_spent": 1800, "roi": 61.7 } } }
    ```

18. **ROI рекламы — детализация**
    URL: `{{base_url}}/api/v2/dashboard/advertising-ROI-chart-more-details?organization_id={{organization_id}}`
    Пример ответа (сокращено):
    ```json
    { "result": { "data": [ { "campaign_id": 61, "campaign_name": "Fingroupit" } ] } }
    ```
