import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:crm_task_manager/models/lead/LeadStatusForFilter.dart';
import 'package:crm_task_manager/models/common/api_exception_model.dart';
import 'package:crm_task_manager/models/user/author_data_response.dart';
import 'package:crm_task_manager/models/event/calendar_model.dart';
import 'package:crm_task_manager/models/common/file_helper.dart';
import 'package:crm_task_manager/models/settings/localization_model.dart';
import 'package:crm_task_manager/models/task/task_overdue_history_model.dart';
import 'package:crm_task_manager/models/workday/timesheet_models.dart';
import 'package:crm_task_manager/models/workday/workday_status_model.dart';
import 'package:crm_task_manager/services/workday_profile_redirect_service.dart';
import 'package:crm_task_manager/models/money/add_cash_desk_model.dart';
import 'package:crm_task_manager/models/money/cash_register_model.dart';
import 'package:crm_task_manager/models/money/expense_model.dart';
import 'package:crm_task_manager/models/money/add_expense_model.dart';
import 'package:crm_task_manager/models/money/income_model.dart';
import 'package:crm_task_manager/models/money/add_income_model.dart';
import 'package:crm_task_manager/models/chat/chatById_model.dart';
import 'package:crm_task_manager/models/chat/chat_messages_page.dart';
import 'package:crm_task_manager/models/chat/chatGetId_model.dart';
import 'package:crm_task_manager/models/chat/chatTaskProfile_model.dart';
import 'package:crm_task_manager/models/lead/city_model.dart';
import 'package:crm_task_manager/models/lead/contact_person_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/deal_stats_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_conversion_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_chart_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/process_speed%20_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/user_task%20_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/deal_stats_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/lead_chart_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/lead_conversion_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/process_speed%20_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/task_chart_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/user_task_model.dart';
import 'package:crm_task_manager/models/deal/deal_name_list.dart';
import 'package:crm_task_manager/models/deal/deal_task_model.dart';
import 'package:crm_task_manager/models/user/department.dart';
import 'package:crm_task_manager/models/task/directory_link_model.dart';
import 'package:crm_task_manager/models/task/directory_model.dart';
import 'package:crm_task_manager/models/event/event_by_Id_model.dart';
import 'package:crm_task_manager/models/event/event_model.dart';
import 'package:crm_task_manager/utils/global_value.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';
import 'package:crm_task_manager/models/my_task/history_model_my-task.dart';
import 'package:crm_task_manager/models/common/integration_model.dart';
import 'package:crm_task_manager/models/lead/lead_deal_model.dart';
import 'package:crm_task_manager/models/lead/lead_filter_channel_model.dart';
import 'package:crm_task_manager/models/lead/lead_list_model.dart';
import 'package:crm_task_manager/models/lead/lead_multi_model.dart' hide LeadData;
import 'package:crm_task_manager/models/lead/lead_navigate_to_chat.dart'
    hide Integration;
