import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crm_task_manager/api/service/localization/localization_service.dart';
import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/offline/db/app_database.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_barcode_scanner_screen.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_filter_sheet.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_payment_screen.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_product_card.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_quantity_screen.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_repository.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const _rmkLoading = Center(
  child: PlayStoreImageLoading(
    size: 80,
    duration: Duration(milliseconds: 1000),
  ),
);

class RmkScreen extends StatefulWidget {
  const RmkScreen({super.key});

  @override
  State<RmkScreen> createState() => _RmkScreenState();
}

class _RmkScreenState extends State<RmkScreen> {
  final RmkRepository _repository = RmkRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  DateTime? _lastBottomSyncAt;
  String _query = '';
  int? _categoryId;
  List<RmkCategory> _latestCategories = const [];
  List<WareHouse> _storages = const [];
  WareHouse? _selectedStorage;
  bool _isSyncing = false;
  bool _isSubmitting = false;
  bool _isLoadingStorages = false;
  bool _hasCompletedInitialLoad = false;
  bool _isSearching = false;
  bool _isSearchRequesting = false;
  bool _isCartReady = false;
  int _searchRequestId = 0;
  String _currencyTitle = 'TJS';

  @override
  void initState() {
    super.initState();
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = 80;
    imageCache.maximumSizeBytes = 48 << 20;
    _scrollController.addListener(_onScroll);
    unawaited(_resetCartSession());
    unawaited(_loadCurrency());
    unawaited(_loadStoragesAndSync());
  }

  Future<void> _resetCartSession() async {
    await _repository.clearCart();
    if (!mounted) return;
    setState(() => _isCartReady = true);
  }

  @override
  void dispose() {
    unawaited(_repository.clearCart());
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter > 500) return;

    final now = DateTime.now();
    final lastSync = _lastBottomSyncAt;
    if (lastSync != null && now.difference(lastSync).inSeconds < 20) return;

