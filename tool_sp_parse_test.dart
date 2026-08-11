import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';

void main() {
  final json = {
    "result": {
      "data": [
        {
          "id": 1,
          "name": "Сделки — Сумма сделки",
          "plan_type": "sum",
          "object_type": "deals",
          "aggregation": "sum_field",
          "aggregation_field": "sum",
          "target_value": 100000000,
          "actual_value": 11500000,
          "percent": 11.5,
          "status": "active",
          "period_type": "month",
          "period_start": "2026-08-01",
          "period_end": "2026-08-31",
          "days_left": 20,
          "days_total": 31,
          "daily_average": 1045454.55,
          "daily_need": 4425000,
          "forecast": 32409091.05,
          "forecast_percent": 32.41,
          "recurrence": "monthly",
          "comment": null,
          "users": [
            {
              "id": 2,
              "name": "Абубакр",
              "lastname": "Ахмедов",
              "full_name": "Абубакр Ахмедов",
              "actual_value": 11500000,
              "percent": 11.5
            }
          ],
          "filters": [],
          "creator": {"id": 1, "name": "Admin"},
          "created_at": "2026-08-05T12:28:11.000000Z"
        }
      ],
      "pagination": {
        "total": 1,
        "count": 1,
        "per_page": 20,
        "current_page": 1,
        "total_pages": 1
      }
    }
  };
  final parsed = SalesPlanListResponse.fromJson(Map<String, dynamic>.from(json));
  print("count=${parsed.data.length} total=${parsed.total} name=${parsed.data.first.name} pct=${parsed.data.first.percent} children=${parsed.data.first.children.length}");
}
