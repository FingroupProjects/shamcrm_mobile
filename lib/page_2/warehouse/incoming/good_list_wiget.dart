import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_state.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
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
  List<Variant> selectedVariants = [];
  Map<int, Map<String, dynamic>> variantDetails = {};
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isDropdownOpen = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  // Контроллеры и FocusNode для полей
  final Map<int, FocusNode> _quantityFocusNodes = {};
  final Map<int, FocusNode> _priceFocusNodes = {};
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, String> _selectedUnits = {}; // Храним выбранные единицы измерения

  final TextStyle variantTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    context.read<VariantBloc>().add(FetchVariants(page: 1));
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    context.read<VariantBloc>().add(SearchVariants(_searchController.text));
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

  void _initializeVariantControllers(int variantId) {
    if (!_quantityControllers.containsKey(variantId)) {
      _quantityControllers[variantId] = TextEditingController();
      _priceControllers[variantId] = TextEditingController();
      _quantityFocusNodes[variantId] = FocusNode();
      _priceFocusNodes[variantId] = FocusNode();

      _quantityFocusNodes[variantId]!.addListener(() {
        if (_quantityFocusNodes[variantId]!.hasFocus) {
          _scrollToFocusedField();
        }
        setState(() {});
      });

      _priceFocusNodes[variantId]!.addListener(() {
        if (_priceFocusNodes[variantId]!.hasFocus) {
          _scrollToFocusedField();
        }
        setState(() {});
      });
    }
  }

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

  void _disposeVariantControllers(int variantId) {
    _quantityControllers[variantId]?.dispose();
    _priceControllers[variantId]?.dispose();
    _quantityFocusNodes[variantId]?.dispose();
    _priceFocusNodes[variantId]?.dispose();

    _quantityControllers.remove(variantId);
    _priceControllers.remove(variantId);
    _quantityFocusNodes.remove(variantId);
    _priceFocusNodes.remove(variantId);
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
                            'Поиск вариантов',
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
                    child: BlocBuilder<VariantBloc, VariantState>(
                      builder: (context, state) {
                        List<Variant> variantList = state is VariantDataLoaded
                            ? state.variants.where((v) => v.isActive).toList()
                            : [];

                        if (variantList.isEmpty) {
                          return const Center(
                            child: Text(
                              'Варианты не найдены',
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
                          itemCount: variantList.length,
                          itemBuilder: (context, index) {
                            final variant = variantList[index];
                            final isSelected = selectedVariants.contains(variant);

                            return Column(
                              children: [
                                _buildListItem(variant, isSelected, () => _toggleVariantSelection(variant)),
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
                                              if (variant.availableUnits.isNotEmpty) ...[
                                                Expanded(
                                                  child: DropdownButtonFormField<String>(
                                                    value: _selectedUnits[variant.id] ?? variant.selectedUnit,
                                                    decoration: _inputDecorationWithDone(
                                                      AppLocalizations.of(context)!.translate('unit') ?? 'Ед. изм.',
                                                      FocusNode(),
                                                    ),
                                                    items: variant.availableUnits
                                                        .map((unit) => DropdownMenuItem<String>(
                                                              value: unit.shortName ?? unit.name,
                                                              child: Text(
                                                                unit.shortName ?? unit.name,
                                                                style: const TextStyle(
                                                                  fontFamily: 'Gilroy',
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ))
                                                        .toList(),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _selectedUnits[variant.id] = value!;
                                                        variantDetails[variant.id]!['unit'] = value;
                                                        _updateVariantSelection();
                                                      });
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                              ],
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _quantityControllers[variant.id],
                                                  focusNode: _quantityFocusNodes[variant.id],
                                                  decoration: _inputDecorationWithDone(
                                                    AppLocalizations.of(context)!.translate('quantity') ??
                                                        'Количество',
                                                    _quantityFocusNodes[variant.id]!,
                                                  ),
                                                  keyboardType: TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.digitsOnly,
                                                  ],
                                                  onChanged: (value) {
                                                    final newQuantity = int.tryParse(value) ?? 0;
                                                    if (newQuantity > 0) {
                                                      setState(() {
                                                        variantDetails[variant.id]!['quantity'] = newQuantity;
                                                        variantDetails[variant.id]!['total'] =
                                                            newQuantity * (variantDetails[variant.id]!['price'] ?? 0.0);
                                                        _updateVariantSelection();
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
                                                  controller: _priceControllers[variant.id],
                                                  focusNode: _priceFocusNodes[variant.id],
                                                  decoration: _inputDecorationWithDone(
                                                    AppLocalizations.of(context)!.translate('price') ?? 'Цена',
                                                    _priceFocusNodes[variant.id]!,
                                                  ),
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                                  ],
                                                  onChanged: (value) {
                                                    final newPrice = double.tryParse(value) ?? 0.0;
                                                    if (newPrice >= 0) {
                                                      setState(() {
                                                        variantDetails[variant.id]!['price'] = newPrice;
                                                        variantDetails[variant.id]!['total'] =
                                                            (variantDetails[variant.id]!['quantity'] ?? 0) * newPrice;
                                                        _updateVariantSelection();
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
                                              '${AppLocalizations.of(context)!.translate('total') ?? 'Сумма'} ${(variantDetails[variant.id]?['total'] ?? 0.0).toStringAsFixed(2)}',
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
                                if (index < variantList.length - 1)
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

  Widget _buildListItem(Variant variant, bool isSelected, VoidCallback onItemSelect) {
    String displayName = variant.fullName?.isNotEmpty == true
        ? variant.fullName!
        : variant.attributeValues.isNotEmpty
            ? variant.attributeValues.map((attr) => attr.value).join(', ')
            : variant.good?.name ?? 'Без названия';

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
                    displayName,
                    style: variantTextStyle,
                  ),
                  Text(
                    variant.good?.category.name ?? '',
                    style: variantTextStyle.copyWith(
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

  void _toggleVariantSelection(Variant variant) {
    setState(() {
      if (selectedVariants.contains(variant)) {
        selectedVariants.remove(variant);
        variantDetails.remove(variant.id);
        _disposeVariantControllers(variant.id);
      } else {
        selectedVariants.add(variant);
        variantDetails[variant.id] = {
          'quantity': 1,
          'price': variant.price ?? 0.0,
          'total': variant.price ?? 0.0,
          'unit': variant.selectedUnit,
        };
        _selectedUnits[variant.id] = variant.selectedUnit ?? '';
        _initializeVariantControllers(variant.id);
        _priceControllers[variant.id]!.text = (variant.price ?? 0.0).toString();
        _quantityControllers[variant.id]!.text = '1';
      }
      _updateVariantSelection();
      _updateOverlay();
    });
  }

  void _updateVariantSelection() {
    widget.onGoodsSelected(selectedVariants.map((v) => {
          'id': v.id,
          'name': v.fullName?.isNotEmpty == true
              ? v.fullName!
              : v.attributeValues.isNotEmpty
                  ? v.attributeValues.map((attr) => attr.value).join(', ')
                  : v.good?.name ?? 'Без названия',
          'quantity': variantDetails[v.id]!['quantity'] ?? 0,
          'price': variantDetails[v.id]!['price'] ?? 0.0,
          'total': variantDetails[v.id]!['total'] ?? 0.0,
          'unit': variantDetails[v.id]!['unit'] ?? '',
        }).toList());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _hideOverlay();

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
  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}