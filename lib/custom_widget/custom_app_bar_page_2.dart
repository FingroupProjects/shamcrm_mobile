
import 'dart:async';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/goods/filter_app_bar_goods.dart';
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

import 'filter/page_2/incoming/filter_app_bar_incoming.dart';

class CustomAppBarPage2 extends StatefulWidget {
  String title;
  Function() onClickProfileAvatar;
  FocusNode focusNode;
  TextEditingController textEditingController;
  ValueChanged<String>? onChangedSearchInput;
  Function(bool) clearButtonClick;
  Function(bool) clearButtonClickFiltr;

  final bool showSearchIcon;
  final bool showFilterIcon;
  final bool showFilterOrderIcon;
  final bool showFilterIncomeIcon;
  final bool showFilterIncomingIcon;

  final Function(Map<String, dynamic>)? onFilterGoodsSelected;
  final Function(Map<String, dynamic>)? onFilterIncomeSelected; // money income
  final Function(Map<String, dynamic>)? onFilterIncomingSelected; // new filter for documents -> incoming screen

  final VoidCallback? onGoodsResetFilters;
  final VoidCallback? onIncomeResetFilters; // money income
  final VoidCallback? onIncomingResetFilters; // new filter for documents -> incoming screen

  final Map<String, dynamic> currentFilters;
  final List<String>? initialLabels;

  CustomAppBarPage2({
    super.key,
    required this.title,
    required this.onClickProfileAvatar,
    required this.onChangedSearchInput,
    required this.textEditingController,
    required this.focusNode,
    required this.clearButtonClick,
    required this.clearButtonClickFiltr,
    this.showSearchIcon = true,
    this.showFilterIcon = true,
    this.showFilterOrderIcon = true,
    this.showFilterIncomeIcon = false,
    this.showFilterIncomingIcon = false,

    this.onFilterGoodsSelected,
    this.onFilterIncomeSelected,
    this.onFilterIncomingSelected,

    this.onGoodsResetFilters,
    this.onIncomeResetFilters,
    this.onIncomingResetFilters,

    required this.currentFilters,
    this.initialLabels,
  });

  @override
  State<CustomAppBarPage2> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBarPage2>
    with TickerProviderStateMixin {
  bool _isSearching = false;
  final ApiService _apiService = ApiService();
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
  bool _isGoodsFiltering = false;
  bool _canCreateProduct = false; // Новая переменная для права product.create
  bool _canCreateOrder = false; // Новая переменная для права order.create
  // bool _isGoodsFiltering = false;
  bool _isOrdersFiltering = false; // Новая переменная для фильтров заказов
  bool _isIncomeFiltering = false; // Новая переменная для фильтров доходов
  bool _isIncomingFiltering = false; //
  

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      //print('CustomAppBarPage2: Инициализация AppBar');
    }
    _searchController = widget.textEditingController;
    focusNode = widget.focusNode;

    if (_cachedUserImage.isNotEmpty) {
      _userImage = _cachedUserImage;
    } else {
      _loadUserProfile();
    }

    _loadNotificationState();
    _setUpSocketForNotifications();
    _checkPermissions(); // Проверяем права доступа при инициализации

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

    // Set initial filtering state based on currentFilters
    _isGoodsFiltering = widget.currentFilters.isNotEmpty ||
        (widget.currentFilters['managers'] != null &&
            widget.currentFilters['managers'].isNotEmpty);

            _isGoodsFiltering = widget.currentFilters.isNotEmpty ||
        (widget.currentFilters['managers'] != null &&
            widget.currentFilters['managers'].isNotEmpty);
    _isOrdersFiltering = widget.currentFilters.isNotEmpty ||
        (widget.currentFilters['fromDate'] != null ||
            widget.currentFilters['toDate'] != null ||
            widget.currentFilters['client'] != null ||
            widget.currentFilters['status'] != null ||
            widget.currentFilters['paymentMethod'] != null ||
            (widget.currentFilters['managers'] != null &&
                widget.currentFilters['managers'].isNotEmpty));
    
    _isIncomeFiltering = widget.currentFilters.isNotEmpty ||
        (widget.currentFilters['date_from'] != null ||
            widget.currentFilters['date_to'] != null ||
            widget.currentFilters['supplier_id'] != null ||
            widget.currentFilters['storage_id'] != null ||
            widget.currentFilters['status'] != null ||
            widget.currentFilters['author_id'] != null ||
            widget.currentFilters['deleted'] != null);

