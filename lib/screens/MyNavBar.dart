import 'package:crm_task_manager/widgets/bottom_navy_bar.dart';
import 'package:flutter/material.dart';

class MyNavBar extends StatefulWidget {
  final Function(int) onItemSelected;
  final List<String> navBarTitles;
  final List<String> activeIcons;
  final List<String> inactiveIcons;

  MyNavBar({
    required this.onItemSelected,
    required int selectedIndex,
    required this.navBarTitles,
    required this.activeIcons,
    required this.inactiveIcons,
  });

  @override
  _MyNavBarState createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> {
  int currentIndex = 0;
  static const double _iconSize = 24;

  final TextStyle _titleStyle = const TextStyle(
    color: Colors.white,
    fontFamily: 'Golos',
    fontWeight: FontWeight.w500,
    fontSize: 14,
  );

  BottomNavyBarItem _buildNavBarItem(
      int index, String title, String activeIconPath, String inactiveIconPath) {
    return BottomNavyBarItem(
      icon: SizedBox(
        width: _iconSize,
        height: _iconSize,
        child: Image.asset(
          currentIndex == index ? activeIconPath : inactiveIconPath,
        ),
      ),
      title: Text(title, style: _titleStyle),
      activeColor: Color(0xff1E2E52),
      inactiveColor: Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Проверка доступности экрана (добавьте свою логику проверки доступности экранов)
    bool allItemsAvailable = widget.navBarTitles.length == widget.activeIcons.length &&
                              widget.navBarTitles.length == widget.inactiveIcons.length;

    return BottomNavyBar(
      backgroundColor: Color(0xffF4F7FD),
      selectedIndex: currentIndex,
      onItemSelected: (index) {
        setState(() {
          currentIndex = index;
        });
        widget.onItemSelected(index);
      },
      items: List.generate(
        widget.navBarTitles.length,
        (index) => _buildNavBarItem(
          index,
          widget.navBarTitles[index],
          widget.activeIcons[index],
          widget.inactiveIcons[index],
        ),
      ),
      iconSize: _iconSize,
      containerHeight: 60, 
      curve: Curves.ease,
      mainAxisAlignment: allItemsAvailable
          ? MainAxisAlignment.spaceAround 
          : MainAxisAlignment.spaceEvenly, 
    );
  }
}
