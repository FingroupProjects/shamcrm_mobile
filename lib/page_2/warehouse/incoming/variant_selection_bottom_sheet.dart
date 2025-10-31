import 'dart:async';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bottom_sheet_bloc/variant_bottom_sheet_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bottom_sheet_bloc/variant_bottom_sheet_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bottom_sheet_bloc/variant_bottom_sheet_state.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VariantSelectionBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> existingItems;
  final bool forceReload;
  final bool? isService;

  const VariantSelectionBottomSheet({
    required this.existingItems,
    this.forceReload = true,
    this.isService,
    super.key,
  });

  @override
  State<VariantSelectionBottomSheet> createState() => _VariantSelectionBottomSheetState();
}

class _VariantSelectionBottomSheetState extends State<VariantSelectionBottomSheet> {
  // Constants
  static const double _scrollThreshold = 0.9;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 500);
  static const double _bottomSheetHeight = 0.85;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final VariantBottomSheetBloc _bloc;

  bool _showAllMode = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _bloc = context.read<VariantBottomSheetBloc>();
    _loadSettings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _showAllMode = prefs.getString('variant_display_mode') == 'all';
    });

    if (mounted) {
      if (_showAllMode) {
        _bloc.add(FetchVariants(forceReload: widget.forceReload, isService: widget.isService));  // ADD isService
      } else {
        _bloc.add(FetchCategories(forceReload: widget.forceReload));
      }
    }
  }

  Future<void> _saveDisplayMode(bool showAll) async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('variant_display_mode', showAll ? 'all' : 'category');
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * _scrollThreshold) {
      final state = _bloc.state;

      if (state.isLoadingMore) return;

      if (state.isInSearchMode && _hasMorePages(state.searchVariantsPagination, state.currentPage)) {
        _bloc.add(FetchMoreSearchResults(state.currentPage));
      } else if (state.isInAllVariantsMode && _hasMorePages(state.allVariantsPagination, state.currentPage)) {
        _bloc.add(FetchMoreVariants(state.currentPage));
      } else if (state.isInCategoryMode && _hasMorePages(state.categoryVariantsPagination, state.currentPage)) {
        _bloc.add(FetchMoreVariantsByCategory(
          categoryId: state.selectedCategoryId!,
          currentPage: state.currentPage,
        ));
      }
    }
  }

  bool _hasMorePages(VariantPagination? pagination, int currentPage) {
    return pagination != null && currentPage < pagination.totalPages;
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDelay, () {
      if (mounted) {
        _bloc.add(SearchAll(query, isService: widget.isService));
      }
    });
  }

  void _toggleDisplayMode() {
    setState(() {
      _showAllMode = !_showAllMode;
      _searchController.clear();
    });

    _saveDisplayMode(_showAllMode);

    if (_showAllMode) {
      _bloc.add(FetchVariants(isService: widget.isService));  // ADD isService
    } else {
      _bloc.add(FetchCategories());
    }
  }

  void _onCategoryTap(int categoryId, String categoryName) {
    _bloc.add(FetchVariantsByCategory(
      categoryId: categoryId,
      categoryName: categoryName,
      isService: widget.isService,  // ADD THIS
    ));
  }

  void _onBackFromCategory() {
    _bloc.add(FetchCategories());
  }

  void _onVariantTap(Variant variant) {
    final isAlreadyAdded = widget.existingItems.any((item) => item['variantId'] == variant.id);

    if (isAlreadyAdded) {
      _showErrorSnackBar(AppLocalizations.of(context)!.translate('item_already_added'));
      return;
    }

    final firstUnitAmount = variant.availableUnits.isNotEmpty ? (variant.availableUnits.first.amount ?? 1) : 1;

    final result = <String, dynamic>{
      'id': variant.goodId,
      'variantId': variant.id,
      'name': variant.fullName ?? variant.good?.name ?? 'Неизвестный товар',
      'quantity': 1,
      'price': variant.price ?? 0.0,
      'total': 0.0,
      'amount': firstUnitAmount,
      'availableUnits': variant.availableUnits,
      'remainder': variant.remainder ?? 0,
    };

    if (variant.availableUnits.isNotEmpty) {
      final firstUnit = variant.availableUnits.first;
      result['selectedUnit'] = firstUnit.shortName ?? firstUnit.name;
      result['unit_id'] = firstUnit.id;
    }

    Navigator.pop(context, result);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _isItemAlreadyAdded(Variant variant) {
    return widget.existingItems.any((item) => item['variantId'] == variant.id);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<VariantBottomSheetBloc, VariantBottomSheetState>(
      builder: (context, state) {
        return PopScope(
          canPop: !state.isInCategoryMode && !state.isInSearchMode,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              if (state.isInSearchMode) {
                _searchController.clear();
                _bloc.add(SearchAll(''));
              } else if (state.isInCategoryMode) {
                _onBackFromCategory();
              }
            }
          },
          child: Container(
            height: MediaQuery.of(context).size.height * _bottomSheetHeight,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                _buildHeader(localizations, state),
                _buildSearchField(localizations, state),
                Expanded(
                  child: _buildContent(localizations, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppLocalizations localizations, VariantBottomSheetState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.translate('select_variant'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
                if (state.isInCategoryMode)
                  _buildCategoryBreadcrumb(state),
                if (state.isInSearchMode)
                  _buildSearchBreadcrumb(state),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xff99A4BA)),
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreadcrumb(VariantBottomSheetState state) {
    // ✅ ИСПРАВЛЕНИЕ: Получаем название категории из состояния
    final categoryName = state.selectedCategoryName ??
        (state.categoryVariants.isNotEmpty
            ? state.categoryVariants.first.good?.category.name ?? ''
            : '');

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: GestureDetector(
        onTap: _onBackFromCategory,
        child: Row(
          children: [
            const Icon(
              Icons.arrow_back,
              size: 14,
              color: Color(0xff4759FF),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                categoryName,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff4759FF),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBreadcrumb(VariantBottomSheetState state) {
    final totalResults = state.searchCategories.length + state.searchVariants.length;
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        localizations.translate('found_results').replaceAll('{count}', totalResults.toString()),
        style: const TextStyle(
          fontSize: 13,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: Color(0xff99A4BA),
        ),
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations localizations, VariantBottomSheetState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: localizations.translate('search_variants'),
                hintStyle: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: Color(0xff99A4BA),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xff4759FF)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xff99A4BA)),
                  onPressed: () {
                    _searchController.clear();
                    _bloc.add(SearchAll(''));
                  },
                )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF4F7FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          if (!state.isInSearchMode && !state.isInCategoryMode) ...[
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  _showAllMode ? Icons.list : Icons.grid_view,
                  color: const Color(0xff4759FF),
                  size: 24,
                ),
                tooltip: _showAllMode ? 'По категориям' : 'Все товары',
                onPressed: _toggleDisplayMode,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations localizations, VariantBottomSheetState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_showAllMode) {
                  _bloc.add(FetchVariants(forceReload: true, isService: widget.isService));  // ADD isService
                } else {
                  _bloc.add(FetchCategories(forceReload: true));
                }
              },
              child: Text(localizations.translate('retry')),
            ),
          ],
        ),
      );
    }

    // Search mode
    if (state.isInSearchMode) {
      return _buildSearchResults(localizations, state);
    }

    // Category mode
    if (state.isInCategoryMode) {
      return _buildCategoryVariants(localizations, state);
    }

    // All variants mode
    if (state.isInAllVariantsMode) {
      return _buildAllVariants(localizations, state);
    }

    // Categories mode
    return _buildCategories(localizations, state);
  }

  Widget _buildSearchResults(AppLocalizations localizations, VariantBottomSheetState state) {
    if (state.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.searchCategories.isEmpty && state.searchVariants.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: localizations.translate('nothing_found'),
        subtitle: localizations.translate('try_different_search'),
      );
    }

    final availableVariants = state.searchVariants
        .where((v) => !_isItemAlreadyAdded(v))
        .toList();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (state.searchCategories.isNotEmpty) ...[
          _buildSectionHeader(localizations.translate('categories'), state.searchCategories.length),
          ...state.searchCategories.map((cat) => _buildCategoryCard(cat)),
          const SizedBox(height: 24),
        ],
        if (availableVariants.isNotEmpty) ...[
          _buildSectionHeader(localizations.translate('goods'), availableVariants.length),
          ...availableVariants.map((v) => _buildVariantCard(v, localizations)),
        ],
        if (state.isLoadingMore)
          _buildLoadingIndicator(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xff4759FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff4759FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(AppLocalizations localizations, VariantBottomSheetState state) {
    if (state.categories.isEmpty) {
      return Center(
        child: Text(
          localizations.translate('no_categories_found'),
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            color: Color(0xff99A4BA),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.categories.length,
      itemBuilder: (context, index) {
        return _buildCategoryCard(state.categories[index]);
      },
    );
  }

  Widget _buildCategoryCard(CategoryWithCount categoryWithCount) {
    final category = categoryWithCount.category;
    final level = categoryWithCount.level;

    final leftPadding = 16.0 + (level * 24.0);

    return GestureDetector(
      onTap: () => _onCategoryTap(category.id, category.name),
      child: Container(
        margin: EdgeInsets.only(bottom: 12, left: level > 0 ? leftPadding - 16 : 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: level > 0 ? const Color(0xFFE5E7EB).withValues(alpha: 0.7) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (level > 0) ...[
                Container(
                  width: 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xff4759FF).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                width: level > 0 ? 40 : 50,
                height: level > 0 ? 40 : 50,
                decoration: BoxDecoration(
                  color: const Color(0xffF4F7FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: category.image != null && category.image!.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: 'https://shamcrm.com/storage/${category.image}',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      level > 0 ? Icons.subdirectory_arrow_right : Icons.category,
                      color: const Color(0xff4759FF),
                      size: level > 0 ? 20 : 28,
                    ),
                  ),
                )
                    : Icon(
                  level > 0 ? Icons.subdirectory_arrow_right : Icons.category,
                  color: const Color(0xff4759FF),
                  size: level > 0 ? 20 : 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: level > 0 ? 14 : 16,
                    fontFamily: 'Gilroy',
                    fontWeight: level > 0 ? FontWeight.w500 : FontWeight.w600,
                    color: const Color(0xff1E2E52),
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xff99A4BA),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllVariants(AppLocalizations localizations, VariantBottomSheetState state) {
    return _buildVariantsList(
      variants: state.allVariants,
      emptyMessageKey: 'no_variants_found',
      state: state,
      localizations: localizations,
    );
  }

  Widget _buildCategoryVariants(AppLocalizations localizations, VariantBottomSheetState state) {
    // ✅ ИСПРАВЛЕНИЕ: Определяем правильное сообщение в зависимости от ситуации
    String emptyMessageKey;
    if (state.categoryVariants.isEmpty) {
      // Если в категории вообще нет товаров
      emptyMessageKey = 'no_goods_in_category';
    } else {
      // Если товары есть, но все уже добавлены
      emptyMessageKey = 'all_variants_added';
    }

    return _buildVariantsList(
      variants: state.categoryVariants,
      emptyMessageKey: emptyMessageKey,
      state: state,
      localizations: localizations,
    );
  }

  Widget _buildVariantsList({
    required List<Variant> variants,
    required String emptyMessageKey,
    required VariantBottomSheetState state,
    required AppLocalizations localizations,
  }) {
    final availableVariants = variants.where((v) => !_isItemAlreadyAdded(v)).toList();

    if (availableVariants.isEmpty) {
      return Center(
        child: Text(
          localizations.translate(emptyMessageKey),
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            color: Color(0xff99A4BA),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: availableVariants.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == availableVariants.length) {
          return _buildLoadingIndicator();
        }

        return _buildVariantCard(availableVariants[index], localizations);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0xff99A4BA)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              color: Color(0xff99A4BA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantCard(Variant variant, AppLocalizations localizations) {
    final displayName = variant.fullName ??
        variant.good?.name ??
        localizations.translate('unknown_variant');
    final imageUrl = variant.good?.mainImageUrl;

    return GestureDetector(
      onTap: () => _onVariantTap(variant),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xffF4F7FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: imageUrl != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.shopping_cart_outlined,
                      color: Color(0xff4759FF),
                      size: 24,
                    ),
                  ),
                )
                    : const Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xff4759FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (variant.price != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          variant.price!.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff4759FF),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.add,
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
