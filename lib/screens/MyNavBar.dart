import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MyNavBar extends StatefulWidget {
  final Function(int, int) onItemSelected;
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
  static final double _navBarHeight = 60;
  List<NavBarItemData>? _orderedItems;
  bool _isReordering = false;
  int _lastItemCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeOrder();
  }

  Future<void> _initializeOrder() async {
    final defaultItems = _getAllItems();
    
    if (defaultItems.isEmpty) {
      //print('⏳ Списки навигации пока пустые, ждём...');
      return;
    }
    
    final savedOrder = await _loadOrder();
    List<NavBarItemData> finalItems;
    
    if (savedOrder != null && savedOrder.isNotEmpty) {
      //print('✅ Загружен сохранённый порядок: ${savedOrder.length} элементов');
      finalItems = [];
      
      for (var savedItem in savedOrder) {
        try {
          final matchingItem = defaultItems.firstWhere(
            (item) => item.groupIndex == savedItem['group'] && 
                     item.itemIndex == savedItem['index'],
          );
          finalItems.add(matchingItem);
        } catch (e) {
          //print('⚠️ Элемент не найден: group=${savedItem['group']}, index=${savedItem['index']}');
        }
      }
      
      for (var item in defaultItems) {
        bool exists = finalItems.any((i) => 
          i.groupIndex == item.groupIndex && i.itemIndex == item.itemIndex
        );
        if (!exists) {
          finalItems.add(item);
          //print('➕ Добавлен новый элемент: group=${item.groupIndex}, index=${item.itemIndex}');
        }
      }
    } else {
      //print('📋 Сохранённый порядок не найден, используем по умолчанию');
      finalItems = defaultItems;
    }
    
    if (mounted) {
      setState(() {
        _orderedItems = finalItems;
        _lastItemCount = finalItems.length;
      });
    }
  }

  Future<List<Map<String, int>>?> _loadOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderJson = prefs.getString('navbar_order_v2');
      
      if (orderJson != null && orderJson.isNotEmpty) {
        //print('📦 JSON из SharedPreferences: $orderJson');
        final List<dynamic> decoded = json.decode(orderJson);
        final result = decoded.map((e) => Map<String, int>.from(e)).toList();
        //print('✅ Успешно декодировано: ${result.length} элементов');
        return result;
      } else {
        //print('❌ navbar_order_v2 пуст или null');
      }
    } catch (e) {
      //print('❌ Ошибка загрузки порядка: $e');
    }
    return null;
  }

  Future<void> _saveOrder(List<NavBarItemData> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final orderList = items.map((item) => {
        'group': item.groupIndex,
        'index': item.itemIndex,
      }).toList();
      
      final orderJson = json.encode(orderList);
      final success = await prefs.setString('navbar_order_v2', orderJson);
      
      if (success) {
        //print('💾 Порядок сохранён успешно: $orderJson');
        final verification = prefs.getString('navbar_order_v2');
        //print('✅ Проверка: данные в SharedPreferences = $verification');
      } else {
        //print('❌ Не удалось сохранить порядок');
      }
    } catch (e) {
      //print('❌ Ошибка сохранения порядка: $e');
    }
  }

  List<NavBarItemData> _getAllItems() {
    List<NavBarItemData> items = [];
    
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
    
    final currentItemCount = widget.navBarTitlesGroup1.length + widget.navBarTitlesGroup2.length;
    
    if (_orderedItems == null || _lastItemCount != currentItemCount) {
      //print('🔄 Количество элементов изменилось: $_lastItemCount -> $currentItemCount');
      _initializeOrder();
      return;
    }
    
    if (_orderedItems != null && _orderedItems!.isNotEmpty) {
      List<NavBarItemData> updatedItems = [];
      
      for (var orderedItem in _orderedItems!) {
        bool newIsActive = false;
        if (orderedItem.groupIndex == 1) {
          newIsActive = widget.currentIndexGroup1 == orderedItem.itemIndex;
        } else if (orderedItem.groupIndex == 2) {
          newIsActive = widget.currentIndexGroup2 == orderedItem.itemIndex;
        }
        
        updatedItems.add(NavBarItemData(
          title: orderedItem.title,
          activeIcon: orderedItem.activeIcon,
          inactiveIcon: orderedItem.inactiveIcon,
          groupIndex: orderedItem.groupIndex,
          itemIndex: orderedItem.itemIndex,
          isActive: newIsActive,
        ));
      }
      
      setState(() {
        _orderedItems = updatedItems;
      });
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveItem();
    });
  }

  void _scrollToActiveItem() {
    if (!_scrollController.hasClients || _orderedItems == null || _orderedItems!.isEmpty) return;
    
    int activeIndex = _orderedItems!.indexWhere((item) => item.isActive);
    
    if (activeIndex != -1) {
      double itemWidth = 120.0;
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
    // Если данные не загружены, показываем пустой контейнер БЕЗ спиннера
    if (_orderedItems == null || _orderedItems!.isEmpty) {
      return Container(
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
      );
    }

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
      child: ReorderableListView.builder(
        scrollController: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: _orderedItems!.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = _orderedItems!.removeAt(oldIndex);
            _orderedItems!.insert(newIndex, item);
            
            //print('🔄 Элемент перемещён с позиции $oldIndex на $newIndex');
            _saveOrder(_orderedItems!);
            _isReordering = false;
          });
        },
        onReorderStart: (index) {
          HapticFeedback.mediumImpact();
          setState(() {
            _isReordering = true;
          });
          //print('🖐️ Начато перемещение элемента на позиции $index');
        },
        onReorderEnd: (index) {
          setState(() {
            _isReordering = false;
          });
          //print('✋ Перемещение завершено');
        },
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final double scale = 1.0 + (animation.value * 0.1);
              final item = _orderedItems![index];
              
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: 0.9,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: item.isActive ? Color(0xff1E2E52) : Color(0xffF4F7FD),
                      border: Border.all(
                        color: Color(0xff1E2E52).withOpacity(0.5),
                        width: item.isActive ? 0 : 0.5,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xff1E2E52).withOpacity(0.4),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.drag_indicator,
                          size: 18,
                          color: item.isActive ? Color(0xffF4F7FD) : Color(0xff1E2E52).withOpacity(0.5),
                        ),
                        SizedBox(width: 6),
                        Image.asset(
                          item.isActive ? item.activeIcon : item.inactiveIcon,
                          width: 22,
                          height: 22,
                          color: item.isActive ? Color(0xffF4F7FD) : Color(0xff1E2E52),
                        ),
                        SizedBox(width: 8),
                        Text(
                          item.title,
                          style: TextStyle(
                            color: item.isActive ? Color(0xffF4F7FD) : Color(0xff1E2E52),
                            fontFamily: 'Golos',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        itemBuilder: (context, index) {
          final item = _orderedItems![index];
          return _NavBarItem(
            key: ValueKey('${item.groupIndex}_${item.itemIndex}'),
            data: item,
            isReordering: _isReordering,
            onTap: () {
              if (!_isReordering) {
                widget.onItemSelected(item.groupIndex, item.itemIndex);
              }
            },
          );
        },
      ),
    );

    // ИСПРАВЛЕННАЯ ЛОГИКА ДЛЯ iOS
    if (Platform.isIOS) {
      return SafeArea(
        top: false,    // Не трогаем верх
        bottom: true,  // Добавляем отступ снизу для home indicator
        child: navBarContent,
      );
    }

    // Для Android оставляем как было
    return SafeArea(
      top: false,
      child: navBarContent,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

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

class _NavBarItem extends StatelessWidget {
  final NavBarItemData data;
  final VoidCallback onTap;
  final bool isReordering;
  
  static const double _iconSize = 22;

  const _NavBarItem({
    required Key key,
    required this.data,
    required this.onTap,
    this.isReordering = false,
  }) : super(key: key);

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
            if (isReordering)
              Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.drag_indicator,
                  size: 18,
                  color: data.isActive ? Color(0xffF4F7FD) : Color(0xff1E2E52).withOpacity(0.5),
                ),
              ),
            Image.asset(
              data.isActive ? data.activeIcon : data.inactiveIcon,
              width: _iconSize,
              height: _iconSize,
              color: data.isActive ? Color(0xffF4F7FD) : Color(0xff1E2E52),
            ),
            SizedBox(width: 8),
            Text(
              data.title,
              style: TextStyle(
                color: data.isActive ? Color(0xffF4F7FD) : Color(0xff1E2E52),
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