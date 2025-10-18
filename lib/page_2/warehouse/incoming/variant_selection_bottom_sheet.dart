import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_state.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  bool _goodMeasurementEnabled = true;
  
  // Режим отображения (false = по категориям (по умолчанию), true = все товары)
  bool _showAllMode = false;
  
  // Выбранная категория (когда режим по категориям)
  int? _selectedCategoryId;
  
  // Флаг для отслеживания инициализации
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadSettings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Загрузка всех настроек из SharedPreferences
  Future<void> _loadSettings() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    
    setState(() {
      _goodMeasurementEnabled = prefs.getBool('good_measurement') ?? true;
      
      // Безопасная загрузка режима отображения (по умолчанию - по категориям)
      try {
        final savedMode = prefs.getString('variant_display_mode');
        _showAllMode = savedMode == 'all';
      } catch (e) {
        // Если был сохранён в другом формате, очищаем и используем значение по умолчанию
        prefs.remove('variant_display_mode');
        _showAllMode = false; // По умолчанию - по категориям
      }
      
      // Безопасная загрузка ID последней выбранной категории
      try {
        final savedCategoryId = prefs.getInt('variant_selected_category_id');
        _selectedCategoryId = savedCategoryId;
      } catch (e) {
        prefs.remove('variant_selected_category_id');
        _selectedCategoryId = null;
      }
      
      _isInitialized = true;
    });
  }

  // Сохранение режима отображения
  Future<void> _saveDisplayMode(bool showAll) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('variant_display_mode', showAll ? 'all' : 'category');
  }

  // Сохранение выбранной категории
  Future<void> _saveSelectedCategory(int? categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    if (categoryId != null) {
      await prefs.setInt('variant_selected_category_id', categoryId);
    } else {
      await prefs.remove('variant_selected_category_id');
    }
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
    // При поиске переключаемся в режим "все товары"
    if (query.isNotEmpty && !_showAllMode) {
      setState(() {
        _showAllMode = true;
        _selectedCategoryId = null;
      });
      _saveDisplayMode(true);
      _saveSelectedCategory(null);
    }
  }

  // Переключение режима отображения
  void _toggleDisplayMode() {
    setState(() {
      _showAllMode = !_showAllMode;
      _selectedCategoryId = null;
    });
    
    // Сохраняем новый режим
    _saveDisplayMode(_showAllMode);
    _saveSelectedCategory(null);
  }

  // Получение уникальных категорий из вариантов
  List<CategoryData> _getCategories(List<Variant> variants) {
    final Map<int, CategoryData> categoriesMap = {};
    
    for (var variant in variants) {
      if (variant.good?.category != null) {
        final category = variant.good!.category;
        categoriesMap[category.id] = category;
      }
    }
    
    return categoriesMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
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

    final Map<String, dynamic> result = {
      'id': variant.goodId,
      'variantId': variant.id,
      'name': variant.fullName ?? variant.good?.name ?? 'Неизвестный товар',
      'quantity': 1,
      'price': variant.price ?? 0.0,
      'total': 0.0,
      'amount': firstUnitAmount,
      'availableUnits': variant.availableUnits,
      'remainder': variant.remainder ?? 0,
    };

    if (_goodMeasurementEnabled) {
      int? unit_id;
      try {
        unit_id = variant.availableUnits.first.id;
      } catch (e) {
        unit_id = null;
      }
      result['selectedUnit'] = (variant.availableUnits.isNotEmpty
          ? (variant.availableUnits.first.shortName ?? variant.availableUnits.first.name)
          : '');
      result['unit_id'] = unit_id;
    }

    // Сохраняем текущую категорию перед закрытием
    if (_selectedCategoryId != null) {
      _saveSelectedCategory(_selectedCategoryId);
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

    // Показываем загрузку пока настройки не загружены
    if (!_isInitialized) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

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

                  // Выбор режима отображения
                  if (_showAllMode || _searchController.text.isNotEmpty) {
                    // Режим "Все товары"
                    return _buildVariantsList(availableVariants, state, localizations);
                  } else {
                    // Режим "По категориям"
                    if (_selectedCategoryId == null) {
                      // Показываем список категорий
                      return _buildCategoriesList(availableVariants, localizations);
                    } else {
                      // Показываем товары выбранной категории
                      final categoryVariants = availableVariants
                          .where((v) => v.good?.category.id == _selectedCategoryId)
                          .toList();
                      return _buildVariantsList(categoryVariants, state, localizations);
                    }
                  }
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
          // Заголовок с индикатором выбранной категории
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                if (_selectedCategoryId != null)
                  BlocBuilder<VariantBloc, VariantState>(
                    builder: (context, state) {
                      if (state is VariantDataLoaded) {
                        final category = state.variants
                            .firstWhere(
                              (v) => v.good?.category.id == _selectedCategoryId,
                              orElse: () => state.variants.first,
                            )
                            .good
                            ?.category;
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryId = null;
                              });
                              _saveSelectedCategory(null);
                            },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.arrow_back,
                                  size: 14,
                                  color: Color(0xff4759FF),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  category?.name ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff4759FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
          ),
          // Кнопка закрытия
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xff99A4BA)),
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Поле поиска
          Expanded(
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
          ),
          const SizedBox(width: 8),
          // Кнопка сортировки
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _showAllMode ? Icons.list : Icons.grid_view,
                color: const Color(0xff4759FF),
                size: 24,
              ),
              tooltip: _showAllMode ? 'По категориям' : 'Все товары',
              onPressed: _toggleDisplayMode,
            ),
          ),
        ],
      ),
    );
  }

  // Список категорий
  Widget _buildCategoriesList(List<Variant> variants, AppLocalizations localizations) {
    final categories = _getCategories(variants);
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryVariantsCount = variants
            .where((v) => v.good?.category.id == category.id)
            .length;
        
        return _buildCategoryCard(category, categoryVariantsCount);
      },
    );
  }

  // Карточка категории
  Widget _buildCategoryCard(CategoryData category, int itemsCount) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = category.id;
        });
        // Сохраняем выбранную категорию
        _saveSelectedCategory(category.id);
      },
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Изображение категории или иконка
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xffF4F7FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: category.image != null && category.image!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: 'https://shamcrm.com/storage/${category.image}',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.category,
                            color: Color(0xff4759FF),
                            size: 28,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.category,
                        color: Color(0xff4759FF),
                        size: 28,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$itemsCount ${_getPluralForm(itemsCount, 'товар', 'товара', 'товаров')}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xff99A4BA),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Список товаров
  Widget _buildVariantsList(List<Variant> variants, VariantDataLoaded state, AppLocalizations localizations) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: variants.length + 1,
      itemBuilder: (context, index) {
        if (index == variants.length) {
          return context.read<VariantBloc>().allVariantsFetched
              ? const SizedBox.shrink()
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
        }

        final variant = variants[index];
        return _buildVariantCard(variant, localizations);
      },
    );
  }

  // Карточка товара с изображением
  Widget _buildVariantCard(Variant variant, AppLocalizations localizations) {
    final displayName = variant.fullName ?? variant.good?.name ?? 'Неизвестный вариант';
    final imageUrl = variant.good?.mainImageUrl;

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
              // Изображение товара или иконка
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xffF4F7FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.shopping_cart_outlined,
                            color: Color(0xff4759FF),
                            size: 24,
                          ),
                        ),
                      )
                    : const Icon(
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
                    if (variant.price != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${variant.price!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff4759FF),
                          ),
                        ),
                      ),
                  ],
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

  // Вспомогательная функция для склонения слов
  String _getPluralForm(int number, String form1, String form2, String form3) {
    final n = number % 100;
    final n1 = n % 10;
    
    if (n > 10 && n < 20) return form3;
    if (n1 > 1 && n1 < 5) return form2;
    if (n1 == 1) return form1;
    
    return form3;
  }
}