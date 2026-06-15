import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/top_selling_goods/sales_dashboard_top_selling_goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/goods_movement/sales_dashboard_goods_movement_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/goods_movement/sales_dashboard_goods_movement_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/manufacture_goods/sales_dashboard_manufacture_goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/manufacture_materials/sales_dashboard_manufacture_materials_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/order_quantity/sales_dashboard_order_quantity_bloc.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/page_2/dashboard/detailed_report/contents/cash_balance_content.dart';
import 'package:crm_task_manager/page_2/dashboard/detailed_report/contents/reconciliation_act_content.dart';
import 'package:crm_task_manager/page_2/dashboard/detailed_report/contents/goods_movement_content.dart';
import 'package:crm_task_manager/page_2/dashboard/detailed_report/contents/sales_dynamics_content.dart';
import 'package:crm_task_manager/page_2/dashboard/detailed_report/contents/net_profit_content.dart';
import 'package:crm_task_manager/page_2/dashboard/detailed_report/contents/profitability_content.dart';
import 'package:crm_task_manager/page_2/dashboard/detailed_report/contents/expense_structure_content.dart';
import 'package:crm_task_manager/page_2/dashboard/detailed_report/contents/manufacture_goods_content.dart';
import 'package:crm_task_manager/page_2/dashboard/detailed_report/contents/manufacture_materials_content.dart';
import 'package:crm_task_manager/page_2/dashboard/detailed_report/contents/order_quantity_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/goods/sales_dashboard_goods_bloc.dart';
import '../../../bloc/page_2_BLOC/dashboard/cash_balance/sales_dashboard_cash_balance_bloc.dart';
import '../../../bloc/page_2_BLOC/dashboard/creditors/sales_dashboard_creditors_bloc.dart';
import '../../../bloc/page_2_BLOC/dashboard/debtors/sales_dashboard_debtors_bloc.dart';
import '../../../bloc/page_2_BLOC/dashboard/reconciliation_act/sales_dashboard_reconciliation_act_bloc.dart';
import '../../../bloc/page_2_BLOC/dashboard/sales_dynamics/sales_dashboard_sales_dynamics_bloc.dart';
import '../../../bloc/page_2_BLOC/dashboard/net_profit/sales_dashboard_net_profit_bloc.dart';
import '../../../bloc/page_2_BLOC/dashboard/profitability/sales_dashboard_profitability_bloc.dart';
import '../../../bloc/page_2_BLOC/dashboard/expense_structure/sales_dashboard_expense_structure_bloc.dart';
import '../../../bloc/page_2_BLOC/dashboard/salary_report/sales_dashboard_salary_report_bloc.dart';
import '../../../custom_widget/custom_app_bar_reports.dart';
import '../../../screens/profile/languages/app_localizations.dart';
import '../../../screens/profile/profile_screen.dart';
import 'contents/creditors_content.dart';
import 'contents/debtors_content.dart';
import 'contents/goods_content.dart';
import 'contents/salary_report_content.dart';
import 'contents/top_selling_goods_content.dart';

class TaskStyles {
  static const TextStyle tabTextStyle = TextStyle(
    fontSize: 14,
    fontFamily: 'Gilroy',
    fontWeight: FontWeight.w500,
  );