    _isIncomingFiltering = widget.currentFilters.isNotEmpty ||
        (widget.currentFilters['date_from'] != null ||
            widget.currentFilters['date_to'] != null ||
            widget.currentFilters['status'] != null ||
            widget.currentFilters['author_id'] != null ||
            widget.currentFilters['deleted'] != null);


  }

  Future<void> _checkPermissions() async {
    try {
      final canCreateProduct = await _apiService.hasPermission('product.create');
      final canCreateOrder = await _apiService.hasPermission('order.create');
      final canReadNotice = await _apiService.hasPermission('notice.read');
      setState(() {
        _canCreateProduct = canCreateProduct;
        _canCreateOrder = canCreateOrder;
        _canReadNotice = canReadNotice;
        if (kDebugMode) {
          //print('CustomAppBarPage2: Проверка разрешений: product.create = $_canCreateProduct, order.create = $_canCreateOrder, notice.read = $_canReadNotice');
        }
      });
    } catch (e) {
      setState(() {
        _canCreateProduct = false;
        _canCreateOrder = false;
        _canReadNotice = false;
        if (kDebugMode) {
          //print('CustomAppBarPage2: Ошибка при проверке прав: $e');
        }
      });
    }
  }
Future<void> _scanBarcode() async {
  try {
    // Открываем экран сканирования
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _BarcodeScannerScreen(),
      ),
    );
    
    if (result != null && result != '-1') {
      if (kDebugMode) {
        print('CustomAppBarPage2: Отсканирован штрихкод: $result');
      }
      context.read<GoodsBloc>().add(SearchGoodsByBarcode(result));
    } else {
      if (kDebugMode) {
        print('CustomAppBarPage2: Сканирование отменено');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('CustomAppBarPage2: Ошибка сканирования: $e');
    }
    showCustomSnackBar(
      context: context,
      message: AppLocalizations.of(context)!.translate('barcode_scan_error'),
      isSuccess: false,
    );
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
          //print('CustomAppBarPage2: Проверка просроченных задач: $_hasOverdueTasks');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        //print('CustomAppBarPage2: Ошибка проверки просроченных задач: $e');
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
      //print('CustomAppBarPage2: Очистка ресурсов');
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
      //print('CustomAppBarPage2: Загрузка состояния уведомлений: $_hasNewNotification');
    }
  }

  Future<void> _setUpSocketForNotifications() async {
    if (kDebugMode) {
      //print('CustomAppBarPage2: Настройка сокета для уведомлений');
    }
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final enteredDomainMap = await ApiService().getEnteredDomain();
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    String? enteredDomain = enteredDomainMap['enteredDomain'];

    final customOptions = PusherChannelsOptions.custom(
      uriResolver: (metadata) =>
          Uri.parse('wss://soketi.$enteredMainDomain/app/app-key'),
      metadata: PusherChannelsOptionsMetadata.byDefault(),
    );

    socketClient = PusherChannelsClient.websocket(
      options: customOptions,
      connectionErrorHandler: (exception, trace, refresh) {
        if (kDebugMode) {
          //print('CustomAppBarPage2: Ошибка соединения сокета: $exception');
        }
      },
      minimumReconnectDelayDuration: const Duration(seconds: 1),
    );

    String userId = prefs.getString('unique_id') ?? '';

    final myPresenceChannel = socketClient.presenceChannel(
      'presence-user.$userId',
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPresenceChannel(
        authorizationEndpoint: Uri.parse(
            'https://$enteredDomain-back.$enteredMainDomain/broadcasting/auth'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Tenant': '$enteredDomain-back'
        },
        onAuthFailed: (exception, trace) {
          if (kDebugMode) {
            //print('CustomAppBarPage2: Ошибка авторизации сокета: $exception');
          }
        },
      ),
    );

    socketClient.onConnectionEstablished.listen((_) {
      myPresenceChannel.subscribeIfNotUnsubscribed();
      notificationSubscription =
          myPresenceChannel.bind('notification.created').listen((event) {
        if (kDebugMode) {
          //print('CustomAppBarPage2: Получено уведомление: ${event.data}');
        }
        setState(() {
          _hasNewNotification = true;
        });
        prefs.setBool('hasNewNotification', true);
      });
    });

    try {
      await socketClient.connect();
      if (kDebugMode) {
        //print('CustomAppBarPage2: Успешное соединение сокета');
      }
    } catch (e) {
      if (kDebugMode) {
        //print('CustomAppBarPage2: Ошибка соединения сокета: $e');
      }
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
          //print('CustomAppBarPage2: Загружено изображение профиля: $_userImage');
        }
      } else if (_userImage.isEmpty && _cachedUserImage.isNotEmpty) {
        setState(() {
          _userImage = _cachedUserImage;
        });
        if (kDebugMode) {
          //print('CustomAppBarPage2: Использовано кэшированное изображение: $_userImage');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        //print('CustomAppBarPage2: Ошибка загрузки профиля: $e');
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
      //print('CustomAppBarPage2: Обновление изображения профиля');
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
                  hintText:
                      AppLocalizations.of(context)!.translate('search_appbar'),
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
                    //print('CustomAppBarPage2: Переключение поиска: $_isSearching');
                  }
                },
              ),
            ),
          ),
        if (widget.showFilterIncomeIcon)
          IconButton(
            icon: Padding(
              padding: const EdgeInsets.only(left: 0),
              child: Image.asset(
                'assets/icons/AppBar/filter.png',
                width: 24,
                height: 24,
                color: _isIncomeFiltering ? _iconColor : null,
              ),
            ),
            onPressed: () {
              navigateToIncomeFilterScreen(context);
            },
          ),
        if (widget.showFilterIncomingIcon)
          IconButton(
            icon: Padding(
              padding: const EdgeInsets.only(left: 0),
              child: Image.asset(
                'assets/icons/AppBar/filter.png',
                width: 24,
                height: 24,
                color: _isIncomingFiltering ? _iconColor : null,
              ),
            ),
            onPressed: () {
              navigateToIncomingFilterScreen(context);
            },
          ),
        if (widget.showFilterIcon && _canCreateProduct)
        IconButton(
          icon: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Image.asset(
              'assets/icons/AppBar/scanner.png',// Предполагается, что есть иконка для штрихкода
              width: 24,
              height: 24,
            ),
          ),
          onPressed: _scanBarcode,
          tooltip: AppLocalizations.of(context)!.translate('scan_barcode'),
        ),
               if (widget.showFilterIcon && _canCreateProduct)

        IconButton(
          icon: Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Image.asset(
              'assets/icons/AppBar/filter.png',
              width: 24,
              height: 24,
              color: _isGoodsFiltering ? _iconColor : null,
            ),
          ),
          onPressed: () {
            navigateToGoodsFilterScreen(context);
          },
        ),
      if (widget.showFilterOrderIcon && _canCreateOrder)
        IconButton(
          icon: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Image.asset(
              'assets/icons/AppBar/filter.png',
              width: 24,
              height: 24,
              color: _isOrdersFiltering ? _iconColor : null, // Добавляем мигание
            ),
          ),
          onPressed: () {
            navigateToOrderFilterScreen(context);
          },
        ),
    ]),
    );
  }

