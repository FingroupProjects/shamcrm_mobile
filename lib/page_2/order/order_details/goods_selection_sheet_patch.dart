import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductSelectionSheetAdd extends StatefulWidget {
  final Order order;

  const ProductSelectionSheetAdd({required this.order, super.key});

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

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
    context.read<GoodsBloc>().add(FetchGoods(page: _currentPage));
    _resetGoodsSelection();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initializeBaseUrl() async {
    try {
      final enteredDomainMap = await _apiService.getEnteredDomain();
      String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
      String? enteredDomain = enteredDomainMap['enteredDomain'];
      setState(() {
        baseUrl = 'https://$enteredDomain-back.$enteredMainDomain/storage';
      });
    } catch (error) {
      setState(() {
        baseUrl = 'https://shamcrm.com/storage/';
      });
    }
  }

  void _resetGoodsSelection() {
    final state = context.read<GoodsBloc>().state;
    if (state is GoodsDataLoaded) {
      for (var product in state.goods) {
        product.isSelected = false;
        product.quantitySelected = 1;
      }
    }
  }

  void _filterProducts(String query, List<Goods> goods) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreGoods();
    }
  }

  void _loadMoreGoods() {
    final state = context.read<GoodsBloc>().state;
    if (state is GoodsDataLoaded) {
      setState(() {
        _isLoadingMore = true;
      });
      context
          .read<GoodsBloc>()
          .add(FetchMoreGoods(state.pagination.currentPage));
    }
  }

  void _returnSelectedProducts(List<Goods> goods) {
    final selectedProducts = goods
        .where((product) => product.isSelected == true)
        .map((product) => {
              'id': product.id,
              'name': product.name,
              'price': product.discountPrice ?? 0.0,
              'quantity': product.quantitySelected ?? 1,
              'imagePath':
                  product.files.isNotEmpty ? product.files[0].path : null,
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
            child: BlocConsumer<GoodsBloc, GoodsState>(
              listener: (context, state) {
                if (state is GoodsDataLoaded) {
                  setState(() {
                    _isLoadingMore = false;
                    _hasMore = state.pagination.currentPage <
                        state.pagination.totalPages;
                  });
                }
              },
              builder: (context, state) {
                // Показываем загрузку только для первой страницы
                if (state is GoodsLoading && _currentPage == 1) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is GoodsDataLoaded) {
                  final filteredProducts = _searchQuery.isEmpty
                      ? state.goods
                      : state.goods
                          .where((product) => product.name
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                          .toList();
                  return _buildProductList(filteredProducts, state);
                } else if (state is GoodsEmpty) {
                  return  Center(child: Text(AppLocalizations.of(context)!.translate('no_products_found')));
                } else if (state is GoodsError) {
                  return Center(child: Text(state.message));
                }
                return  Center(child: Text(AppLocalizations.of(context)!.translate('loading_data')));
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
        onChanged: (query) {
          final state = context.read<GoodsBloc>().state;
          if (state is GoodsDataLoaded) {
            _filterProducts(query, state.goods);
          }
        },
        decoration: InputDecoration(
          hintText:  AppLocalizations.of(context)!.translate('search_product_placeholder'),
          hintStyle: TextStyle( fontFamily: 'Gilroy', fontSize: 14, color: Color(0xff99A4BA)),
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

  Widget _buildProductList(List<Goods> products, GoodsDataLoaded state) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: products.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == products.length && _isLoadingMore) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final product = products[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      product.isSelected = !product.isSelected;
                      if (!product.isSelected) product.quantitySelected = 1;
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
                        _buildProductImage(product),
                        const SizedBox(width: 12),
                        Expanded(child: _buildProductDetails(product)),
                        _buildSelectionIndicator(product),
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

  Widget _buildProductImage(Goods product) {
    return SizedBox(
      width: 48,
      height: 48,
      child: product.files.isNotEmpty && baseUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                '$baseUrl/${product.files[0].path}',
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

 Widget _buildProductDetails(Goods product) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        product.name,
        style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff1E2E52)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Убрали отображение ID
      // const SizedBox(height: 4),
      // Text(
      //   product.id.toString(),
      //   style: const TextStyle(
      //       fontSize: 12,
      //       fontFamily: 'Gilroy',
      //       fontWeight: FontWeight.w500,
      //       color: Color(0xff99A4BA)),
      // ),
      if (product.isSelected) ...[
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
                    if (product.quantitySelected > 1)
                      setState(() => product.quantitySelected--);
                  },
                ),
                Text(
                  '${product.quantitySelected}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52)),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  color: const Color(0xff1E2E52),
                  onPressed: () => setState(() => product.quantitySelected++),
                ),
              ],
            ),
          ],
        ),
      ],
    ],
  );
}
  Widget _buildSelectionIndicator(Goods product) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: product.isSelected
                ? const Color(0xff4CAF50)
                : const Color(0xff99A4BA),
            width: 2),
      ),
      child: product.isSelected
          ? const Icon(Icons.check, color: Color(0xff4CAF50), size: 16)
          : null,
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ElevatedButton(
        onPressed: () {
          final state = context.read<GoodsBloc>().state;
          if (state is GoodsDataLoaded) _returnSelectedProducts(state.goods);
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

extension GoodsSelection on Goods {
  static final _isSelected = Expando<bool>();
  static final _quantitySelected = Expando<int>();

  bool get isSelected => _isSelected[this] ?? false;
  set isSelected(bool value) => _isSelected[this] = value;

  int get quantitySelected => _quantitySelected[this] ?? 1;
  set quantitySelected(int value) => _quantitySelected[this] = value;
}
