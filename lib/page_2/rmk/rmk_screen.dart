import 'dart:async';

import 'package:crm_task_manager/offline/db/app_database.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_filter_sheet.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_product_card.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_quantity_screen.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_repository.dart';
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
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_runSync());
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

  Future<void> _runSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      await _repository.syncInBackground();
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
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
    if (items.isEmpty) return;
    final result = await _repository.submitSale(items);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.sentToServer
              ? 'Продажа отправлена на сервер'
              : 'Продажа сохранена и отправится фоном',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: _DoneButton(
                      total: total,
                      count: cartItems.length,
                      onTap: () => _finishSale(cartItems),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: const Color(0xff1E2E52),
                      onRefresh: _runSync,
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

class _DoneButton extends StatelessWidget {
  const _DoneButton({
    required this.total,
    required this.count,
    required this.onTap,
  });

  final double total;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = count > 0;
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
        child: Text(
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
