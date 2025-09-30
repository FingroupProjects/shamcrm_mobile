import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_state.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart' hide AttributeValue;
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VariantSelectionBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> existingItems;

  const VariantSelectionBottomSheet({
    required this.existingItems,
    super.key,
  });

  @override
  State<VariantSelectionBottomSheet> createState() => _VariantSelectionBottomSheetState();
}

class _VariantSelectionBottomSheetState extends State<VariantSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Variant> _selectedVariants = [];
  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, TextEditingController> _quantityControllers = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      final state = context.read<VariantBloc>().state;
      if (state is VariantDataLoaded && !context.read<VariantBloc>().allVariantsFetched) {
        context.read<VariantBloc>().add(FetchMoreVariants(state.currentPage));
      }
    }
  }

  void _onSearch(String query) {
    context.read<VariantBloc>().add(SearchVariants(query));
  }

  void _toggleVariantSelection(Variant variant) {
    setState(() {
      final index = _selectedVariants.indexWhere((v) => v.id == variant.id);
      if (index >= 0) {
        _selectedVariants.removeAt(index);
        _priceControllers[variant.id]?.dispose();
        _priceControllers.remove(variant.id);
        _quantityControllers[variant.id]?.dispose();
        _quantityControllers.remove(variant.id);
      } else {
        final existingItem = widget.existingItems.firstWhere(
          (item) =>
              item['variantId'] == variant.id &&
              item['unit_id'] == (variant.availableUnits.firstWhere(
                    (unit) => unit.shortName == variant.selectedUnit || unit.name == variant.selectedUnit,
                    orElse: () => variant.availableUnits.first,
                  ).id),
          orElse: () => {},
        );

        final newVariant = variant.copyWith(
          isSelected: true,
          quantitySelected: 0,
          price: existingItem.isNotEmpty ? existingItem['price'] as double : null,
          selectedUnit: existingItem.isNotEmpty
              ? existingItem['selectedUnit'] as String
              : (variant.availableUnits.isNotEmpty
                  ? (variant.availableUnits.first.shortName ?? variant.availableUnits.first.name)
                  : 'шт'),
        );
        _selectedVariants.add(newVariant);
        
        _priceControllers[variant.id] = TextEditingController(
          text: existingItem.isNotEmpty ? (existingItem['price'] as double).toStringAsFixed(2) : '',
        );
        _quantityControllers[variant.id] = TextEditingController(text: '');
      }
    });
  }

  bool _isVariantSelected(int variantId) {
    return _selectedVariants.any((v) => v.id == variantId);
  }

  void _updateQuantity(Variant variant, int newQuantity) {
    setState(() {
      final index = _selectedVariants.indexWhere((v) => v.id == variant.id);
      if (index >= 0 && newQuantity > 0) {
        _selectedVariants[index] = variant.copyWith(quantitySelected: newQuantity);
        _quantityControllers[variant.id]?.text = newQuantity.toString();
      }
    });
  }

  void _updateUnit(Variant variant, String newUnit) {
    setState(() {
      final index = _selectedVariants.indexWhere((v) => v.id == variant.id);
      if (index >= 0) {
        _selectedVariants[index] = variant.copyWith(selectedUnit: newUnit);
      }
    });
  }

  void _updatePrice(Variant variant, double newPrice) {
    setState(() {
      final index = _selectedVariants.indexWhere((v) => v.id == variant.id);
      if (index >= 0) {
        _selectedVariants[index] = variant.copyWith(price: newPrice);
      }
    });
  }

  void _confirmSelection() {
    final localizations = AppLocalizations.of(context)!;

    for (var variant in _selectedVariants) {
      final quantityController = _quantityControllers[variant.id];
      
      if (quantityController == null || quantityController.text.trim().isEmpty) {
        _showErrorSnackBar(
          '${localizations.translate('please_enter_quantity_for') ?? 'Пожалуйста, укажите количество для'} "${variant.fullName ?? variant.good?.name}"'
        );
        return;
      }
      
      final quantity = int.tryParse(quantityController.text);
      if (quantity == null || quantity <= 0) {
        _showErrorSnackBar(
          '${localizations.translate('invalid_quantity_for') ?? 'Некорректное количество для'} "${variant.fullName ?? variant.good?.name}"'
        );
        return;
      }

      final existingItem = widget.existingItems.firstWhere(
        (item) =>
            item['variantId'] == variant.id &&
            item['unit_id'] == (variant.availableUnits.firstWhere(
                  (unit) => unit.shortName == variant.selectedUnit || unit.name == variant.selectedUnit,
                  orElse: () => variant.availableUnits.first,
                ).id),
        orElse: () => {},
      );

      if (existingItem.isNotEmpty) {
        final price = existingItem['price'] as double;
        final selectedUnit = existingItem['selectedUnit'] as String;

        variant = variant.copyWith(
          price: price,
          selectedUnit: selectedUnit,
        );
      } else {
        final priceController = _priceControllers[variant.id];
        if (priceController == null || priceController.text.trim().isEmpty) {
          _showErrorSnackBar(
            '${localizations.translate('please_enter_price_for') ?? 'Пожалуйста, укажите цену для'} "${variant.fullName ?? variant.good?.name}"'
          );
          return;
        }
        
        final price = double.tryParse(priceController.text);
        if (price == null || price <= 0) {
          _showErrorSnackBar(
            '${localizations.translate('invalid_price_for') ?? 'Некорректная цена для'} "${variant.fullName ?? variant.good?.name}"'
          );
          return;
        }
      }
    }

    final result = _selectedVariants.map((variant) {
      final price = variant.price ?? double.parse(_priceControllers[variant.id]?.text ?? '0');
      final quantity = int.parse(_quantityControllers[variant.id]!.text);
      final selectedUnit = variant.selectedUnit ?? (variant.availableUnits.isNotEmpty
          ? (variant.availableUnits.first.shortName ?? variant.availableUnits.first.name)
          : 'шт');
      final unitId = variant.availableUnits.firstWhere(
        (unit) => unit.shortName == selectedUnit || unit.name == selectedUnit,
        orElse: () => variant.availableUnits.first,
      ).id;

      return {
        'id': variant.goodId,
        'variantId': variant.id,
        'name': variant.fullName ?? variant.good?.name ?? 'Неизвестный товар',
        'quantity': quantity,
        'price': price,
        'total': price * quantity,
        'selectedUnit': selectedUnit,
        'unit_id': unitId,
        'availableUnits': variant.availableUnits,
      };
    }).toList();

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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _isItemInExistingItems(Variant variant) {
    return widget.existingItems.any((item) =>
        item['variantId'] == variant.id &&
        item['unit_id'] == (variant.availableUnits.firstWhere(
              (unit) => unit.shortName == variant.selectedUnit || unit.name == variant.selectedUnit,
              orElse: () => variant.availableUnits.first,
            ).id));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(localizations),
          _buildSearchField(localizations),
          if (_selectedVariants.isNotEmpty) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildConfirmButton(localizations),
            ),
          Expanded(
            child: BlocBuilder<VariantBloc, VariantState>(
              builder: (context, state) {
                if (state is VariantLoading && _selectedVariants.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is VariantEmpty) {
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

                if (state is VariantError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  );
                }

                if (state is VariantDataLoaded) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.variants.length + 1,
                    itemBuilder: (context, index) {
                      if (index == state.variants.length) {
                        return context.read<VariantBloc>().allVariantsFetched
                            ? const SizedBox.shrink()
                            : const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                      }

                      final variant = state.variants[index];
                      final isSelected = _isVariantSelected(variant.id);
                      final selectedVariant = _selectedVariants.firstWhere(
                        (v) => v.id == variant.id,
                        orElse: () => variant,
                      );

                      return _buildVariantCard(
                        variant,
                        isSelected,
                        selectedVariant,
                        localizations,
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
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
          Text(
            localizations.translate('select_variants') ?? 'Выбор вариантов',
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xff99A4BA)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: localizations.translate('search_variants') ?? 'Поиск вариантов...',
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
    );
  }

  Widget _buildVariantCard(
    Variant variant,
    bool isSelected,
    Variant selectedVariant,
    AppLocalizations localizations,
  ) {
    final displayName = variant.fullName ?? variant.good?.name ?? 'Неизвестный вариант';
    final availableUnits = variant.availableUnits;
    final priceController = _priceControllers[variant.id];
    final quantityController = _quantityControllers[variant.id];
    final isAlreadyAdded = _isItemInExistingItems(variant);

    return Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xffF4F7FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
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
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _toggleVariantSelection(variant),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xff4759FF) : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xff4759FF) : const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                ),
              ],
            ),
            if (isSelected && priceController != null && quantityController != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 12),
              if (!isAlreadyAdded) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.translate('unit') ?? 'Ед. изм.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w400,
                              color: Color(0xff99A4BA),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (availableUnits.length > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedVariant.selectedUnit,
                                  isDense: true,
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  icon: const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xff4759FF)),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff1E2E52),
                                  ),
                                  items: availableUnits.map((unit) {
                                    return DropdownMenuItem<String>(
                                      value: unit.shortName ?? unit.name,
                                      child: Text(unit.shortName ?? unit.name),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      _updateUnit(variant, newValue);
                                    }
                                  },
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Text(
                                selectedVariant.selectedUnit ?? 'шт',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff1E2E52),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.translate('price') ?? 'Цена',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w400,
                              color: Color(0xff99A4BA),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w600,
                              color: Color(0xff1E2E52),
                            ),
                            decoration: InputDecoration(
                              hintText: localizations.translate('price') ?? 'Цена',
                              hintStyle: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w400,
                                color: Color(0xff99A4BA),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xff4759FF), width: 2),
                              ),
                            ),
                            onChanged: (value) {
                              final newPrice = double.tryParse(value);
                              if (newPrice != null) {
                                _updatePrice(variant, newPrice);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('quantity') ?? 'Количество',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                    decoration: InputDecoration(
                      hintText: localizations.translate('quantity') ?? 'Количество',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff99A4BA),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xff4759FF), width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      final newQuantity = int.tryParse(value);
                      if (newQuantity != null && newQuantity > 0) {
                        _updateQuantity(variant, newQuantity);
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(AppLocalizations localizations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: _confirmSelection,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4759FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 50),
          elevation: 0,
        ),
        child: Text(
          '${localizations.translate('confirm') ?? 'Подтвердить'}',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// Extension для копирования Variant с изменениями
extension VariantCopyWith on Variant {
  Variant copyWith({
    int? id,
    int? goodId,
    bool? isActive,
    String? fullName,
    double? price,
    List<AttributeValue>? attributeValues,
    Goods? good,
    bool? isSelected,
    int? quantitySelected,
    String? selectedUnit,
    List<Unit>? availableUnits,
  }) {
    return Variant(
      id: id ?? this.id,
      goodId: goodId ?? this.goodId,
      isActive: isActive ?? this.isActive,
      fullName: fullName ?? this.fullName,
      price: price ?? this.price,
      attributeValues: attributeValues ?? List<AttributeValue>.from(this.attributeValues),
      good: good ?? this.good,
      isSelected: isSelected ?? this.isSelected,
      quantitySelected: quantitySelected ?? this.quantitySelected,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      availableUnits: availableUnits ?? List<Unit>.from(this.availableUnits),
    );
  }
}