void navigateToGoodsFilterScreen(BuildContext context) {
  if (kDebugMode) {
    print('CustomAppBarPage2: Переход к экрану фильтров товаров');
    print('CustomAppBarPage2: Текущие фильтры: ${widget.currentFilters}');
  }
  List<int>? initialCategoryIds;
  double? initialDiscountPercent;
  List<String>? initialLabels;
  bool? initialIsActive;

  if (widget.currentFilters.containsKey('category_id') &&
      widget.currentFilters['category_id'] is List &&
      widget.currentFilters['category_id'].isNotEmpty) {
    initialCategoryIds = (widget.currentFilters['category_id'] as List)
        .map((id) => int.tryParse(id.toString()) ?? 0)
        .where((id) => id != 0)
        .toList();
  }

  if (widget.currentFilters.containsKey('discount_percent')) {
    initialDiscountPercent = widget.currentFilters['discount_percent'] is double
        ? widget.currentFilters['discount_percent']
        : double.tryParse(widget.currentFilters['discount_percent'].toString());
  }

  if (widget.currentFilters.containsKey('label_id') &&
      widget.currentFilters['label_id'] is List &&
      widget.currentFilters['label_id'].isNotEmpty) {
    initialLabels = List<String>.from(widget.currentFilters['label_id']);
  }

  if (widget.currentFilters.containsKey('is_active')) {
    initialIsActive = widget.currentFilters['is_active'] as bool?;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GoodsFilterScreen(
        onSelectedDataFilter: (filters) {
          if (kDebugMode) {
            print('CustomAppBarPage2: Получены фильтры из GoodsFilterScreen: $filters');
          }
          setState(() {
            _isGoodsFiltering = filters.isNotEmpty;
          });
          widget.onFilterGoodsSelected?.call(filters);
        },
        onResetFilters: () {
          if (kDebugMode) {
            print('CustomAppBarPage2: Сброс фильтров из GoodsFilterScreen');
          }
          setState(() {
            _isGoodsFiltering = false;
          });
          widget.onGoodsResetFilters?.call();
        },
        initialCategoryIds: initialCategoryIds,
        initialDiscountPercent: initialDiscountPercent,
        initialLabels: initialLabels,
        initialIsActive: initialIsActive,
      ),
    ),
  );
}

