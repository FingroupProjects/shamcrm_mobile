import 'dart:io';
import 'package:crm_task_manager/custom_widget/shimmer_wave.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const double _kNavBarHeight = 60;

class NavBarShimmerSkeleton extends StatelessWidget {
  final int itemCount;

  const NavBarShimmerSkeleton({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    Widget navBarContent = Container(
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 0),
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: ShimmerWave(
          duration: const Duration(milliseconds: 1650),
          colors: [
            context.appColors.surfacePrimary.withValues(alpha: 0.68),
            context.appColors.backgroundSecondary.withValues(alpha: 0.9),
            context.appColors.surfaceAccent.withValues(alpha: 0.28),
            context.appColors.surfacePrimary.withValues(alpha: 0.96),
            context.appColors.surfacePrimary.withValues(alpha: 0.68),
          ],
          stops: const [0.0, 0.32, 0.52, 0.68, 1.0],
          child: Row(
            children: List.generate(itemCount, (index) {
              final bool isLast = index == itemCount - 1;
              final int flex = index == 0 ? 5 : 4;

              return Expanded(
                flex: flex,
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 8),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: index == 0
                            ? [
                                context.appColors.buttonPrimaryBg.withValues(
                                  alpha: 0.9,
                                ),
                                context.appColors.buttonPrimaryBg.withValues(
                                  alpha: 0.68,
                                ),
                              ]
                            : [
                                context.appColors.surfacePrimary.withValues(
                                  alpha: 0.88,
                                ),
                                context.appColors.backgroundSecondary
                                    .withValues(alpha: 0.84),
                              ],
                      ),
                      border: Border.all(
                        color: index == 0
                            ? context.appColors.buttonPrimaryBg.withValues(
                                alpha: 0.7,
                              )
                            : context.appColors.borderSubtle.withValues(
                                alpha: 0.78,
                              ),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color:
                              context.appColors.shadow.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xffD8F0FF),
                                Color(0xffFDFEFF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xffDCF2FF),
                                  Color(0xffFDFEFF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );

    if (Platform.isIOS) {
      return SafeArea(
        top: false,
        bottom: true,
        child: navBarContent,
      );
    }

    return SafeArea(
      top: false,
      child: navBarContent,
    );
  }
}

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
  final List<int> unreadCountsGroup1;
  final List<int> unreadCountsGroup2;

  const MyNavBar({
    super.key,
    required this.onItemSelected,
    required this.navBarTitlesGroup1,
    required this.navBarTitlesGroup2,
    required this.activeIconsGroup1,
    required this.activeIconsGroup2,
    required this.inactiveIconsGroup1,
    required this.inactiveIconsGroup2,
    this.unreadCountsGroup1 = const [],
    this.unreadCountsGroup2 = const [],
    this.currentIndexGroup1 = -1,
    this.currentIndexGroup2 = -1,
  });

  @override
  State<MyNavBar> createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> {
  final ScrollController _scrollController = ScrollController();
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
            (item) =>
                item.groupIndex == savedItem['group'] &&
                item.itemIndex == savedItem['index'],
          );
          finalItems.add(matchingItem);
        } catch (e) {
          //print('⚠️ Элемент не найден: group=${savedItem['group']}, index=${savedItem['index']}');
        }
      }

      for (var item in defaultItems) {
        bool exists = finalItems.any((i) =>
            i.groupIndex == item.groupIndex && i.itemIndex == item.itemIndex);
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

      final orderList = items
          .map((item) => {
                'group': item.groupIndex,
                'index': item.itemIndex,
              })
          .toList();

      final orderJson = json.encode(orderList);
      final success = await prefs.setString('navbar_order_v2', orderJson);

      if (success) {
        //print('💾 Порядок сохранён успешно: $orderJson');
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
        unreadCount: i < widget.unreadCountsGroup1.length
            ? widget.unreadCountsGroup1[i]
            : 0,
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
        unreadCount: i < widget.unreadCountsGroup2.length
            ? widget.unreadCountsGroup2[i]
            : 0,
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

    final currentItemCount =
        widget.navBarTitlesGroup1.length + widget.navBarTitlesGroup2.length;

    if (_orderedItems == null || _lastItemCount != currentItemCount) {
      //print('🔄 Количество элементов изменилось: $_lastItemCount -> $currentItemCount');
      _initializeOrder();
      return;
    }

    if (_orderedItems != null && _orderedItems!.isNotEmpty) {
      final currentItems = _getAllItems();
      List<NavBarItemData> updatedItems = [];

      for (var orderedItem in _orderedItems!) {
        final latestItemIndex = currentItems.indexWhere((item) {
          return item.groupIndex == orderedItem.groupIndex &&
              item.itemIndex == orderedItem.itemIndex;
        });

        if (latestItemIndex == -1) {
          continue;
        }

        final latestItem = currentItems[latestItemIndex];

        updatedItems.add(NavBarItemData(
          title: latestItem.title,
          activeIcon: latestItem.activeIcon,
          inactiveIcon: latestItem.inactiveIcon,
          unreadCount: latestItem.unreadCount,
          groupIndex: latestItem.groupIndex,
          itemIndex: latestItem.itemIndex,
          isActive: latestItem.isActive,
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
    if (!_scrollController.hasClients ||
        _orderedItems == null ||
        _orderedItems!.isEmpty) return;

    int activeIndex = _orderedItems!.indexWhere((item) => item.isActive);

    if (activeIndex != -1) {
      double itemWidth = 120.0;
      double targetOffset = (activeIndex * itemWidth) -
          (MediaQuery.of(context).size.width / 2) +
          (itemWidth / 2);

      targetOffset =
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

      _scrollController.animateTo(
        targetOffset,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Пока порядок кнопок грузится из SharedPreferences, показываем skeleton,
    // чтобы нижняя панель не появлялась резким пустым блоком.
    if (_orderedItems == null || _orderedItems!.isEmpty) {
      return NavBarShimmerSkeleton(
        itemCount: widget.navBarTitlesGroup1.isNotEmpty ||
                widget.navBarTitlesGroup2.isNotEmpty
            ? (widget.navBarTitlesGroup1.length +
                    widget.navBarTitlesGroup2.length)
                .clamp(3, 4)
            : 4,
      );
    }

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    Widget navBarContent = Container(
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 0),
      color: Colors.transparent,
      child: SizedBox(
        height: _kNavBarHeight,
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

              _saveOrder(_orderedItems!);
              _isReordering = false;
            });
          },
          onReorderStart: (index) {
            HapticFeedback.mediumImpact();
            setState(() {
              _isReordering = true;
            });
          },
          onReorderEnd: (index) {
            setState(() {
              _isReordering = false;
            });
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: item.isActive
                            ? context.appColors.buttonPrimaryBg.withValues(
                                alpha: 0.96,
                              )
                            : context.appColors.surfacePrimary.withValues(
                                alpha: 0.68,
                              ),
                        border: Border.all(
                          color: item.isActive
                              ? context.appColors.buttonPrimaryBg
                              : context.appColors.borderSubtle.withValues(
                                  alpha: 0.8,
                                ),
                          width: item.isActive ? 1 : 0.8,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: item.isActive
                                ? context.appColors.buttonPrimaryBg.withValues(
                                    alpha: 0.28,
                                  )
                                : context.appColors.shadow.withValues(
                                    alpha: 0.08,
                                  ),
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
                            color: item.isActive
                                ? context.appColors.buttonPrimaryFg
                                : context.appColors.iconSecondary,
                          ),
                          SizedBox(width: 6),
                          Image.asset(
                            item.isActive ? item.activeIcon : item.inactiveIcon,
                            width: 22,
                            height: 22,
                            color: item.isActive
                                ? context.appColors.buttonPrimaryFg
                                : context.appColors.iconSecondary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            item.title,
                            style: TextStyle(
                              color: item.isActive
                                  ? context.appColors.buttonPrimaryFg
                                  : context.appColors.textPrimary.withValues(
                                      alpha: 0.78,
                                    ),
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
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
      ),
    );

    return navBarContent;
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
  final int unreadCount;
  final int groupIndex;
  final int itemIndex;
  final bool isActive;

  NavBarItemData({
    required this.title,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.unreadCount,
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: data.isActive
                  ? context.appColors.buttonPrimaryBg.withValues(alpha: 0.96)
                  : context.appColors.surfacePrimary.withValues(alpha: 0.68),
              border: Border.all(
                color: data.isActive
                    ? context.appColors.buttonPrimaryBg
                    : context.appColors.borderSubtle.withValues(alpha: 0.82),
                width: data.isActive ? 1 : 0.8,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: data.isActive
                  ? [
                      BoxShadow(
                        color: context.appColors.buttonPrimaryBg.withValues(
                          alpha: 0.28,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
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
                      color: data.isActive
                          ? context.appColors.buttonPrimaryFg
                          : context.appColors.iconSecondary,
                    ),
                  ),
                Image.asset(
                  data.isActive ? data.activeIcon : data.inactiveIcon,
                  width: _iconSize,
                  height: _iconSize,
                  color: data.isActive
                      ? context.appColors.buttonPrimaryFg
                      : context.appColors.iconSecondary,
                ),
                SizedBox(width: 8),
                Text(
                  data.title,
                  style: TextStyle(
                    color: data.isActive
                        ? context.appColors.buttonPrimaryFg
                        : context.appColors.textPrimary.withValues(alpha: 0.78),
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          if (data.unreadCount > 0)
            Positioned(
              top: -8,
              left: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: const BoxDecoration(
                  color: Color(0xffF44336),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  data.unreadCount > 99 ? '99+' : '${data.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Golos',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
