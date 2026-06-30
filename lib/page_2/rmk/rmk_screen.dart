import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crm_task_manager/api/service/localization_service.dart';
import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/offline/db/app_database.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_barcode_scanner_screen.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_filter_sheet.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_payment_screen.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_product_card.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_quantity_screen.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_repository.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
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
  String _currencyTitle = 'TJS';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadCurrency());
    unawaited(_loadStoragesAndSync());
  }

  @override
  void dispose() {
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
        await _runSync(resetCatalogCache: true);
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
    if (_storages.isEmpty) {
      await _loadStoragesAndSync();
      return;
    }

    final selected = await showModalBottomSheet<WareHouse>(
      context: context,
      backgroundColor: Colors.white,
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
                  color: const Color(0xffD7DEE9),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Склад',
                    style: TextStyle(
                      color: Color(0xff1E2E52),
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
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _query = value);

      final query = value.trim();
      if (query.isNotEmpty && _selectedStorage != null) {
        final localGoods = await _repository.watchGoods(query: query).first;
        if (localGoods.isEmpty) {
          final found = await _repository.searchAndCacheGoods(query, _selectedStorage!.id);
          if (!found && mounted && _query == value) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)?.translate('product_not_found') ?? 'Товар не найден'
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
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
    final action = await showModalBottomSheet<_RmkFilterAction>(
      context: context,
      backgroundColor: Colors.white,
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
                    color: const Color(0xffD7DEE9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Фильтр',
                    style: TextStyle(
                      color: Color(0xff1E2E52),
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
      );
      if (!mounted) return;

      showCustomSnackBar(
        context: context,
        message: result.sentToServer
            ? 'Продажа успешно создана'
            : (result.error ?? 'Ошибка при создании продажи'),
        isSuccess: result.sentToServer,
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

    final total = items.fold<double>(
      0,
      (sum, item) => sum + (item.customTotal ?? item.quantity * item.price),
    );

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
              decoration: const BoxDecoration(
                color: Color(0xffF8F9FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                        const Expanded(
                          child: Text(
                            'Выбранные товары',
                            style: TextStyle(
                              color: Color(0xff1E2E52),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${items.length} шт',
                            style: const TextStyle(
                              color: Color(0xff1E2E52),
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
                        return Dismissible(
                          key: ValueKey(item.goodId),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) {
                            _repository.removeCartItem(item.goodId);
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xffFF4D4D),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          child: _RmkSelectedCartCard(
                            item: item,
                            onTap: () async {
                              Navigator.pop(context);
                              final good =
                                  await _repository.getGoodById(item.goodId);
                              if (!mounted || good == null) return;
                              await _openQuantityScreen(good);
                            },
                          ),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff1E2E52)
                                  .withValues(alpha: 0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Итого',
                              style: TextStyle(
                                color: Color(0xff718096),
                                fontFamily: 'Gilroy',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatMoney(total),
                              style: const TextStyle(
                                color: Color(0xff1E2E52),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: _isSearching
            ? _AppBarSearchField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
              )
            : const Text(
                'РМК',
                style: TextStyle(
                  color: Color(0xff1E2E52),
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
                    foregroundColor: const Color(0xff1E2E52),
                    overlayColor:
                        const Color(0xff1E2E52).withValues(alpha: 0.06),
                  ),
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xff1E2E52),
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
                    foregroundColor: const Color(0xff1E2E52),
                    overlayColor:
                        const Color(0xff1E2E52).withValues(alpha: 0.06),
                  ),
                  icon: Image.asset(
                    'assets/icons/AppBar/search.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: _toggleSearch,
                ),
                IconButton(
                  tooltip: 'Фильтр',
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xff1E2E52),
                    overlayColor:
                        const Color(0xff1E2E52).withValues(alpha: 0.06),
                  ),
                  icon: Image.asset(
                    'assets/icons/AppBar/filter.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: _openMainFilter,
                ),
                IconButton(
                  tooltip: 'Сканер',
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xff1E2E52),
                    overlayColor:
                        const Color(0xff1E2E52).withValues(alpha: 0.06),
                  ),
                  icon: Image.asset(
                    'assets/icons/AppBar/scanner.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: _scanBarcode,
                ),
                const SizedBox(width: 6),
              ],
      ),
      body: StreamBuilder<List<RmkCartItem>>(
        stream: _repository.watchCart(),
        builder: (context, cartSnapshot) {
          final cartItems = cartSnapshot.data ?? const <RmkCartItem>[];
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
                    color: const Color(0xffF8F9FB),
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
                      color: const Color(0xff1E2E52),
                      backgroundColor: Colors.white,
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
    final color = isActive ? const Color(0xff1E2E52) : const Color(0xff99A4BA);
    return Material(
      color: const Color(0xffF4F7FD),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xff1E2E52).withValues(alpha: 0.06),
        highlightColor: const Color(0xff1E2E52).withValues(alpha: 0.04),
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
                      style: const TextStyle(
                        color: Color(0xff718096),
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
                      style: const TextStyle(
                        color: Color(0xff1E2E52),
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_right_rounded,
                color: Color(0xff99A4BA),
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
    final isEnabled = count > 0 && !isLoading;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnabled
                    ? const Color(0xff1E2E52)
                    : const Color(0xffCBD5E0),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isEnabled ? onTap : null,
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Готово · ${_formatMoney(total)} $currencyTitle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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
                  isEnabled ? Colors.white : const Color(0xffE2E8F0),
              foregroundColor: const Color(0xff1E2E52),
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isEnabled
                      ? const Color(0xffD9E2F1)
                      : const Color(0xffE2E8F0),
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
                  color: isEnabled
                      ? const Color(0xff1E2E52)
                      : const Color(0xff99A4BA),
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
                        color: const Color(0xff1E2E52),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
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
    return Material(
      color: isSelected ? const Color(0xff1E2E52) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xff1E2E52).withValues(alpha: 0.08),
        highlightColor: const Color(0xff1E2E52).withValues(alpha: 0.04),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xff1E2E52)
                  : const Color(0xffD9E2F1),
            ),
          ),
          child: Center(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xff1E2E52),
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
    final total = item.customTotal ?? item.quantity * item.price;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffE7EDF6)),
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
                      style: const TextStyle(
                        color: Color(0xff1E2E52),
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
                  const Text(
                    'Сумма',
                    style: TextStyle(
                      color: Color(0xff99A4BA),
                      fontFamily: 'Gilroy',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMoney(total),
                    style: const TextStyle(
                      color: Color(0xff1E2E52),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffF4F7FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xff718096),
                fontFamily: 'Gilroy',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xff1E2E52),
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
    return SizedBox(
      height: 42,
      child: TextSelectionTheme(
        data: const TextSelectionThemeData(
          cursorColor: Color(0xff1E2E52),
          selectionColor: Color(0x331E2E52),
          selectionHandleColor: Color(0xff1E2E52),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          autofocus: true,
          cursorColor: const Color(0xff1E2E52),
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            color: Color(0xff1E2E52),
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Поиск',
            hintStyle: const TextStyle(
              color: Color(0xff99A4BA),
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.search,
              size: 21,
              color: Color(0xff99A4BA),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 42,
              minHeight: 42,
            ),
            filled: true,
            fillColor: const Color(0xffF4F7FD),
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffF4F7FD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffF4F7FD)),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatMoney(double value) {
  if (value == value.roundToDouble()) return '${value.toInt()}';
  return value.toStringAsFixed(2);
}
