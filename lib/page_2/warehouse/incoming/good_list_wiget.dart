import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class GoodsListWidget extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onGoodsSelected;
  final String? searchHint;
  final EdgeInsets? padding;

  const GoodsListWidget({
    Key? key,
    required this.onGoodsSelected,
    this.searchHint,
    this.padding,
  }) : super(key: key);

  @override
  _GoodsListWidgetState createState() => _GoodsListWidgetState();
}

class _GoodsListWidgetState extends State<GoodsListWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Goods> selectedGoods = [];
  Map<int, Map<String, dynamic>> goodsDetails = {};
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isDropdownOpen = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  // Добавляем FocusNode для полей количества и цены
  final Map<int, FocusNode> _quantityFocusNodes = {};
  final Map<int, FocusNode> _priceFocusNodes = {};
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, TextEditingController> _priceControllers = {};

  final TextStyle goodsTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    context.read<GoodsBloc>().add(FetchGoods());
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_isDropdownOpen) {
      final currentFocusNode = FocusScope.of(context).focusedChild;
      _updateOverlay();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentFocusNode != null) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  void _showOverlay() {
    if (_isDropdownOpen) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isDropdownOpen = true);
  }

  void _hideOverlay() {
    if (!_isDropdownOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isDropdownOpen = false);
  }

  void _updateOverlay() {
    if (_isDropdownOpen) {
      final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
      _hideOverlay();
      _showOverlay();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(offset);
        }
      });
    }
  }

  // Новый метод для создания InputDecoration с поддержкой iOS клавиатуры
  InputDecoration _inputDecorationWithDone(String label, FocusNode focusNode) {
    return InputDecoration(
      labelText: label,
      hintText: label,
      labelStyle: const TextStyle(
        fontFamily: 'Gilroy',
        fontSize: 12,
        color: Color(0xff99A4BA),
      ),
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
      // Добавляем суффиксную иконку для закрытия клавиатуры
      suffixIcon: focusNode.hasFocus 
        ? IconButton(
            icon: const Icon(Icons.keyboard_hide, size: 20),
            onPressed: () {
              focusNode.unfocus();
            },
          )
        : null,
    );
  }

  // Метод для создания Toolbar над клавиатурой
  Widget _buildInputToolbar(FocusNode focusNode) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFFE5E7EB),
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              focusNode.unfocus();
            },
            child: Text(
              AppLocalizations.of(context)!.translate('cancel') ?? 'Отмена',
              style: const TextStyle(
                color: Color(0xff4759FF),
                fontSize: 16,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              focusNode.unfocus();
            },
            child: Text(
              AppLocalizations.of(context)!.translate('done') ?? 'Готово',
              style: const TextStyle(
                color: Color(0xff4759FF),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Инициализация контроллеров и FocusNode для товара
  void _initializeGoodsControllers(int goodsId) {
    if (!_quantityControllers.containsKey(goodsId)) {
      _quantityControllers[goodsId] = TextEditingController();
      _priceControllers[goodsId] = TextEditingController();
      _quantityFocusNodes[goodsId] = FocusNode();
      _priceFocusNodes[goodsId] = FocusNode();
      
      // Добавляем слушатели для автоматического скролла при фокусе
      _quantityFocusNodes[goodsId]!.addListener(() {
        if (_quantityFocusNodes[goodsId]!.hasFocus) {
          _scrollToFocusedField();
        }
        setState(() {}); // Для обновления суффиксной иконки
      });
      
      _priceFocusNodes[goodsId]!.addListener(() {
        if (_priceFocusNodes[goodsId]!.hasFocus) {
          _scrollToFocusedField();
        }
        setState(() {}); // Для обновления суффиксной иконки
      });
    }
  }

  // Метод для скролла к полю в фокусе
  void _scrollToFocusedField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Очистка ресурсов для товара
  void _disposeGoodsControllers(int goodsId) {
    _quantityControllers[goodsId]?.dispose();
    _priceControllers[goodsId]?.dispose();
    _quantityFocusNodes[goodsId]?.dispose();
    _priceFocusNodes[goodsId]?.dispose();
    
    _quantityControllers.remove(goodsId);
    _priceControllers.remove(goodsId);
    _quantityFocusNodes.remove(goodsId);
    _priceFocusNodes.remove(goodsId);
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: widget.searchHint ??
                            AppLocalizations.of(context)!.translate('search_goods') ??
                            'Поиск товаров',
                        hintStyle: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          color: Color(0xff99A4BA),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xff4759FF),
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xff99A4BA),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<GoodsBloc, GoodsState>(
                      builder: (context, state) {
                        List<Goods> goodsList = state is GoodsDataLoaded
                            ? state.goods.where((g) => g.isActive == true).toList()
                            : [];

                        if (goodsList.isEmpty) {
                          return const Center(
                            child: Text(
                              'Товары не найдены',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xff99A4BA),
                                fontFamily: 'Gilroy',
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: goodsList.length,
                          itemBuilder: (context, index) {
                            final goods = goodsList[index];

                            if (_searchController.text.isNotEmpty &&
                                !goods.name.toLowerCase().contains(
                                    _searchController.text.toLowerCase())) {
                              return const SizedBox.shrink();
                            }

                            final isSelected = selectedGoods.contains(goods);

                            return Column(
                              children: [
                                _buildListItem(goods, isSelected, () => _toggleGoodsSelection(goods)),
                                if (isSelected) ...[
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _quantityControllers[goods.id],
                                                  focusNode: _quantityFocusNodes[goods.id],
                                                  decoration: _inputDecorationWithDone(
                                                    AppLocalizations.of(context)!.translate('quantity') ??
                                                        'Количество',
                                                    _quantityFocusNodes[goods.id]!,
                                                  ),
                                                  keyboardType: TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.digitsOnly,
                                                  ],
                                                  onChanged: (value) {
                                                    final newQuantity = int.tryParse(value) ?? 0;
                                                    if (newQuantity > 0) {
                                                      setState(() {
                                                        goodsDetails[goods.id]!['quantity'] = newQuantity;
                                                        goodsDetails[goods.id]!['total'] =
                                                            newQuantity * (goodsDetails[goods.id]!['price'] ?? 0.0);
                                                        _updateGoodsSelection();
                                                      });
                                                    }
                                                  },
                                                  onTap: () {
                                                    _scrollToFocusedField();
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _priceControllers[goods.id],
                                                  focusNode: _priceFocusNodes[goods.id],
                                                  decoration: _inputDecorationWithDone(
                                                    AppLocalizations.of(context)!.translate('price') ?? 'Цена',
                                                    _priceFocusNodes[goods.id]!,
                                                  ),
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                                  ],
                                                  onChanged: (value) {
                                                    final newPrice = double.tryParse(value) ?? 0.0;
                                                    if (newPrice >= 0) {
                                                      setState(() {
                                                        goodsDetails[goods.id]!['price'] = newPrice;
                                                        goodsDetails[goods.id]!['total'] =
                                                            (goodsDetails[goods.id]!['quantity'] ?? 0) * newPrice;
                                                        _updateGoodsSelection();
                                                      });
                                                    }
                                                  },
                                                  onTap: () {
                                                    _scrollToFocusedField();
                                                  },
                                                ),
                                              ),
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
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (index < goodsList.length - 1)
                                  const Divider(height: 20, color: Color(0xFFE5E7EB)),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(Goods goods, bool isSelected, VoidCallback onItemSelect) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onItemSelect,
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
                  Text(
                    goods.name,
                    style: goodsTextStyle,
                  ),
                  Text(
                    goods.category.name,
                    style: goodsTextStyle.copyWith(
                      fontSize: 12,
                      color: const Color(0xff99A4BA),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      hintText: label,
      labelStyle: const TextStyle(
        fontFamily: 'Gilroy',
        fontSize: 12,
        color: Color(0xff99A4BA),
      ),
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

  void _toggleGoodsSelection(Goods goods) {
    setState(() {
      if (selectedGoods.contains(goods)) {
        selectedGoods.remove(goods);
        goodsDetails.remove(goods.id);
        // Очищаем ресурсы для этого товара
        _disposeGoodsControllers(goods.id);
      } else {
        selectedGoods.add(goods);
        goodsDetails[goods.id] = {
          'quantity': null,
          'price': null,
          'total': 0.0,
        };
        // Инициализируем контроллеры для нового товара
        _initializeGoodsControllers(goods.id);
      }
      _updateGoodsSelection();
      _updateOverlay();
    });
  }

  void _updateGoodsSelection() {
    widget.onGoodsSelected(selectedGoods.map((g) => {
          'id': g.id,
          'name': g.name,
          'quantity': goodsDetails[g.id]!['quantity'] ?? 0,
          'price': goodsDetails[g.id]!['price'] ?? 0.0,
          'total': goodsDetails[g.id]!['total'] ?? 0.0,
        }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GoodsBloc, GoodsState>(
      listener: (context, state) {
        if (state is GoodsError && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message) ?? '',
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
        }
      },
      child: Padding(
        padding: widget.padding ?? EdgeInsets.zero,
        child: FormField<List<Goods>>(
          validator: (value) {
            if (selectedGoods.isEmpty) {
              return AppLocalizations.of(context)!.translate('field_required_goods') ??
                  'Выберите хотя бы один товар';
            }
            for (var goods in selectedGoods) {
              if (goodsDetails[goods.id]!['quantity'] == null ||
                  goodsDetails[goods.id]!['quantity'] <= 0) {
                return AppLocalizations.of(context)!.translate('invalid_quantity') ??
                    'Укажите корректное количество';
              }
              if (goodsDetails[goods.id]!['price'] == null ||
                  goodsDetails[goods.id]!['price'] < 0) {
                return AppLocalizations.of(context)!.translate('invalid_price') ??
                    'Укажите корректную цену';
              }
            }
            return null;
          },
          builder: (FormFieldState<List<Goods>> field) {
            return GestureDetector(
              // Добавляем возможность закрытия клавиатуры при тапе на пустое место
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('goods') ?? 'Товары',
                    style: goodsTextStyle.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 1,
                        color: field.hasError ? Colors.red : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: CompositedTransformTarget(
                      link: _layerLink,
                      child: GestureDetector(
                        onTap: () {
                          if (!_isDropdownOpen) {
                            _showOverlay();
                          } else {
                            _hideOverlay();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedGoods.isEmpty
                                      ? AppLocalizations.of(context)!.translate('select_goods') ??
                                          'Выберите товары'
                                      : selectedGoods.map((e) => e.name).join(', '),
                                  style: goodsTextStyle.copyWith(
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: const Color(0xff1E2E52),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 0),
                      child: Text(
                        field.errorText!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _hideOverlay();
    
    // Очищаем все контроллеры и FocusNode
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _quantityFocusNodes.values) {
      focusNode.dispose();
    }
    for (var focusNode in _priceFocusNodes.values) {
      focusNode.dispose();
    }
    
    super.dispose();
  }
}