// Файл: simple_goods_widget.dart
// Расположение: lib/page_2/warehouse/write_off/simple_goods_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class SimpleGoodsSelectionBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> existingItems;

  const SimpleGoodsSelectionBottomSheet({
    Key? key,
    required this.existingItems,
  }) : super(key: key);

  @override
  _SimpleGoodsSelectionBottomSheetState createState() => _SimpleGoodsSelectionBottomSheetState();
}

class _SimpleGoodsSelectionBottomSheetState extends State<SimpleGoodsSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Goods> selectedGoods = [];
  Map<int, int> goodsQuantities = {}; // Только количество, без цены
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<GoodsBloc>().add(FetchGoods());
  }

  bool _isGoodsAlreadyAdded(int goodsId) {
    return widget.existingItems.any((item) => item['id'] == goodsId);
  }

  void _returnSelectedProducts() {
    // Фильтруем только товары с заполненным количеством
    final selectedProducts = selectedGoods
        .where((goods) => 
            goodsQuantities.containsKey(goods.id) && 
            goodsQuantities[goods.id]! > 0)
        .map((goods) => {
              'id': goods.id,
              'name': goods.name,
              'quantity': goodsQuantities[goods.id]!,
            })
        .toList();

    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('please_fill_quantity') ?? 'Заполните количество для выбранных товаров',
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
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    Navigator.pop(context, selectedProducts);
  }

  void _toggleGoodsSelection(Goods goods) {
    setState(() {
      if (selectedGoods.contains(goods)) {
        selectedGoods.remove(goods);
        goodsQuantities.remove(goods.id);
      } else {
        selectedGoods.add(goods);
        goodsQuantities[goods.id] = 0;
      }
    });
  }

  void _updateGoodsQuantity(int goodsId, int quantity) {
    if (goodsQuantities.containsKey(goodsId)) {
      setState(() {
        goodsQuantities[goodsId] = quantity;
      });
    }
  }

  List<Goods> _getFilteredGoods(List<Goods> allGoods) {
    final activeGoods = allGoods.where((g) => g.isActive == true).toList();
    
    if (_searchController.text.isEmpty) {
      return activeGoods;
    }
    
    return activeGoods.where((goods) =>
        goods.name.toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();
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
                  final filteredGoods = _getFilteredGoods(state.goods);
                  
                  if (filteredGoods.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!.translate('no_products_found') ?? 'Товары не найдены',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xff99A4BA),
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    );
                  }
                  
                  return _buildGoodsList(filteredGoods);
                } else if (state is GoodsError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          _buildAddButton(),
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
            AppLocalizations.of(context)!.translate('select_goods') ?? 'Выбрать товары',
            style: const TextStyle(
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
        controller: _searchController,
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.translate('search_goods') ?? 'Поиск товаров',
          hintStyle: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 14,
            color: Color(0xff99A4BA),
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xff99A4BA)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffE0E7FF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xff4759FF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffE0E7FF)),
          ),
        ),
      ),
    );
  }

  Widget _buildGoodsList(List<Goods> goods) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: goods.length,
      itemBuilder: (context, index) {
        final goodsItem = goods[index];
        final isSelected = selectedGoods.contains(goodsItem);
        final isAlreadyAdded = _isGoodsAlreadyAdded(goodsItem.id);
        
        return Column(
          children: [
            _buildGoodsListItem(goodsItem, isSelected, isAlreadyAdded),
            if (isSelected) _buildQuantityForm(goodsItem),
            if (index < goods.length - 1)
              const Divider(height: 20, color: Color(0xFFE5E7EB)),
          ],
        );
      },
    );
  }

  Widget _buildGoodsListItem(Goods goods, bool isSelected, bool isAlreadyAdded) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF4F7FD) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleGoodsSelection(goods),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xff1E2E52),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goods.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xff1E2E52),
                              ),
                            ),
                          ),
                          if (isAlreadyAdded)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xff4759FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Добавлен',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Gilroy',
                                  color: Color(0xff4759FF),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        goods.category.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff99A4BA),
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityForm(Goods goods) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FD),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: _inputDecoration(
                  AppLocalizations.of(context)!.translate('quantity') ?? 'Количество',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final newQuantity = int.tryParse(value) ?? 0;
                  if (newQuantity > 0) {
                    _updateGoodsQuantity(goods.id, newQuantity);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(
        fontFamily: 'Gilroy',
        fontSize: 12,
        color: Color(0xff99A4BA),
      ),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(
          color: Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(
          color: Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(
          color: Color(0xff4759FF),
          width: 1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ElevatedButton(
        onPressed: _returnSelectedProducts,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4759FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.translate('add') ?? 'Добавить',
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

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}