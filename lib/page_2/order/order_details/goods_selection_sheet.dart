import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductSelectionSheet extends StatefulWidget {
  final Order order; // Добавляем текущий заказ

  const ProductSelectionSheet({required this.order, super.key});

  @override
  State<ProductSelectionSheet> createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends State<ProductSelectionSheet> {
  String _searchQuery = '';
  String _selectedFilter = 'Новый';
  String? baseUrl;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
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
        baseUrl = 'https://shamcrm.com/storage/';
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

void _updateOrderWithSelectedProducts(List<Goods> goods) {
  // Собираем новые выбранные товары
  final selectedProducts = goods
      .where((product) => product.isSelected == true)
      .map((product) => {
            'good_id': product.id,
            'quantity': product.quantitySelected ?? 1,
            'price': product.discountPrice ?? 0.0,
          })
      .toList();

  if (selectedProducts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Выберите хотя бы один товар',
          style: TextStyle(fontFamily: 'Gilroy', color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Собираем ВСЕ текущие товары заказа
  final currentGoods = widget.order.goods
      .map((good) => {
            'good_id': good.goodId,
            'quantity': good.quantity,
            'price': good.price,
          })
      .toList();

  // Объединяем текущие и новые товары
  final updatedGoods = [...currentGoods, ...selectedProducts];

  // Логирование для отладки
  print('Current goods: $currentGoods');
  print('Selected products: $selectedProducts');
  print('Updated goods: $updatedGoods');

  // Отправляем событие обновления заказа
  context.read<OrderBloc>().add(UpdateOrder(
    orderId: widget.order.id,
    phone: widget.order.phone,
    leadId: widget.order.lead.id,
    delivery: widget.order.delivery,
    deliveryAddress: widget.order.deliveryAddress ?? '',
    goods: updatedGoods,
    organizationId: 1, // Можно сделать динамическим
  ));

  // Закрываем BottomSheet после отправки
  Navigator.pop(context);
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
            child: BlocBuilder<GoodsBloc, GoodsState>(
              builder: (context, state) {
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
                return const Center(child: Text('Ожидание данных...'));
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
                '$baseUrl/${product.files[0].path}',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholderImage();
                },
              ),
            )
          : _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.image, color: Colors.grey, size: 24)),
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
          if (state is GoodsDataLoaded) _updateOrderWithSelectedProducts(state.goods);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4759FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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