void navigateToOrderFilterScreen(BuildContext context) {
  if (kDebugMode) {
    print('CustomAppBarPage2: Переход к экрану фильтров заказов');
    print('CustomAppBarPage2: Текущие фильтры: ${widget.currentFilters}');
  }

  DateTime? initialFromDate = widget.currentFilters['fromDate'];
  DateTime? initialToDate = widget.currentFilters['toDate'];
  String? initialClient = widget.currentFilters['client'];
  String? initialStatus = widget.currentFilters['status'];
  String? initialPaymentMethod = widget.currentFilters['paymentMethod'];
  List<String>? initialManagers = widget.currentFilters['managers'] != null
      ? List<String>.from(widget.currentFilters['managers'])
      : null;
  List<String>? initialLeads = widget.currentFilters['leads'] != null
      ? List<String>.from(widget.currentFilters['leads'])
      : null;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => OrdersFilterScreen(
        onSelectedDataFilter: (filters) {
          if (kDebugMode) {
            //print('CustomAppBarPage2: Получены фильтры из OrdersFilterScreen: $filters');
          }
          setState(() {
            _isOrdersFiltering = filters.isNotEmpty ||
                (filters['managers'] != null && filters['managers'].isNotEmpty) ||
                (filters['leads'] != null && filters['leads'].isNotEmpty) ||
                filters['fromDate'] != null ||
                filters['toDate'] != null ||
                filters['client'] != null ||
                filters['status'] != null ||
                filters['paymentMethod'] != null;
          });
          widget.onFilterGoodsSelected?.call(filters);
        },
        onResetFilters: () {
          if (kDebugMode) {
            //print('CustomAppBarPage2: Сброс фильтров из OrdersFilterScreen');
          }
          setState(() {
            _isOrdersFiltering = false;
            widget.currentFilters.clear(); // Очищаем фильтры
          });
          widget.onGoodsResetFilters?.call();
        },
        initialFromDate: initialFromDate,
        initialToDate: initialToDate,
        initialClient: initialClient,
        initialStatus: initialStatus,
        initialPaymentMethod: initialPaymentMethod,
        initialManagers: initialManagers,
        initialLeads: initialLeads,
      ),
    ),
  );
}

  void navigateToIncomeFilterScreen(BuildContext context) {
    if (kDebugMode) {
      // print('CustomAppBarPage2: Переход к экрану фильтров доходов');
      // print('CustomAppBarPage2: Текущие фильтры: ${widget.currentFilters}');
    }

    DateTime? initialFromDate = widget.currentFilters['date_from'];
    DateTime? initialToDate = widget.currentFilters['date_to'];
    String? initialSupplier;
    String? initialStatus;
    String? initialAuthor;
    String? initialCashRegister;
    String? initialLead;
    bool? initialIsDeleted;

    if (widget.currentFilters.containsKey('supplier_id')) {
        initialSupplier = widget.currentFilters['supplier_id'];
    }

    if (widget.currentFilters.containsKey('cash_register_id')) {
        initialCashRegister = widget.currentFilters['cash_register_id'];
    }

    if (widget.currentFilters.containsKey('lead_id')) {
      initialLead = widget.currentFilters['lead_id'].toString();
    }

    if (widget.currentFilters.containsKey('status')) {
      initialStatus = widget.currentFilters['status'].toString();
    }

    if (widget.currentFilters.containsKey('author_id')) {
      initialAuthor = widget.currentFilters['author_id'].toString();
    }

    if (widget.currentFilters.containsKey('deleted')) {
      final deletedValue = widget.currentFilters['deleted'];
      if (deletedValue is String) {
        initialIsDeleted = deletedValue  == '1';
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncomeFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              print('CustomAppBarPage2: Получены фильтры из IncomeFilterScreen: $filters');
            }
            setState(() {
              _isIncomeFiltering = filters.isNotEmpty ||
                  filters['date_from'] != null ||
                  filters['date_to'] != null ||
                  filters['supplier'] != null ||
                  filters['approved'] != null ||
                  filters['author'] != null ||
                  filters['lead_id'] != null ||
                  filters['cash_register_id'] != null ||
                  filters['isDeleted'] != null;
            });
            debugPrint("_isIncomeFiltering: $_isIncomeFiltering");
            debugPrint("filters: $filters");
            widget.onFilterIncomeSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              print('CustomAppBarPage2: Сброс фильтров из IncomeFilterScreen');
            }
            setState(() {
              _isIncomeFiltering = false;
              widget.currentFilters.clear();
            });
            widget.onIncomeResetFilters?.call();
          },
          initialFromDate: initialFromDate,
          initialToDate: initialToDate,
          initialSupplier: initialSupplier,
          initialStatus: initialStatus,
          initialAuthor: initialAuthor,
          initialLead: initialLead,
          initialCashRegister: initialCashRegister,
          initialIsDeleted: initialIsDeleted,
        ),
      ),
    );
  }

  void navigateToIncomingFilterScreen(BuildContext context) {
    if (kDebugMode) {
      // print('CustomAppBarPage2: Переход к экрану фильтров доходов');
      // print('CustomAppBarPage2: Текущие фильтры: ${widget.currentFilters}');
    }

    DateTime? initialFromDate = widget.currentFilters['date_from'];
    DateTime? initialToDate = widget.currentFilters['date_to'];
    String? initialStatus;
    String? initialAuthor;
    bool? initialIsDeleted;

    if (widget.currentFilters.containsKey('status')) {
      initialStatus = widget.currentFilters['status'].toString();
    }

    if (widget.currentFilters.containsKey('author_id')) {
      initialAuthor = widget.currentFilters['author_id'].toString();
    }

    if (widget.currentFilters.containsKey('deleted')) {
      final deletedValue = widget.currentFilters['deleted'];
      if (deletedValue is String) {
        initialIsDeleted = deletedValue  == '1';
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncomingFilterScreen(
          onSelectedDataFilter: (filters) {
            if (kDebugMode) {
              print('CustomAppBarPage2: Получены фильтры из IncomingFilterScreen: $filters');
            }
            setState(() {
              _isIncomingFiltering = filters.isNotEmpty ||
                  filters['date_from'] != null ||
                  filters['date_to'] != null ||
                  filters['author_id'] != null;
            });
            debugPrint("_isIncomingFiltering: $_isIncomingFiltering");
            debugPrint("filters: $filters");
            widget.onFilterIncomingSelected?.call(filters);
          },
          onResetFilters: () {
            if (kDebugMode) {
              print('CustomAppBarPage2: Сброс фильтров из IncomingFilterScreen');
            }
            setState(() {
              _isIncomingFiltering = false;
              widget.currentFilters.clear();
            });
            widget.onIncomingResetFilters?.call();
          },
          initialFromDate: initialFromDate,
          initialToDate: initialToDate,
          initialStatus: initialStatus,
          initialAuthor: initialAuthor,
          initialIsDeleted: initialIsDeleted,
        ),
      ),
    );
  }

}

