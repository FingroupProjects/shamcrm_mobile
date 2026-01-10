import 'package:crm_task_manager/models/batch_model.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class GoodsSelectionBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> existingItems;

  // this 3 fields are for batches
  final bool showBatchRemainders;
  final int? supplierId;
  final int? storageId;

  const GoodsSelectionBottomSheet({
    Key? key,
    required this.existingItems,
    this.showBatchRemainders = false,
    this.supplierId,
    this.storageId,
  }) : super(key: key);

  @override
  _GoodsSelectionBottomSheetState createState() => _GoodsSelectionBottomSheetState();
}

class _GoodsSelectionBottomSheetState extends State<GoodsSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Goods> selectedGoods = [];
  Map<int, Map<String, dynamic>> goodsDetails = {};
  Map<int, Map<String, bool>> fieldErrors = {}; // Для отслеживания ошибок валидации
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<GoodsBloc>().add(FetchGoods());
  }

  bool _isGoodsAlreadyAdded(int goodsId) {
    return widget.existingItems.any((item) => item['id'] == goodsId);
  }

  // Валидация полей для конкретного товара
  bool _validateGoodsFields(int goodsId) {
    final details = goodsDetails[goodsId];
    final isAlreadyAdded = _isGoodsAlreadyAdded(goodsId);

    if (details == null) return false;

    bool isQuantityValid = details['quantity'] != null && details['quantity'] > 0;
    bool isPriceValid = isAlreadyAdded || (details['price'] != null && details['price'] >= 0);

    // Обновляем состояние ошибок
    setState(() {
      fieldErrors[goodsId] = {
        'quantity': !isQuantityValid,
        'price': !isPriceValid,
      };
    });

    return isQuantityValid && isPriceValid;
  }

  // Валидация всех выбранных товаров
  bool _validateAllSelectedGoods() {
    bool allValid = true;

    for (final goods in selectedGoods) {
      if (!_validateGoodsFields(goods.id)) {
        allValid = false;
      }
    }

    return allValid;
  }

  void _returnSelectedProducts() {
    // Проверяем валидность всех полей
    if (!_validateAllSelectedGoods()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('please_fill_all_required_fields') ??
                'Пожалуйста, заполните все обязательные поля (количество и цена)',
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

    // Фильтруем только товары с заполненными данными
    final selectedProducts = selectedGoods
        .where((goods) =>
            goodsDetails.containsKey(goods.id) &&
            goodsDetails[goods.id]!['quantity'] != null &&
            goodsDetails[goods.id]!['quantity'] > 0 &&
            (_isGoodsAlreadyAdded(goods.id) ||
                (goodsDetails[goods.id]!['price'] != null && goodsDetails[goods.id]!['price'] >= 0)))
        .map((goods) => {
              'id': goods.id,
              'name': goods.name,
              'quantity': goodsDetails[goods.id]!['quantity'],
              'price': goodsDetails[goods.id]!['price'] ?? 0.0,
              'total': goodsDetails[goods.id]!['total'] ?? 0.0,
              // 'unit_id': goods.unitId,
            })
        .toList();

    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('no_valid_products_selected') ?? 'Не выбрано ни одного корректного товара',
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
    if (widget.showBatchRemainders) {
      context.read<GoodsBloc>().add(FetchBash(
            goodVariantId: goods.id,
            storageId: widget.storageId!,
            supplierId: widget.supplierId!,
            good:goods,
          ));
      return;
    }
    setState(() {
      if (selectedGoods.contains(goods)) {
        selectedGoods.remove(goods);
        goodsDetails.remove(goods.id);
        fieldErrors.remove(goods.id); // Удаляем ошибки
      } else {
        selectedGoods.add(goods);
        goodsDetails[goods.id] = {
          'quantity': null,
          'price': _isGoodsAlreadyAdded(goods.id) ? null : null,
          'total': 0.0,
        };
        fieldErrors[goods.id] = {
          'quantity': false,
          'price': false,
        };
      }
    });
  }

  void _updateGoodsDetails(int goodsId, String field, dynamic value) {
    if (goodsDetails.containsKey(goodsId)) {
      setState(() {
        goodsDetails[goodsId]![field] = value;

        // Очищаем ошибку для конкретного поля при вводе корректного значения
        if (fieldErrors.containsKey(goodsId)) {
          if (field == 'quantity' && value != null && value > 0) {
            fieldErrors[goodsId]!['quantity'] = false;
          } else if (field == 'price' && value != null && value >= 0) {
            fieldErrors[goodsId]!['price'] = false;
          }
        }

        // Пересчитываем общую сумму
        final quantity = goodsDetails[goodsId]!['quantity'];
        final price = goodsDetails[goodsId]!['price'];

        if (quantity != null && price != null && quantity > 0 && price >= 0) {
          goodsDetails[goodsId]!['total'] = quantity * price;
        } else if (_isGoodsAlreadyAdded(goodsId) && quantity != null && quantity > 0) {
          // Для уже добавленных товаров используем цену из существующего списка
          final existingItem = widget.existingItems.firstWhere((item) => item['id'] == goodsId);
          final existingPrice = existingItem['price'] ?? 0.0;
          goodsDetails[goodsId]!['price'] = existingPrice;
          goodsDetails[goodsId]!['total'] = quantity * existingPrice;
        } else {
          goodsDetails[goodsId]!['total'] = 0.0;
        }
      });
    }
  }

  List<Goods> _getFilteredGoods(List<Goods> allGoods) {
    final activeGoods = allGoods.where((g) => g.isActive == true).toList();

    if (_searchController.text.isEmpty) {
      return activeGoods;
    }

    return activeGoods.where((goods) => goods.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoodsBloc, GoodsState>(
      builder: (context, state) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              _buildHeader(state, context),
              if (state is! BatchLoaded) _buildSearchField(),
              const SizedBox(height: 12),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state is BatchLoaded) {
                      return _buildBatchDetails(state.batches, state.good); // Show batch details inline
                    } else if (state is GoodsLoading) {
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
              if (state is! BatchLoaded) _buildAddButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBatchDetails(List<BatchData> batches, Goods good) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: batches.map((batch) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final selectedBatch = {
                          'id': good.id, // или нужный ID товара
                          'name': good.name,
                          'quantity': batch.quantity ?? 0,
                          'price': double.tryParse(batch.price ?? '0') ?? 0.0,
                          'total': (batch.quantity ?? 0) * (double.tryParse(batch.price ?? '0') ?? 0.0),
                          'unit_id': good.unitId,
                        };

                        Navigator.pop(context, [selectedBatch]);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        child: Row(
                          children: [
                            // Иконка партии
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: Color(0xff4759FF),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Данные партии
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    batch.batch,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Gilroy',
                                      color: Color(0xff1E2E52),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Кол-во: ',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xff99A4BA),
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'Gilroy',
                                        ),
                                      ),
                                      Text(
                                        batch.quantity?.toString() ?? '0',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xff1E2E52),
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Gilroy',
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Цена: ',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xff99A4BA),
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'Gilroy',
                                        ),
                                      ),
                                      Text(
                                        batch.price,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xff1E2E52),
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Gilroy',
                                        ),
                                      ),
                                    ],
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
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(GoodsState state, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            state is BatchLoaded
                ? 'Пакетные остатки'
                : AppLocalizations.of(context)!.translate('select_goods') ?? 'Выбрать товары',
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xff1E2E52), size: 24),
            onPressed: () =>
                state is BatchLoaded ? context.read<GoodsBloc>().add(CloseBatchRemainders()) : Navigator.pop(context),
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
            if (isSelected) _buildGoodsDetailsForm(goodsItem, isAlreadyAdded),
            if (index < goods.length - 1) const Divider(height: 20, color: Color(0xFFE5E7EB)),
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

  Widget _buildGoodsDetailsForm(Goods goods, bool isAlreadyAdded) {
    final hasQuantityError = fieldErrors[goods.id]?['quantity'] ?? false;
    final hasPriceError = fieldErrors[goods.id]?['price'] ?? false;

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
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Выравниваем по верху
              children: [
                Expanded(
                  child: Container(
                    height: 70, // Фиксированная высота для контейнера поля
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          decoration: _inputDecoration(
                            AppLocalizations.of(context)!.translate('quantity') ?? 'Количество',
                            hasError: hasQuantityError,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newQuantity = int.tryParse(value) ?? 0;
                            if (newQuantity > 0) {
                              _updateGoodsDetails(goods.id, 'quantity', newQuantity);
                            } else {
                              _updateGoodsDetails(goods.id, 'quantity', null);
                            }
                          },
                        ),
                        const SizedBox(height: 4),
                        // Резервируем место под текст ошибки
                        Container(
                          height: 16, // Фиксированная высота для текста ошибки
                          alignment: Alignment.centerLeft,
                          child: hasQuantityError
                              ? Text(
                                  AppLocalizations.of(context)!.translate('quantity_required') ?? 'Количество обязательно',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                    fontFamily: 'Gilroy',
                                  ),
                                )
                              : null, // Пустое место если нет ошибки
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isAlreadyAdded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 70, // Такая же фиксированная высота
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            decoration: _inputDecoration(
                              AppLocalizations.of(context)!.translate('price') ?? 'Цена',
                              hasError: hasPriceError,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final newPrice = double.tryParse(value) ?? 0.0;
                              if (newPrice >= 0) {
                                _updateGoodsDetails(goods.id, 'price', newPrice);
                              } else {
                                _updateGoodsDetails(goods.id, 'price', null);
                              }
                            },
                          ),
                          const SizedBox(height: 4),
                          // Резервируем место под текст ошибки
                          Container(
                            height: 16, // Фиксированная высота для текста ошибки
                            alignment: Alignment.centerLeft,
                            child: hasPriceError
                                ? Text(
                                    AppLocalizations.of(context)!.translate('price_required') ?? 'Цена обязательна',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                      fontFamily: 'Gilroy',
                                    ),
                                  )
                                : null, // Пустое место если нет ошибки
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${AppLocalizations.of(context)!.translate('total') ?? 'Сумма'} ${(goodsDetails[goods.id]?['total'] ?? 0.0).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: Color(0xff4759FF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {bool hasError = false}) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(
        fontFamily: 'Gilroy',
        fontSize: 12,
        color: Color(0xff99A4BA),
      ),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(
          color: hasError ? Colors.red : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(
          color: hasError ? Colors.red : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(
          color: hasError ? Colors.red : const Color(0xff4759FF),
          width: 1,
        ),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(
          color: Colors.red,
          width: 1,
        ),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(
          color: Colors.red,
          width: 2,
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
