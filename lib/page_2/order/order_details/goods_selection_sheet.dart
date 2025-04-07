import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductSelectionSheet extends StatefulWidget {
  const ProductSelectionSheet({super.key});

  @override
  State<ProductSelectionSheet> createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends State<ProductSelectionSheet> {
  String _searchQuery = '';
  String _selectedFilter = 'Новый';
  String? baseUrl; // Добавляем переменную для базового URL\\
  final ApiService _apiService = ApiService(); // Экземпляр ApiService

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl(); // Инициализируем базовый URL
    context.read<GoodsBloc>().add(FetchGoods());
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
        baseUrl = 'https://shamcrm.com/storage/'; // Резервный URL
      });
    }
  }

  void _filterProducts(String query, List<Goods> goods) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _addSelectedProducts(List<Goods> goods) {
    final selectedProducts = goods
        .where((product) => product.isSelected == true)
        .map((product) => {
              'id': product.id,
              'name': product.name,
              'price': product.discountPrice ?? 0.0,
              'quantity': product.quantitySelected ?? 1,
            })
        .toList();

    if (selectedProducts.isNotEmpty) {
      Navigator.pop(context, selectedProducts);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Выберите хотя бы один товар',
            style: TextStyle(fontFamily: 'Gilroy', color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Убираем создание нового GoodsBloc здесь, предполагаем, что он уже предоставлен сверху
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
            child: BlocBuilder<GoodsBloc, GoodsState>(
              builder: (context, state) {
                print('Current state: $state'); // Отладка состояния
                if (state is GoodsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is GoodsDataLoaded) {
                  final filteredProducts = _searchQuery.isEmpty
                      ? state.goods
                      : state.goods
                          .where((product) => product.name
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                          .toList();
                  return _buildProductList(filteredProducts);
                } else if (state is GoodsEmpty) {
                  return const Center(child: Text('Товары не найдены'));
                } else if (state is GoodsError) {
                  return Center(child: Text(state.message));
                }
                return const Center(
                    child: Text('Ожидание данных...')); // Изменено для ясности
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
          const Text(
            'Добавление товара',
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
          hintText: 'Поиск по названию, артикулу, штри...',
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

  Widget _buildProductList(List<Goods> products) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: products.length,
      itemBuilder: (context, index) {
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
              '$baseUrl/${product.files[0].path}', // Полный URL с динамическим baseUrl
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildPlaceholderImage(); // Показываем заглушку во время загрузки
              },
            ),
          )
        : _buildPlaceholderImage(),
  );
}

  Widget _buildPlaceholderImage() {
    return Container(
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
        const SizedBox(height: 4),
        Text(
          product.id.toString(),
          style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Color(0xff99A4BA)),
        ),
        if (product.isSelected) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Количество',
                  style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff99A4BA))),
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
          if (state is GoodsDataLoaded) _addSelectedProducts(state.goods);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4759FF),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Center(
          child: Text(
            'Добавить',
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