    _lastBottomSyncAt = now;
    unawaited(_runSync());
  }

  Future<void> _loadCurrency() async {
    final currency = await LocalizationService.getCurrency();
    if (!mounted) return;
    setState(() {
      _currencyTitle = currency?.symbolCode?.trim().isNotEmpty == true
          ? currency!.symbolCode!.trim()
          : (currency?.name?.trim().isNotEmpty == true
              ? currency!.name!.trim()
              : _currencyTitle);
    });
  }

  Future<void> _runSync({bool resetCatalogCache = false}) async {
    final storageId = _selectedStorage?.id;
    if (_isSyncing || storageId == null) return;
    setState(() => _isSyncing = true);
    try {
      await _repository.syncInBackground(
        storageId: storageId,
        resetCatalogCache: resetCatalogCache,
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _loadStoragesAndSync() async {
    if (_isLoadingStorages) return;
    setState(() => _isLoadingStorages = true);
    try {
      final storages = await _repository.getStorages();
      if (!mounted) return;

      final selectedStorage = storages.firstOrNull;
      setState(() {
        _storages = storages;
        _selectedStorage = selectedStorage;
      });

      if (selectedStorage != null) {
        unawaited(_runSync(resetCatalogCache: true));
      }
    } catch (error) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: 'Не удалось загрузить склады',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStorages = false;
          _hasCompletedInitialLoad = true;
        });
      }
    }
  }

  Future<void> _handlePullRefresh() async {
    await _runSync(resetCatalogCache: true);
  }

  bool get _isCatalogLoading => _isLoadingStorages || _isSyncing;

  String _emptyCatalogMessage() {
    if (_selectedStorage == null) {
      return 'Выберите склад в фильтре';
    }
    if (_query.isNotEmpty || _categoryId != null) {
      return 'Ничего не найдено';
    }
    return 'Нет товаров на выбранном складе';
  }

  Future<void> _selectStorage(WareHouse storage) async {
    if (_selectedStorage?.id == storage.id) return;
    await _repository.clearCart();
    setState(() {
      _selectedStorage = storage;
      _lastBottomSyncAt = null;
    });
    unawaited(_runSync(resetCatalogCache: true));
  }

  Future<void> _openStoragePicker() async {
    final colors = context.appColors;
    if (_storages.isEmpty) {
      await _loadStoragesAndSync();
      return;
    }

    final selected = await showModalBottomSheet<WareHouse>(
      context: context,
      backgroundColor: colors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderSubtle,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Склад',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontFamily: 'Gilroy',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: _storages.length,
                  itemBuilder: (context, index) {
                    final storage = _storages[index];
                    return _StoragePickerTile(
                      title: storage.name,
                      isSelected: storage.id == _selectedStorage?.id,
                      onTap: () => Navigator.pop(context, storage),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      await _selectStorage(selected);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() => _query = value);
      unawaited(_searchGoodsOnServer(value));
    });
  }

  Future<void> _searchGoodsOnServer(String value) async {
    final query = value.trim();
    final storageId = _selectedStorage?.id;
    if (query.isEmpty || storageId == null) {
      _searchRequestId += 1;
      if (mounted) {
        setState(() => _isSearchRequesting = false);
      }
      return;
    }

    final requestId = ++_searchRequestId;
    setState(() => _isSearchRequesting = true);
    try {
      await _repository.searchAndCacheGoods(query, storageId);
    } finally {
      if (mounted && requestId == _searchRequestId) {
        setState(() => _isSearchRequesting = false);
      }
    }
  }

  void _toggleSearch() {
    _searchDebounce?.cancel();
    _searchRequestId += 1;
    setState(() {
      _isSearching = !_isSearching;
      _isSearchRequesting = false;
      if (!_isSearching) {
        _searchController.clear();
        _query = '';
        _searchFocusNode.unfocus();
      }
    });

    if (_isSearching) {
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _openFilter(List<RmkCategory> categories) async {
    final selected = await showRmkFilterSheet(
      context: context,
      categories: categories,
      selectedCategoryId: _categoryId,
    );
    if (!mounted) return;
    setState(() => _categoryId = selected);
  }

  Future<void> _openMainFilter() async {
    final colors = context.appColors;
    final action = await showModalBottomSheet<_RmkFilterAction>(
      context: context,
      backgroundColor: colors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderSubtle,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Фильтр',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontFamily: 'Gilroy',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _RmkFilterOptionTile(
                  icon: Icons.warehouse_outlined,
                  title: 'Склад',
                  value: _selectedStorage?.name ?? 'Выберите склад',
                  isLoading: _isLoadingStorages,
                  onTap: () => Navigator.pop(context, _RmkFilterAction.storage),
                ),
                const SizedBox(height: 8),
                _RmkFilterOptionTile(
                  icon: Icons.tune_rounded,
                  title: 'Категория',
                  value: _selectedCategoryTitle(_latestCategories),
                  isActive: _categoryId != null,
                  onTap: () =>
                      Navigator.pop(context, _RmkFilterAction.category),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    switch (action) {
      case _RmkFilterAction.storage:
        await _openStoragePicker();
        return;
      case _RmkFilterAction.category:
        await _openFilter(_latestCategories);
        return;
    }
  }

  String _selectedCategoryTitle(List<RmkCategory> categories) {
    final id = _categoryId;
    if (id == null) return 'Все товары';
    for (final category in categories) {
      if (category.id == id) return category.name;
    }
    return 'Все товары';
  }

  List<_RmkCategoryStatusItem> _buildCategoryStatusItems(
    List<RmkCategory> categories,
  ) {
    final roots = categories.where((item) => item.parentId == null).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final items = <_RmkCategoryStatusItem>[
      const _RmkCategoryStatusItem(
        id: null,
        title: 'Все',
      ),
    ];

    void appendNode(RmkCategory category) {
      items.add(
        _RmkCategoryStatusItem(
          id: category.id,
          title: category.name,
        ),
      );

      final children = categories
          .where((item) => item.parentId == category.id)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      for (final child in children) {
        appendNode(child);
      }
    }

    for (final root in roots) {
      appendNode(root);
    }

    return items;
  }

  Future<void> _finishSale(List<RmkCartItem> items) async {
    if (items.isEmpty || _isSubmitting) return;
    final storageId = _selectedStorage?.id;
    if (storageId == null) {
      showCustomSnackBar(
        context: context,
        message: 'Выберите склад',
        isSuccess: false,
      );
      return;
    }

    final total = items.fold<double>(
      0,
      (sum, item) => sum + (item.customTotal ?? item.quantity * item.price),
    );
    final payment = await Navigator.push<RmkPaymentResult>(
      context,
      MaterialPageRoute(builder: (_) => RmkPaymentScreen(total: total)),
    );
    if (!mounted || payment == null) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await _repository.submitSale(
        items,
        storageId: storageId,
        paymentMode: payment.mode.value,
        paymentMethod: payment.method?.value,
        paidAmount: payment.paidAmount,
        debtAmount: payment.debtAmount,
        leadId: payment.leadId,
        currencyId: payment.currencyId,
        exchangeRate: payment.exchangeRate,
        comment: payment.comment,
      );
      if (!mounted) return;

      showCustomSnackBar(
        context: context,
        message: result.sentToServer
            ? 'Продажа успешно создана'
            : (result.error ?? 'Ошибка при создании продажи'),
        isSuccess: result.sentToServer,
      );
    } catch (error) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: error.toString(),
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openQuantityScreen(RmkGood good) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RmkQuantityScreen(
          good: good,
          repository: _repository,
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final storageId = _selectedStorage?.id;
    if (storageId == null) {
      showCustomSnackBar(
        context: context,
        message: 'Выберите склад',
        isSuccess: false,
      );
      return;
    }

    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const RmkBarcodeScannerScreen()),
    );
    if (!mounted || barcode == null || barcode.isEmpty) return;

    final good = await _repository.findGoodByBarcode(
      barcode,
      storageId: storageId,
    );
    if (!mounted) return;
    if (good == null) {
      showCustomSnackBar(
        context: context,
        message: 'Товар по штрихкоду не найден',
        isSuccess: false,
      );
      return;
    }
    await _openQuantityScreen(good);
  }

  Future<void> _openSelectedItemsSheet(List<RmkCartItem> items) async {
    if (items.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final colors = sheetContext.appColors;
        return StreamBuilder<List<RmkCartItem>>(
          stream: _repository.watchCart(),
          initialData: items,
          builder: (context, snapshot) {
            final cartItems = snapshot.data ?? const <RmkCartItem>[];
            if (cartItems.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (sheetContext.mounted && Navigator.of(sheetContext).canPop()) {
                  Navigator.of(sheetContext).pop();
                }
              });
            }
            final total = cartItems.fold<double>(
              0,
              (sum, item) =>
                  sum + (item.customTotal ?? item.quantity * item.price),
            );

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.72,
              minChildSize: 0.46,
              maxChildSize: 0.92,
              builder: (context, controller) {
                return Container(
                  decoration: BoxDecoration(
                    color: colors.surfacePrimary,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xffD7DEE9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Выбранные товары',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontFamily: 'Gilroy',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (cartItems.isNotEmpty)
                              TextButton(
                                onPressed: () => unawaited(_repository.clearCart()),
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.buttonDangerBg,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Очистить',
                                  style: TextStyle(
                                    color: colors.buttonDangerBg,
                                    fontFamily: 'Gilroy',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfacePrimary,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: colors.borderSubtle),
                              ),
                              child: Text(
                                '${cartItems.length} шт',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontFamily: 'Gilroy',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: cartItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return _RmkSelectedCartCard(
                              item: item,
                              onRemove: () =>
                                  unawaited(_repository.removeCartItem(item.goodId)),
                              onTap: () async {
                                Navigator.pop(sheetContext);
                                final good =
                                    await _repository.getGoodById(item.goodId);
                                if (!mounted || good == null) return;
                                await _openQuantityScreen(good);
                              },
                            );
                          },
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfacePrimary,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.borderSubtle),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.shadow.withValues(alpha: 0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Итого',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontFamily: 'Gilroy',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatMoney(total),
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontFamily: 'Gilroy',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final themeController = AppThemeController.instance;
    final isDark = themeController.isDarkMode ||
        Theme.of(context).brightness == Brightness.dark;
    final appBarForeground = isDark ? colors.textInverse : colors.textPrimary;
    final appBarShellColor =
        isDark ? colors.surfaceElevated : colors.surfacePrimary;
    if (kDebugMode) {
      debugPrint(
        'RMK AppBar theme: mode=${themeController.themeMode}, '
        'isDark=$isDark, brightness=${Theme.of(context).brightness}, '
        'fg=${appBarForeground.toARGB32().toRadixString(16)}, '
        'shell=${appBarShellColor.toARGB32().toRadixString(16)}',
      );
    }

    return Scaffold(
      backgroundColor: colors.surfacePrimary,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: colors.surfacePrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        leadingWidth: 74,
        titleSpacing: 8,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Material(
            color: appBarShellColor,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              splashColor: colors.buttonPrimaryBg.withValues(alpha: 0.08),
              highlightColor: colors.buttonPrimaryBg.withValues(alpha: 0.05),
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: appBarForeground,
                ),
              ),
            ),
          ),
        ),
        title: _isSearching
            ? _AppBarSearchField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
              )
            : _AppBarTitleShell(
                title: 'РМК',
                textColor: appBarForeground,
                backgroundColor: appBarShellColor,
              ),
        actions: _isSearching
            ? [
                _AppBarActionButton(
                  tooltip: 'Закрыть поиск',
                  icon: Icon(
                    Icons.close,
                    color: appBarForeground,
                    size: 24,
                  ),
                  onPressed: _toggleSearch,
                ),
                const SizedBox(width: 6),
              ]
            : [
                _AppBarActionButton(
                  tooltip: 'Поиск',
                  icon: Image.asset(
                    'assets/icons/AppBar/search.png',
                    width: 24,
                    height: 24,
                    color: appBarForeground,
                  ),
                  onPressed: _toggleSearch,
                ),
                _AppBarActionButton(
                  tooltip: 'Фильтр',
                  icon: Image.asset(
                    'assets/icons/AppBar/filter.png',
                    width: 24,
                    height: 24,
                    color: appBarForeground,
                  ),
                  onPressed: _openMainFilter,
                ),
                _AppBarActionButton(
                  tooltip: 'Сканер',
                  icon: Image.asset(
                    'assets/icons/AppBar/scanner.png',
                    width: 24,
                    height: 24,
                    color: appBarForeground,
                  ),
                  onPressed: _scanBarcode,
                ),
                const SizedBox(width: 6),
              ],
      ),
      body: StreamBuilder<List<RmkCartItem>>(
        stream: _repository.watchCart(),
        builder: (context, cartSnapshot) {
          final cartItems = _isCartReady
              ? (cartSnapshot.data ?? const <RmkCartItem>[])
              : const <RmkCartItem>[];
          final cartQuantities = {
            for (final item in cartItems) item.goodId: item.quantity,
          };
          final total = cartItems.fold<double>(
            0,
            (sum, item) =>
                sum + (item.customTotal ?? item.quantity * item.price),
          );

          return StreamBuilder<List<RmkCategory>>(
            stream: _repository.watchCategories(),
            builder: (context, categorySnapshot) {
              final categories = categorySnapshot.data ?? const <RmkCategory>[];
              _latestCategories = categories;

              return Column(
                children: [
                  Container(
                    color: colors.surfacePrimary,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Column(
                      children: [
                        _DoneButton(
                          total: total,
                          count: cartItems.length,
                          isLoading: _isSubmitting,
                          currencyTitle: _currencyTitle,
                          onOpenItems: () => _openSelectedItemsSheet(cartItems),
                          onTap: () => _finishSale(cartItems),
                        ),
                        const SizedBox(height: 10),
                        _CategoryStatusBar(
                          items: _buildCategoryStatusItems(categories),
                          selectedCategoryId: _categoryId,
                          onSelected: (categoryId) {
                            setState(() => _categoryId = categoryId);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: colors.textPrimary,
                      backgroundColor: colors.surfacePrimary,
                      onRefresh: _handlePullRefresh,
                      child: CustomScrollView(
                        controller: _scrollController,
                        cacheExtent: 280,
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          StreamBuilder<List<RmkGood>>(
                            stream: _repository.watchGoods(
                              query: _query,
                              categoryIds: _query.trim().isNotEmpty ||
                                      _categoryId == null
                                  ? null
                                  : RmkRepository
                                      .categoryIdsIncludingDescendants(
                                      _categoryId!,
                                      categories,
                                    ),
                            ),
                            builder: (context, goodsSnapshot) {
                              final goods =
                                  goodsSnapshot.data ?? const <RmkGood>[];
                              final hasSearchQuery = _query.trim().isNotEmpty;
                              final showFullScreenLoader = goods.isEmpty &&
                                  (hasSearchQuery
                                      ? _isSearchRequesting
                                      : _isCatalogLoading);
                              if (showFullScreenLoader) {
                                return const SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: _rmkLoading,
                                );
                              }

                              if (goods.isEmpty) {
                                return SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                        _hasCompletedInitialLoad
                                            ? _emptyCatalogMessage()
                                            : 'Загрузка каталога...',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontFamily: 'Gilroy',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return SliverMainAxisGroup(
                                slivers: [
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      18,
                                    ),
                                    sliver: SliverGrid(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount:
                                            MediaQuery.sizeOf(context).width >=
                                                    900
                                                ? 5
                                                : MediaQuery.sizeOf(context)
                                                            .width >=
                                                        700
                                                    ? 4
                                                    : 3,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                        childAspectRatio:
                                            MediaQuery.sizeOf(context).width >=
                                                    700
                                                ? 0.76
                                                : 0.7,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final good = goods[index];
                                          return RmkProductCard(
                                            good: good,
                                            selectedQuantity:
                                                cartQuantities[good.id] ?? 0,
                                            onTap: () =>
                                                _openQuantityScreen(good),
                                          );
                                        },
                                        childCount: goods.length,
                                        addAutomaticKeepAlives: false,
                                      ),
                                    ),
                                  ),
                                  if (_isSyncing && !hasSearchQuery)
                                    const SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          16,
                                          0,
                                          16,
                                          24,
                                        ),
                                        child: PlayStoreImageLoading(
                                          size: 48,
                                          duration: Duration(
                                            milliseconds: 1000,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _StoragePickerTile extends StatelessWidget {
  const _StoragePickerTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected ? colors.surfaceElevated : colors.surfacePrimary,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          splashColor: colors.buttonPrimaryBg.withValues(alpha: 0.08),
          highlightColor: colors.buttonPrimaryBg.withValues(alpha: 0.05),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(
                  Icons.warehouse_outlined,
                  color: colors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_rounded,
                    color: colors.buttonPrimaryBg,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _RmkFilterAction { storage, category }

class _RmkFilterOptionTile extends StatelessWidget {
  const _RmkFilterOptionTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.isActive = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final bool isActive;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = isActive ? colors.buttonPrimaryBg : colors.textSecondary;
    return Material(
      color: colors.surfaceElevated,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        splashColor: colors.buttonPrimaryBg.withValues(alpha: 0.08),
        highlightColor: colors.buttonPrimaryBg.withValues(alpha: 0.05),
        onTap: isLoading ? null : onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: PlayStoreImageLoading(
                    size: 24,
                    duration: Duration(milliseconds: 1000),
                  ),
                )
              else
                Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontFamily: 'Gilroy',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_right_rounded,
                color: colors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({
    required this.total,
    required this.count,
    required this.isLoading,
    required this.currencyTitle,
    required this.onOpenItems,
    required this.onTap,
  });

  final double total;
  final int count;
  final bool isLoading;
  final String currencyTitle;
  final VoidCallback onOpenItems;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEnabled = count > 0 && !isLoading;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isEnabled ? colors.buttonPrimaryBg : colors.surfaceElevated,
                foregroundColor:
                    isEnabled ? colors.buttonPrimaryFg : colors.textPrimary,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(
                    color: isEnabled ? Colors.transparent : colors.borderSubtle,
                  ),
                ),
              ),
              onPressed: isEnabled ? onTap : null,
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.buttonPrimaryFg,
                        ),
                      ),
                    )
                  : Text(
                      'Готово · ${_formatMoney(total)} $currencyTitle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isEnabled
                            ? colors.buttonPrimaryFg
                            : colors.textPrimary,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isEnabled ? colors.surfacePrimary : colors.surfaceElevated,
              foregroundColor:
                  isEnabled ? colors.buttonPrimaryBg : colors.textSecondary,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: isEnabled ? colors.borderSubtle : colors.borderSubtle,
                ),
              ),
            ),
            onPressed: isEnabled ? onOpenItems : null,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 22,
                  color:
                      isEnabled ? colors.buttonPrimaryBg : colors.textSecondary,
                ),
                if (count > 0)
                  Positioned(
                    top: 8,
                    right: 7,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: colors.buttonPrimaryBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: colors.buttonPrimaryFg,
                          fontFamily: 'Gilroy',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RmkCategoryStatusItem {
  const _RmkCategoryStatusItem({
    required this.id,
    required this.title,
  });

  final int? id;
  final String title;
}

class _CategoryStatusBar extends StatelessWidget {
  const _CategoryStatusBar({
    required this.items,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<_RmkCategoryStatusItem> items;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item.id == selectedCategoryId;
          return _CategoryStatusChip(
            title: item.title,
            isSelected: isSelected,
            onTap: () => onSelected(item.id),
          );
        },
      ),
    );
  }
}

class _CategoryStatusChip extends StatelessWidget {
  const _CategoryStatusChip({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: isSelected ? colors.buttonPrimaryBg : colors.surfacePrimary,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        splashColor: colors.buttonPrimaryBg.withValues(alpha: 0.08),
        highlightColor: colors.buttonPrimaryBg.withValues(alpha: 0.04),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? colors.buttonPrimaryBg : colors.borderSubtle,
            ),
          ),
          child: Center(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? colors.buttonPrimaryFg : colors.textPrimary,
                fontFamily: 'Gilroy',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RmkSelectedCartCard extends StatelessWidget {
  const _RmkSelectedCartCard({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  final RmkCartItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final total = item.customTotal ?? item.quantity * item.price;
    return Material(
      color: colors.surfacePrimary,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfacePrimary,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RmkSelectedItemImage(imageUrl: item.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _RmkMetaChip(
                          label: 'Кол-во',
                          value: _formatMoney(item.quantity),
                        ),
                        _RmkMetaChip(
                          label: 'Цена',
                          value: _formatMoney(item.price),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Material(
                    color: colors.surfaceElevated,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onRemove,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Сумма',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontFamily: 'Gilroy',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMoney(total),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RmkSelectedItemImage extends StatelessWidget {
  const _RmkSelectedItemImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 62,
        height: 62,
        child: url == null || url.isEmpty
            ? ColoredBox(
                color: colors.surfaceElevated,
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: colors.textSecondary,
                ),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: 220,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (_, __) =>
                    ColoredBox(color: colors.surfaceElevated),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: colors.surfaceElevated,
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: colors.textSecondary,
                  ),
                ),
              ),
      ),
    );
  }
}

class _RmkMetaChip extends StatelessWidget {
  const _RmkMetaChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'Gilroy',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: colors.textPrimary,
                fontFamily: 'Gilroy',
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarSearchField extends StatelessWidget {
  const _AppBarSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 42,
      child: TextSelectionTheme(
        data: TextSelectionThemeData(
          cursorColor: colors.buttonPrimaryBg,
          selectionColor: colors.buttonPrimaryBg.withValues(alpha: 0.2),
          selectionHandleColor: colors.buttonPrimaryBg,
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          autofocus: true,
          cursorColor: colors.buttonPrimaryBg,
          textInputAction: TextInputAction.search,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Поиск',
            hintStyle: TextStyle(
              color: colors.textSecondary,
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 21,
              color: colors.iconSecondary,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 42,
              minHeight: 42,
            ),
            filled: true,
            fillColor: colors.surfaceElevated,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: colors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: colors.buttonPrimaryBg),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarActionButton extends StatelessWidget {
  const _AppBarActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: colors.surfaceElevated,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            splashColor: colors.buttonPrimaryBg.withValues(alpha: 0.08),
            highlightColor: colors.buttonPrimaryBg.withValues(alpha: 0.05),
            onTap: onPressed,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(child: icon),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarTitleShell extends StatelessWidget {
  const _AppBarTitleShell({
    required this.title,
    required this.textColor,
    required this.backgroundColor,
  });

  final String title;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.borderSubtle),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontFamily: 'Gilroy',
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _formatMoney(double value) {
  if (value == value.roundToDouble()) return '${value.toInt()}';
  return value.toStringAsFixed(2);
}
