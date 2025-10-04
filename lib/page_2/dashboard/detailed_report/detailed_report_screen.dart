import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/top_selling_goods/sales_dashboard_top_selling_goods_bloc.dart';
import 'package:crm_task_manager/page_2/dashboard/detailed_report/cash_balance_content.dart';
import 'package:crm_task_manager/page_2/dashboard/detailed_report/top_selling_goods_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/goods/sales_dashboard_goods_bloc.dart';
import '../../../bloc/page_2_BLOC/dashboard/cash_balance/sales_dashboard_cash_balance_bloc.dart';
import '../../../bloc/page_2_BLOC/dashboard/creditors/sales_dashboard_creditors_bloc.dart';
import '../../../bloc/page_2_BLOC/dashboard/debtors/sales_dashboard_debtors_bloc.dart';
import '../../../custom_widget/custom_app_bar_reports.dart';
import '../../../screens/profile/languages/app_localizations.dart';
import '../../../screens/profile/profile_screen.dart';
import 'creditors_content.dart';
import 'debtors_content.dart';
import 'goods_content.dart';

class TaskStyles {
  static const Color activeColor = Color(0xff1E2E52);
  static const Color inactiveColor = Color(0xff99A4BA);

  static const TextStyle tabTextStyle = TextStyle(
    fontSize: 14,
    fontFamily: 'Gilroy',
    fontWeight: FontWeight.w500,
  );

  static BoxDecoration tabButtonDecoration(bool isActive) {
    return BoxDecoration(
      color: isActive ? const Color(0xff1E2E52) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isActive ? const Color(0xff1E2E52) : const Color(0xff99A4BA),
        width: 1,
      ),
      boxShadow: isActive
          ? [
        BoxShadow(
          color: const Color(0xff1E2E52).withOpacity(0.1),
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

class _DetailedReportScreenState extends State<DetailedReportScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final List<Map<String, dynamic>> _tabTitles = [
    {'id': 0, 'title': 'Товары / Неликвидный товары'},
    {'id': 1, 'title': 'Остаток кассы'},
    {'id': 2, 'title': 'Наши долги'},
    {'id': 3, 'title': 'Нам должны'},
    {'id': 4, 'title': 'Топ продаваемых товаров'},
    {'id': 5, 'title': 'Динамика продаж'},
    {'id': 6, 'title': 'Чистая прибыль'},
    {'id': 7, 'title': 'Рентабельность продаж'},
    {'id': 8, 'title': 'Структура затрат'},
    {'id': 9, 'title': 'Количество заказов'},
  ];
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

  @override
  void initState() {
    super.initState();

    // Initialize blocs
    _goodsBloc = SalesDashboardGoodsBloc()..add(LoadGoodsReport());
    _cashBalanceBloc = SalesDashboardCashBalanceBloc()..add(LoadCashBalanceReport());
    _creditorsBloc = SalesDashboardCreditorsBloc()..add(LoadCreditorsReport());
    _debtorsBloc = SalesDashboardDebtorsBloc()..add(LoadDebtorsReport());
    _topSellingGoodsBloc = SalesDashboardTopSellingGoodsBloc()..add(LoadTopSellingGoodsReport());

    _currentTabIndex = widget.currentTabIndex;
    _scrollController = ScrollController();
    _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());
    _tabController = TabController(
      length: _tabTitles.length,
      vsync: this,
      initialIndex: widget.currentTabIndex,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      _scrollToActiveTab();
    });

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
    final search = _currentSearch;

    if (id == 0) {
      _goodsBloc.add(LoadGoodsReport(filter: filter, search: search));
    } else if (id == 1) {
      debugPrint("Reloading Cash Balance with filter: $filter and search: $search");
      _cashBalanceBloc.add(LoadCashBalanceReport(filter: filter, search: search));
    } else if (id == 2) {
      _creditorsBloc.add(LoadCreditorsReport(filter: filter, search: search));
    } else if (id == 3) {
      _debtorsBloc.add(LoadDebtorsReport(filter: filter, search: search));
    } else if (id == 4) {
      _topSellingGoodsBloc.add(LoadTopSellingGoodsReport(filter: filter, search: search));
    }
  }

  void _handleFilterSelected(Map<String, dynamic> selectedFilters) {
    debugPrint("Selected Filters: $selectedFilters, currentTabIndex: $_currentTabIndex");
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<SalesDashboardGoodsBloc>.value(value: _goodsBloc),
        BlocProvider<SalesDashboardCashBalanceBloc>.value(value: _cashBalanceBloc),
        BlocProvider<SalesDashboardCreditorsBloc>.value(value: _creditorsBloc),
        BlocProvider<SalesDashboardDebtorsBloc>.value(value: _debtorsBloc),
        BlocProvider<SalesDashboardTopSellingGoodsBloc>.value(value: _topSellingGoodsBloc),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          elevation: 0,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: !isClickAvatarIcon,
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
            showFilterIcon: !isClickAvatarIcon,
            currentTabIndex: _currentTabIndex,
            onChangedSearchInput: _onSearch,
            textEditingController: _searchController,
            focusNode: _searchFocusNode,
            clearButtonClick: (isSearching) {
              _resetSearch();
            },
            currentFilters: _filters[_currentTabIndex] ?? {},
            onFilterSelected: _handleFilterSelected,
            onResetFilters: _handleResetFilters,
          ),
        ),
        body: isClickAvatarIcon
            ? ProfileScreen()
            : Column(
          children: [
            const SizedBox(height: 15),
            _buildCustomTabBar(),
            Expanded(
              child: _buildTabBarView(),
            ),
          ],
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

    return GestureDetector(
      key: _tabKeys[index],
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Container(
        decoration: TaskStyles.tabButtonDecoration(isActive),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Text(
          _tabTitles[index]['title'],
          style: TaskStyles.tabTextStyle.copyWith(
            color: isActive ? Colors.white : TaskStyles.inactiveColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: List.generate(_tabTitles.length, (index) {
        return _buildTabContent(_tabTitles[index]['id'], _tabTitles[index]['title']);
      }),
    );
  }

  Widget _buildTabContent(int id, String tabTitle) {
    if (id == 0) {
      return GoodsContent();
    } else if (id == 1) {
      return CashBalanceContent();
    } else if (id == 2) {
      return CreditorsContent();
    } else if (id == 3) {
      return DebtorsContent();
    } else if (id == 4) {
      return TopSellingGoodsContent();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(
            5,
                (index) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Container(color: Colors.blue, height: 200),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToActiveTab() {
    final keyContext = _tabKeys[_currentTabIndex].currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final tabWidth = box.size.width;
      final screenWidth = MediaQuery.of(context).size.width;

      if (position.dx < 0 || (position.dx + tabWidth) > screenWidth) {
        double targetOffset = _scrollController.offset + position.dx - (screenWidth / 2) + (tabWidth / 2);
        targetOffset = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }
}