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

  const VariantSelectionBottomSheet({
    required this.existingItems,
    this.forceReload = true,
    super.key,
  });

  @override
  State<VariantSelectionBottomSheet> createState() => _VariantSelectionBottomSheetState();
}

class _VariantSelectionBottomSheetState extends State<VariantSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categorySearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final VariantBottomSheetBloc _bloc;

  bool _showAllMode = false;
  int? _selectedCategoryId;
  bool _isWaitingForCategories = false;

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
    _categorySearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _showAllMode = prefs.getString('variant_display_mode') == 'all';
      _selectedCategoryId = prefs.getInt('variant_selected_category_id');
    });

    if (mounted) {
      if (_showAllMode) {
        _bloc.add(FetchVariants());
      } else if (_selectedCategoryId != null) {
        _bloc.add(FetchVariantsByCategory(categoryId: _selectedCategoryId!));
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

  Future<void> _saveSelectedCategory(int? categoryId) async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (categoryId != null) {
      await prefs.setInt('variant_selected_category_id', categoryId);
    } else {
      await prefs.remove('variant_selected_category_id');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      final state = context.read<VariantBottomSheetBloc>().state;

      if (state is AllVariantLoaded) {
        if (state.currentPage < state.pagination.totalPages) {
          context.read<VariantBottomSheetBloc>().add(FetchMoreVariants(state.currentPage));
        }
      } else if (state is CategoryVariantsLoaded) {
        if (state.currentPage < state.pagination.totalPages) {
          context.read<VariantBottomSheetBloc>().add(FetchMoreVariantsByCategory(
            categoryId: state.categoryId,
            currentPage: state.currentPage,
          ));
        }
      }
    }
  }

  void _onSearch(String query) {
    if (_showAllMode) {
      // Search in all variants mode
      _bloc.add(FetchVariants(page: 1));
    } else if (_selectedCategoryId == null) {
      // Search in categories
      setState(() {
        _isWaitingForCategories = true;
      });
      _bloc.add(FetchCategories(search: query.isEmpty ? null : query));
    }
  }

  void _toggleDisplayMode() {
    setState(() {
      _showAllMode = !_showAllMode;
      _selectedCategoryId = null;
      _searchController.clear();
    });

    _saveDisplayMode(_showAllMode);
    _saveSelectedCategory(null);

    if (_showAllMode) {
      _bloc.add(FetchVariants());
    } else {
      _bloc.add(FetchCategories());
    }
  }

  void _onVariantTap(Variant variant) {
    final isAlreadyAdded = widget.existingItems.any((item) => item['variantId'] == variant.id);

    if (isAlreadyAdded) {
      _showErrorSnackBar(AppLocalizations.of(context)!.translate('item_already_added') ?? 'Товар уже добавлен');
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

    if (_selectedCategoryId != null) {
      _saveSelectedCategory(_selectedCategoryId);
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

    return PopScope(
      canPop: _showAllMode || _selectedCategoryId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_showAllMode && _selectedCategoryId != null) {
          setState(() {
            _selectedCategoryId = null;
          });
          _saveSelectedCategory(null);
          _bloc.add(FetchCategories());
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(localizations),
            _buildSearchField(localizations),
            Expanded(
              child: BlocBuilder<VariantBottomSheetBloc, VariantBottomSheetState>(
                builder: (context, state) {
                  if (state is AllVariantLoading || state is CategoryVariantsLoading || state is CategoriesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is AllVariantLoaded) {
                    if (state.variants.isEmpty) {
                      return Center(
                        child: Text(
                          localizations.translate('no_variants_found') ?? 'Варианты не найдены',
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            color: Color(0xff99A4BA),
                          ),
                        ),
                      );
                    }
                    final availableVariants = state.variants.where((variant) => !_isItemAlreadyAdded(variant)).toList();
                    return _buildVariantsList(availableVariants, state, localizations);
                  }

                  if (state is CategoriesLoaded) {
                    if (_isWaitingForCategories) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _isWaitingForCategories = false;
                          });
                        }
                      });
                    }

                    if (state.categories.isEmpty) {
                      return Center(
                        child: Text(
                          localizations.translate('no_categories_found') ?? 'Категории не найдены',
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            color: Color(0xff99A4BA),
                          ),
                        ),
                      );
                    }
                    return _buildCategoriesListFromApi(state.categories, localizations);
                  }

                  if (state is CategoryVariantsLoaded) {
                    final availableVariants = state.variants.where((variant) => !_isItemAlreadyAdded(variant)).toList();

                    if (availableVariants.isEmpty) {
                      return Center(
                        child: Text(
                          localizations.translate('all_variants_added') ?? 'Все варианты уже добавлены',
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            color: Color(0xff99A4BA),
                          ),
                        ),
                      );
                    }

                    return _buildCategoryVariantsList(availableVariants, state, localizations);
                  }

                  if (state is AllVariantError || state is CategoriesError || state is CategoryVariantsError) {
                    final message = (state is AllVariantError)
                        ? state.message
                        : (state is CategoriesError)
                        ? state.message
                        : (state is CategoryVariantsError)
                        ? state.message
                        : 'Unknown error';

                    return Center(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE5E7EB).withOpacity(0.5),
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
                  localizations.translate('select_variant') ?? 'Выбор товара',
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
                BlocBuilder<VariantBottomSheetBloc, VariantBottomSheetState>(
                  builder: (context, state) {
                    if (state is CategoryVariantsLoaded) {
                      final categoryName = state.variants.isNotEmpty ? state.variants.first.good?.category.name : '';

                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = null;
                            });
                            _saveSelectedCategory(null);
                            context.read<VariantBottomSheetBloc>().add(FetchCategories());
                          },
                          child: Row(
                            children: [
                              const Icon(
                                Icons.arrow_back,
                                size: 14,
                                color: Color(0xff4759FF),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                categoryName ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff4759FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
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

  Widget _buildSearchField(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: localizations.translate('search_variants') ?? 'Поиск товаров...',
                hintStyle: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: Color(0xff99A4BA),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xff4759FF)),
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
      ),
    );
  }

  Widget _buildCategoriesListFromApi(List<CategoryWithCount> categories, AppLocalizations localizations) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final categoryWithCount = categories[index];
        return _buildCategoryCard(categoryWithCount);
      },
    );
  }

  Widget _buildCategoryCard(CategoryWithCount categoryWithCount) {
    final category = categoryWithCount.category;
    final itemsCount = categoryWithCount.goodsCount;
    final level = categoryWithCount.level;

    final leftPadding = 16.0 + (level * 24.0);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = category.id;
        });
        _saveSelectedCategory(category.id);
        context.read<VariantBottomSheetBloc>().add(FetchVariantsByCategory(categoryId: category.id));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12, left: level > 0 ? leftPadding - 16 : 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: level > 0 ? const Color(0xFFE5E7EB).withOpacity(0.7) : const Color(0xFFE5E7EB),
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
                    color: const Color(0xff4759FF).withOpacity(0.3),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: level > 0 ? 14 : 16,
                        fontFamily: 'Gilroy',
                        fontWeight: level > 0 ? FontWeight.w500 : FontWeight.w600,
                        color: const Color(0xff1E2E52),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$itemsCount ${_getPluralForm(itemsCount, 'товар', 'товара', 'товаров')}',
                      style: TextStyle(
                        fontSize: level > 0 ? 12 : 13,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: const Color(0xff99A4BA),
                      ),
                    ),
                  ],
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

  Widget _buildVariantsList(List<Variant> variants, AllVariantLoaded state, AppLocalizations localizations) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: variants.length + 1,
      itemBuilder: (context, index) {
        if (index == variants.length) {
          final showLoader = state.currentPage < state.pagination.totalPages;

          return showLoader
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
              : const SizedBox.shrink();
        }

        final variant = variants[index];
        return _buildVariantCard(variant, localizations);
      },
    );
  }

  Widget _buildCategoryVariantsList(List<Variant> variants, CategoryVariantsLoaded state, AppLocalizations localizations) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: variants.length + 1,
      itemBuilder: (context, index) {
        if (index == variants.length) {
          final showLoader = state.currentPage < state.pagination.totalPages;

          return showLoader
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
              : const SizedBox.shrink();
        }

        final variant = variants[index];
        return _buildVariantCard(variant, localizations);
      },
    );
  }

  Widget _buildVariantCard(Variant variant, AppLocalizations localizations) {
    final displayName = variant.fullName ?? variant.good?.name ?? 'Неизвестный вариант';
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
                          '${variant.price!.toStringAsFixed(2)}',
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

  String _getPluralForm(int number, String form1, String form2, String form3) {
    final n = number % 100;
    final n1 = n % 10;

    if (n > 10 && n < 20) return form3;
    if (n1 > 1 && n1 < 5) return form2;
    if (n1 == 1) return form1;

    return form3;
  }
}