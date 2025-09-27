import 'package:flutter/material.dart';

class ShowInfoScreen extends StatefulWidget {
  @override
  _ShowInfoScreenState createState() => _ShowInfoScreenState();
}

class _ShowInfoScreenState extends State<ShowInfoScreen> {
  late ScrollController _scrollController;
  List<Map<String, dynamic>> _tabTitles = [
    {'id': 1, 'title': 'To Do'},
    {'id': 2, 'title': 'In Progress'},
    {'id': 3, 'title': 'Done'},
  ];
  int _currentTabIndex = 0;
  List<GlobalKey> _tabKeys = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabKeys = List.generate(_tabTitles.length, (_) => GlobalKey());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tabs')),
      body: Column(
        children: [
          SizedBox(height: 15),
          _buildCustomTabBar(),
          Expanded(child: SizedBox()), // Empty body
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
    bool isActive = _currentTabIndex == index;
    String taskCount = '0'; // Hardcoded without Bloc

    return GestureDetector(
      key: _tabKeys[index],
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
        _scrollToActiveTab();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.blue : Colors.grey),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tabTitles[index]['title'],
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? Colors.blue : Colors.grey,
                ),
              ),
              child: Text(
                taskCount,
                style: TextStyle(
                  color: isActive ? Colors.blue : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
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
        double targetOffset = _scrollController.offset +
            position.dx -
            (MediaQuery.of(context).size.width / 2) +
            (tabWidth / 2);

        _scrollController.animateTo(
          targetOffset,
          duration: Duration(milliseconds: 100),
          curve: Curves.linear,
        );
      }
    }
  }
}