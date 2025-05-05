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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    context.read<GoodsBloc>().add(FetchGoods());
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
        context.read<GoodsBloc>().add(FetchMoreGoods(state.currentPage));
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      _lastSearchQuery = query;
      _isSearching = query.isNotEmpty;
    });
    context.read<GoodsBloc>().add(SearchGoods(query));
  }

  void _resetSearch() {
    setState(() {
      _isSearching = false;
      _lastSearchQuery = '';
      _searchController.clear();
    });
    context.read<GoodsBloc>().add(FetchGoods());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
            });
          },
          clearButtonClickFiltr: (isSearching) {},
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
                } else if (state is GoodsError) {
                  showCustomSnackBar(
                    context: context,
                    message: AppLocalizations.of(context)!.translate(state.message),
                    isSuccess: false,
                  );
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
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.goods.length +
                        (context.read<GoodsBloc>().allGoodsFetched ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index == state.goods.length) {
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
                          goodsDescription: goods.description ?? "",
                          goodsCategory: goods.category.name,
                          goodsStockQuantity: goods.quantity ?? 0,
                          goodsFiles: goods.files,
                        ),
                      );
                    },
                  );
                } else if (state is GoodsEmpty) {
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
                          onPressed: () =>
                              context.read<GoodsBloc>().add(FetchGoods()),
                          child: Text(localizations!.translate('update')),
                        ),
                      ],
                    ),
                  );
                } else if (state is GoodsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(localizations!.translate('error_loading_goods')),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<GoodsBloc>().add(FetchGoods());
                          },
                          child: Text(localizations.translate('retry')),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(child: Text('Error'));
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GoodsAddScreen()),
          );
          if (result == true) {
            context.read<GoodsBloc>().add(FetchGoods());
          }
        },
        backgroundColor: const Color(0xff1E2E52),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}