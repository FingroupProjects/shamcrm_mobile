import 'dart:async';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/act_filter.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/expense_structure_filter.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/goods_movement_filter.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/manufacture_reports_filter.dart';
import 'package:crm_task_manager/models/user/user_byId_model..dart';

import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'filter/page_2/reports/cash_balance_filter.dart';
import 'filter/page_2/reports/goods_filter.dart';
import 'filter/page_2/reports/creditors_filter.dart';
import 'filter/page_2/reports/debtors_filter.dart';
import 'filter/page_2/reports/profitability_filters.dart';
import 'filter/page_2/reports/top_selling_goods_filter.dart';
import 'filter/page_2/reports/sales_dynamics_filter.dart';
import 'filter/page_2/reports/net_profit_filter.dart';
import 'filter/page_2/reports/orders_quantity_filter.dart';

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
  final Map<int, Map<String, dynamic>> currentFilters;
  final List<String>? initialLabels;
  final int currentTabIndex;
  final int currentTabId;

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
    required this.currentTabId,
  });

  @override
  State<CustomAppBarReports> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBarReports>
    with TickerProviderStateMixin {
  bool _isSearching = false;
  late TextEditingController _searchController;
  late FocusNode focusNode;
  String _userImage = '';
  String _lastLoadedImage = '';
  static String _cachedUserImage = '';
  bool _hasNewNotification = false;
  PusherChannelsClient? socketClient;
  StreamSubscription<ChannelReadEvent>? notificationSubscription;
  Timer? _checkOverdueTimer;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  bool _hasOverdueTasks = false;
  bool _canReadNotice = true;
  Color _iconColor = Colors.black;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      ////print('CustomAppBarReports: Инициализация AppBar');
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
  }

  @override
  void didUpdateWidget(CustomAppBarReports oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if tab changed or filters changed
    if (oldWidget.currentTabIndex != widget.currentTabIndex ||
        oldWidget.currentFilters != widget.currentFilters) {
      // No need to setState here, just rebuild
    }
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
          ////print('CustomAppBarReports: Проверка просроченных задач: $_hasOverdueTasks');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        ////print('CustomAppBarReports: Ошибка проверки просроченных задач: $e');
      }
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _checkOverdueTimer?.cancel();
    _timer.cancel();
    notificationSubscription?.cancel();
    socketClient?.disconnect();
    if (kDebugMode) {
      ////print('CustomAppBarReports: Очистка ресурсов');
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
      ////print('CustomAppBarReports: Загрузка состояния уведомлений: $_hasNewNotification');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String UUID = prefs.getString('userID') ??
          AppLocalizations.of(context)!.translate('not_found');
      UserByIdProfile userProfile =
          await ApiService().getUserById(int.parse(UUID));

      if (userProfile.image != null && userProfile.image != _lastLoadedImage) {
        setState(() {
          _userImage = userProfile.image!;
          _lastLoadedImage = userProfile.image!;
          _cachedUserImage = userProfile.image!;
        });
        await prefs.setString('userProfileImage_$UUID', _userImage);
        if (kDebugMode) {
          ////print('CustomAppBarReports: Загружено изображение профиля: $_userImage');
        }
      } else if (_userImage.isEmpty && _cachedUserImage.isNotEmpty) {
        setState(() {
          _userImage = _cachedUserImage;
        });
        if (kDebugMode) {
          ////print('CustomAppBarReports: Использовано кэшированное изображение: $_userImage');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        ////print('CustomAppBarReports: Ошибка загрузки профиля: $e');
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
      ////print('CustomAppBarReports: Обновление изображения профиля');
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
        final text =
            RegExp(r'>([^<]+)</text>').firstMatch(imageSource)?.group(1) ?? '';
        final backgroundColor =
            extractBackgroundColorFromSvg(imageSource) ?? Color(0xFF2C2C2C);

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

  Widget _buildAppBarAssetIcon(
    BuildContext context,
    String assetPath, {
    Color? color,
    double size = 24,
  }) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      color: color ?? context.appColors.iconPrimary,
    );
  }

  Widget _buildSearchCloseButton(BuildContext context) {
    return AppBarShell.capsule(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Tooltip(
        message: AppLocalizations.of(context)!.translate('search'),
        preferBelow: false,
        decoration: BoxDecoration(
          color: context.appColors.surfacePrimary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: context.appShadows.card,
        ),
        textStyle: context.appTextStyles.bodySm.copyWith(
          color: context.appColors.textPrimary,
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(Icons.close, color: context.appColors.iconPrimary),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              FocusScope.of(context).unfocus();
            });
            widget.clearButtonClick(false);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate if current tab has filters
    final isFiltering =
        widget.currentFilters[widget.currentTabIndex]?.isNotEmpty ?? false;

    return AppBarShell(
      leading: _isSearching
          ? const SizedBox.shrink()
          : AppBarShell.capsule(
              context,
              width: AppBarShell.orbSize,
              padding: EdgeInsets.zero,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: _buildAvatarImage(_userImage),
                onPressed: widget.onClickProfileAvatar,
              ),
            ),
      center: !_isSearching
          ? AppBarShell.capsule(
              context,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: context.appTextStyles.titleLg.copyWith(
                        color: context.appColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          : TextField(
              controller: _searchController,
              focusNode: focusNode,
              onChanged: widget.onChangedSearchInput,
              onSubmitted: (value) {
                widget.onChangedSearchInput?.call(value);
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!
                    .translate('search_appbar'),
                border: InputBorder.none,
                hintStyle: context.appTextStyles.bodyMd.copyWith(
                  color: context.appColors.fieldHint,
                ),
              ),
              style: context.appTextStyles.bodyLg.copyWith(
                color: context.appColors.textPrimary,
              ),
              autofocus: true,
            ),
      trailing: _isSearching
          ? _buildSearchCloseButton(context)
          : (widget.showSearchIcon || widget.showFilterIcon)
              ? AppBarShell.capsule(
                  context,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showSearchIcon)
                        Tooltip(
                          message:
                              AppLocalizations.of(context)!.translate('search'),
                          preferBelow: false,
                          decoration: BoxDecoration(
                            color: context.appColors.surfacePrimary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: context.appShadows.card,
                          ),
                          textStyle: context.appTextStyles.bodySm.copyWith(
                            color: context.appColors.textPrimary,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            icon: _isSearching
                                ? Icon(Icons.close,
                                    color: context.appColors.iconPrimary)
                                : _buildAppBarAssetIcon(
                                    context,
                                    'assets/icons/AppBar/search.png',
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
                                ////print('CustomAppBarReports: Переключение поиска: $_isSearching');
                              }
                            },
                          ),
                        ),
                      if (!_isSearching) ...[
                        if (widget.showSearchIcon && widget.showFilterIcon)
                          Container(
                            width: 1,
                            height: 24,
                            color: context.appColors.borderSubtle.withValues(
                              alpha: 0.28,
                            ),
                          ),
                        if (widget.showFilterIcon)
                          IconButton(
                            icon: _buildAppBarAssetIcon(
                              context,
                              'assets/icons/AppBar/filter.png',
                              color: isFiltering
                                  ? _iconColor
                                  : context.appColors.iconPrimary,
                            ),
                            onPressed: () => navigateToFilterScreen(context),
                          ),
                      ],
                    ],
                  ),
                )
              : null,
    );
  }

  void navigateToFilterScreen(BuildContext context) {
    if (kDebugMode) {
      //print('CustomAppBarReports: Переход к экрану фильтров widget.currentTabId=${widget.currentTabIndex}');
      //print('CustomAppBarReports: Текущие фильтры: ${widget.currentFilters[widget.currentTabIndex]}');
    }

    DateTime? initialFromDate;
    DateTime? initialToDate;
    String? sumFrom;
    String? sumTo;
    String? categoryId;
    String? daysWithoutMovement;
    String? goodId;
    String? article_id;
    String? leadId;
    String? supplierId;
    String? statusId;
    DateTime? period;

    final currentFilter = widget.currentFilters[widget.currentTabIndex] ?? {};

    // Extract filter parameters
    if (currentFilter.containsKey('from_date') ||
        currentFilter.containsKey('date_from')) {
      final fromDate = currentFilter['from_date'] ?? currentFilter['date_from'];
      if (fromDate is DateTime) {
        initialFromDate = fromDate;
      } else if (fromDate is int) {
        initialFromDate = DateTime.fromMillisecondsSinceEpoch(fromDate);
      } else if (fromDate is String) {
        initialFromDate = DateTime.tryParse(fromDate);
      }
    }

    if (currentFilter.containsKey('to_date') ||
        currentFilter.containsKey('date_to')) {
      final toDate = currentFilter['to_date'] ?? currentFilter['date_to'];
      if (toDate is DateTime) {
        initialToDate = toDate;
      } else if (toDate is int) {
        initialToDate = DateTime.fromMillisecondsSinceEpoch(toDate);
      } else if (toDate is String) {
        initialToDate = DateTime.tryParse(toDate);
      }
    }

    if (currentFilter.containsKey('period')) {
      final period = currentFilter['period'];
      if (period is DateTime) {
        initialToDate = period;
      } else if (period is int) {
        initialToDate = DateTime.fromMillisecondsSinceEpoch(period);
      } else if (period is String) {
        initialToDate = DateTime.tryParse(period);
      }
    }

    if (currentFilter.containsKey('sum_from')) {
      final sumFromValue = currentFilter['sum_from'];
      sumFrom = sumFromValue?.toString();
    }

    if (currentFilter.containsKey('sum_to')) {
      final sumToValue = currentFilter['sum_to'];
      sumTo = sumToValue?.toString();
    }

    if (currentFilter.containsKey('category_id')) {
      final categoryIdValue = currentFilter['category_id'];
      categoryId = categoryIdValue?.toString();
    }

    if (currentFilter.containsKey('days_without_movement')) {
      final daysWithoutMovementValue = currentFilter['days_without_movement'];
      daysWithoutMovement = daysWithoutMovementValue?.toString();
    }

    if (currentFilter.containsKey('good_id')) {
      final goodIdValue = currentFilter['good_id'];
      goodId = goodIdValue?.toString();
    }

    if (currentFilter.containsKey('article_id')) {
      final expenseArticleIdValue = currentFilter['article_id'];
      article_id = expenseArticleIdValue?.toString();
    }

    if (currentFilter.containsKey('lead_id')) {
      final leadIdValue = currentFilter['lead_id'];
      leadId = leadIdValue?.toString();
    }

    if (currentFilter.containsKey('supplier_id')) {
      final supplierIdValue = currentFilter['supplier_id'];
      supplierId = supplierIdValue?.toString();
    }

    if (currentFilter.containsKey('status_id')) {
      final statusIdValue = currentFilter['status_id'];
      statusId = statusIdValue?.toString();
    }

    // Navigate to the appropriate filter screen based on currentTabId
    Widget filterScreen;
    switch (widget.currentTabId) {
      case 0:
        filterScreen = GoodsFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              //print('CustomAppBarReports: Получены фильтры из GoodsFilterScreen: $filters');
            }
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              //print('CustomAppBarReports: Сброс фильтров из GoodsFilterScreen');
            }
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
        filterScreen = ActFilterScreen(
            onSelectedDataFilter: (filters) {
              if (kDebugMode) {
                //print('CustomAppBarReports: Получены фильтры из ActFilterScreen: $filters');
              }
              widget.onFilterSelected?.call(filters);
            },
            onResetFilters: () {
              if (kDebugMode) {
                //print('CustomAppBarReports: Сброс фильтров из ActFilter');
              }
              widget.onResetFilters?.call();
            },
            initialFromDate: initialFromDate,
            initialToDate: initialToDate,
            // initialAmountFrom: sumFrom,
            // initialAmountTo: sumTo,
            initialLead: leadId,
            initialSupplier: supplierId);
        break;
      case 11:
        filterScreen = GoodsMovementFilterScreen(
            onSelectedDataFilter: (filters) {
              if (kDebugMode) {
                //print('CustomAppBarReports: Получены фильтры из GoodsMovementFilterScreen: $filters');
              }
              widget.onFilterSelected?.call(filters);
            },
            onResetFilters: () {
              if (kDebugMode) {
                //print('CustomAppBarReports: Сброс фильтров из GoodsMovementFilterScreen');
              }
              widget.onResetFilters?.call();
            },
            initialFromDate: initialFromDate,
            initialToDate: initialToDate,
            initialAmountFrom: sumFrom,
            initialAmountTo: sumTo,
            initialLead: leadId,
            initialSupplier: supplierId);
        break;
      case 2:
        filterScreen = CashBalanceFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              //print('CustomAppBarReports: Получены фильтры из CashBalanceFilterScreen: $filters');
            }
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              //print('CustomAppBarReports: Сброс фильтров из CashBalanceFilterScreen');
            }
            widget.onResetFilters?.call();
          },
          initialFromDate: initialFromDate,
          initialToDate: initialToDate,
          initialAmountFrom: sumFrom,
          initialAmountTo: sumTo,
        );
        break;
      case 3:
        filterScreen = CreditorsFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              //print('CustomAppBarReports: Получены фильтры из CreditorsFilterScreen: $filters');
            }
            debugPrint("CustomAppBarReports.filter: $filters");
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              //print('CustomAppBarReports: Сброс фильтров из CreditorsFilterScreen');
            }
            widget.onResetFilters?.call();
          },
          initialFromDate: initialFromDate,
          initialToDate: initialToDate,
          initialAmountFrom: sumFrom,
          initialAmountTo: sumTo,
          initialLead: leadId,
          initialSupplier: supplierId,
        );
        break;
      case 4:
        filterScreen = DebtorsFilterScreen(
            onSelectedDataFilter: (filters) {
              if (kDebugMode) {
                //print('CustomAppBarReports: Получены фильтры из DebtorsFilterScreen: $filters');
              }
              widget.onFilterSelected?.call(filters);
            },
            onResetFilters: () {
              if (kDebugMode) {
                //print('CustomAppBarReports: Сброс фильтров из DebtorsFilterScreen');
              }
              widget.onResetFilters?.call();
            },
            initialFromDate: initialFromDate,
            initialToDate: initialToDate,
            initialAmountFrom: sumFrom,
            initialAmountTo: sumTo,
            initialLead: leadId,
            initialSupplier: supplierId);
        break;
      case 5:
        filterScreen = TopSellingGoodsFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              //print('CustomAppBarReports: Получены фильтры из TopSellingGoodsFilterScreen: $filters');
            }
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              //print('CustomAppBarReports: Сброс фильтров из TopSellingGoodsFilterScreen');
            }
            widget.onResetFilters?.call();
          },
          sumFrom: sumFrom,
          sumTo: sumTo,
          dateFrom: initialFromDate,
          dateTo: initialToDate,
          categoryId: categoryId,
          goodId: goodId,
        );
        break;
      case 6:
        filterScreen = SalesDynamicsFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              //print('CustomAppBarReports: Получены фильтры из SalesDynamicsFilterScreen: $filters');
            }
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              //print('CustomAppBarReports: Сброс фильтров из SalesDynamicsFilterScreen');
            }
            widget.onResetFilters?.call();
          },
          categoryId: categoryId,
          goodId: goodId,
          period: period,
        );
        break;
      case 7:
        filterScreen = NetProfitFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              //print('CustomAppBarReports: Получены фильтры из NetProfitFilterScreen: $filters');
            }
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              //print('CustomAppBarReports: Сброс фильтров из NetProfitFilterScreen');
            }
            widget.onResetFilters?.call();
          },
          categoryId: categoryId,
          goodId: goodId,
          period: period,
        );
        break;
      case 8:
        filterScreen = ProfitabilityFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              //print('CustomAppBarReports: Получены фильтры из ProfitabilityFilterScreen: $filters');
            }
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              //print('CustomAppBarReports: Сброс фильтров из ProfitabilityFilterScreen');
            }
            widget.onResetFilters?.call();
          },
          period: period,
          categoryId: categoryId,
          goodId: goodId,
        );
        break;
      case 9:
        filterScreen = ExpenseStructureFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              //print('CustomAppBarReports: Получены фильтры из ExpenseStructureFilterScreen: $filters');
            }
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              //print('CustomAppBarReports: Сброс фильтров из ExpenseStructureFilterScreen');
            }
            widget.onResetFilters?.call();
          },
          categoryId: categoryId,
          articleId: article_id,
          initialDateFrom: initialFromDate,
          initialDateTo: initialToDate,
        );
        break;
      case 10:
        filterScreen = OrdersQuantityFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              //print('CustomAppBarReports: Получены фильтры из OrdersQuantityFilterScreen: $filters');
            }
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              //print('CustomAppBarReports: Сброс фильтров из OrdersQuantityFilterScreen');
            }
            widget.onResetFilters?.call();
          },
          initialFromDate: initialFromDate,
          initialToDate: initialToDate,
          initialSumFrom: sumFrom,
          initialSumTo: sumTo,
          initialStatus: statusId,
        );
        break;
      case 13:
      case 14:
        filterScreen = ManufactureReportsFilterScreen(
          onSelectedDataFilter: (filters) {
            widget.onFilterSelected?.call(filters);
          },
          onResetFilters: () {
            widget.onResetFilters?.call();
          },
          initialFromDate: initialFromDate,
          initialToDate: initialToDate,
          initialStorageId: currentFilter['storage_id']?.toString(),
          initialGoodId: currentFilter['good_id']?.toString(),
        );
        break;
      default:
        if (kDebugMode) {
          //print('CustomAppBarReports: Неизвестный id таба: ${widget.currentTabId}');
        }
        return; // Exit if tab index is invalid
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => filterScreen),
    );
  }
}