import 'package:crm_task_manager/models/field/main_field_model.dart';
import 'package:crm_task_manager/models/lead/manager_model.dart';
import 'package:crm_task_manager/models/settings/mini_app_settiings.dart';
import 'package:crm_task_manager/models/my_task/my-task_Status_Name_model.dart';
import 'package:crm_task_manager/models/my_task/my-task_model.dart';
import 'package:crm_task_manager/models/my_task/my-taskbyId_model.dart';
import 'package:crm_task_manager/models/event/notice_history_model.dart';
import 'package:crm_task_manager/models/event/notice_sms_sample_model.dart';
import 'package:crm_task_manager/models/event/notice_subject_model.dart';
import 'package:crm_task_manager/models/notification/notifications_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/task_chart_model.dart';
import 'package:crm_task_manager/screens/analytics/models/dashboard_statistics_model.dart';
import 'package:crm_task_manager/screens/analytics/models/deals_by_managers_model.dart';
import 'package:crm_task_manager/screens/analytics/models/lead_chart_model.dart';
import 'package:crm_task_manager/screens/analytics/models/lead_conversion_by_statuses_model.dart';
import 'package:crm_task_manager/screens/analytics/models/lead_process_speed_model.dart';
import 'package:crm_task_manager/screens/analytics/models/lead_channels_model.dart';
import 'package:crm_task_manager/screens/analytics/models/message_stats_model.dart';
import 'package:crm_task_manager/screens/analytics/models/online_store_orders_model.dart';
import 'package:crm_task_manager/screens/analytics/models/source_of_leads_model.dart';
import 'package:crm_task_manager/screens/analytics/models/task_chart_v2_model.dart';
import 'package:crm_task_manager/screens/analytics/models/top_selling_products_model.dart';
import 'package:crm_task_manager/screens/analytics/models/users_chart_model.dart';
import 'package:crm_task_manager/screens/analytics/models/completed_tasks_model.dart';
import 'package:crm_task_manager/screens/analytics/models/telephony_events_model.dart';
import 'package:crm_task_manager/screens/analytics/models/replies_messages_model.dart';
import 'package:crm_task_manager/screens/analytics/models/task_stats_by_project_model.dart';
import 'package:crm_task_manager/screens/analytics/models/connected_accounts_model.dart';
import 'package:crm_task_manager/screens/analytics/models/advertising_roi_model.dart';
import 'package:crm_task_manager/screens/analytics/models/telephony_by_hour_model.dart';
import 'package:crm_task_manager/screens/analytics/models/targeted_ads_model.dart';
import 'package:crm_task_manager/screens/analytics/models/dashboard_setting_item.dart';
import 'package:crm_task_manager/models/user/organization_model.dart';
import 'package:crm_task_manager/models/task/overdue_task_response.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/models/page_2/call_analytics_model.dart';
import 'package:crm_task_manager/models/page_2/call_center_by_id_model.dart';
import 'package:crm_task_manager/models/page_2/call_center_model.dart';
import 'package:crm_task_manager/models/page_2/call_statistics1_model.dart';
import 'package:crm_task_manager/models/page_2/call_summary_stats_model.dart';
import 'package:crm_task_manager/models/page_2/category_dashboard_warehouse_model.dart';
import 'package:crm_task_manager/models/field/field_configuration.dart';
import 'package:crm_task_manager/models/page_2/expense_details_document_model.dart'
    as expDoc;
import 'package:crm_task_manager/models/page_2/expense_document_model.dart'
    as expense;
import 'package:crm_task_manager/models/page_2/opening_supplier_model.dart'
    as opening_supplier;
import 'package:crm_task_manager/models/page_2/openings/client_dialog_model.dart'
    as opening_lead;
import 'package:crm_task_manager/models/page_2/order_status_warehouse_model.dart';
import 'package:crm_task_manager/models/page_2/expense_article_dashboard_warehouse_model.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/models/page_2/character_list_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/dashboard_goods_report.dart';
import 'package:crm_task_manager/models/page_2/dashboard/cash_balance_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/dashboard_top.dart';
import 'package:crm_task_manager/models/page_2/dashboard/debtors_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/creditors_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/illiquids_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/manufacture_report_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/salary_report_model.dart';
import 'package:crm_task_manager/models/page_2/delivery_address_model.dart';
import 'package:crm_task_manager/models/page_2/good_dashboard_warehouse_model.dart'
    as dgrmodel;
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_history_model.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/models/page_2/label_list_model.dart';
import 'package:crm_task_manager/models/page_2/lead_order_model.dart';
import 'package:crm_task_manager/models/page_2/measure_unit_model.dart';
import 'package:crm_task_manager/models/page_2/monthly_call_stats.dart';
import 'package:crm_task_manager/models/page_2/operator_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/order_history_model.dart';
import 'package:crm_task_manager/models/page_2/order_internet_store_model.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
import 'package:crm_task_manager/models/page_2/price_type_model.dart';
import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryById.dart';
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/models/page_2/openings/goods_openings_model.dart';
import 'package:crm_task_manager/models/page_2/openings/supplier_openings_model.dart';
import 'package:crm_task_manager/models/page_2/openings/client_openings_model.dart';
import 'package:crm_task_manager/models/page_2/openings/cash_register_openings_model.dart'
    as openings;
