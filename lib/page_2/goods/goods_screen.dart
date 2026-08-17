import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/page_2/goods/goods_card.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/goods/goods_add_screen.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/helpful_empty_state.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoodsScreen extends StatefulWidget {
  @override
  _GoodsScreenState createState() => _GoodsScreenState();
}

class _GoodsScreenState extends State<GoodsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool isClickAvatarIcon = false;
  late ScrollController _scrollController;
  Map<String, dynamic> _currentFilters = {};
  bool _canCreateProduct = false;
  bool _isTojsokhtmontjTenant = false;
  String? _tojsokhtmontjSortBy;
  String _tojsokhtmontjSortDirection = 'asc';
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    if (kDebugMode) {
      debugPrint('GoodsScreen: Инициализация экрана товаров');
    }
    context.read<GoodsBloc>().add(FetchGoods());
    _searchController.addListener(() {
      _onSearch(_searchController.text);
    });
    _checkPermissions();
    _loadTenantFlags();
  }

  Future<void> _loadTenantFlags() async {
    final isTojsokhtmontjTenant = await _apiService.isTojsokhtmontjTenant();
    if (!mounted) return;
    setState(() {
      _isTojsokhtmontjTenant = isTojsokhtmontjTenant;
    });
  }

  Future<void> _checkPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool integrationWith1C =
          prefs.getBool('integration_with_1C') ?? false;
      final bool canCreate = await _apiService.hasPermission('product.create');

      setState(() {
        _canCreateProduct = canCreate && !integrationWith1C;
        if (kDebugMode) {
          debugPrint(
              'GoodsScreen: _canCreateProduct установлен в $_canCreateProduct (canCreate: $canCreate, integration_with_1C: $integrationWith1C)');
        }
      });
    } catch (e) {
      setState(() {
        _canCreateProduct = false;
        if (kDebugMode) {
          debugPrint('GoodsScreen: Ошибка при проверке прав: $e');
        }
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !context.read<GoodsBloc>().allGoodsFetched) {
      final state = context.read<GoodsBloc>().state;
      if (state is GoodsDataLoaded) {
        if (kDebugMode) {
          debugPrint(
              'GoodsScreen: Загрузка следующей страницы товаров, текущая страница: ${state.currentPage}');
        }
        context.read<GoodsBloc>().add(FetchMoreGoods(state.currentPage));
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (kDebugMode) {
        debugPrint('GoodsScreen: Поиск товаров с запросом: $query');
      }
    });
    context.read<GoodsBloc>().add(SearchGoods(query));
  }

  void _resetSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      if (kDebugMode) {
        debugPrint('GoodsScreen: Сброс поиска');
      }
    });
    context.read<GoodsBloc>().add(FetchGoods());
  }

  void _onFilterSelected(Map<String, dynamic> filters) {
    if (kDebugMode) {
      debugPrint('GoodsScreen: Применение фильтров: $filters');
    }
    setState(() {
      _currentFilters = Map.from(filters);
      if (kDebugMode) {
        debugPrint('GoodsScreen: Сохранены текущие фильтры: $_currentFilters');
      }
    });
    context.read<GoodsBloc>().add(FilterGoods(filters));
  }

  void _onResetFilters() {
    if (kDebugMode) {
      debugPrint('GoodsScreen: Сброс фильтров');
    }
    setState(() {
      _currentFilters = {};
      _tojsokhtmontjSortBy = null;
      _tojsokhtmontjSortDirection = 'asc';
      if (kDebugMode) {
        debugPrint('GoodsScreen: Очищены текущие фильтры');
      }
    });
    context.read<GoodsBloc>().add(FilterGoods({}));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    if (kDebugMode) {
      debugPrint('GoodsScreen: Очистка ресурсов');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBarPage2(
          title: isClickAvatarIcon
              ? localizations!.translate('appbar_settings')
              : localizations!.translate('appbar_goods'),
          onClickProfileAvatar: () {
            setState(() {
              isClickAvatarIcon = !isClickAvatarIcon;
              if (kDebugMode) {
                debugPrint(
                    'GoodsScreen: Переключение на профиль: $isClickAvatarIcon');
              }
            });
          },
          clearButtonClickFiltr: (isSearching) {
            if (kDebugMode) {
              debugPrint('GoodsScreen: Очистка фильтров через AppBar');
            }
          },
          showSearchIcon: true,
          showFilterOrderIcon: false,
          showFilterIcon: true,
          onChangedSearchInput: (input) {
            _onSearch(input);
          },
          textEditingController: _searchController,
          focusNode: _searchFocusNode,
          clearButtonClick: (isSearching) {
            _resetSearch();
          },
          onFilterGoodsSelected: _onFilterSelected,
          onGoodsResetFilters: _onResetFilters,
          currentFilters: _currentFilters,
          isTojsokhtmontjTenant: _isTojsokhtmontjTenant,
          initialLabels: _currentFilters['label_id'] != null
              ? List<String>.from(_currentFilters['label_id'])
              : null,
        ),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : BlocConsumer<GoodsBloc, GoodsState>(
              listener: (context, state) {
                if (state is GoodsSuccess) {
                  showCustomSnackBar(
                    context: context,
                    message:
                        AppLocalizations.of(context)!.translate(state.message),
                    isSuccess: true,
                  );
                } else if (state is GoodsError) {
                  showCustomSnackBar(
                    context: context,
                    message:
                        AppLocalizations.of(context)!.translate(state.message),
                    isSuccess: false,
                  );
                } else if (state is GoodsBarcodeSearchResult) {
                  if (state.isSingle) {
                    if (kDebugMode) {
                      debugPrint(
                          'GoodsScreen: Найден один товар, переход к карточке с id: ${state.goods.first.id}');
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GoodsDetailsScreen(
                          id: state.goods.first.id,
                          isFromBarcodeSearch: true,
                        ),
                      ),
                    ).then((_) {
                      if (kDebugMode) {
                        debugPrint(
                            'GoodsScreen: Возврат из просмотра товара, загружаем обычный список');
                      }
                      context.read<GoodsBloc>().add(FetchGoods());
                    });
                  } else if (state.isMultiple) {
                    if (kDebugMode) {
                      debugPrint(
                          'GoodsScreen: Найдено несколько товаров: ${state.goods.length}');
                    }
                    // Список отображается в builder
                  }
                  // Случай state.isEmpty обрабатывается в builder
                }
              },
              builder: (context, state) {
                if (state is GoodsLoading) {
                  return const Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                } else if (state is GoodsDataLoaded) {
                  final goodsList =
                      _filterAndSortTojsokhtmontjGoods(state.goods);
                  final list = _buildGoodsList(
                    goodsList,
                    showLoader: !context.read<GoodsBloc>().allGoodsFetched,
                  );
                  if (!_isTojsokhtmontjTenant) return list;
                  return Column(
                    children: [
                      _buildTojsokhtmontjDirectoryToolbar(),
                      Expanded(child: list),
                    ],
                  );
                } else if (state is GoodsBarcodeSearchResult) {
                  if (state.isMultiple) {
                    final goodsList =
                        _filterAndSortTojsokhtmontjGoods(state.goods);
                    final list = _buildGoodsList(
                      goodsList,
                      showLoader: false,
                    );
                    if (!_isTojsokhtmontjTenant) return list;
                    return Column(
                      children: [
                        _buildTojsokhtmontjDirectoryToolbar(),
                        Expanded(child: list),
                      ],
                    );
                  } else if (state.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: colors.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            localizations!.translate('goods_not_found'),
                            style: TextStyle(
                              fontSize: 18,
                              color: colors.textMuted,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<GoodsBloc>().add(FetchGoods());
                            },
                            child: Text(localizations!.translate('show_all')),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const Center(
                      child: PlayStoreImageLoading(
                        size: 80.0,
                        duration: Duration(milliseconds: 1000),
                      ),
                    );
                  }
                } else if (state is GoodsEmpty) {
                  return _isSearching
                      ? HelpfulEmptyState.search(localizations!)
                      : HelpfulEmptyState.section(
                          l10n: localizations!,
                          icon: Icons.inventory_2_outlined,
                          titleKey: 'empty_goods_title',
                          subtitleKey: 'empty_goods_subtitle',
                          actionKey: 'empty_goods_action',
                          onAction: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GoodsAddScreen(),
                              ),
                            );
                          },
                        );
                } else if (state is GoodsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, size: 64, color: colors.textMuted),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            friendlyError(state.message),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: colors.textMuted,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<GoodsBloc>().add(FetchGoods());
                          },
                          child: Text(localizations!.translate('update')),
                        ),
                      ],
                    ),
                  );
                }

                return const Center(
                  child: PlayStoreImageLoading(
                    size: 80.0,
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              },
            ),
      floatingActionButton: _canCreateProduct
          ? FloatingActionButton(
              onPressed: () async {
                if (kDebugMode) {
                  debugPrint('GoodsScreen: Переход к экрану добавления товара');
                }
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GoodsAddScreen()),
                );
                if (result == true) {
                  if (kDebugMode) {
                    debugPrint(
                        'GoodsScreen: Обновление списка товаров после добавления');
                  }
                  context.read<GoodsBloc>().add(FetchGoods());
                }
              },
              backgroundColor: colors.buttonPrimaryBg,
              child: Icon(Icons.add, color: colors.buttonPrimaryFg),
            )
          : null,
    );
  }

  Widget _buildGoodsList(List<Goods> goodsList, {required bool showLoader}) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: goodsList.length + (showLoader ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == goodsList.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: PlayStoreImageLoading(
                size: 80,
                duration: Duration(milliseconds: 1000),
              ),
            ),
          );
        }

        final goods = goodsList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GoodsCard(
            goodsId: goods.id,
            goodsName: goods.name,
            goodsDescription: goods.description ?? '',
            goodsCategory: goods.category.name,
            goodsStockQuantity: goods.quantity ?? 0,
            goodsFiles: goods.files,
            isActive: goods.isActive,
            label: goods.label,
            isTojsokhtmontjTenant: _isTojsokhtmontjTenant,
            availabilityStatus: goods.availabilityStatus,
            characteristicsSummary: goods.characteristicsSummary,
            characteristics: goods.characteristicLabels,
            goodsPrice: double.tryParse(goods.price ?? '') ??
                goods.discountedPrice ??
                goods.discountPrice,
            orderId: goods.orderId,
            orderNumber: goods.orderNumber,
          ),
        );
      },
    );
  }

  Widget _buildTojsokhtmontjDirectoryToolbar() {
    final colors = context.appColors;
    return Container(
      color: colors.surfaceAccent,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            _buildSortHeader('№', 'number', flex: 2),
            _buildSortHeader('Категория', 'category', flex: 4),
            _buildSortHeader('Статус', 'status', flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildSortHeader(String title, String field, {required int flex}) {
    final colors = context.appColors;
    final isActive = _tojsokhtmontjSortBy == field;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () {
          setState(() {
            if (_tojsokhtmontjSortBy == field) {
              _tojsokhtmontjSortDirection =
                  _tojsokhtmontjSortDirection == 'asc' ? 'desc' : 'asc';
            } else {
              _tojsokhtmontjSortBy = field;
              _tojsokhtmontjSortDirection = 'asc';
            }
          });
        },
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? colors.success : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              '$title ${isActive ? (_tojsokhtmontjSortDirection == 'asc' ? '↑' : '↓') : '↕'}',
              style: context.appTextStyles.caption.copyWith(
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? colors.buttonPrimaryBg : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Goods> _filterAndSortTojsokhtmontjGoods(List<Goods> goods) {
    if (!_isTojsokhtmontjTenant || _tojsokhtmontjSortBy == null) return goods;

    final sorted = List<Goods>.from(goods);
    final direction = _tojsokhtmontjSortDirection == 'desc' ? -1 : 1;

    int statusRank(String? status) {
      final normalized = (status ?? '').toLowerCase().replaceAll('ё', 'е');
      if (normalized.contains('брон')) return 0;
      if (normalized.contains('прод')) return 1;
      if (normalized.contains('резерв')) return 2;
      if (normalized.contains('свобод')) return 3;
      return 4;
    }

    sorted.sort((a, b) {
      var result = 0;
      switch (_tojsokhtmontjSortBy) {
        case 'number':
          result = (a.sortOrder ?? a.id).compareTo(b.sortOrder ?? b.id);
        case 'category':
          result = a.category.name
              .toLowerCase()
              .compareTo(b.category.name.toLowerCase());
        case 'status':
          final aRank = statusRank(a.availabilityStatus);
          final bRank = statusRank(b.availabilityStatus);
          if (aRank == 4 && bRank != 4) return 1;
          if (aRank != 4 && bRank == 4) return -1;
          result = aRank.compareTo(bRank);
      }
      if (result == 0) result = a.id.compareTo(b.id);
      return result * direction;
    });
    return sorted;
  }
}
