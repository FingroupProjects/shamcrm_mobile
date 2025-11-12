import 'dart:async';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bottom_sheet_bloc/variant_bottom_sheet_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bottom_sheet_bloc/variant_bottom_sheet_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bottom_sheet_bloc/variant_bottom_sheet_state.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductSelectionSheetAdd extends StatefulWidget {
  final Order? order;

  const ProductSelectionSheetAdd({ this.order, super.key});

  @override
  State<ProductSelectionSheetAdd> createState() =>
      _ProductSelectionSheetAddState();
}

class _ProductSelectionSheetAddState extends State<ProductSelectionSheetAdd> {
  // Constants
  static const double _scrollThreshold = 0.9;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 500);
  static const double _bottomSheetHeight = 0.85;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  late final VariantBottomSheetBloc _bloc;

  String? baseUrl;
  bool _showAllMode = false;
  Timer? _searchDebounce;
  int? currencyId;

  // Для хранения выбранных товаров
  final Map<int, Variant> _selectedVariants = {};
  final Map<int, int> _selectedQuantities = {};
  final Map<int, TextEditingController> _quantityControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
    _loadCurrencyId();
    _scrollController.addListener(_onScroll);
    _bloc = context.read<VariantBottomSheetBloc>();
    _loadSettings();
  }

  Future<void> _initializeBaseUrl() async {
    try {
      final staticBaseUrl = await _apiService.getStaticBaseUrl();
      setState(() {
        baseUrl = staticBaseUrl;
      });
    } catch (error) {
      setState(() {
        baseUrl = 'https://shamcrm.com/storage';
      });
    }
  }

  // Метод загрузки currencyId из SharedPreferences
  Future<void> _loadCurrencyId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrencyId = prefs.getInt('currency_id');

      if (kDebugMode) {
        //print('ProductSelectionSheetAdd: Загружен currency_id из SharedPreferences: $savedCurrencyId');
      }

      setState(() {
        currencyId = savedCurrencyId ?? 0;
      });

      if (currencyId == 0 || currencyId == null) {
        await _fetchCurrencyFromAPI();
      }
    } catch (e) {
      if (kDebugMode) {
        //print('ProductSelectionSheetAdd: Ошибка загрузки currency_id: $e');
      }
      setState(() {
        currencyId = 1; // По умолчанию доллар
      });
    }
  }

  // Метод загрузки currency_id из API
  Future<void> _fetchCurrencyFromAPI() async {
    try {
      final apiService = ApiService();
      final organizationId = await apiService.getSelectedOrganization();
      final settingsList = await apiService.getMiniAppSettings(organizationId);

      if (settingsList.isNotEmpty) {
        final settings = settingsList.first;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('currency_id', settings.currencyId);

        setState(() {
          currencyId = settings.currencyId;
        });

        if (kDebugMode) {
          //print('ProductSelectionSheetAdd: Загружен currency_id из API: ${settings.currencyId}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        //print('ProductSelectionSheetAdd: Ошибка загрузки currency_id из API: $e');
      }
      setState(() {
        currencyId = 1; // По умолчанию доллар
      });
    }
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
        _bloc.add(FetchVariants(forceReload: true));
      } else {
        _bloc.add(FetchCategories(forceReload: true));
      }
    }
  }

  Future<void> _saveDisplayMode(bool showAll) async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('variant_display_mode', showAll ? 'all' : 'category');
  }

  // Метод форматирования цены
  String _formatPrice(double? price) {
    if (price == null) price = 0;
    String symbol = '₽';

    if (kDebugMode) {
      //print('ProductSelectionSheetAdd: _formatPrice вызван с currency_id: $currencyId');
    }

    switch (currencyId) {
      case 1:
        symbol = '\$';
        break;
      case 2:
        symbol = '€';
        break;
      case 3:
        symbol = 'UZS';
        break;
      case 4:
        symbol = 'TJS';
        break;
      default:
        symbol = '₽';
        if (kDebugMode) {
          //print('ProductSelectionSheetAdd: Используется валюта по умолчанию (UZS) для currency_id: $currencyId');
        }
    }

    if (kDebugMode) {
      //print('ProductSelectionSheetAdd: Выбранный символ валюты: $symbol для цены: $price');
    }

    return '${NumberFormat('#,##0', 'ru_RU').format(price)} $symbol';
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
        _bloc.add(SearchAll(query));
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
      _bloc.add(FetchVariants());
    } else {
      _bloc.add(FetchCategories());
    }
  }

  void _onCategoryTap(int categoryId, String categoryName) {
    _bloc.add(FetchVariantsByCategory(
      categoryId: categoryId,
      categoryName: categoryName,
    ));
  }

  void _onBackFromCategory() {
    _bloc.add(FetchCategories());
  }

  void _onVariantTap(Variant variant) {
    final variantId = variant.id;
    final wasSelected = _selectedVariants.containsKey(variantId);

    setState(() {
      if (wasSelected) {
        _selectedVariants.remove(variantId);
        _selectedQuantities.remove(variantId);
      } else {
        _selectedVariants[variantId] = variant;
        _selectedQuantities[variantId] = 1;
      }
    });

    if (wasSelected) {
      FocusScope.of(context).unfocus();
      _disposeQuantityController(variantId);
    } else {
      _syncQuantityController(variantId);
    }
  }

  bool _isVariantSelected(Variant variant) {
    return _selectedVariants.containsKey(variant.id);
  }

  int _getVariantQuantity(Variant variant) {
    return _selectedQuantities[variant.id] ?? 1;
  }

  TextEditingController _getQuantityController(Variant variant) {
    final variantId = variant.id;
    final currentText = '${_getVariantQuantity(variant)}';
    final controller = _quantityControllers[variantId];

    if (controller != null) {
      if (controller.text != currentText) {
        controller.value = TextEditingValue(
          text: currentText,
          selection: TextSelection.collapsed(offset: currentText.length),
        );
      }
      return controller;
    }

    final newController = TextEditingController(text: currentText);
    _quantityControllers[variantId] = newController;
    return newController;
  }

  void _syncQuantityController(int variantId) {
    final controller = _quantityControllers[variantId];
    if (controller == null) return;

    final text = '${_selectedQuantities[variantId] ?? 1}';
    if (controller.text == text) return;

    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _updateVariantQuantity(Variant variant, int quantity) {
    if (!_selectedVariants.containsKey(variant.id)) {
      return;
    }

    final normalizedQuantity = quantity < 1 ? 1 : quantity;
    final currentQuantity = _getVariantQuantity(variant);

    if (currentQuantity == normalizedQuantity) {
      _syncQuantityController(variant.id);
      return;
    }

    setState(() {
      _selectedQuantities[variant.id] = normalizedQuantity;
    });

    _syncQuantityController(variant.id);
  }

  void _handleQuantityInput(Variant variant, String value) {
    if (value.isEmpty) {
      return;
    }

    final parsedValue = int.tryParse(value);
    if (parsedValue == null) {
      _syncQuantityController(variant.id);
      return;
    }

    _updateVariantQuantity(variant, parsedValue);
  }

  void _disposeQuantityController(int variantId) {
    final controller = _quantityControllers.remove(variantId);
    controller?.dispose();
  }

  void _incrementQuantity(Variant variant) {
    if (_selectedVariants.containsKey(variant.id)) {
      final currentQuantity = _getVariantQuantity(variant);
      _updateVariantQuantity(variant, currentQuantity + 1);
    }
  }

  void _decrementQuantity(Variant variant) {
    if (_selectedVariants.containsKey(variant.id)) {
      final currentQty = _getVariantQuantity(variant);
      if (currentQty > 1) {
        _updateVariantQuantity(variant, currentQty - 1);
      } else {
        _syncQuantityController(variant.id);
      }
    }
  }

  void _returnSelectedProducts() {
    final selectedProducts = _selectedVariants.values
        .map((variant) => {
      'id': variant.id,
      'name': _getDisplayName(variant),
      'price': variant.price ?? 0.0,
      'quantity': _getVariantQuantity(variant),
      'imagePath': variant.good?.files.isNotEmpty == true
          ? variant.good!.files[0].path
          : null,
    })
        .toList();

    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('please_select_product'),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.red,
          elevation: 3,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    Navigator.pop(context, selectedProducts);
  }

  String _getDisplayName(Variant variant) {
    if (variant.attributeValues.isNotEmpty) {
      return variant.attributeValues
          .map((attr) => attr.value)
          .join(', ');
    }
    return variant.fullName?.isNotEmpty == true
        ? variant.fullName!
        : variant.good?.name ?? 'Без названия';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _quantityControllers.clear();
    super.dispose();
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
                // Вместо SearchAll('') возвращаемся к предыдущему режиму
                if (_showAllMode) {
                  _bloc.add(FetchVariants());
                } else {
                  _bloc.add(FetchCategories());
                }
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
                _buildAddButton(localizations),
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
                  localizations.translate('add_producted'),
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
                    // Вместо SearchAll('') возвращаемся к предыдущему режиму
                    if (_showAllMode) {
                      _bloc.add(FetchVariants());
                    } else {
                      _bloc.add(FetchCategories());
                    }
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
    // Show loading only if there's no data yet
    if (state.isLoading && !state.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && !state.hasData) { // Only show error if no data
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
                  _bloc.add(FetchVariants(forceReload: true));
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

    // Categories mode (show even if loading for smoother transitions)
    if (state.categories.isNotEmpty || state.isLoading) {
      return _buildCategories(localizations, state);
    }

    // Fallback: show loading
    return const Center(child: CircularProgressIndicator());
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

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (state.searchCategories.isNotEmpty) ...[
          _buildSectionHeader(localizations.translate('categories'), state.searchCategories.length),
          ...state.searchCategories.map((cat) => _buildCategoryCard(cat)),
          const SizedBox(height: 24),
        ],
        if (state.searchVariants.isNotEmpty) ...[
          _buildSectionHeader(localizations.translate('goods'), state.searchVariants.length),
          ...state.searchVariants.map((v) => _buildVariantCard(v, localizations)),
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
    if (state.isLoading && state.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

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
    String emptyMessageKey = state.categoryVariants.isEmpty
        ? 'no_goods_in_category'
        : 'no_variants_found';

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
    if (variants.isEmpty) {
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
      itemCount: variants.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == variants.length) {
          return _buildLoadingIndicator();
        }

        return _buildVariantCard(variants[index], localizations);
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
    final displayName = _getDisplayName(variant);
    final imageUrl = variant.good?.mainImageUrl;
    final isSelected = _isVariantSelected(variant);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xff4759FF) : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _onVariantTap(variant),
              child: Row(
                children: [
                  _buildProductImage(variant, imageUrl),
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
                        const SizedBox(height: 4),
                        Text(
                          _formatPrice(variant.price),
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff4759FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSelectionIndicator(variant),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.translate('stock_quantity_details'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _decrementQuantity(variant),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.remove,
                              size: 20,
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          child: TextField(
                            controller: _getQuantityController(variant),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff1E2E52),
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) => _handleQuantityInput(variant, value),
                            onEditingComplete: () {
                              if ((_quantityControllers[variant.id]?.text ?? '').isEmpty) {
                                _syncQuantityController(variant.id);
                              }
                              FocusScope.of(context).unfocus();
                            },
                            onSubmitted: (value) => _handleQuantityInput(variant, value),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _incrementQuantity(variant),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.add,
                              size: 20,
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Variant variant, String? imageUrl) {
    return Container(
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
    );
  }

  Widget _buildSelectionIndicator(Variant variant) {
    final isSelected = _isVariantSelected(variant);
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const Color(0xff4CAF50) : const Color(0xff99A4BA),
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Color(0xff4CAF50), size: 16)
          : null,
    );
  }

  Widget _buildAddButton(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ElevatedButton(
        onPressed: _returnSelectedProducts,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4759FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Center(
          child: Text(
            localizations.translate('add'),
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}