import 'package:crm_task_manager/models/page_2/good_variants_model.dart';
import 'package:crm_task_manager/models/money/price_type_model.dart';
import 'package:crm_task_manager/models/task/project_task_model.dart';
import 'package:crm_task_manager/models/sales_funnel/sales_funnel_model.dart';
import 'package:crm_task_manager/models/lead/source_list_model.dart';
import 'package:crm_task_manager/models/lead/advertising_campaign_model.dart';
import 'package:crm_task_manager/models/lead/source_model.dart';
import 'package:crm_task_manager/models/common/supplier_list_model.dart';
import 'package:crm_task_manager/models/task/task_Status_Name_model.dart';
import 'package:crm_task_manager/models/chat/chats_model.dart' hide Integration;
import 'package:crm_task_manager/models/deal/dealById_model.dart';
import 'package:crm_task_manager/models/deal/deal_history_model.dart';
import 'package:crm_task_manager/models/deal/deal_model.dart';
import 'package:crm_task_manager/models/lead/lead_history_model.dart';
import 'package:crm_task_manager/models/lead/lead_sms_model.dart';
import 'package:crm_task_manager/models/task/history_model_task.dart';
import 'package:crm_task_manager/models/lead/leadById_model.dart' hide Integration;
import 'package:crm_task_manager/models/lead/lead_model.dart';
import 'package:crm_task_manager/models/lead/notes_model.dart';
import 'package:crm_task_manager/models/common/pagination_dto.dart';
import 'package:crm_task_manager/models/task/project_model.dart';
import 'package:crm_task_manager/models/lead/region_model.dart';
import 'package:crm_task_manager/models/lead/reason_for_refusal_model.dart';
import 'package:crm_task_manager/models/user/role_model.dart';
import 'package:crm_task_manager/models/task/task_model.dart';
import 'package:crm_task_manager/models/task/taskbyId_model.dart' hide ChatById;
import 'package:crm_task_manager/models/chat/template_model.dart';
import 'package:crm_task_manager/models/user/user_byId_model..dart';
import 'package:crm_task_manager/models/user/user_data_response.dart';
import 'package:crm_task_manager/models/user/user_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_edit_screen.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/task_dropdown_bottom_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/money/batch_model.dart';
import '../../models/money/cash_register_list_model.dart';
import '../../models/page_2/dashboard_goods_movement_history_model.dart';
import '../../models/auth/domain_check.dart';
import '../../models/money/income_categories_data_response.dart';
import '../../models/auth/login_model.dart';
import '../../models/money/money_income_document_model.dart';
import '../../models/money/employee_remaining_model.dart';
import '../../models/money/money_outcome_document_model.dart';
import '../../models/money/outcome_categories_data_response.dart';
import '../../models/page_2/dashboard/act_of_reconciliation_model.dart';
import '../../models/page_2/dashboard/expense_structure.dart';
import '../../models/page_2/dashboard/net_profit_model.dart';
import '../../models/page_2/dashboard/order_dashboard_model.dart';
import '../../models/page_2/dashboard/order_quantity_content.dart';
import '../../models/page_2/dashboard/profitability_dashboard_model.dart';
import '../../models/page_2/dashboard/sales_model.dart';
import '../../models/page_2/dashboard/net_profit_content_model.dart';
import '../../models/page_2/dashboard/profitability_content_model.dart';
import '../../models/page_2/dashboard/expense_structure_content.dart';
import '../../models/page_2/dashboard/top_selling_card_model.dart';
import '../../models/page_2/dashboard/top_selling_model.dart';

// HTTP Inspector imports (только для DEBUG)
import 'http/http_logger.dart';
import 'http/http_log_model.dart';
import 'http/dio_client.dart';

