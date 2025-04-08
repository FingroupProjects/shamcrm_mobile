import 'package:crm_task_manager/custom_widget/animation.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    context.read<GoodsBloc>().add(FetchGoods());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !(context.read<GoodsBloc>().allGoodsFetched)) {
      final state = context.read<GoodsBloc>().state;
      if (state is GoodsDataLoaded) {
        context.read<GoodsBloc>().add(FetchMoreGoods(state.currentPage));
      }
    }
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
          onChangedSearchInput: (input) {},
          textEditingController: TextEditingController(),
          focusNode: FocusNode(),
          clearButtonClick: (isSearching) {},
        ),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : BlocBuilder<GoodsBloc, GoodsState>(
              builder: (context, state) {
                if (state is GoodsLoading) {
                  return const Center(
                      child: PlayStoreImageLoading(
                          size: 80.0,
                          duration: Duration(milliseconds: 1000)));
                } else if (state is GoodsDataLoaded) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.goods.length + (context.read<GoodsBloc>().allGoodsFetched ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index == state.goods.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: PlayStoreImageLoading(
                                size: 80.0,
                                duration: Duration(milliseconds: 1000)),
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
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Товаров нет',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontFamily: 'Gilroy'),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.read<GoodsBloc>().add(FetchGoods()),
                          child: Text('Обновить'),
                        ),
                      ],
                    ),
                  );
                } else if (state is GoodsError) {
                  return Center(child: Text(state.message));
                }
                return Center(child: Text('Неизвестное состояние'));
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
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}