import 'package:flutter/material.dart';

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
    {'id': 1, 'title': 'Продажи', 'count': '15'},
    {'id': 2, 'title': 'Доходы', 'count': '8'},
    {'id': 3, 'title': 'Расходы', 'count': '23'},
    {'id': 4, 'title': 'Прибыль', 'count': '12'},
    {'id': 5, 'title': 'Товары', 'count': '45'},
    {'id': 6, 'title': 'Клиенты', 'count': '67'},
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xffF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xffCBD5E1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _getTabIcon(tabTitle),
                    SizedBox(width: 12),
                    Text(
                      'Отчёт по: $tabTitle',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Период: Январь 2025 - Сентябрь 2025',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    color: Color(0xff64748B),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Different card types based on data category
          ...List.generate(5, (index) => _buildSpecializedCard(tabTitle, index)),
        ],
      ),
    );
  }

  // Helper method to get appropriate icon for each tab
  Widget _getTabIcon(String tabTitle) {
    switch (tabTitle) {
      case 'Продажи':
        return Icon(Icons.trending_up, color: Color(0xff1E2E52), size: 24);
      case 'Доходы':
        return Icon(Icons.account_balance_wallet, color: Color(0xff1E2E52), size: 24);
      case 'Расходы':
        return Icon(Icons.trending_down, color: Color(0xff1E2E52), size: 24);
      case 'Прибыль':
        return Icon(Icons.analytics, color: Color(0xff1E2E52), size: 24);
      case 'Товары':
        return Icon(Icons.inventory_2, color: Color(0xff1E2E52), size: 24);
      case 'Клиенты':
        return Icon(Icons.people, color: Color(0xff1E2E52), size: 24);
      default:
        return Icon(Icons.analytics_outlined, color: Color(0xff1E2E52), size: 24);
    }
  }

  // Build specialized cards based on data type
  Widget _buildSpecializedCard(String category, int index) {
    switch (category) {
      case 'Продажи':
        return _buildSalesCard(index);
      case 'Доходы':
        return _buildIncomeCard(index);
      case 'Расходы':
        return _buildExpenseCard(index);
      case 'Прибыль':
        return _buildProfitCard(index);
      case 'Товары':
        return _buildProductCard(index);
      case 'Клиенты':
        return _buildClientCard(index);
      default:
        return _buildGenericCard(category, index);
    }
  }

  // Sales Card - focuses on sales metrics
  Widget _buildSalesCard(int index) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xffE2E8F0), width: 1),
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
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(left: BorderSide(width: 4, color: Colors.green)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.shopping_cart, color: Colors.green, size: 16),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Продажа #${1000 + index}',
                    style: TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xff1E2E52)),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoBox('Сумма:', '${(index + 1) * 15000} ₽', Colors.green),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoBox('Клиент:', 'Клиент ${index + 1}', Colors.blue),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoBox('Дата:', '${15 + index}.09.2025', Colors.purple),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoBox('Статус:', 'Завершена', Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Product Card - focuses on inventory
  Widget _buildProductCard(int index) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xffE2E8F0), width: 1),
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
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(left: BorderSide(width: 4, color: Colors.orange)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.inventory, color: Colors.orange, size: 16),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Товар ${index + 1}',
                    style: TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xff1E2E52)),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoBox('Количество:', '${(index + 1) * 50}', Colors.orange),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoBox('Цена:', '${(index + 1) * 250} ₽', Colors.green),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoBox('Категория:', 'Категория ${index + 1}', Colors.blue),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoBox('Поставщик:', 'ООО "Поставщик"', Colors.purple),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Client Card - focuses on client information
  Widget _buildClientCard(int index) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xffE2E8F0), width: 1),
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
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(left: BorderSide(width: 4, color: Colors.blue)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person, color: Colors.blue, size: 16),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Клиент ${index + 1}',
                    style: TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xff1E2E52)),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoBox('Email:', 'client${index + 1}@email.com', Colors.blue),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoBox('Телефон:', '+7 999 123 45 6${index}', Colors.green),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoBox('Регион:', 'Москва', Colors.purple),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoBox('Покупки:', '${(index + 1) * 3}', Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Income Card
  Widget _buildIncomeCard(int index) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xffE2E8F0), width: 1),
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
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(left: BorderSide(width: 4, color: Colors.green)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Доход ${index + 1}',
                    style: TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xff1E2E52)),
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
                Expanded(
                  child: _buildInfoBox('Сумма:', '${(index + 1) * 25000} ₽', Colors.green),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildInfoBox('Источник:', 'Продажи', Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Expense Card
  Widget _buildExpenseCard(int index) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xffE2E8F0), width: 1),
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
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(left: BorderSide(width: 4, color: Colors.red)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_downward, color: Colors.red, size: 16),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Расход ${index + 1}',
                    style: TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xff1E2E52)),
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
                Expanded(
                  child: _buildInfoBox('Сумма:', '${(index + 1) * 8000} ₽', Colors.red),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildInfoBox('Категория:', 'Операционные', Colors.orange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Profit Card
  Widget _buildProfitCard(int index) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xffE2E8F0), width: 1),
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
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(left: BorderSide(width: 4, color: Colors.purple)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.trending_up, color: Colors.purple, size: 16),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Прибыль за ${index + 1} квартал',
                    style: TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xff1E2E52)),
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
                Expanded(
                  child: _buildInfoBox('Чистая прибыль:', '${(index + 1) * 17000} ₽', Colors.purple),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildInfoBox('Маржа:', '${15 + index}%', Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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