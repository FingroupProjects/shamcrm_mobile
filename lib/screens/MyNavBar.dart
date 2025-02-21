import 'package:crm_task_manager/widgets/bottom_navy_bar.dart';
import 'package:flutter/material.dart';

class MyNavBar extends StatefulWidget {
  final Function(int) onItemSelected;
  final List<String> navBarTitles;
  final List<String> activeIcons;
  final List<String> inactiveIcons;
  final int currentIndex; // Новый параметр для начального индекса

  MyNavBar({
    required this.onItemSelected,
    required this.navBarTitles,
    required this.activeIcons,
    required this.inactiveIcons,
    this.currentIndex = 0, // Значение по умолчанию
  });

  @override
  _MyNavBarState createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> {
  late int currentIndex = widget.currentIndex; // Инициализируем значением по умолчанию

static const double _iconSize = 20;

  final TextStyle _titleStyle = const TextStyle(
    color: Colors.white,
    fontFamily: 'Golos',
    fontWeight: FontWeight.w500,
    fontSize: 14,
  );

  @override
  void initState() {
    super.initState();

    // Обновляем currentIndex на основании переданных аргументов после построения виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['screenIndex'] != null) {
        setState(() {
          currentIndex = args['screenIndex']; // Обновляем currentIndex из аргументов
        });
      }
    });
  }

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
    bool allItemsAvailable = widget.navBarTitles.length == widget.activeIcons.length &&
        widget.navBarTitles.length == widget.inactiveIcons.length;

    return BottomNavyBar(
      backgroundColor: Color(0xffF4F7FD),
      selectedIndex: currentIndex == -1 ? -1 : currentIndex, // Если текущий индекс -1, ничего не выбрано
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
