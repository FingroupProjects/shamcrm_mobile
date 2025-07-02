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
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/foundation.dart';

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
  String _lastSearchQuery = '';
  Map<String, dynamic> _currentFilters = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    if (kDebugMode) {
      print('GoodsScreen: Инициализация экрана товаров');
    }
    context.read<GoodsBloc>().add(FetchGoods());
    context.read<GoodsBloc>().add(FetchSubCategories());
    _searchController.addListener(() {
      _onSearch(_searchController.text);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !context.read<GoodsBloc>().allGoodsFetched) {
      final state = context.read<GoodsBloc>().state;
      if (state is GoodsDataLoaded) {
        if (kDebugMode) {
          print('GoodsScreen: Загрузка следующей страницы товаров, текущая страница: ${state.currentPage}');
        }
        context.read<GoodsBloc>().add(FetchMoreGoods(state.currentPage));
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      _lastSearchQuery = query;
      _isSearching = query.isNotEmpty;
      if (kDebugMode) {
        print('GoodsScreen: Поиск товаров с запросом: $query');
      }
    });
    context.read<GoodsBloc>().add(SearchGoods(query));
  }

  void _resetSearch() {
    setState(() {
      _isSearching = false;
      _lastSearchQuery = '';
      _searchController.clear();
      if (kDebugMode) {
        print('GoodsScreen: Сброс поиска');
      }
    });
    context.read<GoodsBloc>().add(FetchGoods());
  }

  void _onFilterSelected(Map<String, dynamic> filters) {
  if (kDebugMode) {
    print('GoodsScreen: Применение фильтров: $filters');
  }
  setState(() {
    _currentFilters = Map.from(filters);
    if (kDebugMode) {
      print('GoodsScreen: Сохранены текущие фильтры: $_currentFilters');
    }
  });
  context.read<GoodsBloc>().add(FilterGoods(filters));
}
  void _onResetFilters() {
    if (kDebugMode) {
      print('GoodsScreen: Сброс фильтров');
    }
    setState(() {
      _currentFilters = {};
      if (kDebugMode) {
        print('GoodsScreen: Очищены текущие фильтры');
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
      print('GoodsScreen: Очистка ресурсов');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                print('GoodsScreen: Переключение на профиль: $isClickAvatarIcon');
              }
            });
          },
          clearButtonClickFiltr: (isSearching) {
            if (kDebugMode) {
              print('GoodsScreen: Очистка фильтров через AppBar');
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
          currentFilters: _currentFilters, // Pass current filters
        ),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : BlocConsumer<GoodsBloc, GoodsState>(
              listener: (context, state) {
                if (state is GoodsSuccess) {
                  showCustomSnackBar(
                    context: context,
                    message: AppLocalizations.of(context)!.translate(state.message),
                    isSuccess: true,
                  );
                  if (kDebugMode) {
                    print('GoodsScreen: Успех: ${state.message}');
                  }
                } else if (state is GoodsError) {
                  showCustomSnackBar(
                    context: context,
                    message: AppLocalizations.of(context)!.translate(state.message),
                    isSuccess: false,
                  );
                  if (kDebugMode) {
                    print('GoodsScreen: Ошибка: ${state.message}');
                  }
                }
              },
              builder: (context, state) {
                if (state is GoodsLoading) {
                  if (kDebugMode) {
                    print('GoodsScreen: Состояние загрузки');
                  }
                  return const Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                } else if (state is GoodsDataLoaded) {
                  if (kDebugMode) {
                    print('GoodsScreen: Загружено товаров: ${state.goods.length}');
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.goods.length +
                        (context.read<GoodsBloc>().allGoodsFetched ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index == state.goods.length) {
                        if (kDebugMode) {
                          print('GoodsScreen: Отображение индикатора загрузки для следующей страницы');
                        }
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: PlayStoreImageLoading(
                              size: 80.0,
                              duration: Duration(milliseconds: 1000),
                            ),
                          ),
                        );
                      }
                      final Goods goods = state.goods[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GoodsCard(
                          goodsId: goods.id,
                          goodsName: goods.name,
                          isNew: goods.isNew,
                          isPopular: goods.isPopular,
                          isSale: goods.isSale,
                          goodsDescription: goods.description ?? "",
                          goodsCategory: goods.category.name,
                          goodsStockQuantity: goods.quantity ?? 0,
                          goodsFiles: goods.files,
                          isActive: goods.isActive,
                        ),
                      );
                    },
                  );
                } else if (state is GoodsEmpty) {
                  if (kDebugMode) {
                    print('GoodsScreen: Список товаров пуст');
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching
                              ? localizations!.translate('nothing_found')
                              : localizations!.translate('no_products'),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (kDebugMode) {
                              print('GoodsScreen: Обновление списка товаров');
                            }
                            context.read<GoodsBloc>().add(FetchGoods());
                          },
                          child: Text(localizations!.translate('update')),
                        ),
                      ],
                    ),
                  );
                } else if (state is GoodsError) {
                  if (kDebugMode) {
                    print('GoodsScreen: Ошибка загрузки товаров: ${state.message}');
                  }
                  context.read<GoodsBloc>().add(FetchGoods());
                  return const Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                }
                if (kDebugMode) {
                  print('GoodsScreen: Неизвестное состояние');
                }
                return const Center(child: Text('Error'));
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (kDebugMode) {
            print('GoodsScreen: Переход к экрану добавления товара');
          }
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GoodsAddScreen()),
          );
          if (result == true) {
            if (kDebugMode) {
              print('GoodsScreen: Обновление списка товаров после добавления');
            }
            context.read<GoodsBloc>().add(FetchGoods());
          }
        },
        backgroundColor: const Color(0xff1E2E52),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}