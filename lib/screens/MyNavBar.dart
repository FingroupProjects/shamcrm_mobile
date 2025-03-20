import 'dart:io';

import 'package:crm_task_manager/widgets/bottom_navy_bar.dart';
import 'package:flutter/material.dart';

class MyNavBar extends StatefulWidget {
  final Function(int) onItemSelectedGroup1;
  final Function(int) onItemSelectedGroup2;
  final List<String> navBarTitlesGroup1;
  final List<String> navBarTitlesGroup2;
  final List<String> activeIconsGroup1;
  final List<String> activeIconsGroup2;
  final List<String> inactiveIconsGroup1;
  final List<String> inactiveIconsGroup2;
  final int currentIndexGroup1;
  final int currentIndexGroup2;

  MyNavBar({
    required this.onItemSelectedGroup1,
    required this.onItemSelectedGroup2,
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
  late int currentIndexGroup1 = widget.currentIndexGroup1;
  late int currentIndexGroup2 = widget.currentIndexGroup2;
  final PageController _pageController = PageController(initialPage: 0);

  static const double _iconSize = 20;
  static final double _navBarHeight = Platform.isIOS ? 90 : 60;

  final TextStyle _titleStyle = const TextStyle(
    color: Colors.white,
    fontFamily: 'Golos',
    fontWeight: FontWeight.w500,
    fontSize: 14,
  );

  BottomNavyBarItem _buildNavBarItem(
      int index, String title, String activeIconPath, String inactiveIconPath, bool isActive) {
    return BottomNavyBarItem(
      icon: Row(
        children: [
          SizedBox(
            width: _iconSize,
            height: _iconSize,
            child: Image.asset(
              isActive ? activeIconPath : inactiveIconPath,
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
  return Container(
    height: _navBarHeight,
    child: Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                if (page == 0) {
                  currentIndexGroup1 = 0;
                  currentIndexGroup2 = -1;
                  widget.onItemSelectedGroup1(0);
                } else {
                  currentIndexGroup1 = -1;
                  currentIndexGroup2 = 0; 
                  widget.onItemSelectedGroup2(0);
                }
              });
            },
            children: [
              BottomNavyBar(
                backgroundColor: Color(0xffF4F7FD),
                selectedIndex: currentIndexGroup1 == -1 ? -1 : currentIndexGroup1,
                onItemSelected: (index) {
                  setState(() {
                    currentIndexGroup1 = index;
                    currentIndexGroup2 = -1;
                  });
                  widget.onItemSelectedGroup1(index);
                },
                items: List.generate(
                  widget.navBarTitlesGroup1.length,
                  (index) => _buildNavBarItem(
                    index,
                    widget.navBarTitlesGroup1[index],
                    widget.activeIconsGroup1[index],
                    widget.inactiveIconsGroup1[index],
                    currentIndexGroup1 == index,
                  ),
                ),
                iconSize: _iconSize,
                containerHeight: _navBarHeight,
                curve: Curves.ease,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
              ),
              BottomNavyBar(
                backgroundColor: Color(0xffF4F7FD),
                selectedIndex: currentIndexGroup2 == -1 ? -1 : currentIndexGroup2,
                onItemSelected: (index) {
                  setState(() {
                    currentIndexGroup2 = index;
                    currentIndexGroup1 = -1;
                  });
                  widget.onItemSelectedGroup2(index);
                },
                items: List.generate(
                  widget.navBarTitlesGroup2.length,
                  (index) => _buildNavBarItem(
                    index,
                    widget.navBarTitlesGroup2[index],
                    widget.activeIconsGroup2[index],
                    widget.inactiveIconsGroup2[index],
                    currentIndexGroup2 == index,
                  ),
                ),
                iconSize: _iconSize,
                containerHeight: _navBarHeight,
                curve: Curves.ease,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}