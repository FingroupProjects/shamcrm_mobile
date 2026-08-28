import 'dart:async';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/localization/localization_service.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/offline/db/app_database.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_barcode_scanner_screen.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_filter_sheet.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_product_card.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_quantity_screen.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_repository.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

const _fastIncomingLoading = Center(
  child: PlayStoreImageLoading(
    size: 80,
    duration: Duration(milliseconds: 1000),
  ),
);

class FastIncomingScreen extends StatefulWidget {
  const FastIncomingScreen({super.key});

  @override
  State<FastIncomingScreen> createState() => _FastIncomingScreenState();
}

class _FastIncomingScreenState extends State<FastIncomingScreen> {
  final RmkRepository _repository = RmkRepository();
  final ApiService _apiService = ApiService();
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
  bool _hasApprovePermission = false;
  bool _isCartReady = false;
  String _currencyTitle = 'TJS';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_resetCartSession());
    unawaited(_loadCurrency());
    unawaited(_loadStoragesAndSync());
    unawaited(_checkApprovePermission());
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

  Future<void> _checkApprovePermission() async {
    try {
      final hasPermission =
          await _apiService.hasPermission('income_document.approve');
      if (!mounted) return;
      setState(() => _hasApprovePermission = hasPermission);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasApprovePermission = false);
    }
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
        await _runSync(resetCatalogCache: true);
      }
    } catch (_) {
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
    if (_storages.isEmpty) {
      await _loadStoragesAndSync();
      return;
    }

    final colors = context.appColors;
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
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
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
    _searchDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() => _query = value);
    });
  }

  void _toggleSearch() {
    _searchDebounce?.cancel();
    setState(() {
      _isSearching = !_isSearching;
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
      const _RmkCategoryStatusItem(id: null, title: 'Все'),
    ];

    void appendNode(RmkCategory category) {
      items.add(_RmkCategoryStatusItem(id: category.id, title: category.name));

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

  Future<void> _finishIncoming(List<RmkCartItem> items) async {
    if (items.isEmpty || _isSubmitting) return;
    final finish = await Navigator.push<_FastIncomingFinishResult>(
      context,
      MaterialPageRoute(
        builder: (_) => FastIncomingFinishScreen(
          total: items.fold<double>(
            0,
            (sum, item) =>
                sum + (item.customTotal ?? item.quantity * item.price),
          ),
          storages: _storages,
          selectedStorage: _selectedStorage,
          currencyTitle: _currencyTitle,
        ),
      ),
    );
    if (!mounted || finish == null) return;

    final storage = finish.storage ?? _selectedStorage;
    if (storage == null) {
      showCustomSnackBar(
        context: context,
        message: 'Выберите склад',
        isSuccess: false,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final goodsPayload = <Map<String, dynamic>>[];
      for (final item in items) {
        final unitId = await _repository.requiredUnitIdForCartItem(item);
        goodsPayload.add({
          'good_id': item.goodId,
          'quantity': item.quantity,
          'price': item.price,
          'unit_id': unitId,
          'sum': item.customTotal ?? item.quantity * item.price,
        });
      }

      final isoDate =
          DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(DateTime.now());

      await _apiService.createPurchaseDocument(
        date: isoDate,
        storageId: storage.id,
        supplierId: finish.supplier?.id,
        comment: 'PURCHASE',
        paidAmount: finish.paidAmount,
        debtAmount: finish.debtAmount,
        documentGoods: goodsPayload,
        organizationId: 1,
        salesFunnelId: 1,
        approve: _hasApprovePermission,
      );

      await _repository.clearCart();
      if (!mounted) return;

      showCustomSnackBar(
        context: context,
        message: 'Покупка товаров создана',
        isSuccess: true,
      );
    } catch (error) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: friendlyError(error),
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
          enforceStockLimit: false,
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

    final total = items.fold<double>(
      0,
      (sum, item) => sum + (item.customTotal ?? item.quantity * item.price),
    );

    final colors = context.appColors;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.46,
          maxChildSize: 0.92,
          builder: (context, controller) {
            return Container(
              color: colors.surfacePrimary,
              child: SafeArea(
                top: false,
                child: Column(
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${items.length} шт',
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
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _RmkSelectedCartCard(
                            item: item,
                            onTap: () async {
                              Navigator.pop(context);
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
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colors.shadow.withValues(alpha: 0.06),
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
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.surfacePrimary,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: colors.surfacePrimary,
        elevation: 0,
        titleSpacing: 16,
        title: _isSearching
            ? _AppBarSearchField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
              )
            : Text(
                'Покупка товаров',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
        actions: _isSearching
            ? [
                IconButton(
                  tooltip: 'Закрыть поиск',
                  style: IconButton.styleFrom(
                    foregroundColor: colors.iconPrimary,
                    overlayColor: colors.iconPrimary.withValues(alpha: 0.08),
                  ),
                  icon: Icon(
                    Icons.close,
                    color: colors.iconPrimary,
                    size: 24,
                  ),
                  onPressed: _toggleSearch,
                ),
                const SizedBox(width: 6),
              ]
            : [
                IconButton(
                  tooltip: 'Поиск',
                  style: IconButton.styleFrom(
                    foregroundColor: colors.iconPrimary,
                    overlayColor: colors.iconPrimary.withValues(alpha: 0.08),
                  ),
                  icon: Image.asset(
                    'assets/icons/AppBar/search.png',
                    width: 24,
                    height: 24,
                    color: colors.iconPrimary,
                  ),
                  onPressed: _toggleSearch,
                ),
                IconButton(
                  tooltip: 'Фильтр',
                  style: IconButton.styleFrom(
                    foregroundColor: colors.iconPrimary,
                    overlayColor: colors.iconPrimary.withValues(alpha: 0.08),
                  ),
                  icon: Image.asset(
                    'assets/icons/AppBar/filter.png',
                    width: 24,
                    height: 24,
                    color: colors.iconPrimary,
                  ),
                  onPressed: _openMainFilter,
                ),
                IconButton(
                  tooltip: 'Сканер',
                  style: IconButton.styleFrom(
                    foregroundColor: colors.iconPrimary,
                    overlayColor: colors.iconPrimary.withValues(alpha: 0.08),
                  ),
                  icon: Image.asset(
                    'assets/icons/AppBar/scanner.png',
                    width: 24,
                    height: 24,
                    color: colors.iconPrimary,
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
                          onTap: () => _finishIncoming(cartItems),
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
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          StreamBuilder<List<RmkGood>>(
                            stream: _repository.watchGoods(
                              query: _query,
                              categoryIds: _categoryId == null
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
                              if (_isCatalogLoading && goods.isEmpty) {
                                return const SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: _fastIncomingLoading,
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
                                        style: const TextStyle(
                                          color: Color(0xff718096),
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
                                      ),
                                    ),
                                  ),
                                  if (_isSyncing)
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
                                          duration:
                                              Duration(milliseconds: 1000),
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

class FastIncomingFinishScreen extends StatefulWidget {
  const FastIncomingFinishScreen({
    super.key,
    required this.total,
    required this.storages,
    required this.selectedStorage,
    required this.currencyTitle,
  });

  final double total;
  final List<WareHouse> storages;
  final WareHouse? selectedStorage;
  final String currencyTitle;

  @override
  State<FastIncomingFinishScreen> createState() =>
      _FastIncomingFinishScreenState();
}

class _FastIncomingFinishScreenState extends State<FastIncomingFinishScreen> {
  late final TextEditingController _paidAmountController;
  Supplier? _selectedSupplier;
  WareHouse? _selectedStorage;
  String? _supplierErrorText;
  String? _storageErrorText;

  double get _paidAmount {
    final parsed = double.tryParse(
      _paidAmountController.text.replaceAll(',', '.'),
    );
    return (parsed ?? 0).clamp(0, widget.total).toDouble();
  }

  double get _debtAmount => (widget.total - _paidAmount).clamp(0, widget.total);

  bool get _requiresSupplier => _debtAmount > 0;

  @override
  void initState() {
    super.initState();
    _selectedStorage = widget.selectedStorage ??
        (widget.storages.length == 1 ? widget.storages.first : null);
    _paidAmountController =
        TextEditingController(text: _compactNumber(widget.total));
    _paidAmountController.addListener(_normalizePaidAmountInput);
  }

  @override
  void dispose() {
    _paidAmountController.removeListener(_normalizePaidAmountInput);
    _paidAmountController.dispose();
    super.dispose();
  }

  void _normalizePaidAmountInput() {
    final text = _paidAmountController.text;
    final normalized = _normalizeCalculatorInput(text);
    if (text == normalized) return;

    _paidAmountController.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }

  String _normalizeCalculatorInput(String value) {
    if (value.isEmpty) return value;
    if (value == '.') return '0.';
    if (value.startsWith('.')) return '0$value';

    if (value.contains('.')) {
      final parts = value.split('.');
      final integerPart = parts.first.replaceFirst(RegExp(r'^0+(?=\d)'), '');
      final normalizedIntegerPart = integerPart.isEmpty ? '0' : integerPart;
      return '$normalizedIntegerPart.${parts.sublist(1).join()}';
    }

    final normalized = value.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    return normalized.isEmpty ? '0' : normalized;
  }

  Future<void> _pickStorage() async {
    final colors = context.appColors;
    final selected = await showModalBottomSheet<WareHouse>(
      context: context,
      backgroundColor: colors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: widget.storages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final storage = widget.storages[index];
                    final isSelected = storage.id == _selectedStorage?.id;
                    return Material(
                      color: isSelected
                          ? colors.surfaceElevated
                          : colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(context, storage),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  storage.name,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontFamily: 'Gilroy',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_rounded,
                                  color: colors.iconPrimary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    setState(() {
      _selectedStorage = selected;
      _storageErrorText = null;
    });
  }

  void _submit() {
    if (widget.storages.length > 1 && _selectedStorage == null) {
      setState(() => _storageErrorText = 'Выберите склад');
      return;
    }
    if (_requiresSupplier && _selectedSupplier == null) {
      setState(() => _supplierErrorText = 'Поле обязательно для заполнения');
      return;
    }

    Navigator.pop(
      context,
      _FastIncomingFinishResult(
        paidAmount: _paidAmount,
        debtAmount: _debtAmount,
        supplier: _selectedSupplier,
        storage: _selectedStorage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colors.surfacePrimary,
        appBar: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: colors.surfacePrimary,
          elevation: 0,
          title: Text(
            'Готово',
            style: TextStyle(
              color: colors.textPrimary,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  children: [
                    _FinishSummaryRow(
                      title: 'Всего:',
                      value:
                          '${_compactNumber(widget.total)} ${widget.currencyTitle}',
                      isPrimary: true,
                    ),
                    const SizedBox(height: 12),
                    _FinishSummaryRow(
                      title: 'Долг:',
                      value:
                          '${_compactNumber(_debtAmount)} ${widget.currencyTitle}',
                    ),
                    const SizedBox(height: 18),
                    _FinishAmountField(
                      controller: _paidAmountController,
                      currencyTitle: widget.currencyTitle,
                      onChanged: () {
                        setState(() {
                          if (!_requiresSupplier) {
                            _supplierErrorText = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    if (widget.storages.length > 1) ...[
                      _FinishSelectField(
                        label: 'Склад',
                        value: _selectedStorage?.name,
                        hint: 'Выберите склад',
                        onTap: _pickStorage,
                      ),
                      if (_storageErrorText != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _storageErrorText!,
                          style: const TextStyle(
                            color: Color(0xffEF4444),
                            fontFamily: 'Gilroy',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                    ],
                    _FastSupplierSelector(
                      selectedSupplier: _selectedSupplier,
                      showError: _supplierErrorText != null,
                      errorText: _supplierErrorText,
                      onChanged: (supplier) {
                        setState(() {
                          _selectedSupplier = supplier;
                          _supplierErrorText = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  MediaQuery.paddingOf(context).bottom + 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.buttonPrimaryBg,
                      foregroundColor: colors.buttonPrimaryFg,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submit,
                    child: Text(
                      'Создать приход',
                      style: TextStyle(
                        color: colors.buttonPrimaryFg,
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FastSupplierSelector extends StatefulWidget {
  const _FastSupplierSelector({
    required this.selectedSupplier,
    required this.onChanged,
    this.showError = false,
    this.errorText,
  });

  final Supplier? selectedSupplier;
  final ValueChanged<Supplier?> onChanged;
  final bool showError;
  final String? errorText;

  @override
  State<_FastSupplierSelector> createState() => _FastSupplierSelectorState();
}

class _FastSupplierSelectorState extends State<_FastSupplierSelector> {
  static const int _pageSize = 20;
  final ApiService _apiService = ApiService();
  List<Supplier> _loadedSuppliers = [];

  Future<CustomDropdownPaginatedResponse<Supplier>> _searchSuppliers(
    String query,
    int page,
  ) async {
    final items = await _apiService.getSupplier(
      search: query,
      page: page,
      perPage: _pageSize,
    );
    if (mounted) {
      setState(() {
        _loadedSuppliers = page == 1 ? items : [..._loadedSuppliers, ...items];
      });
    }
    return CustomDropdownPaginatedResponse<Supplier>(
      items: items,
      hasMore: items.length >= _pageSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final selected = widget.selectedSupplier;
    final borderColor =
        widget.showError ? const Color(0xffE45454) : colors.borderSubtle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Поставщик',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<Supplier>.searchRequestPaginated(
          key: ValueKey(selected?.id),
          paginatedRequest: _searchSuppliers,
          futureRequestDelay: const Duration(milliseconds: 300),
          closeDropDownOnClearFilterSearch: true,
          items: selected != null
              ? <Supplier>[
                  selected,
                  ..._loadedSuppliers.where((item) => item.id != selected.id),
                ]
              : _loadedSuppliers,
          searchHintText: 'Поиск',
          overlayHeight: 400,
          excludeSelected: false,
          initialItem: selected,
          decoration: CustomDropdownDecoration(
            closedFillColor: colors.surfaceElevated,
            expandedFillColor: colors.surfacePrimary,
            closedBorder: Border.all(color: borderColor, width: 1.5),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(color: borderColor, width: 1.5),
            expandedBorderRadius: BorderRadius.circular(12),
            searchFieldDecoration: SearchFieldDecoration(
              autoFocus: false,
              fillColor: colors.surfaceElevated,
              hintStyle: TextStyle(color: colors.textSecondary),
              textStyle: TextStyle(color: colors.textPrimary),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: colors.iconSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.buttonPrimaryBg),
              ),
            ),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                  ),
                ),
                if ((item.phone ?? '').trim().isNotEmpty)
                  Text(
                    item.phone!.trim(),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Gilroy',
                    ),
                  ),
              ],
            );
          },
          headerBuilder: (context, item, enabled) {
            return Text(
              item.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
            );
          },
          hintBuilder: (context, hint, enabled) {
            return Text(
              'Выберите поставщика',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textSecondary,
              ),
            );
          },
          noResultFoundBuilder: (context, text) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Ничего не найдено',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    color: colors.textPrimary,
                  ),
                ),
              ),
            );
          },
          onChanged: widget.onChanged,
        ),
        if (widget.showError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.errorText ?? 'Поле обязательно для заполнения',
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xffE45454),
              ),
            ),
          ),
      ],
    );
  }
}

class _FastIncomingFinishResult {
  const _FastIncomingFinishResult({
    required this.paidAmount,
    required this.debtAmount,
    this.supplier,
    this.storage,
  });

  final double paidAmount;
  final double debtAmount;
  final Supplier? supplier;
  final WareHouse? storage;
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected ? const Color(0xffF4F7FD) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xff1E2E52).withValues(alpha: 0.05),
          highlightColor: const Color(0xff1E2E52).withValues(alpha: 0.03),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                const Icon(
                  Icons.warehouse_outlined,
                  color: Color(0xff99A4BA),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xff1E2E52),
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_rounded,
                    color: Color(0xff1E2E52),
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
    final color = isActive ? colors.buttonPrimaryBg : colors.iconSecondary;
    return Material(
      color: colors.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: colors.buttonPrimaryBg.withValues(alpha: 0.06),
        highlightColor: colors.buttonPrimaryBg.withValues(alpha: 0.04),
        onTap: isLoading ? null : onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                color: colors.iconSecondary,
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
                    isEnabled ? colors.buttonPrimaryBg : colors.borderSubtle,
                foregroundColor: colors.buttonPrimaryFg,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                            colors.buttonPrimaryFg),
                      ),
                    )
                  : Text(
                      'Готово · ${_formatMoney(total)} $currencyTitle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
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
                  isEnabled ? colors.surfaceElevated : colors.surfaceElevated,
              foregroundColor: colors.iconPrimary,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colors.borderSubtle,
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
                  color: isEnabled ? colors.iconPrimary : colors.iconSecondary,
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
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: colors.buttonPrimaryBg.withValues(alpha: 0.08),
        highlightColor: colors.buttonPrimaryBg.withValues(alpha: 0.04),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
  });

  final RmkCartItem item;
  final VoidCallback onTap;

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
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 62,
        height: 62,
        child: url == null || url.isEmpty
            ? const ColoredBox(
                color: Color(0xffEEF2F7),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xff99A4BA),
                ),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: 220,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (_, __) =>
                    const ColoredBox(color: Color(0xffEEF2F7)),
                errorWidget: (_, __, ___) => const ColoredBox(
                  color: Color(0xffEEF2F7),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xff99A4BA),
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
        borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.buttonPrimaryBg),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinishSummaryRow extends StatelessWidget {
  const _FinishSummaryRow({
    required this.title,
    required this.value,
    this.isPrimary = false,
  });

  final String title;
  final String value;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: isPrimary ? colors.textPrimary : colors.textSecondary,
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontFamily: 'Gilroy',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FinishAmountField extends StatelessWidget {
  const _FinishAmountField({
    required this.controller,
    required this.currencyTitle,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String currencyTitle;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'Оплачено',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 210,
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              textAlign: TextAlign.right,
              onChanged: (_) => onChanged(),
              style: TextStyle(
                color: colors.textPrimary,
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                isDense: true,
                alignLabelWithHint: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                suffixText: currencyTitle,
                suffixStyle: TextStyle(
                  color: colors.textPrimary,
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishSelectField extends StatelessWidget {
  const _FinishSelectField({
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Material(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? hint,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: value == null
                            ? colors.textSecondary
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colors.iconSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _compactNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(2);
}

String _formatMoney(double value) {
  if (value == value.roundToDouble()) return '${value.toInt()}';
  return value.toStringAsFixed(2);
}
