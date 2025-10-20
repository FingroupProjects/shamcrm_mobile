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
  final bool forceReload; // Флаг для принудительной перезагрузки

  const VariantSelectionBottomSheet({
    required this.existingItems,
    this.forceReload = false,
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
  
  bool _dataInitialized = false;
  
  void _initializeData() {
    // Защита от повторной инициализации
    if (_dataInitialized) {
      print('⚠️ _initializeData already called, skipping');
      return;
    }
    _dataInitialized = true;
    
    if (_showAllMode) {
      print('📦 Loading ALL variants');
      // В режиме "все товары" загружаем все варианты
      context.read<VariantBloc>().add(FetchVariants());
    } else if (_selectedCategoryId != null) {
      print('📦 Loading variants for saved category: $_selectedCategoryId');
      // Если была сохранена категория - загружаем её товары
      context.read<VariantBloc>().add(FetchVariantsByCategory(categoryId: _selectedCategoryId!));
    } else {
      print('📂 Loading CATEGORIES first');
      // В режиме "по категориям" загружаем список категорий
      context.read<VariantBloc>().add(FetchCategories());
    }
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
        print('🔍 SharedPreferences: variant_display_mode = "$savedMode"');
        
        // ВРЕМЕННО: Принудительно сбрасываем в режим категорий если был 'all'
        // Уберите эти 4 строки после тестирования
        if (savedMode == 'all') {
          print('🔄 Forcing reset to categories mode');
          prefs.setString('variant_display_mode', 'category');
          _showAllMode = false;
        } else {
          _showAllMode = savedMode == 'all';
        }
        
        print('🔍 _showAllMode = $_showAllMode (${_showAllMode ? "All goods" : "Categories"})');
      } catch (e) {
        print('⚠️ Error loading display mode: $e');
        // Если был сохранён в другом формате, очищаем и используем значение по умолчанию
        prefs.remove('variant_display_mode');
        _showAllMode = false; // По умолчанию - по категориям
        print('🔍 Reset to default: _showAllMode = false (Categories)');
      }
      
      // Безопасная загрузка ID последней выбранной категории
      try {
        final savedCategoryId = prefs.getInt('variant_selected_category_id');
        print('🔍 SharedPreferences: variant_selected_category_id = $savedCategoryId');
        _selectedCategoryId = savedCategoryId;
      } catch (e) {
        print('⚠️ Error loading category id: $e');
        prefs.remove('variant_selected_category_id');
        _selectedCategoryId = null;
      }
      
      _isInitialized = true;
    });
    
    // Инициализируем данные после загрузки настроек
    if (mounted) {
      _initializeData();
    }
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
      } else if (state is CategoryVariantsLoaded) {
        // Проверяем, есть ли ещё страницы для загрузки
        if (state.currentPage < state.pagination.totalPages) {
          context.read<VariantBloc>().add(FetchMoreVariantsByCategory(
            categoryId: state.categoryId,
            currentPage: state.currentPage,
          ));
        }
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
    
    // Загружаем данные в зависимости от режима (не зависит от _dataInitialized)
    if (_showAllMode) {
      context.read<VariantBloc>().add(FetchVariants());
    } else {
      context.read<VariantBloc>().add(FetchCategories());
    }
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

    return PopScope(
      canPop: _showAllMode || _selectedCategoryId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_showAllMode && _selectedCategoryId != null) {
          // Если мы в режиме категорий и выбрана категория - возвращаемся к списку категорий
          setState(() {
            _selectedCategoryId = null;
          });
          _saveSelectedCategory(null);
          // Загружаем список категорий
          context.read<VariantBloc>().add(FetchCategories());
        }
      },
      child: Container(
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
                  // Обработка состояний загрузки
                  if (state is VariantLoading || state is CategoriesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (state is CategoryVariantsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Обработка пустых состояний
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

                  // Обработка ошибок
                  if (state is VariantError || state is CategoriesError) {
                    final message = state is VariantError ? state.message : (state as CategoriesError).message;
                    return Center(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    );
                  }

                  // Обработка загруженных категорий
                  if (state is CategoriesLoaded) {
                    if (state.categories.isEmpty) {
                      return Center(
                        child: Text(
                          localizations.translate('no_categories_found') ?? 'Категории не найдены',
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            color: Color(0xff99A4BA),
                          ),
                        ),
                      );
                    }
                    return _buildCategoriesListFromApi(state.categories, localizations);
                  }

                  // Обработка загруженных вариантов по категории
                  if (state is CategoryVariantsLoaded) {
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

                    return _buildCategoryVariantsList(availableVariants, state, localizations);
                  }

                  // Обработка загруженных вариантов (режим "Все товары")
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

                    return _buildVariantsList(availableVariants, state, localizations);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
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
                BlocBuilder<VariantBloc, VariantState>(
                  builder: (context, state) {
                    if (state is CategoryVariantsLoaded) {
                      // Получаем имя категории из первого варианта
                      final categoryName = state.variants.isNotEmpty 
                          ? state.variants.first.good?.category.name 
                          : '';
                      
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = null;
                            });
                            _saveSelectedCategory(null);
                            context.read<VariantBloc>().add(FetchCategories());
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
                                categoryName ?? '',
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

  // Список категорий из API
  Widget _buildCategoriesListFromApi(List<CategoryWithCount> categories, AppLocalizations localizations) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final categoryWithCount = categories[index];
        return _buildCategoryCard(categoryWithCount.category, categoryWithCount.goodsCount);
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
        // Загружаем варианты для выбранной категории
        context.read<VariantBloc>().add(FetchVariantsByCategory(categoryId: category.id));
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

  // Список товаров (все товары)
  Widget _buildVariantsList(List<Variant> variants, VariantDataLoaded state, AppLocalizations localizations) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: variants.length + 1,
      itemBuilder: (context, index) {
        if (index == variants.length) {
          final showLoader = _showAllMode && !context.read<VariantBloc>().allVariantsFetched;

          return showLoader
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
              : const SizedBox.shrink();
        }

        final variant = variants[index];
        return _buildVariantCard(variant, localizations);
      },
    );
  }

  // Список товаров категории
  Widget _buildCategoryVariantsList(List<Variant> variants, CategoryVariantsLoaded state, AppLocalizations localizations) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: variants.length + 1,
      itemBuilder: (context, index) {
        if (index == variants.length) {
          final showLoader = state.currentPage < state.pagination.totalPages;

          return showLoader
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
              : const SizedBox.shrink();
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
                Icons.add,
                color: Color(0xff99A4BA),
                size: 22,
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