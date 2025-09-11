import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class GoodsListWidget extends StatefulWidget {
  final Function(Goods) onGoodsSelected;
  final String? selectedGoodsId;
  final String? searchHint;
  final EdgeInsets? padding;

  const GoodsListWidget({
    Key? key,
    required this.onGoodsSelected,
    this.selectedGoodsId,
    this.searchHint,
    this.padding,
  }) : super(key: key);

  @override
  _GoodsListWidgetState createState() => _GoodsListWidgetState();
}

class _GoodsListWidgetState extends State<GoodsListWidget> {
  Goods? selectedGoodsData;

  @override
  void initState() {
    super.initState();
    context.read<GoodsBloc>().add(FetchGoods());
  }

  // Метод для получения правильной цены товара
  double _getGoodsPrice(Goods goods) {
    // Если есть цена со скидкой, используем её
    if (goods.discountedPrice != null) {
      return goods.discountedPrice!;
    }
    
    // Иначе используем обычную цену
    if (goods.discountPrice != null) {
      return goods.discountPrice!;
    }
    
    // Или парсим из строки
    return double.tryParse(goods.price ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GoodsBloc, GoodsState>(
      listener: (context, state) {
        if (state is GoodsError && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message) ?? '',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.red,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Padding(
        padding: widget.padding ?? EdgeInsets.zero,
        child: BlocBuilder<GoodsBloc, GoodsState>(
          builder: (context, state) {
            // Обновляем данные при успешной загрузке
            if (state is GoodsDataLoaded) {
              List<Goods> goodsList = state.goods;
              
              if (widget.selectedGoodsId != null && goodsList.isNotEmpty) {
                try {
                  selectedGoodsData = goodsList.firstWhere(
                    (goods) => goods.id.toString() == widget.selectedGoodsId,
                  );
                } catch (e) {
                  selectedGoodsData = null;
                }
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.translate('goods') ?? 'Товары',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  child: CustomDropdown<Goods>.search(
                    closeDropDownOnClearFilterSearch: true,
                    items: state is GoodsDataLoaded ? state.goods.where((goods) => goods.isActive == true).toList() : [],
                    searchHintText: widget.searchHint ?? AppLocalizations.of(context)!.translate('search_goods') ?? 'Поиск товаров',
                    overlayHeight: 400,
                    enabled: true,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: const Color(0xffF4F7FD),
                      expandedFillColor: Colors.white,
                      closedBorder: Border.all(
                        color: const Color(0xffF4F7FD),
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: const Color(0xffF4F7FD),
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      final price = _getGoodsPrice(item);
                      final hasDiscount = item.discount != null && item.discount!.isNotEmpty && item.discountedPrice != null;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xffF4F7FD),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: item.files.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.files.first.path,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.inventory_2_outlined,
                                            color: Color(0xff1E2E52).withOpacity(0.4),
                                            size: 20,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.inventory_2_outlined,
                                      color: Color(0xff1E2E52).withOpacity(0.4),
                                      size: 20,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      color: Color(0xff1E2E52),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Gilroy',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        item.category.name,
                                        style: TextStyle(
                                          color: Color(0xff1E2E52).withOpacity(0.7),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'Gilroy',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          if (hasDiscount && item.price != null)
                                            Text(
                                              '${double.tryParse(item.price!) ?? 0} ₽',
                                              style: const TextStyle(
                                                color: Color(0xff99A4BA),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w400,
                                                fontFamily: 'Gilroy',
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                          Text(
                                            '${price.toStringAsFixed(0)} ₽',
                                            style: TextStyle(
                                              color: hasDiscount ? const Color(0xffFF2929) : const Color(0xff1E2E52),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Gilroy',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    headerBuilder: (context, selectedItem, enabled) {
                      if (state is GoodsLoading) {
                        return Text(
                          AppLocalizations.of(context)!.translate('select_goods') ?? 'Выберите товар',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        );
                      }

                      if (selectedItem != null) {
                        return Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xffF4F7FD),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: selectedItem.files.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        selectedItem.files.first.path,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.inventory_2_outlined,
                                            color: Color(0xff1E2E52).withOpacity(0.4),
                                            size: 16,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.inventory_2_outlined,
                                      color: Color(0xff1E2E52).withOpacity(0.4),
                                      size: 16,
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedItem.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Gilroy',
                                  color: Color(0xff1E2E52),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }

                      return Text(
                        AppLocalizations.of(context)!.translate('select_goods') ?? 'Выберите товар',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!.translate('select_goods') ?? 'Выберите товар',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    excludeSelected: false,
                    initialItem: (state is GoodsDataLoaded && state.goods.contains(selectedGoodsData))
                        ? selectedGoodsData
                        : null,
                    onChanged: (value) {
                      if (value != null) {
                        widget.onGoodsSelected(value);
                        setState(() {
                          selectedGoodsData = value;
                        });
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}