import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_column.dart';
import 'package:flutter/material.dart';

class OrderScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _tabTitles = [
    {'id': 1, 'title': 'Новый'},
    {'id': 2, 'title': 'Ожидает оплаты'},
    {'id': 3, 'title': 'Оплачен'},
    {'id': 4, 'title': 'В обработке'},
    {'id': 5, 'title': 'Отправлен'},
    {'id': 6, 'title': 'Завершен'},
    {'id': 7, 'title': 'Отменен'},
  ];
  int _currentTabIndex = 0;
  List<GlobalKey> _tabKeys = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
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
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToActiveTab() {
    final keyContext = _tabKeys[_currentTabIndex].currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      final position =
          box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final tabWidth = box.size.width;
      double targetOffset = _scrollController.offset +
          position.dx -
          (MediaQuery.of(context).size.width / 2) +
          (tabWidth / 2);
      _scrollController.animateTo(
        targetOffset,
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    // Логика поиска будет добавлена позже в order_column.dart
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBarPage2(
          title: 'Заказы',
          onChangedSearchInput: (value) {
            _onSearch(value);
          },
          showFilterOrderIcon: true,
          showFilterIcon: false,
          showSearchIcon: true,
          onClickProfileAvatar: () {
            // Логика перехода на профиль, если нужна
          },
          textEditingController: _searchController,
          focusNode: _focusNode,
          clearButtonClick: (value) {
            if (!value) {
              setState(() {
                _isSearching = false;
                _searchController.clear();
              });
            }
          },
          clearButtonClickFiltr: (value) {
            // Логика фильтрации, если нужна
          },
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 15),
          _buildCustomTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabTitles.map((tab) {
                return OrderColumn(
                  statusId: tab['id'],
                  name: tab['title'],
                  searchQuery: _isSearching ? _searchController.text : null,
                );
              }).toList(),
            ),
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
          bool isActive = _tabController.index == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              key: _tabKeys[index],
              onTap: () => _tabController.animateTo(index),
              child: Container(
                decoration: BoxDecoration(
                  color: isActive
                      ? Color.fromARGB(255, 255, 255, 255)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? Colors.black : const Color(0xff99A4BA),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Text(
                  _tabTitles[index]['title'],
                  style: TaskStyles.tabTextStyle.copyWith(
                    color: isActive
                        ? TaskStyles.activeColor
                        : TaskStyles.inactiveColor,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
