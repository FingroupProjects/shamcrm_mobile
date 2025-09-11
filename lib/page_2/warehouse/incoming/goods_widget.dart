import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class GoodsSelectionWidget extends StatefulWidget {
  final Function(Goods) onGoodsSelected;
  final String? searchHint;
  final EdgeInsets? padding;

  const GoodsSelectionWidget({
    Key? key,
    required this.onGoodsSelected,
    this.searchHint,
    this.padding,
  }) : super(key: key);

  @override
  _GoodsSelectionWidgetState createState() => _GoodsSelectionWidgetState();
}

class _GoodsSelectionWidgetState extends State<GoodsSelectionWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Goods> _filteredGoods = [];
  List<Goods> _allGoods = [];
  String? _baseUrl;

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
    context.read<GoodsBloc>().add(FetchGoods());
  }

  Future<void> _loadBaseUrl() async {
    // Здесь должна быть загрузка baseUrl из вашего API сервиса
    // Пример: final apiService = context.read<ApiService>();
    // _baseUrl = await apiService.getStaticBaseUrl();
    setState(() {
      _baseUrl = 'https://shamcrm.com/storage'; // Замените на ваш базовый URL
    });
  }

  void _filterGoods(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredGoods = _allGoods;
      } else {
        _filteredGoods = _allGoods
            .where((goods) =>
                goods.name.toLowerCase().contains(query.toLowerCase()) ||
                goods.category.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }


  double _getGoodsPrice(Goods goods) {
    // Определяем цену с учетом скидки
    if (goods.discount != null && goods.discount!.isNotEmpty) {
      final now = DateTime.now();
      for (var discount in goods.discount!) {
        final from = DateTime.parse(discount.from);
        final to = DateTime.parse(discount.to);
        if (now.isAfter(from) && now.isBefore(to)) {
          final originalPrice = double.tryParse(goods.price ?? '0') ?? 0;
          final discountPercent = discount.percent;
          return originalPrice * (1 - discountPercent / 100);
        }
      }
    }
    return double.tryParse(goods.price ?? '0') ?? 0;
  }

  Widget _buildGoodsItem(Goods goods) {
    final price = _getGoodsPrice(goods);
    final hasDiscount = goods.discount != null && goods.discount!.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onGoodsSelected(goods),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffF4F7FD)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xffF4F7FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: goods.files.isNotEmpty && _baseUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '$_baseUrl/${goods.files.first.path}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.inventory_2_outlined,
                                color: Color(0xff99A4BA),
                                size: 24,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff4759FF)),
                                ),
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xff99A4BA),
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goods.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: Color(0xff1E2E52),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasDiscount)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xffFF2929),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${goods.discount!.first.percent}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goods.category.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w400,
                                color: Color(0xff99A4BA),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (hasDiscount && double.tryParse(goods.price ?? '0') != null)
                                Text(
                                  '${double.parse(goods.price!).toStringAsFixed(0)} ₽',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff99A4BA),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                '${price.toStringAsFixed(0)} ₽',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  color: hasDiscount ? const Color(0xffFF2929) : const Color(0xff1E2E52),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xff4759FF),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: BlocListener<GoodsBloc, GoodsState>(
        listener: (context, state) {
          if (state is GoodsError && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  localizations.translate(state.message) ?? state.message,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
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
              ),
            );
          }
          
          if (state is GoodsDataLoaded && mounted) {
            setState(() {
              _allGoods = state.goods.where((goods) => goods.isActive ?? false).toList();
              _filteredGoods = _allGoods;
            });
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _searchController,
              label: localizations.translate('search_goods') ?? 'Поиск товаров',
              hintText: widget.searchHint ?? 'Введите название товара...',
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xff99A4BA),
                size: 20,
              ),
              onChanged: _filterGoods,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<GoodsBloc, GoodsState>(
                builder: (context, state) {
                  if (state is GoodsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xff4759FF)),
                      ),
                    );
                  }

                  if (state is GoodsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xff99A4BA),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localizations.translate('failed_to_load_goods') ?? 'Ошибка загрузки товаров',
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff99A4BA),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<GoodsBloc>().add(FetchGoods());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff4759FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              localizations.translate('retry') ?? 'Повторить',
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_filteredGoods.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xff99A4BA),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty
                                ? (localizations.translate('no_goods_found') ?? 'Товары не найдены')
                                : (localizations.translate('no_goods_available') ?? 'Нет доступных товаров'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff99A4BA),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _filteredGoods.length,
                    itemBuilder: (context, index) {
                      return _buildGoodsItem(_filteredGoods[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}