// final String baseUrl = 'https://fingroup-back.shamcrm.com/api';
// final String baseUrl = 'https://ede8-95-142-94-22.ngrok-free.app';

// final String baseUrlSocket ='https://fingroup-back.shamcrm.com/broadcasting/auth';

part 'core/api_service_base.dart';
part 'core/api_http.dart';
part 'core/api_session.dart';
part 'core/api_init.dart';
part 'core/api_misc.dart';
part 'auth/api_auth.dart';
part 'workday/api_workday.dart';
part 'fcm/api_fcm_voip.dart';
part 'organization/api_organization.dart';
part 'leads/api_leads.dart';
part 'deals/api_deals.dart';
part 'tasks/api_tasks.dart';
part 'my_tasks/api_my_tasks.dart';
part 'chats/api_chats.dart';
part 'analytics/api_analytics.dart';
part 'notifications/api_notifications.dart';
part 'events/api_events.dart';
part 'warehouse/api_catalog.dart';
part 'warehouse/api_documents.dart';
part 'warehouse/api_orders.dart';
part 'warehouse/api_dashboards.dart';
part 'warehouse/api_call_center.dart';
part 'cash/api_cash.dart';
part 'sales_plan/api_sales_plan.dart';
part 'localization/api_localization.dart';

class ApiService extends ApiServiceBase {
  static const Duration _defaultRequestTimeout = Duration(seconds: 20);
  static const Duration _slowListRequestTimeout = Duration(seconds: 45);

  static const String workdayReadPermission = 'timesheet.read';

  static const Set<String> _tojsokhtmontjSubdomains = {
    'tojsokhtmontj',
    'tojsokhtmontj-back',
    'tojsokhtmontj-new-back',
    'tojsokhtmontj-new',
  };

  static const Set<String> _stomatradeSubdomains = {
    'stomatrade',
    'stomatrade-back',
    'stomatrade-new',
    'stomatrade-new-back',
  };

  static const Set<String> _fuzaylovazamSubdomains = {
    'fuzaylovazam7gmailcom',
    'fuzaylovazam7gmailcom-back',
    'fuzaylovazam7gmailcom-new',
    'fuzaylovazam7gmailcom-new-back',
  };

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static DateTime? _lastWorkdayWarningAt;

  static bool _isWorkdayRedirectInProgress = false;

  static bool _isForceLogoutInProgress = false;

  static const List<String> _noSessionCheckEndpoints = [
    '/login',
    '/get-user-by-email',
    '/checkDomain',
    // '/add-fcm-token',
  ];

  static Map<String, dynamic>? _analyticsFilters;

  static final Map<String, String> _analyticsResponseCache = {};

  static const String _pendingFcmKey = 'pending_fcm_token';

  static const String _pendingVoipKey = 'pending_ios_voip_token';

  static const String _voipSyncStatusKey = 'ios_voip_sync_status';

  static const String _voipSyncAtKey = 'ios_voip_sync_at';

  static const String _voipSyncHttpCodeKey = 'ios_voip_sync_http_code';

  static const String _voipSyncErrorKey = 'ios_voip_sync_error';

  static const List<String> _excludedEndpoints = [
    '/login',
    '/checkDomain',
    '/logout',
    '/forgotPin',
    '/add-fcm-token',
  ];

  ApiService() {
    _initializeIfDomainExists();
  }

  static void setAnalyticsFilters(Map<String, dynamic>? filters) {
    if (filters == null) {
      _analyticsFilters = null;
      return;
    }
    _analyticsFilters = Map<String, dynamic>.from(filters);
  }

  static void clearAnalyticsFilters() {
    _analyticsFilters = null;
  }

  static void clearAnalyticsResponseCache() {
    _analyticsResponseCache.clear();
  }
}

class OrderStatusUpdateException implements Exception {
  final int statusCode;
  final String message;

  OrderStatusUpdateException(this.statusCode, this.message);

  @override
  String toString() => 'OrderStatusUpdateException($statusCode, $message)';
}
