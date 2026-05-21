import 'dart:async';

import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/offline/db/app_database.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_filter_sheet.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_product_card.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_quantity_screen.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_repository.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

class RmkScreen extends StatefulWidget {
  const RmkScreen({super.key});

  @override
  State<RmkScreen> createState() => _RmkScreenState();
}

class _RmkScreenState extends State<RmkScreen> {
  final RmkRepository _repository = RmkRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  DateTime? _lastBottomSyncAt;
  String _query = '';
  int? _categoryId;
  List<WareHouse> _storages = const [];
  WareHouse? _selectedStorage;
  bool _isSyncing = false;
  bool _isSubmitting = false;
  bool _isLoadingStorages = false;

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
        setState(() => _isLoadingStorages = false);
      }
    }
  }

  Future<void> _handlePullRefresh() async {
    unawaited(_runSync(resetCatalogCache: true));
    await Future<void>.delayed(const Duration(milliseconds: 160));
  }

  Future<void> _selectStorage(WareHouse storage) async {
    if (_selectedStorage?.id == storage.id) return;
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
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (context, index) {
              final storage = _storages[index];
              final isSelected = storage.id == _selectedStorage?.id;
              return ListTile(
                title: Text(
                  storage.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff1E2E52),
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xff1E2E52))
                    : null,
                onTap: () => Navigator.pop(context, storage),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: _storages.length,
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

  Future<void> _openFilter(List<RmkCategory> categories) async {
    final selected = await showRmkFilterSheet(
      context: context,
      categories: categories,
      selectedCategoryId: _categoryId,
    );
    if (!mounted) return;
    setState(() => _categoryId = selected);
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

    setState(() => _isSubmitting = true);
    try {
      final result = await _repository.submitSale(
        items,
        storageId: storageId,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text(
          'РМК',
          style: TextStyle(
            color: Color(0xff1E2E52),
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
          ),
        ),
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

              return Column(
                children: [
                  Container(
                    color: const Color(0xffF8F9FB),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Column(
                      children: [
                        _StorageButton(
                          storageName: _selectedStorage?.name,
                          isLoading: _isLoadingStorages,
                          onTap: _openStoragePicker,
                        ),
                        const SizedBox(height: 8),
                        _DoneButton(
                          total: total,
                          count: cartItems.length,
                          isLoading: _isSubmitting,
                          onTap: () => _finishSale(cartItems),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: const Color(0xff1E2E52),
                      onRefresh: _handlePullRefresh,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _SearchHeaderDelegate(
                              child: Container(
                                color: const Color(0xffF8F9FB),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 6, 16, 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _SearchField(
                                        controller: _searchController,
                                        onChanged: _onSearchChanged,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _FilterButton(
                                      isActive: _categoryId != null,
                                      onTap: () => _openFilter(categories),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          StreamBuilder<List<RmkGood>>(
                            stream: _repository.watchGoods(
                              query: _query,
                              categoryId: _categoryId,
                            ),
                            builder: (context, goodsSnapshot) {
                              final goods =
                                  goodsSnapshot.data ?? const <RmkGood>[];
                              if (goods.isEmpty) {
                                return const SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Text(
                                        'Товары появятся после первой синхронизации',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xff718096),
                                          fontFamily: 'Gilroy',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 18),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        MediaQuery.sizeOf(context).width >= 520
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
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => RmkQuantityScreen(
                                                good: good,
                                                repository: _repository,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    childCount: goods.length,
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_isSyncing)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Color(0xff1E2E52),
                                    ),
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
            },
          );
        },
      ),
    );
  }
}

class _StorageButton extends StatelessWidget {
  const _StorageButton({
    required this.storageName,
    required this.isLoading,
    required this.onTap,
  });

  final String? storageName;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xff1E2E52),
          side: const BorderSide(color: Color(0xffE2E8F0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xff1E2E52),
                ),
              )
            : const Icon(Icons.warehouse_outlined, size: 18),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            storageName ?? 'Выберите склад',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
            ),
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
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled ? const Color(0xff1E2E52) : const Color(0xffCBD5E0),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  fontSize: 17,
                ),
              ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Поиск',
          prefixIcon: const Icon(Icons.search, size: 21),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xffE2E7F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xff1E2E52)),
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.isActive,
    required this.onTap,
  });

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: isActive ? const Color(0xff1E2E52) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Icon(
            Icons.tune,
            color: isActive ? Colors.white : const Color(0xff1E2E52),
          ),
        ),
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SearchHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

String _formatMoney(double value) {
  if (value == value.roundToDouble()) return '${value.toInt()}';
  return value.toStringAsFixed(2);
}
