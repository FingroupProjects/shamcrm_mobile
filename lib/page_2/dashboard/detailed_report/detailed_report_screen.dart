import 'package:crm_task_manager/page_2/dashboard/detailed_report/cash_balance_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/goods/sales_dashboard_goods_bloc.dart';
import '../../../bloc/page_2_BLOC/dashboard/cash_balance/sales_dashboard_cash_balance_bloc.dart';
import '../../../bloc/page_2_BLOC/dashboard/creditors/sales_dashboard_creditors_bloc.dart';
import '../../../bloc/page_2_BLOC/dashboard/debtors/sales_dashboard_debtors_bloc.dart';
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
  @override
  _DetailedReportScreenState createState() => _DetailedReportScreenState();

  final int currentTabIndex;

  const DetailedReportScreen({super.key, required this.currentTabIndex});
}

class _DetailedReportScreenState extends State<DetailedReportScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  List<Map<String, dynamic>> _tabTitles = [
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
  List<GlobalKey> _tabKeys = [];
  late int _currentTabIndex;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.currentTabIndex;
    _scrollController = ScrollController();
    _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());
    _tabController = TabController(
      length: _tabTitles.length,
      vsync: this,
      initialIndex: widget.currentTabIndex,  // This is the key fix
    );
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      _scrollToActiveTab();
    });

    // Optional: Scroll to the initial tab after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveTab();
    });
  }
  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xff1E2E52)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Детальный отчёт',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          _buildCustomTabBar(),
          Expanded(
            child: _buildTabBarView(),
          ),
        ],
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
      return BlocProvider(
        create: (context) => SalesDashboardGoodsBloc(),
        child: GoodsContent(),
      );
    } else if (id == 1) {
      return BlocProvider(
        create: (context) => SalesDashboardCashBalanceBloc(),
        child: CashBalanceContent(),
      );
    }  else if (id == 2) {
      return BlocProvider(
        create: (context) => SalesDashboardCreditorsBloc(),
        child: CreditorsContent(),
      );
    } else if (id == 3) {
      return BlocProvider(
        create: (context) => SalesDashboardDebtorsBloc(),
        child: DebtorsContent(),
      );
    }
    // etc...

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(5, (index) => Container(margin: EdgeInsets.only(bottom: 16), child: Container(color: Colors.blue ,height: 200))),
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

      if (position.dx < 0 || (position.dx + tabWidth) > MediaQuery.of(context).size.width) {
        double targetOffset = _scrollController.offset + position.dx - (MediaQuery.of(context).size.width / 2) + (tabWidth / 2);

        if (targetOffset != _scrollController.offset) {
          _scrollController.animateTo(
            targetOffset,
            duration: Duration(milliseconds: 100),
            curve: Curves.linear,
          );
        }
      }
    }
  }
}
