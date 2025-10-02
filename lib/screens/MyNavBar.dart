import 'dart:io';
import 'package:flutter/material.dart';

class MyNavBar extends StatefulWidget {
  final Function(int, int) onItemSelected; // (groupIndex, itemIndex)
  final List<String> navBarTitlesGroup1;
  final List<String> navBarTitlesGroup2;
  final List<String> activeIconsGroup1;
  final List<String> activeIconsGroup2;
  final List<String> inactiveIconsGroup1;
  final List<String> inactiveIconsGroup2;
  final int currentIndexGroup1;
  final int currentIndexGroup2;

  MyNavBar({
    required this.onItemSelected,
    required this.navBarTitlesGroup1,
    required this.navBarTitlesGroup2,
    required this.activeIconsGroup1,
    required this.activeIconsGroup2,
    required this.inactiveIconsGroup1,
    required this.inactiveIconsGroup2,
    this.currentIndexGroup1 = -1,
    this.currentIndexGroup2 = -1,
  });

  @override
  _MyNavBarState createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> {
  final ScrollController _scrollController = ScrollController();
  static final double _navBarHeight = Platform.isIOS ? 80 : 60;

  // Объединяем данные из обеих групп
  List<NavBarItemData> _getAllItems() {
    List<NavBarItemData> items = [];
    
    // Группа 1
    for (int i = 0; i < widget.navBarTitlesGroup1.length; i++) {
      items.add(NavBarItemData(
        title: widget.navBarTitlesGroup1[i],
        activeIcon: widget.activeIconsGroup1[i],
        inactiveIcon: widget.inactiveIconsGroup1[i],
        groupIndex: 1,
        itemIndex: i,
        isActive: widget.currentIndexGroup1 == i,
      ));
    }
    
    // Группа 2
    for (int i = 0; i < widget.navBarTitlesGroup2.length; i++) {
      items.add(NavBarItemData(
        title: widget.navBarTitlesGroup2[i],
        activeIcon: widget.activeIconsGroup2[i],
        inactiveIcon: widget.inactiveIconsGroup2[i],
        groupIndex: 2,
        itemIndex: i,
        isActive: widget.currentIndexGroup2 == i,
      ));
    }
    
    return items;
  }

  @override
  void didUpdateWidget(MyNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Автоматический скролл к активному элементу
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveItem();
    });
  }

  void _scrollToActiveItem() {
    if (!_scrollController.hasClients) return;
    
    final items = _getAllItems();
    int activeIndex = items.indexWhere((item) => item.isActive);
    
    if (activeIndex != -1) {
      double itemWidth = 120.0; // Примерная ширина элемента
      double targetOffset = (activeIndex * itemWidth) - 
                           (MediaQuery.of(context).size.width / 2) + 
                           (itemWidth / 2);
      
      targetOffset = targetOffset.clamp(
        0.0, 
        _scrollController.position.maxScrollExtent
      );
      
      _scrollController.animateTo(
        targetOffset,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _getAllItems();
    
    Widget navBarContent = Container(
      height: _navBarHeight,
      decoration: BoxDecoration(
        color: Color(0xffF4F7FD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _NavBarItem(
            data: item,
            onTap: () {
              widget.onItemSelected(item.groupIndex, item.itemIndex);
            },
          );
        },
      ),
    );

    if (Platform.isAndroid) {
      return SafeArea(
        top: false,
        child: navBarContent,
      );
    }

    return navBarContent;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// Модель данных для элемента навигации
class NavBarItemData {
  final String title;
  final String activeIcon;
  final String inactiveIcon;
  final int groupIndex;
  final int itemIndex;
  final bool isActive;

  NavBarItemData({
    required this.title,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.groupIndex,
    required this.itemIndex,
    required this.isActive,
  });
}

// Виджет отдельного элемента навигации
class _NavBarItem extends StatelessWidget {
  final NavBarItemData data;
  final VoidCallback onTap;
  
  static const double _iconSize = 22;

  const _NavBarItem({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: data.isActive ? Color(0xff1E2E52) : Color(0xffF4F7FD),
          border: Border.all(
            color: Color(0xff1E2E52).withOpacity(0.5),
            width: data.isActive ? 0 : 0.5,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: data.isActive
              ? [
                  BoxShadow(
                    color: Color(0xff1E2E52).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              data.isActive ? data.activeIcon : data.inactiveIcon,
              width: _iconSize,
              height: _iconSize,
              color: data.isActive ?  Color(0xffF4F7FD) : Color(0xff1E2E52),
            ),
            SizedBox(width: 8),
            Text(
              data.title,
              style: TextStyle(
                color: data.isActive ?  Color(0xffF4F7FD) : Color(0xff1E2E52),
                fontFamily: 'Golos',
                fontWeight: data.isActive ? FontWeight.w500 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
