import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_state.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductSelectionSheetAdd extends StatefulWidget {
  final Order? order;

  const ProductSelectionSheetAdd({ this.order, super.key});

  @override
  State<ProductSelectionSheetAdd> createState() =>
      _ProductSelectionSheetAddState();
}

class _ProductSelectionSheetAddState extends State<ProductSelectionSheetAdd> {
  String _searchQuery = '';
  String? baseUrl;
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int? currencyId; // Поле для хранения currency_id

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
    _loadCurrencyId(); // Загружаем currencyId при инициализации
    context.read<VariantBloc>().add(FetchVariants(page: _currentPage));
    _resetVariantSelection();
    _scrollController.addListener(_onScroll);
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

  // Метод форматирования цены
  String _formatPrice(double? price) {
    if (price == null) price = 0;
    String symbol = '₽'; // По умолчанию сум

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

  void _resetVariantSelection() {
    final state = context.read<VariantBloc>().state;
    if (state is VariantDataLoaded) {
      for (var variant in state.variants) {
        variant.isSelected = false;
        variant.quantitySelected = 1;
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
    });
    context.read<VariantBloc>().add(SearchVariants(query));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreVariants();
    }
  }

  void _loadMoreVariants() {
    final state = context.read<VariantBloc>().state;
    if (state is VariantDataLoaded) {
      setState(() {
        _isLoadingMore = true;
      });
      context
          .read<VariantBloc>()
          .add(FetchMoreVariants(state.pagination.currentPage));
    }
  }

  void _returnSelectedProducts(List<Variant> variants) {
    final selectedProducts = variants
        .where((variant) => variant.isSelected == true)
        .map((variant) => {
              'id': variant.id,
              'name': _getDisplayName(variant),
              'price': variant.price ?? 0.0,
              'quantity': variant.quantitySelected,
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
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.red,
          elevation: 3,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: Duration(seconds: 3),
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchField(),
          const SizedBox(height: 12),
          Expanded(
            child: BlocConsumer<VariantBloc, VariantState>(
              listener: (context, state) {
                if (state is VariantDataLoaded) {
                  setState(() {
                    _isLoadingMore = false;
                    _hasMore =
                        state.pagination.currentPage < state.pagination.totalPages;
                  });
                }
              },
              builder: (context, state) {
                if (state is VariantLoading && _currentPage == 1) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is VariantDataLoaded) {
                  final filteredVariants = _searchQuery.isEmpty
                      ? state.variants
                      : state.variants
                          .where((variant) =>
                              _getDisplayName(variant)
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()))
                          .toList();
                  return _buildProductList(filteredVariants, state);
                } else if (state is VariantEmpty) {
                  return Center(
                      child: Text(AppLocalizations.of(context)!
                          .translate('no_products_found')));
                } else if (state is VariantError) {
                  return Center(child: Text(state.message));
                }
                return Center(
                    child: Text(AppLocalizations.of(context)!
                        .translate('loading_data')));
              },
            ),
          ),
          _buildAddButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('add_producted'),
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xff1E2E52), size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: _filterProducts,
        decoration: InputDecoration(
          hintText:
              AppLocalizations.of(context)!.translate('search_product_placeholder'),
          hintStyle: TextStyle(
              fontFamily: 'Gilroy', fontSize: 14, color: Color(0xff99A4BA)),
          prefixIcon: Icon(Icons.search, color: Color(0xff99A4BA)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xffE0E7FF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xff4759FF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xffE0E7FF)),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(List<Variant> variants, VariantDataLoaded state) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: variants.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == variants.length && _isLoadingMore) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final variant = variants[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      variant.isSelected = !variant.isSelected;
                      if (!variant.isSelected) variant.quantitySelected = 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildProductImage(variant),
                        const SizedBox(width: 12),
                        Expanded(child: _buildProductDetails(variant)),
                        _buildSelectionIndicator(variant),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage(Variant variant) {
    return SizedBox(
      width: 48,
      height: 48,
      child: variant.good?.files.isNotEmpty == true && baseUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                '$baseUrl/${variant.good!.files[0].path}',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholderImage(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xff4759FF)),
                    ),
                  );
                },
              ),
            )
          : _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.grey[200],
      child:
          const Center(child: Icon(Icons.image, color: Colors.grey, size: 24)),
    );
  }

  Widget _buildProductDetails(Variant variant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getDisplayName(variant),
          style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Color(0xff1E2E52)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          _formatPrice(variant.price),
          style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff4759FF)),
        ),
        if (variant.isSelected) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('stock_quantity_details'),
                style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xff99A4BA)),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    color: const Color(0xff1E2E52),
                    onPressed: () {
                      if (variant.quantitySelected > 1)
                        setState(() => variant.quantitySelected--);
                    },
                  ),
                  Text(
                    '${variant.quantitySelected}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff1E2E52)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    color: const Color(0xff1E2E52),
                    onPressed: () => setState(() => variant.quantitySelected++),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSelectionIndicator(Variant variant) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: variant.isSelected
                ? const Color(0xff4CAF50)
                : const Color(0xff99A4BA),
            width: 2),
      ),
      child: variant.isSelected
          ? const Icon(Icons.check, color: Color(0xff4CAF50), size: 16)
          : null,
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ElevatedButton(
        onPressed: () {
          final state = context.read<VariantBloc>().state;
          if (state is VariantDataLoaded) _returnSelectedProducts(state.variants);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4759FF),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.translate('add'),
            style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Colors.white),
          ),
        ),
      ),
    );
  }
}

extension VariantSelection on Variant {
  static final _isSelected = Expando<bool>();
  static final _quantitySelected = Expando<int>();

  bool get isSelected => _isSelected[this] ?? false;
  set isSelected(bool value) => _isSelected[this] = value;

  int get quantitySelected => _quantitySelected[this] ?? 1;
  set quantitySelected(int value) => _quantitySelected[this] = value;
}