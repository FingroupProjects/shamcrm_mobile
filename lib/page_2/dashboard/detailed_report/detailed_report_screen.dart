import 'package:crm_task_manager/models/page_2/dashboard/dashboard_goods_report.dart';
import 'package:crm_task_manager/page_2/dashboard/detailed_report/cards/goods_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/goods/sales_dashboard_goods_bloc.dart';
import 'cards/cash_balance_card.dart';
import 'cards/our_debts_card.dart';
import 'cards/owed_to_us_card.dart';
import 'cards/sales_dynamics_card.dart';
import 'cards/top_selling_products_card.dart';
import 'cards/net_profit_card.dart';
import 'cards/sales_profitability_card.dart';
import 'cards/cost_structure_card.dart';
import 'cards/orders_count_card.dart';
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
      boxShadow: isActive ? [
        BoxShadow(
          color: const Color(0xff1E2E52).withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ] : null,
    );
  }
}

class DetailedReportScreen extends StatefulWidget {
  @override
  _DetailedReportScreenState createState() => _DetailedReportScreenState();
}

class _DetailedReportScreenState extends State<DetailedReportScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  List<Map<String, dynamic>> _tabTitles = [
    {'id': 1, 'title': 'Товары / Неликвидный товары', 'count': '15'},
    {'id': 2, 'title': 'Остаток кассы', 'count': '8'},
    {'id': 3, 'title': 'Наши долги', 'count': '23'},
    {'id': 4, 'title': 'Нам должны', 'count': '12'},
    {'id': 5, 'title': 'Топ продаваемых товаров', 'count': '45'},
    {'id': 6, 'title': 'Динамика продаж', 'count': '67'},
    {'id': 7, 'title': 'Чистая прибыль', 'count': '34'},
    {'id': 8, 'title': 'Рентабельность продаж', 'count': '56'},
    {'id': 9, 'title': 'Структура затрат', 'count': '78'},
    {'id': 10, 'title': 'Количество заказов', 'count': '89'},
  ];
  int _currentTabIndex = 0;
  List<GlobalKey> _tabKeys = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
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
    String taskCount = _tabTitles[index]['count'];

    return GestureDetector(
      key: _tabKeys[index],
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Container(
        decoration: TaskStyles.tabButtonDecoration(isActive),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tabTitles[index]['title'],
              style: TaskStyles.tabTextStyle.copyWith(
                color: isActive
                    ? Colors.white
                    : TaskStyles.inactiveColor,
              ),
            ),
            Transform.translate(
              offset: const Offset(12, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xff1E2E52)
                        : const Color(0xff99A4BA),
                    width: 1,
                  ),
                ),
                child: Text(
                  taskCount.toString(),
                  style: TextStyle(
                    color: isActive ? Colors.black : const Color(0xff99A4BA),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: List.generate(_tabTitles.length, (index) {
        return _buildTabContent(_tabTitles[index]['title']);
      }),
    );
  }

  Widget _buildTabContent(String tabTitle) {

    if (tabTitle == 'Товары / Неликвидный товары') {
      return BlocProvider(
        create: (context) => SalesDashboardGoodsBloc(),
        child: GoodsContent(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          ...List.generate(5, (index) => Container(
              margin: EdgeInsets.only(bottom: 16),
              child: _buildSpecializedCard(tabTitle, index))
          ),
        ],
      ),
    );
  }

  // Helper method to get appropriate icon for each tab
  Widget _getTabIcon(String tabTitle) {
    switch (tabTitle) {
      case 'Товары / Неликвидный товары':
        return Icon(Icons.inventory_2, color: Color(0xff1E2E52), size: 24);
      case 'Остаток кассы':
        return Icon(Icons.account_balance_wallet, color: Color(0xff1E2E52), size: 24);
      case 'Наши долги':
        return Icon(Icons.credit_card_off, color: Color(0xff1E2E52), size: 24);
      case 'Нам должны':
        return Icon(Icons.account_balance, color: Color(0xff1E2E52), size: 24);
      case 'Топ продаваемых товаров':
        return Icon(Icons.trending_up, color: Color(0xff1E2E52), size: 24);
      case 'Динамика продаж':
        return Icon(Icons.show_chart, color: Color(0xff1E2E52), size: 24);
      case 'Чистая прибыль':
        return Icon(Icons.attach_money, color: Color(0xff1E2E52), size: 24);
      case 'Рентабельность продаж':
        return Icon(Icons.pie_chart, color: Color(0xff1E2E52), size: 24);
      case 'Структура затрат':
        return Icon(Icons.analytics, color: Color(0xff1E2E52), size: 24);
      case 'Количество заказов':
        return Icon(Icons.shopping_cart, color: Color(0xff1E2E52), size: 24);
      default:
        return Icon(Icons.analytics_outlined, color: Color(0xff1E2E52), size: 24);
    }
  }

  // Build specialized cards based on data type
  Widget _buildSpecializedCard(String category, int index) {
    switch (category) {
      case 'Товары / Неликвидный товары':
        return _buildGoodsCard(index);
      case 'Остаток кассы':
        return CashBalanceCard(
          balance: '125,000 ₽',
          onTap: () => _onCardTap(category),
        );
      case 'Наши долги':
        return OurDebtsCard(
          amount: '45,000 ₽',
          onTap: () => _onCardTap(category),
        );
      case 'Нам должны':
        return OwedToUsCard(
          amount: '78,000 ₽',
          onTap: () => _onCardTap(category),
        );
      case 'Топ продаваемых товаров':
        return TopSellingProductsCard(
          count: '12 товаров',
          onTap: () => _onCardTap(category),
        );
      case 'Динамика продаж':
        return SalesDynamicsCard(
          percentage: '+15.3%',
          onTap: () => _onCardTap(category),
        );
      case 'Чистая прибыль':
        return NetProfitCard(
          amount: '234,000 ₽',
          onTap: () => _onCardTap(category),
        );
      case 'Рентабельность продаж':
        return SalesProfitabilityCard(
          percentage: '18.5%',
          onTap: () => _onCardTap(category),
        );
      case 'Структура затрат':
        return CostStructureCard(
          amount: '156,000 ₽',
          onTap: () => _onCardTap(category),
        );
      case 'Количество заказов':
        return OrdersCountCard(
          count: '89 заказов',
          onTap: () => _onCardTap(category),
        );
      default:
        return _buildGenericCard(category, index);
    }
  }

  void _onCardTap(String category) {
    // Handle card tap - can navigate to detailed view
    print('Tapped on: $category');
  }

  // Goods Card - for displaying goods/illiquid goods
  Widget _buildGoodsCard(int index) {
    return GoodsCard(goods: DashboardGoods(
        storages: [],
        id: 1, article: 'article', name: 'name', category: 'category', totalQuantity: '1', daysWithoutMovement: '1', sum: '1'), onClick: (e) {}, onLongPress: (e) {}, isSelectionMode: false, isSelected: false, );
  }

  // Generic fallback card
  Widget _buildGenericCard(String category, int index) {
    return _buildDataCard(category, index);
  }

  // Helper method for info boxes
  Widget _buildInfoBox(String label, String value, Color accentColor) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xffF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xffCBD5E1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xff475569),
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

      if (position.dx < 0 || (position.dx + tabWidth) > MediaQuery
          .of(context)
          .size
          .width) {
        double targetOffset = _scrollController.offset +
            position.dx -
            (MediaQuery
                .of(context)
                .size
                .width / 2) +
            (tabWidth / 2);

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

  _buildDataCard(String category, int index) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xffE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xff1E2E52).withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xffF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                left: BorderSide(
                  width: 4,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xff1E2E52).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$category - Запись ${index + 1}',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Left column
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xffF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xffCBD5E1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Значение:',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff475569),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${(index + 1) * 1250} ₽',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // Right column
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xffF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xffCBD5E1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Дата:',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff475569),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${15 + index}.09.2025',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}