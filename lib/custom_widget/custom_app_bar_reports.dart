import 'dart:async';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/goods/filter_app_bar_goods.dart' as goods;
import 'package:crm_task_manager/custom_widget/filter/page_2/income/filter_app_bar_income.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/orders/filter_app_bar_orders.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';

import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'filter/page_2/incoming/filter_app_bar_income.dart';
import 'filter/page_2/reports/cash_balance_filter.dart';
import 'filter/page_2/reports/goods_filter.dart';
import 'filter/page_2/reports/creditors_filter.dart';
import 'filter/page_2/reports/debtors_filter.dart';
import 'filter/page_2/reports/top_selling_goods_filter.dart';
import 'filter/page_2/reports/sales_dynamics_filter.dart';
import 'filter/page_2/reports/net_profit_filter.dart';
import 'filter/page_2/reports/sales_profitability_filter.dart';
import 'filter/page_2/reports/cost_structure_filter.dart';
import 'filter/page_2/reports/orders_count_filter.dart';

class CustomAppBarReports extends StatefulWidget {
  final String title;
  Function() onClickProfileAvatar;
  final FocusNode focusNode;
  final TextEditingController textEditingController;
  final ValueChanged<String>? onChangedSearchInput;
  Function(bool) clearButtonClick;
  Function(bool) clearButtonClickFilter;
  final bool showSearchIcon;
  final bool showFilterIcon;
  final Function(Map<String, dynamic>)? onFilterSelected;
  final VoidCallback? onResetFilters;
  final Map<String, dynamic> currentFilters;
  final List<String>? initialLabels;
  final int currentTabIndex;

  CustomAppBarReports({
    super.key,
    required this.title,
    required this.onClickProfileAvatar,
    required this.onChangedSearchInput,
    required this.textEditingController,
    required this.focusNode,
    required this.clearButtonClick,
    required this.clearButtonClickFilter,
    this.showSearchIcon = true,
    this.showFilterIcon = true,
    this.onFilterSelected,
    this.onResetFilters,
    required this.currentFilters,
    this.initialLabels,
    required this.currentTabIndex,
  });

  @override
  State<CustomAppBarReports> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBarReports> with TickerProviderStateMixin {
  bool _isSearching = false;
  late TextEditingController _searchController;
  late FocusNode focusNode;
  String _userImage = '';
  String _lastLoadedImage = '';
  static String _cachedUserImage = '';
  bool _hasNewNotification = false;
  late PusherChannelsClient socketClient;
  StreamSubscription<ChannelReadEvent>? notificationSubscription;
  Timer? _checkOverdueTimer;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  bool _hasOverdueTasks = false;
  bool _canReadNotice = true;
  Color _iconColor = Colors.black;
  late Timer _timer;
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      //print('CustomAppBarReports: Инициализация AppBar');
    }
    _searchController = widget.textEditingController;
    focusNode = widget.focusNode;

    if (_cachedUserImage.isNotEmpty) {
      _userImage = _cachedUserImage;
    } else {
      _loadUserProfile();
    }

    _loadNotificationState();

