import 'package:crm_task_manager/core/platform/app_platform.dart';

/// Флаги видимости разделов приложения.
const bool kShowRmk = true;
const bool kShowRmkSales = true;
const bool kShowSip = true;
const bool kShowSalesPlanning = true;

bool get sipEnabled => kShowSip && !AppPlatform.isDesktop;
