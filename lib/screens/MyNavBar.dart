import 'package:crm_task_manager/widgets/bottom_navy_bar.dart';
import 'package:flutter/material.dart';

class MyNavBar extends StatefulWidget {
  final Function(int) onItemSelected;
  final List<String> navBarTitles;
  final List<String> activeIcons;
  final List<String> inactiveIcons;
  final int currentIndex;

  MyNavBar({
    required this.onItemSelected,
    required this.navBarTitles,
    required this.activeIcons,
    required this.inactiveIcons,
    this.currentIndex = 0,
  });

  @override
  _MyNavBarState createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> {
  late int currentIndex = widget.currentIndex;
  final PageController _pageController = PageController(initialPage: 0);

  static const double _iconSize = 20;
  static const double _navBarHeight = 95; 

  final TextStyle _titleStyle = const TextStyle(
    color: Colors.white,
    fontFamily: 'Golos',
    fontWeight: FontWeight.w500,
    fontSize: 14,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['screenIndex'] != null) {
        setState(() {
          currentIndex = args['screenIndex'];
        });
      }
    });
  }

  BottomNavyBarItem _buildNavBarItem(
      int index, String title, String activeIconPath, String inactiveIconPath) {
    return BottomNavyBarItem(
      icon: Row(
        children: [
          SizedBox(
            width: _iconSize,
            height: _iconSize,
            child: Image.asset(
              currentIndex == index ? activeIconPath : inactiveIconPath,
            ),
          ),
          SizedBox(width: 3),
        ],
      ),
      title: Transform.translate(
        offset: Offset(2, -1),
        child: Text(title, style: _titleStyle),
      ),
      activeColor: Color(0xff1E2E52),
      inactiveColor: Colors.grey,
    );
  }

 @override
Widget build(BuildContext context) {
  bool allItemsAvailable = widget.navBarTitles.length == widget.activeIcons.length &&
      widget.navBarTitles.length == widget.inactiveIcons.length;
  return Container(
    height: _navBarHeight, 
    child: Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index == 1 ? 5 : 0;
              });
              widget.onItemSelected(currentIndex); 
            },
            children: [
              _buildNavBarPage(0, 5), 
              if (widget.navBarTitles.length > 5)
                _buildNavBarPage(5, widget.navBarTitles.length), 
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildNavBarPage(int startIndex, int endIndex) {
  return BottomNavyBar(
    backgroundColor: Color(0xffF4F7FD),
    selectedIndex: currentIndex == -1 ? -1 : currentIndex % 5, 
    onItemSelected: (index) {
      setState(() {
        currentIndex = startIndex + index;
      });
      widget.onItemSelected(startIndex + index);
      _pageController.jumpToPage(currentIndex ~/ 5); 
    },
    items: List.generate(
      endIndex - startIndex,
      (index) => _buildNavBarItem(
        startIndex + index,
        widget.navBarTitles[startIndex + index],
        widget.activeIcons[startIndex + index],
        widget.inactiveIcons[startIndex + index],
      ),
    ),
    iconSize: _iconSize,
    containerHeight: _navBarHeight,
    curve: Curves.ease,
    mainAxisAlignment: MainAxisAlignment.spaceAround,
  );
}
}