class _BarcodeScannerScreen extends StatefulWidget {
  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen>
    with TickerProviderStateMixin {
  MobileScannerController controller = MobileScannerController();
  bool isScanned = false;
  bool isFlashOn = false;
  
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Анимация сканирующей линии
    _scanLineController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    ));
    
    // Анимация пульсации углов
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  // Функция для выбора изображения из галереи и сканирования штрих-кода
  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        // Показываем индикатор загрузки
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
                  ),
                  // SizedBox(height: 16),
                  // Text(
                  //   'Сканирование изображения...',
                  //   style: TextStyle(color: Colors.white),
                  // ),
                ],
              ),
            ),
          ),
        );

        // Сканируем штрих-код из выбранного изображения
        final BarcodeCapture? barcodeCapture = await controller.analyzeImage(image.path);
        
        // Убираем индикатор загрузки
        Navigator.of(context).pop();
        
        if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
          final String code = barcodeCapture.barcodes.first.rawValue ?? '';
          if (code.isNotEmpty) {
            // Успешно нашли штрих-код
            HapticFeedback.lightImpact();
            Navigator.of(context).pop(code);
          } else {
            _showErrorMessage('Штрих-код не найден на изображении');
          }
        } else {
          _showErrorMessage('Штрих-код не найден на изображении');
        }
      }
    } catch (e) {
      // Убираем индикатор если он показывается
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showErrorMessage('Ошибка при обработке изображения');
    }
  }

  // Показать сообщение об ошибке
  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text(
              'Ошибка',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: Color(0xFF00FF88)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Камера на весь экран
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (!isScanned) {
                isScanned = true;
                // Вибрация при успешном сканировании
                HapticFeedback.lightImpact();
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String code = barcodes.first.rawValue ?? '';
                  Navigator.of(context).pop(code);
                }
              }
            },
          ),
          
          // Темный оверлей с вырезом для сканирования
          _buildScanOverlay(),
          
          // Верхняя панель
          _buildTopBar(),
          
          // Нижняя панель
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return CustomPaint(
      painter: ScanOverlayPainter(),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Container(
            width: 280,
            height: 280,
            child: Stack(
              children: [
                // Анимированные углы рамки
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ScanFramePainter(_pulseAnimation.value),
                      size: Size(280, 280),
                    );
                  },
                ),
                
                // Сканирующая линия
                AnimatedBuilder(
                  animation: _scanLineAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: _scanLineAnimation.value * 260 + 10,
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFF00FF88),
                              Color(0xFF00FF88),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF00FF88).withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Кнопка назад
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop('-1'),
              ),
            ),
            
            Expanded(
              child: Text(
                'Сканер штрих-кода',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Кнопка фонарика
            Container(
              decoration: BoxDecoration(
                color: isFlashOn 
                    ? Color(0xFF00FF88).withOpacity(0.2)
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFlashOn 
                      ? Color(0xFF00FF88)
                      : Colors.white.withOpacity(0.2),
                ),
              ),
              child: IconButton(
                icon: Icon(
                  isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: isFlashOn ? Color(0xFF00FF88) : Colors.white,
                ),
                onPressed: () {
                  controller.toggleTorch();
                  setState(() {
                    isFlashOn = !isFlashOn;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: 32,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Инструкция
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Color(0xFF00FF88),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Наведите камеру на штрих-код',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Кнопки действий
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Кнопка галереи
                _buildActionButton(
                  icon: Icons.photo_library,
                  label: 'Галерея',
                  onPressed: _pickImageFromGallery,
                ),
                
                // Центральная кнопка отмены
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () => Navigator.of(context).pop('-1'),
                  ),
                ),
                
                // Пустое место для симметрии
                SizedBox(width: 64),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    controller.dispose();
    super.dispose();
  }
}

// Класс для рисования оверлея с вырезом
class ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 280,
      height: 280,
    );

    final path = Path()
      ..addRect(rect)
      ..addRRect(RRect.fromRectAndRadius(scanRect, Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Класс для рисования анимированной рамки
class ScanFramePainter extends CustomPainter {
  final double animationValue;

  ScanFramePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF00FF88).withOpacity(animationValue)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0;
    final cornerRadius = 20.0;

    // Верхний левый угол
    canvas.drawPath(
      Path()
        ..moveTo(cornerRadius, 0)
        ..lineTo(cornerLength, 0)
        ..moveTo(0, cornerRadius)
        ..lineTo(0, cornerLength),
      paint,
    );

    // Верхний правый угол
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - cornerRadius, 0)
        ..moveTo(size.width, cornerRadius)
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Нижний левый угол
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height - cornerRadius)
        ..moveTo(cornerRadius, size.height)
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Нижний правый угол
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - cornerLength)
        ..lineTo(size.width, size.height - cornerRadius)
        ..moveTo(size.width - cornerRadius, size.height)
        ..lineTo(size.width - cornerLength, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}