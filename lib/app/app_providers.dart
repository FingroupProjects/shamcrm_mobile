import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/storage/secure_storage_service.dart';
import 'package:crm_task_manager/bloc/My-Task_Status_Name/statusName_bloc.dart';
import 'package:crm_task_manager/bloc/Task_Status_Name/statusName_bloc.dart';
import 'package:crm_task_manager/bloc/advertising_campaign_list/advertising_campaign_bloc.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/forgot_auth_bloc.dart';
import 'package:crm_task_manager/bloc/auth_domain/domain_bloc.dart';
import 'package:crm_task_manager/bloc/author/get_all_author_bloc.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_bloc.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_bloc.dart';
import 'package:crm_task_manager/bloc/call_bloc/operator_bloc/operator_bloc.dart';
import 'package:crm_task_manager/bloc/cash_desk/cash_desk_bloc.dart';
import 'package:crm_task_manager/bloc/cash_register_list/cash_register_list_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_task_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/bloc/chats/delete_message/delete_message_bloc.dart';
import 'package:crm_task_manager/bloc/chats/groupe_chat/group_chat_bloc.dart';
import 'package:crm_task_manager/bloc/chats/template_bloc/template_bloc.dart';
import 'package:crm_task_manager/bloc/city_list/city_bloc.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_bloc.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_file_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_text_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_voice_cubit.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/lead_chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_task_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/conversion/conversion_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/dealStats/dealStats_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/lead_chart/chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/process_speed/ProcessSpeed_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/task_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/user_task/user_task_bloc.dart';
import 'package:crm_task_manager/bloc/data_1c/data_1c_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_bloc.dart';
import 'package:crm_task_manager/bloc/deal_name_list_bloc/deal_name_list_bloc.dart';
import 'package:crm_task_manager/bloc/deal_task/deal_task_bloc.dart';
import 'package:crm_task_manager/bloc/directory_bloc/directory_bloc.dart';
import 'package:crm_task_manager/bloc/event/event_bloc.dart';
import 'package:crm_task_manager/bloc/eventByID/event_byId_bloc.dart';
import 'package:crm_task_manager/bloc/expense/expense_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/history_deal/deal_history_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead/history_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_bloc.dart';
import 'package:crm_task_manager/bloc/history_my-task/task_history_bloc.dart';
import 'package:crm_task_manager/bloc/history_task/task_history_bloc.dart';
import 'package:crm_task_manager/bloc/income/income_bloc.dart';
import 'package:crm_task_manager/bloc/income_category_list/income_category_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_bloc.dart';
import 'package:crm_task_manager/bloc/lead_channel_list/lead_channel_bloc.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_multi_list/lead_multi_bloc.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_bloc.dart';
import 'package:crm_task_manager/bloc/lead_status_for_filter/lead_status_for_filter_bloc.dart';
import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_bloc.dart';
import 'package:crm_task_manager/bloc/login/login_bloc.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task_by_id/taskById_bloc.dart';
import 'package:crm_task_manager/bloc/my-task_status_add/task_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_bloc.dart';
import 'package:crm_task_manager/bloc/notifications/notifications_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_by_id/catgeoryById_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/cash_balance/sales_dashboard_cash_balance_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/category_dashboard_warehouse/category_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/creditors/sales_dashboard_creditors_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/debtors/sales_dashboard_debtors_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/good_dashboard_warehouse/good_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/goods/sales_dashboard_goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/sales_dashboard_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/deliviry_adress/delivery_address_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/client_return/client_return_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/client_sale/bloc/client_sale_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/client_sale/bloc/client_sale_document_history/bloc/client_sale_document_history_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/article_bloc/expense_article_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_document_history/incoming_document_history_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/storage_bloc/storage_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/units_bloc/units_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/manufacture/manufacture_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/measure_units/measure_units_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/movement/movement_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/price_type/bloc/price_type_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/storage/bloc/storage_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/supplier_return/supplier_return_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/write_off/write_off_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_by_id/goodsById_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/label/label_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/lead_order.dart/lead_order_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_history/history_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bottom_sheet_bloc/variant_bottom_sheet_bloc.dart';
import 'package:crm_task_manager/bloc/permission/permession_bloc.dart';
import 'package:crm_task_manager/bloc/pricce_type/price_type_bloc.dart';
import 'package:crm_task_manager/bloc/profile/profile_bloc.dart';
import 'package:crm_task_manager/bloc/project/project_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_bloc.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:crm_task_manager/bloc/role/role_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_bloc.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_bloc.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_dashboard_bloc.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_detail_bloc.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_leaderboard_bloc.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_bloc.dart';
import 'package:crm_task_manager/bloc/source_list/source_bloc.dart';
import 'package:crm_task_manager/bloc/supplier_list/supplier_list_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task_add_from_deal/task_add_from_deal_bloc.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_bloc.dart';
import 'package:crm_task_manager/bloc/task_overdue_history/task_overdue_history_bloc.dart';
import 'package:crm_task_manager/bloc/task_status_add/task_bloc.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/bloc/user/create_cleant/create_client_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> createAppProviders({
  required ApiService apiService,
  required AuthService authService,
}) {
  return [
    ChangeNotifierProvider<AppThemeController>.value(
      value: AppThemeController.instance,
    ),
    Provider<ApiService>.value(value: apiService),
    Provider<AuthService>.value(value: authService),
    BlocProvider(create: (context) => DomainBloc(apiService)),
    BlocProvider(create: (context) => LoginBloc(apiService)),
    BlocProvider(create: (context) => LeadBloc(apiService)),
    BlocProvider(create: (context) => HistoryBloc(apiService)),
    BlocProvider(create: (context) => NotesBloc(apiService)),
    BlocProvider(create: (context) => GetAllManagerBloc()),
    BlocProvider(create: (context) => GetAllRegionBloc()),
    BlocProvider(create: (context) => GetAllCityBloc()),
    BlocProvider(create: (context) => GetAllSourceBloc()),
    BlocProvider(create: (context) => GetAllLeadChannelBloc()),
    BlocProvider(create: (context) => GetAllAdvertisingCampaignBloc()),
    BlocProvider(create: (context) => GetAllLeadBloc(apiService: apiService)),
    BlocProvider(create: (context) => GetAllCashRegisterBloc()),
    BlocProvider(create: (context) => GetAllIncomeCategoryBloc()),
    BlocProvider(create: (context) => GetAllSupplierBloc()),
    BlocProvider(create: (context) => GetAllRegionBloc()),
    BlocProvider(create: (context) => GetAllLeadMultiBloc()),
    BlocProvider(create: (context) => DealBloc(apiService)),
    BlocProvider(create: (context) => TaskBloc(apiService)),
    BlocProvider(create: (context) => MyTaskBloc(apiService)),
    BlocProvider(create: (context) => GetTaskProjectBloc()),
    BlocProvider(create: (context) => GetAllProjectBloc()),
    BlocProvider(create: (context) => UserTaskBloc(apiService)),
    BlocProvider(create: (context) => HistoryBlocTask(apiService)),
    BlocProvider(create: (context) => TaskOverdueHistoryBloc(apiService)),
    BlocProvider(create: (context) => HistoryLeadsBloc(apiService)),
    BlocProvider(create: (context) => HistoryBlocMyTask(apiService)),
    BlocProvider(create: (context) => RoleBloc(apiService)),
    BlocProvider(create: (context) => TaskStatusNameBloc(apiService)),
    BlocProvider(create: (context) => MyTaskMyStatusNameBloc(apiService)),
    BlocProvider(create: (context) => LeadByIdBloc(apiService)),
    BlocProvider(create: (context) => DealByIdBloc(apiService)),
    BlocProvider(create: (context) => TaskByIdBloc(apiService)),
    BlocProvider(create: (context) => MyTaskByIdBloc(apiService)),
    BlocProvider(create: (context) => DealHistoryBloc(apiService)),
    BlocProvider(create: (context) => GetAllClientBloc(apiService: apiService)),
    BlocProvider(create: (context) => GetAllAuthorBloc(apiService: apiService)),
    BlocProvider(create: (context) => CreateClientBloc()),
    BlocProvider(create: (context) => GroupChatBloc(apiService)),
    BlocProvider(create: (context) => DeleteMessageBloc(ApiService())),
    BlocProvider(create: (context) => ListenSenderTextCubit()),
    BlocProvider(create: (context) => ListenSenderVoiceCubit()),
    BlocProvider(create: (context) => ListenSenderFileCubit()),
    BlocProvider(create: (context) => ChatsBloc(apiService),),
    BlocProvider(create: (context) => TaskStatusBloc(ApiService())),
    BlocProvider(create: (context) => MyTaskStatusBloc(ApiService())),
    BlocProvider(create: (context) => OrganizationBloc(ApiService())),
    BlocProvider(create: (context) => NotificationBloc(ApiService())),
    BlocProvider(create: (context) => ChatsBloc(apiService),),
    BlocProvider(create: (context) => TaskStatusBloc(ApiService())),
    BlocProvider(create: (context) => DashboardChartBloc(ApiService())),
    BlocProvider(  create: (context) => DashboardChartBlocManager(ApiService())),
    BlocProvider(create: (context) => DashboardConversionBloc(ApiService())),
    BlocProvider(create: (context) => DashboardConversionBlocManager(ApiService())),
    BlocProvider(create: (context) => UserBlocManager(ApiService())),
    BlocProvider(create: (context) => DealStatsBloc(ApiService())),
    BlocProvider(create: (context) => DealStatsManagerBloc(ApiService())),
    BlocProvider(create: (context) => DashboardTaskChartBloc(ApiService())),
    BlocProvider( create: (context) => DashboardTaskChartBlocManager(ApiService())),
    BlocProvider(create: (context) => LeadDealsBloc(ApiService())),
    BlocProvider(create: (context) => DealTasksBloc(ApiService())),
    BlocProvider(create: (context) => ProcessSpeedBlocManager(ApiService())),
    BlocProvider(create: (context) => ContactPersonBloc(ApiService())),
    BlocProvider(create: (context) => LeadToChatBloc(apiService)),
    BlocProvider(create: (context) => ChatProfileBloc(ApiService())),
    BlocProvider(create: (context) => TaskProfileBloc(ApiService())),
    BlocProvider(create: (context) => PermissionsBloc(ApiService())),
    BlocProvider( create: (context) => ForgotPinBloc(apiService: ApiService())),
    BlocProvider(create: (context) => SourceLeadBloc(apiService)),
    BlocProvider(create: (context) => LeadToCBloc(apiService: apiService)),
    BlocProvider(create: (context) => Data1CBloc(apiService: apiService)),
    BlocProvider(create: (context) => ProfileBloc(apiService: apiService)),
    BlocProvider(create: (context) => ProcessSpeedBloc(apiService)),
    BlocProvider(create: (context) => TaskCompletionBloc(apiService)),
    BlocProvider( create: (context) => TaskAddFromDealBloc(apiService: ApiService())),
    BlocProvider(create: (context) => EventBloc(apiService)),
    BlocProvider(create: (context) => SalesPlanBloc(apiService)),
    BlocProvider(create: (context) => SalesPlanDetailBloc(apiService)),
    BlocProvider(create: (context) => SalesPlanDashboardBloc(apiService)),
    BlocProvider(create: (context) => SalesPlanLeaderboardBloc(apiService)),
    BlocProvider(create: (context) => NoticeBloc(apiService)),
    BlocProvider(create: (context) => GetAllSubjectBloc()),
    BlocProvider(create: (context) => GetAllDealNameBloc()),
    BlocProvider(create: (context) => CategoryBloc(apiService)),
    BlocProvider(create: (context) => CategoryByIdBloc(apiService)),
    BlocProvider(create: (context) => OrderBloc(apiService)),
    BlocProvider(create: (context) => GoodsBloc(apiService)),
    BlocProvider(create: (context) => GoodsByIdBloc(apiService)),
    BlocProvider(create: (context) => BranchBloc(apiService)),
    BlocProvider(create: (context) => DeliveryAddressBloc(apiService)),
    BlocProvider(create: (context) => LeadOrderBloc(apiService)),
    BlocProvider(create: (context) => CalendarBloc(apiService)),
    BlocProvider(create: (context) => OrderHistoryBloc(apiService)),
    BlocProvider(create: (context) => GetDirectoryBloc()),
    BlocProvider(create: (context) => OrderByLeadBloc(apiService)),
    BlocProvider(create: (context) => PriceTypeBloc(apiService)),
    BlocProvider(create: (context) => LabelBloc(apiService)),
    BlocProvider(create: (context) => VariantBloc(apiService)),
    BlocProvider(create: (context) => VariantBottomSheetBloc(apiService)),
    BlocProvider(create: (context) => CallCenterBloc(ApiService()),),
    BlocProvider(create: (context) => SalesFunnelBloc(ApiService())),
    BlocProvider(create: (context) => OperatorBloc(ApiService())),
    BlocProvider(create: (context) => TemplateBloc(ApiService())),
    BlocProvider(create: (context) => LeadStatusForFilterBloc(apiService)),
    BlocProvider(create: (context) => IncomingBloc(apiService)),
    BlocProvider<StorageBloc>(  create: (context) => StorageBloc(apiService), ),
    BlocProvider<UnitsBloc>(  create: (context) => UnitsBloc(apiService), ),
    BlocProvider<ExpenseArticleBloc>(  create: (context) => ExpenseArticleBloc(apiService),),
    BlocProvider<SupplierBloc>(  create: (context) => SupplierBloc(apiService),),
    BlocProvider<ClientSaleBloc>( create: (context) => ClientSaleBloc(apiService),),
    BlocProvider<ClientSaleDocumentHistoryBloc>(  create: (context) => ClientSaleDocumentHistoryBloc(apiService),),
    BlocProvider<IncomingDocumentHistoryBloc>( create: (context) =>    IncomingDocumentHistoryBloc(context.read<ApiService>()),),
    BlocProvider(create: (context) => ClientReturnBloc(apiService)),
    BlocProvider(create: (context) => SupplierBloc(apiService)),
    BlocProvider(create: (context) => MeasureUnitsBloc(apiService)),
    BlocProvider(create: (context) => WareHouseBloc(apiService)),
    BlocProvider(create: (context) => PriceTypeScreenBloc(apiService)),
    BlocProvider(create: (context) => SupplierReturnBloc(apiService)),
    BlocProvider(create: (context) => WriteOffBloc(apiService)),
    BlocProvider(create: (context) => MovementBloc(apiService)),
    BlocProvider(create: (context) => ManufactureBloc(apiService)),
    BlocProvider(create: (context) => CashDeskBloc()),
    BlocProvider(create: (context) => ExpenseBloc()),
    BlocProvider(create: (context) => IncomeBloc()),
    BlocProvider( create: (context) => CategoryDashboardWarehouseBloc(apiService)),
    BlocProvider( create: (context) => GoodDashboardWarehouseBloc(apiService)),
    BlocProvider(create: (context) => SalesDashboardBloc()),
    BlocProvider(create: (context) => SalesDashboardGoodsBloc()),
    BlocProvider(create: (context) => SalesDashboardCashBalanceBloc()),
    BlocProvider(create: (context) => SalesDashboardCreditorsBloc()),
    BlocProvider(create: (context) => SalesDashboardDebtorsBloc()),
    BlocProvider(create: (context) => FieldConfigurationBloc(apiService)),
  ];
}