    _blinkController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _blinkAnimation = CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    );
    _checkOverdueTasks();
    _checkOverdueTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkOverdueTasks(),
    );

    _timer = Timer.periodic(Duration(milliseconds: 700), (timer) {
      setState(() {
        _iconColor = (_iconColor == Colors.blue) ? Colors.black : Colors.blue;
      });
    });

    _isFiltering = widget.currentFilters.isNotEmpty;
  }

  Future<void> _checkOverdueTasks() async {
    try {
      final apiService = ApiService();
      final hasOverdue = await apiService.checkOverdueTasks();
      if (mounted) {
        setState(() {
          _hasOverdueTasks = hasOverdue;
        });
        if (kDebugMode) {
          //print('CustomAppBarReports: Проверка просроченных задач: $_hasOverdueTasks');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        //print('CustomAppBarReports: Ошибка проверки просроченных задач: $e');
      }
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _checkOverdueTimer?.cancel();
    _timer.cancel();
    notificationSubscription?.cancel();
    socketClient.disconnect();
    if (kDebugMode) {
      //print('CustomAppBarReports: Очистка ресурсов');
    }
    super.dispose();
  }

  Future<void> _loadNotificationState() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasNewNotification = prefs.getBool('hasNewNotification') ?? false;
    setState(() {
      _hasNewNotification = hasNewNotification;
    });
    if (kDebugMode) {
      //print('CustomAppBarReports: Загрузка состояния уведомлений: $_hasNewNotification');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String UUID = prefs.getString('userID') ?? AppLocalizations.of(context)!.translate('not_found');
      UserByIdProfile userProfile = await ApiService().getUserById(int.parse(UUID));

      if (userProfile.image != null && userProfile.image != _lastLoadedImage) {
        setState(() {
          _userImage = userProfile.image!;
          _lastLoadedImage = userProfile.image!;
          _cachedUserImage = userProfile.image!;
        });
        await prefs.setString('userProfileImage_$UUID', _userImage);
        if (kDebugMode) {
          //print('CustomAppBarReports: Загружено изображение профиля: $_userImage');
        }
      } else if (_userImage.isEmpty && _cachedUserImage.isNotEmpty) {
        setState(() {
          _userImage = _cachedUserImage;
        });
        if (kDebugMode) {
          //print('CustomAppBarReports: Использовано кэшированное изображение: $_userImage');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        //print('CustomAppBarReports: Ошибка загрузки профиля: $e');
      }
      if (_userImage.isEmpty && _cachedUserImage.isNotEmpty) {
        setState(() {
          _userImage = _cachedUserImage;
        });
      }
    }
  }

  Future<void> refreshUserImage() async {
    _lastLoadedImage = '';
    await _loadUserProfile();
    if (kDebugMode) {
      //print('CustomAppBarReports: Обновление изображения профиля');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.delayed(Duration(milliseconds: 1), () {
      if (mounted) {
        _loadUserProfile();
      }
    });
  }

  String? extractImageUrlFromSvg(String svg) {
    if (svg.contains('href="')) {
      final start = svg.indexOf('href="') + 6;
      final end = svg.indexOf('"', start);
      return svg.substring(start, end);
    }
    return null;
  }

  Color? extractBackgroundColorFromSvg(String svg) {
    final fillMatch = RegExp(r'fill="(#[A-Fa-f0-9]+)"').firstMatch(svg);
    if (fillMatch != null) {
      final colorHex = fillMatch.group(1);
      if (colorHex != null) {
        final hex = colorHex.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    return null;
  }

  Widget _buildAvatarImage(String imageSource) {
    if (imageSource.isEmpty) {
      return Image.asset(
        'assets/icons/playstore.png',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    }

    if (imageSource.startsWith('<svg')) {
      final imageUrl = extractImageUrlFromSvg(imageSource);

      if (imageUrl != null) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        final text = RegExp(r'>([^<]+)</text>').firstMatch(imageSource)?.group(1) ?? '';
        final backgroundColor = extractBackgroundColorFromSvg(imageSource) ?? Color(0xFF2C2C2C);

        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            border: Border.all(
              color: Colors.white,
              width: 0,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Image.network(
      imageSource,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center();
      },
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/icons/playstore.png',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: kToolbarHeight,
      color: Colors.white,
      padding: EdgeInsets.zero,
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: _buildAvatarImage(_userImage),
            onPressed: widget.onClickProfileAvatar,
          ),
        ),
        SizedBox(width: 8),
        if (!_isSearching)
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
        if (_isSearching)
          Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: _isSearching ? 200.0 : 0.0,
              child: TextField(
                controller: _searchController,
                focusNode: focusNode,
                onChanged: widget.onChangedSearchInput,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.translate('search_appbar'),
                  border: InputBorder.none,
                ),
                style: TextStyle(fontSize: 16),
                autofocus: true,
              ),
            ),
          ),
        if (widget.showSearchIcon)
          Transform.translate(
            offset: const Offset(10, 0),
            child: Tooltip(
              message: AppLocalizations.of(context)!.translate('search'),
              preferBelow: false,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              textStyle: TextStyle(
                fontSize: 12,
                color: Colors.black,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                icon: _isSearching
                    ? Icon(Icons.close)
                    : Image.asset(
                        'assets/icons/AppBar/search.png',
                        width: 24,
                        height: 24,
                      ),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                    }
                  });
                  widget.clearButtonClick(_isSearching);
                  if (_isSearching) {
                    Future.delayed(Duration(milliseconds: 100), () {
                      FocusScope.of(context).requestFocus(focusNode);
                    });
                  }
                  if (kDebugMode) {
                    //print('CustomAppBarReports: Переключение поиска: $_isSearching');
                  }
                },
              ),
            ),
          ),
        if (widget.showFilterIcon)
          IconButton(
            icon: Image.asset(
              'assets/icons/AppBar/filter.png',
              width: 24,
              height: 24,
              color: _isFiltering ? _iconColor : null,
            ),
            onPressed: () => navigateToFilterScreen(context),
          ),
      ]),
    );
  }

  void navigateToFilterScreen(BuildContext context) {
    if (kDebugMode) {
      print('CustomAppBarReports: Переход к экрану фильтров widget.currentTabIndex=${widget.currentTabIndex}');
      print('CustomAppBarReports: Текущие фильтры: ${widget.currentFilters}');
    }

    DateTime? initialFromDate;
    DateTime? initialToDate;
    String? sumFrom;
    String? sumTo;
    String? categoryId;
    String? daysWithoutMovement;
    String? goodId;

    // Extract filter parameters
    if (widget.currentFilters.containsKey('from_date')) {
      final fromDate = widget.currentFilters['from_date'];
      if (fromDate is DateTime) {
        initialFromDate = fromDate;
      } else if (fromDate is int) {
        initialFromDate = DateTime.fromMillisecondsSinceEpoch(fromDate);
      } else if (fromDate is String) {
        initialFromDate = DateTime.tryParse(fromDate);
      }
    }

    if (widget.currentFilters.containsKey('to_date')) {
      final toDate = widget.currentFilters['to_date'];
      if (toDate is DateTime) {
        initialToDate = toDate;
      } else if (toDate is int) {
        initialToDate = DateTime.fromMillisecondsSinceEpoch(toDate);
      } else if (toDate is String) {
        initialToDate = DateTime.tryParse(toDate);
      }
    }

    if (widget.currentFilters.containsKey('sum_from')) {
      final sumFromValue = widget.currentFilters['sum_from'];
      sumFrom = sumFromValue?.toString();
    }

    if (widget.currentFilters.containsKey('sum_to')) {
      final sumToValue = widget.currentFilters['sum_to'];
      sumTo = sumToValue?.toString();
    }

    if (widget.currentFilters.containsKey('category_id')) {
      final categoryIdValue = widget.currentFilters['category_id'];
      categoryId = categoryIdValue?.toString();
    }

    if (widget.currentFilters.containsKey('days_without_movement')) {
      final daysWithoutMovementValue = widget.currentFilters['days_without_movement'];
      daysWithoutMovement = daysWithoutMovementValue?.toString();
    }

    if (widget.currentFilters.containsKey('good_id')) {
      final goodIdValue = widget.currentFilters['good_id'];
      goodId = goodIdValue?.toString();
    }

    // Navigate to the appropriate filter screen based on currentTabIndex
    Widget filterScreen;
    switch (widget.currentTabIndex) {
      case 0:
        filterScreen = GoodsFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              print('CustomAppBarReports: Получены фильтры из GoodsFilterScreen: $filters');
            }
            setState(() {
              _isFiltering = filters.isNotEmpty;
            });
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              print('CustomAppBarReports: Сброс фильтров из GoodsFilterScreen');
            }
            setState(() {
              _isFiltering = false;
            });
            widget.onResetFilters?.call();
          },
          initialAmountFrom: sumFrom,
          initialAmountTo: sumTo,
          categoryId: categoryId,
          daysWithoutMovement: daysWithoutMovement,
          goodId: goodId,
        );
        break;
      case 1:
        filterScreen = CashBalanceFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              print('CustomAppBarReports: Получены фильтры из CashBalanceFilterScreen: $filters');
            }
            setState(() {
              _isFiltering = filters.isNotEmpty;
            });
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              print('CustomAppBarReports: Сброс фильтров из CashBalanceFilterScreen');
            }
            setState(() {
              _isFiltering = false;
            });
            widget.onResetFilters?.call();
          },
          initialFromDate: initialFromDate,
          initialToDate: initialToDate,
          initialAmountFrom: sumFrom,
          initialAmountTo: sumTo,
        );
        break;
      case 2:
        filterScreen = CreditorsFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              print('CustomAppBarReports: Получены фильтры из CreditorsFilterScreen: $filters');
            }
            setState(() {
              _isFiltering = filters.isNotEmpty;
            });
            debugPrint("CustomAppBarReports.filter: $filters");
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              print('CustomAppBarReports: Сброс фильтров из CreditorsFilterScreen');
            }
            setState(() {
              _isFiltering = false;
            });
            widget.onResetFilters?.call();
          },
          initialFromDate: initialFromDate,
          initialToDate: initialToDate,
          initialAmountFrom: sumFrom,
          initialAmountTo: sumTo,
        );
        break;
      case 3:
        filterScreen = DebtorsFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              print('CustomAppBarReports: Получены фильтры из DebtorsFilterScreen: $filters');
            }
            setState(() {
              _isFiltering = filters.isNotEmpty;
            });
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              print('CustomAppBarReports: Сброс фильтров из DebtorsFilterScreen');
            }
            setState(() {
              _isFiltering = false;
            });
            widget.onResetFilters?.call();
          },
          initialFromDate: initialFromDate,
          initialToDate: initialToDate,
          initialAmountFrom: sumFrom,
          initialAmountTo: sumTo,
        );
        break;
      case 4:
        filterScreen = TopSellingGoodsFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              print('CustomAppBarReports: Получены фильтры из TopSellingGoodsFilterScreen: $filters');
            }
            setState(() {
              _isFiltering = filters.isNotEmpty;
            });
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              print('CustomAppBarReports: Сброс фильтров из TopSellingGoodsFilterScreen');
            }
            setState(() {
              _isFiltering = false;
            });
            widget.onResetFilters?.call();
          },
          initialFromDate: initialFromDate,
          initialToDate: initialToDate,
          initialAmountFrom: sumFrom,
          initialAmountTo: sumTo,
        );
        break;
      case 5:
        filterScreen = SalesDynamicsFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              print('CustomAppBarReports: Получены фильтры из SalesDynamicsFilterScreen: $filters');
            }
            setState(() {
              _isFiltering = filters.isNotEmpty;
            });
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              print('CustomAppBarReports: Сброс фильтров из SalesDynamicsFilterScreen');
            }
            setState(() {
              _isFiltering = false;
            });
            widget.onResetFilters?.call();
          },
          initialFromDate: initialFromDate,
          initialToDate: initialToDate,
          initialAmountFrom: sumFrom,
          initialAmountTo: sumTo,
        );
        break;
      case 6:
        filterScreen = NetProfitFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              print('CustomAppBarReports: Получены фильтры из NetProfitFilterScreen: $filters');
            }
            setState(() {
              _isFiltering = filters.isNotEmpty;
            });
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              print('CustomAppBarReports: Сброс фильтров из NetProfitFilterScreen');
            }
            setState(() {
              _isFiltering = false;
            });
            widget.onResetFilters?.call();
          },
          initialFromDate: initialFromDate,
          initialToDate: initialToDate,
          initialAmountFrom: sumFrom,
          initialAmountTo: sumTo,
        );
        break;
      case 7:
        filterScreen = SalesProfitabilityFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              print('CustomAppBarReports: Получены фильтры из SalesProfitabilityFilterScreen: $filters');
            }
            setState(() {
              _isFiltering = filters.isNotEmpty;
            });
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              print('CustomAppBarReports: Сброс фильтров из SalesProfitabilityFilterScreen');
            }
            setState(() {
              _isFiltering = false;
            });
            widget.onResetFilters?.call();
          },
          initialFromDate: initialFromDate,
          initialToDate: initialToDate,
          initialAmountFrom: sumFrom,
          initialAmountTo: sumTo,
        );
        break;
      case 8:
        filterScreen = CostStructureFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              print('CustomAppBarReports: Получены фильтры из CostStructureFilterScreen: $filters');
            }
            setState(() {
              _isFiltering = filters.isNotEmpty;
            });
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              print('CustomAppBarReports: Сброс фильтров из CostStructureFilterScreen');
            }
            setState(() {
              _isFiltering = false;
            });
            widget.onResetFilters?.call();
          },
          initialFromDate: initialFromDate,
          initialToDate: initialToDate,
          initialAmountFrom: sumFrom,
          initialAmountTo: sumTo,
        );
        break;
      case 9:
        filterScreen = OrdersCountFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              print('CustomAppBarReports: Получены фильтры из OrdersCountFilterScreen: $filters');
            }
            setState(() {
              _isFiltering = filters.isNotEmpty;
            });
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              print('CustomAppBarReports: Сброс фильтров из OrdersCountFilterScreen');
            }
            setState(() {
              _isFiltering = false;
            });
            widget.onResetFilters?.call();
          },
          initialFromDate: initialFromDate,
          initialToDate: initialToDate,
          initialAmountFrom: sumFrom,
          initialAmountTo: sumTo,
        );
        break;
      default:
        if (kDebugMode) {
          print('CustomAppBarReports: Неизвестный индекс таба: ${widget.currentTabIndex}');
        }
        return; // Exit if tab index is invalid
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => filterScreen),
    );
  }
}
