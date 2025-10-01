import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_state.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    bool _goodMeasurementEnabled = true; // добавляем флаг


  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
        _loadGoodMeasurementSetting(); // загружаем настройку

  }
 // Добавляем метод загрузки настройки
  Future<void> _loadGoodMeasurementSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _goodMeasurementEnabled = prefs.getBool('good_measurement') ?? true;
    });
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

  void _onVariantTap(Variant variant) {
    final isAlreadyAdded = widget.existingItems.any((item) => item['variantId'] == variant.id);
    
    if (isAlreadyAdded) {
      _showErrorSnackBar(
        AppLocalizations.of(context)!.translate('item_already_added') ?? 'Товар уже добавлен'
      );
      return;
    }

    final firstUnitAmount = variant.availableUnits.isNotEmpty 
        ? (variant.availableUnits.first.amount ?? 1) 
        : 1;

    // Формируем результат с учётом настройки good_measurement
    final result = {
      'id': variant.goodId,
      'variantId': variant.id,
      'name': variant.fullName ?? variant.good?.name ?? 'Неизвестный товар',
      'quantity': 1,
      'price': 0.0,
      'total': 0.0,
      'amount': firstUnitAmount,
      'availableUnits': variant.availableUnits,
    };

    // Добавляем unit-поля только если good_measurement включен
    if (_goodMeasurementEnabled) {
      result['selectedUnit'] = (variant.availableUnits.isNotEmpty
          ? (variant.availableUnits.first.shortName ?? variant.availableUnits.first.name)
          : null)!;
      result['unit_id'] = variant.availableUnits.isNotEmpty 
          ? variant.availableUnits.first.id 
          : 2;
    }

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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _isItemAlreadyAdded(Variant variant) {
    return widget.existingItems.any((item) => item['variantId'] == variant.id);
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
          Expanded(
            child: BlocBuilder<VariantBloc, VariantState>(
              builder: (context, state) {
                if (state is VariantLoading) {
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
                  // Фильтруем уже добавленные товары
                  final availableVariants = state.variants
                      .where((variant) => !_isItemAlreadyAdded(variant))
                      .toList();

                  if (availableVariants.isEmpty) {
                    return Center(
                      child: Text(
                        localizations.translate('all_variants_added') ?? 'Все варианты уже добавлены',
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
                    itemCount: availableVariants.length + 1,
                    itemBuilder: (context, index) {
                      if (index == availableVariants.length) {
                        return context.read<VariantBloc>().allVariantsFetched
                            ? const SizedBox.shrink()
                            : const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                      }

                      final variant = availableVariants[index];
                      return _buildVariantCard(variant, localizations);
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
            localizations.translate('select_variant') ?? 'Выбор товара',
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
          hintText: localizations.translate('search_variants') ?? 'Поиск товаров...',
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

  Widget _buildVariantCard(Variant variant, AppLocalizations localizations) {
    final displayName = variant.fullName ?? variant.good?.name ?? 'Неизвестный вариант';

    return GestureDetector(
      onTap: () => _onVariantTap(variant),
      child: Container(
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
          child: Row(
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
                child: Text(
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
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xff99A4BA),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}