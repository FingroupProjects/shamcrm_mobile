import 'dart:async';

import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/offline/db/app_database.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_barcode_scanner_screen.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_filter_sheet.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_payment_screen.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_product_card.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_quantity_screen.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_repository.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
                    child: _DoneButton(
                      total: total,
                      count: cartItems.length,
                      isLoading: _isSubmitting,
                      onTap: () => _finishSale(cartItems),
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
                                  : RmkRepository.categoryIdsIncludingDescendants(
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
                                                    520
                                                ? 3
                                                : 2,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                        childAspectRatio: 0.72,
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
    required this.onTap,
  });

  final double total;
  final int count;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = count > 0 && !isLoading;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled ? const Color(0xff1E2E52) : const Color(0xffCBD5E0),
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                'Готово · ${_formatMoney(total)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
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