  static BoxDecoration tabButtonDecoration(
      BuildContext context, bool isActive) {
    final colors = context.appColors;
    return BoxDecoration(
      color: isActive
          ? colors.buttonPrimaryBg
          : colors.surfacePrimary.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isActive ? colors.buttonPrimaryBg : colors.borderSubtle,
        width: 1,
      ),
      boxShadow: isActive
          ? [
              BoxShadow(
                color: colors.buttonPrimaryBg.withValues(alpha: 0.18),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }
}

class DetailedReportScreen extends StatefulWidget {
  final int currentTabIndex;

  const DetailedReportScreen({super.key, required this.currentTabIndex});

  @override
  _DetailedReportScreenState createState() => _DetailedReportScreenState();
}

class _DetailedReportScreenState extends State<DetailedReportScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  late ScrollController _scrollController;
  static const List<Map<String, dynamic>> _baseTabTitles = [
    {'id': 0, 'titleKey': 'tab_goods_illiquid'},
    {'id': 1, 'titleKey': 'tab_reconciliation_act'},
    {'id': 11, 'titleKey': 'tab_goods_movement'},
    {'id': 2, 'titleKey': 'tab_cash_balance'},
    {'id': 3, 'titleKey': 'tab_our_debts'},
    {'id': 4, 'titleKey': 'tab_owed_to_us'},
    {'id': 5, 'titleKey': 'tab_top_selling_products'},
    {'id': 6, 'titleKey': 'tab_sales_dynamics'},
    {'id': 7, 'titleKey': 'tab_net_profit'},
    {'id': 8, 'titleKey': 'tab_profitability_sales'},
    {'id': 9, 'titleKey': 'tab_expense_structure'},
    {'id': 10, 'titleKey': 'order_quantity'},
  ];
  static const List<Map<String, dynamic>> _manufactureTabTitles = [
    {'id': 13, 'titleKey': 'tab_manufacture_goods'},
    {'id': 14, 'titleKey': 'tab_manufacture_materials'},
  ];
  static const Map<String, dynamic> _salaryTab = {
    'id': 12,
    'titleKey': 'tab_salary_debt',
  };
  List<Map<String, dynamic>> _tabTitles = [];
  late List<GlobalKey> _tabKeys;
  late int _currentTabIndex;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool isClickAvatarIcon = false;

  final Map<int, Map<String, dynamic>> _filters = {};
  String _currentSearch = '';

  // Store bloc instances
  late SalesDashboardGoodsBloc _goodsBloc;
  late SalesDashboardCashBalanceBloc _cashBalanceBloc;
  late SalesDashboardCreditorsBloc _creditorsBloc;
  late SalesDashboardDebtorsBloc _debtorsBloc;
  late SalesDashboardTopSellingGoodsBloc _topSellingGoodsBloc;
  late SalesDashboardSalesDynamicsBloc _salesDynamicsBloc;
  late SalesDashboardNetProfitBloc _netProfitBloc;
  late SalesDashboardProfitabilityBloc _profitabilityBloc;
  late SalesDashboardExpenseStructureBloc _expenseStructureBloc;
  late SalesDashboardSalaryReportBloc _salaryReportBloc;
  late SalesDashboardManufactureGoodsBloc _manufactureGoodsBloc;
  late SalesDashboardManufactureMaterialsBloc _manufactureMaterialsBloc;
  late SalesDashboardOrderQuantityBloc _orderQuantityBloc;
  late SalesDashboardReconciliationActBloc _reconciliationActBloc;
  late SalesDashboardGoodsMovementBloc _goodsMovementBloc;
  bool _hasManufacture = false;
  bool _tabControllerInitialized = false;

  @override
  void initState() {
    super.initState();

    // Initialize blocs
    _goodsBloc = SalesDashboardGoodsBloc()..add(LoadGoodsReport());
    _cashBalanceBloc = SalesDashboardCashBalanceBloc()
      ..add(LoadCashBalanceReport());
    _creditorsBloc = SalesDashboardCreditorsBloc()..add(LoadCreditorsReport());
    _debtorsBloc = SalesDashboardDebtorsBloc()..add(LoadDebtorsReport());
    _topSellingGoodsBloc = SalesDashboardTopSellingGoodsBloc()
      ..add(LoadTopSellingGoodsReport());
    _salesDynamicsBloc = SalesDashboardSalesDynamicsBloc()
      ..add(LoadSalesDynamicsReport());
    _netProfitBloc = SalesDashboardNetProfitBloc()..add(LoadNetProfitReport());
    _profitabilityBloc = SalesDashboardProfitabilityBloc()
      ..add(LoadProfitabilityReport());
    _expenseStructureBloc = SalesDashboardExpenseStructureBloc()
      ..add(LoadExpenseStructureReport());
    _salaryReportBloc = SalesDashboardSalaryReportBloc()
      ..add(
        LoadSalaryReport(
          filter: {'year': DateTime.now().year.toString()},
        ),
      );
    _manufactureGoodsBloc = SalesDashboardManufactureGoodsBloc();
    _manufactureMaterialsBloc = SalesDashboardManufactureMaterialsBloc();
    _orderQuantityBloc = SalesDashboardOrderQuantityBloc()
      ..add(LoadOrderQuantityReport());
    _reconciliationActBloc = SalesDashboardReconciliationActBloc();
    _goodsMovementBloc = SalesDashboardGoodsMovementBloc()
      ..add(LoadGoodsMovementReport());

    _scrollController = ScrollController();
    _rebuildTabs(initialIndex: widget.currentTabIndex);
    _loadManufactureSettings();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveTab();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();

    // Dispose blocs
    _goodsBloc.close();
    _cashBalanceBloc.close();
    _creditorsBloc.close();
    _debtorsBloc.close();
    _topSellingGoodsBloc.close();
    _salesDynamicsBloc.close();
    _netProfitBloc.close();
    _profitabilityBloc.close();
    _expenseStructureBloc.close();
    _salaryReportBloc.close();
    _manufactureGoodsBloc.close();
    _manufactureMaterialsBloc.close();
    _orderQuantityBloc.close();
    _reconciliationActBloc.close();
    _goodsMovementBloc.close();

    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _currentSearch = query;
    });
    _reloadCurrentTabData();
  }

  void _resetSearch() {
    _searchController.clear();
    setState(() {
      _currentSearch = '';
    });
    _reloadCurrentTabData();
  }

  void _reloadCurrentTabData() {
    final id = _tabTitles[_currentTabIndex]['id'];
    final filter = _filters[_currentTabIndex] ?? {};
    // Нормализуем поиск: пустая строка становится null
    final search = (_currentSearch.isEmpty || _currentSearch.trim().isEmpty)
        ? null
        : _currentSearch.trim();

    debugPrint(
        "DetailedReportScreen._reloadCurrentTabData: filter: $filter and search: $search");

    if (id == 0) {
      _goodsBloc.add(LoadGoodsReport(filter: filter, search: search));
    } else if (id == 1) {
      _reconciliationActBloc
          .add(LoadReconciliationActReport(filter: filter, search: search));
    } else if (id == 11) {
      _goodsMovementBloc
          .add(LoadGoodsMovementReport(filter: filter, search: search));
    } else if (id == 2) {
      _cashBalanceBloc
          .add(LoadCashBalanceReport(filter: filter, search: search));
    } else if (id == 3) {
      _creditorsBloc.add(LoadCreditorsReport(filter: filter, search: search));
    } else if (id == 4) {
      _debtorsBloc.add(LoadDebtorsReport(filter: filter, search: search));
    } else if (id == 5) {
      _topSellingGoodsBloc
          .add(LoadTopSellingGoodsReport(filter: filter, search: search));
    } else if (id == 6) {
      _salesDynamicsBloc
          .add(LoadSalesDynamicsReport(filter: filter, search: search));
    } else if (id == 7) {
      _netProfitBloc.add(LoadNetProfitReport(filter: filter, search: search));
    } else if (id == 8) {
      _profitabilityBloc
          .add(LoadProfitabilityReport(filter: filter, search: search));
    } else if (id == 9) {
      _expenseStructureBloc
          .add(LoadExpenseStructureReport(filter: filter, search: search));
    } else if (id == 12) {
      final salaryFilter = Map<String, dynamic>.from(filter);
      salaryFilter.putIfAbsent('year', () => DateTime.now().year.toString());
      _salaryReportBloc
          .add(LoadSalaryReport(filter: salaryFilter, search: search));
    } else if (id == 13) {
      _manufactureGoodsBloc
          .add(LoadManufactureGoodsReport(filter: filter, search: search));
    } else if (id == 14) {
      _manufactureMaterialsBloc
          .add(LoadManufactureMaterialsReport(filter: filter, search: search));
    } else if (id == 10) {
      _orderQuantityBloc
          .add(LoadOrderQuantityReport(filter: filter, search: search));
    }
  }

  void _handleFilterSelected(Map<String, dynamic> selectedFilters) {
    debugPrint(
        "Selected Filters: $selectedFilters, currentTabIndex: $_currentTabIndex");
    setState(() {
      _filters[_currentTabIndex] = selectedFilters;
    });
    _reloadCurrentTabData();
  }

  void _handleResetFilters() {
    setState(() {
      _filters[_currentTabIndex] = {};
    });
    _reloadCurrentTabData();
  }

  Future<void> _loadManufactureSettings() async {
    try {
      final settings = await _apiService.getSettings(null);
      final result = settings['result'] as Map<String, dynamic>?;
      final hasManufacture =
          result?['has_manufacture'] == true || result?['has_manufacture'] == 1;

      if (!mounted || _hasManufacture == hasManufacture) return;

      setState(() {
        _hasManufacture = hasManufacture;
        _rebuildTabs(preserveCurrentSelection: true);
      });
    } catch (_) {
      if (!mounted) return;
    }
  }

  void _rebuildTabs({
    int? initialIndex,
    bool preserveCurrentSelection = false,
  }) {
    final currentTabId = preserveCurrentSelection && _tabTitles.isNotEmpty
        ? _tabTitles[_currentTabIndex]['id'] as int
        : null;

    _tabTitles = [
      ..._baseTabTitles,
      _salaryTab,
      if (_hasManufacture) ..._manufactureTabTitles,
    ];

    final nextIndex = preserveCurrentSelection && currentTabId != null
        ? _tabTitles.indexWhere((tab) => tab['id'] == currentTabId)
        : (initialIndex ?? widget.currentTabIndex);
    _currentTabIndex =
        nextIndex >= 0 && nextIndex < _tabTitles.length ? nextIndex : 0;

    _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());

    if (_tabControllerInitialized) {
      _tabController.dispose();
    }

    _tabController = TabController(
      length: _tabTitles.length,
      vsync: this,
      initialIndex: _currentTabIndex,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      _reloadCurrentTabData();
      _scrollToActiveTab();
    });
    _tabControllerInitialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _reloadCurrentTabData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return WillPopScope(
      onWillPop: () async {
        // Возвращаем true для перезагрузки дашборда
        Navigator.of(context).pop(true);
        return false; // Блокируем стандартный pop
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SalesDashboardGoodsBloc>.value(value: _goodsBloc),
          BlocProvider<SalesDashboardCashBalanceBloc>.value(
              value: _cashBalanceBloc),
          BlocProvider<SalesDashboardCreditorsBloc>.value(
              value: _creditorsBloc),
          BlocProvider<SalesDashboardDebtorsBloc>.value(value: _debtorsBloc),
          BlocProvider<SalesDashboardTopSellingGoodsBloc>.value(
              value: _topSellingGoodsBloc),
          BlocProvider<SalesDashboardSalesDynamicsBloc>.value(
              value: _salesDynamicsBloc),
          BlocProvider<SalesDashboardNetProfitBloc>.value(
              value: _netProfitBloc),
          BlocProvider<SalesDashboardProfitabilityBloc>.value(
              value: _profitabilityBloc),
          BlocProvider<SalesDashboardExpenseStructureBloc>.value(
              value: _expenseStructureBloc),
          BlocProvider<SalesDashboardSalaryReportBloc>.value(
              value: _salaryReportBloc),
          BlocProvider<SalesDashboardManufactureGoodsBloc>.value(
              value: _manufactureGoodsBloc),
          BlocProvider<SalesDashboardManufactureMaterialsBloc>.value(
              value: _manufactureMaterialsBloc),
          BlocProvider<SalesDashboardOrderQuantityBloc>.value(
              value: _orderQuantityBloc),
          BlocProvider<SalesDashboardReconciliationActBloc>.value(
              value: _reconciliationActBloc),
          BlocProvider<SalesDashboardGoodsMovementBloc>.value(
              value: _goodsMovementBloc),
        ],
        child: Scaffold(
          backgroundColor: context.appColors.backgroundPrimary,
          appBar: AppBar(
            forceMaterialTransparency: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: !isClickAvatarIcon
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.appColors.iconPrimary,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  )
                : null,
            automaticallyImplyLeading: false,
            title: CustomAppBarReports(
              title: isClickAvatarIcon
                  ? localizations!.translate('appbar_settings')
                  : localizations!.translate('appbar_detailed_report'),
              onClickProfileAvatar: () {
                setState(() {
                  isClickAvatarIcon = !isClickAvatarIcon;
                });
              },
              clearButtonClickFilter: (isSearching) {},
              showSearchIcon: !isClickAvatarIcon,
              showFilterIcon: !isClickAvatarIcon &&
                  _tabTitles[_currentTabIndex]['id'] != 12,
              currentTabIndex: _currentTabIndex,
              currentTabId: _tabTitles[_currentTabIndex]['id'] as int,
              onChangedSearchInput: _onSearch,
              textEditingController: _searchController,
              focusNode: _searchFocusNode,
              clearButtonClick: (isSearching) {
                _resetSearch();
              },
              currentFilters: _filters,
              onFilterSelected: _handleFilterSelected,
              onResetFilters: _handleResetFilters,
            ),
          ),
          body: isClickAvatarIcon
              ? ProfileScreen()
              : Stack(
                  children: [
                    const Positioned.fill(
                      child: AppBackgroundOverlay(
                        preset: AppBackgroundPreset.aurora,
                      ),
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 15),
                        _buildCustomTabBar(),
                        Expanded(
                          child: _buildTabBarView(),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: Row(
        children: List.generate(_tabTitles.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildTabButton(index),
          );
        }),
      ),
    );
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;
    final localizations = AppLocalizations.of(context)!;

    return GestureDetector(
      key: _tabKeys[index],
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Container(
        decoration: TaskStyles.tabButtonDecoration(context, isActive),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Text(
          localizations.translate(_tabTitles[index]['titleKey']),
          style: TaskStyles.tabTextStyle.copyWith(
            color: isActive
                ? context.appColors.textInverse
                : context.appColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: List.generate(_tabTitles.length, (index) {
        return _buildTabContent(_tabTitles[index]['id']);
      }),
    );
  }

  Widget _buildTabContent(int id) {
    if (id == 0) {
      return GoodsContent();
    } else if (id == 1) {
      return ReconciliationActContent();
    } else if (id == 11) {
      return GoodsMovementContent();
    } else if (id == 2) {
      return CashBalanceContent();
    } else if (id == 3) {
      return CreditorsContent();
    } else if (id == 4) {
      return DebtorsContent();
    } else if (id == 5) {
      return TopSellingGoodsContent();
    } else if (id == 6) {
      return SalesDynamicsContent();
    } else if (id == 7) {
      return NetProfitContent();
    } else if (id == 8) {
      return ProfitabilityContent();
    } else if (id == 9) {
      return ExpenseStructureContent();
    } else if (id == 12) {
      final currentFilter = _filters[_currentTabIndex] ?? {};
      final selectedYear = int.tryParse(
        currentFilter['year']?.toString() ?? DateTime.now().year.toString(),
      );

      return SalaryReportContent(
        selectedYear: selectedYear,
        onYearChanged: (year) {
          setState(() {
            _filters[_currentTabIndex] = {
              ...(_filters[_currentTabIndex] ?? {}),
              'year': year.toString(),
            };
          });
          _reloadCurrentTabData();
        },
      );
    } else if (id == 13) {
      return const ManufactureGoodsContent();
    } else if (id == 14) {
      return const ManufactureMaterialsContent();
    } else if (id == 10) {
      return const OrderQuantityContent();
    } else {
      return Container();
    }
  }

  void _scrollToActiveTab() {
    final keyContext = _tabKeys[_currentTabIndex].currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      final position =
          box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final tabWidth = box.size.width;
      final screenWidth = MediaQuery.of(context).size.width;

      if (position.dx < 0 || (position.dx + tabWidth) > screenWidth) {
        double targetOffset = _scrollController.offset +
            position.dx -
            (screenWidth / 2) +
            (tabWidth / 2);
        targetOffset =
            targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }
}
