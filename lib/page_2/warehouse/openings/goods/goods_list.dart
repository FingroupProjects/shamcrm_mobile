import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/openings/goods/goods_list_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/openings/goods/goods_list_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/openings/goods/goods_list_state.dart';
import 'package:crm_task_manager/models/page_2/good_variants_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

class GoodsRadioGroupWidget extends StatefulWidget {
  final String? selectedGood;
  final Function(GoodVariantItem) onSelectGood;
  final bool showPrice;

  const GoodsRadioGroupWidget({
    super.key,
    required this.onSelectGood,
    this.selectedGood,
    this.showPrice = false,
  });

  @override
  State<GoodsRadioGroupWidget> createState() => _GoodsRadioGroupWidgetState();
}

class _GoodsRadioGroupWidgetState extends State<GoodsRadioGroupWidget> {
  List<GoodVariantItem> goodsList = [];
  GoodVariantItem? selectedGoodData;
  String? _autoSelectedGoodId;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      //debugPrint('🟢 GoodsWidget: initState - showPrice=${widget.showPrice}');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<GetAllGoodsListBloc>().state;

        if (kDebugMode) {
          //debugPrint('🟢 GoodsWidget: postFrameCallback - state=${state.runtimeType}');
        }

        if (state is GetAllGoodsListSuccess) {
          goodsList = state.goodsList;
          if (kDebugMode) {
            //debugPrint('🟢 GoodsWidget: Found cached data - ${goodsList.length} goods');
          }
          _updateSelectedGoodData();
        }

        if (state is! GetAllGoodsListSuccess) {
          if (kDebugMode) {
            //debugPrint('🟢 GoodsWidget: Dispatching GetAllGoodsListEv()');
          }
          context.read<GetAllGoodsListBloc>().add(GetAllGoodsListEv());
        }
      }
    });
  }

  void _updateSelectedGoodData() {
    debugPrint("_updateSelectedGoodData started");
    if (widget.selectedGood != null && goodsList.isNotEmpty) {
      try {
        // ИСПРАВЛЕНО: Ищем в текущем списке goodsList
        selectedGoodData = goodsList.firstWhere(
          (good) => good.id.toString() == widget.selectedGood,
        );
        if (kDebugMode) {
          debugPrint('🟢 GoodsWidget: Selected good found - ${selectedGoodData?.fullName ?? selectedGoodData?.good?.name}');
        }
      } catch (e) {
        selectedGoodData = null; // ИСПРАВЛЕНО: обнуляем если не найден
        if (kDebugMode) {
          debugPrint('🔴 GoodsWidget: Selected good NOT found - searching for ${widget.selectedGood}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      //debugPrint('🟡 GoodsWidget: build() called');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('good'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        BlocBuilder<GetAllGoodsListBloc, GetAllGoodsListState>(
          builder: (context, state) {
            if (kDebugMode) {
              //debugPrint('🔵 GoodsWidget BlocBuilder: state=${state.runtimeType}');
            }

            final isLoading = state is GetAllGoodsListLoading;

            if (state is GetAllGoodsListSuccess) {
              goodsList = state.goodsList;
              if (kDebugMode) {
                //debugPrint('🔵 GoodsWidget BlocBuilder: SUCCESS - ${goodsList.length} goods loaded');
                if (goodsList.isNotEmpty) {
                  //debugPrint('🔵 GoodsWidget BlocBuilder: First good = ${goodsList.first.name}, price=${goodsList.first.price}');
                }
              }
              // ИСПРАВЛЕНО: Обновляем selectedGoodData из текущего списка
              _updateSelectedGoodData();

              if (goodsList.length == 1 &&
                  (widget.selectedGood == null || selectedGoodData == null) &&
                  _autoSelectedGoodId != goodsList.first.id.toString()) {
                final singleGood = goodsList.first;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  widget.onSelectGood(singleGood);
                  setState(() {
                    selectedGoodData = singleGood;
                    _autoSelectedGoodId = singleGood.id.toString();
                  });
                });
              }
            }

            if (state is GetAllGoodsListError) {
              if (kDebugMode) {
                //debugPrint('🔴 GoodsWidget BlocBuilder: ERROR - ${state.message}');
              }
            }

            if (kDebugMode) {
              //debugPrint('🔵 GoodsWidget BlocBuilder: Rendering dropdown - items=${goodsList.length}, isLoading=$isLoading');
              //debugPrint('🔵 GoodsWidget BlocBuilder: selectedGoodData=${selectedGoodData?.name}, id=${selectedGoodData?.id}');
            }

            // ИСПРАВЛЕНО: Проверяем что selectedGoodData действительно в списке
            final actualInitialItem = (selectedGoodData != null && goodsList.contains(selectedGoodData))
                ? selectedGoodData
                : null;

            if (kDebugMode && selectedGoodData != null && !goodsList.contains(selectedGoodData)) {
              //debugPrint('⚠️ GoodsWidget: selectedGoodData not in list, resetting to null');
            }

            debugPrint("GoodsWidget dropdown items count: ${goodsList.length}");
            debugPrint("goodsList ids : ${goodsList.map((e) => e.id).toList()}");
            debugPrint("GoodsWidget selectedGoodData: ${selectedGoodData?.toString()}");
            debugPrint("goodsList contains selectedGoodData: ${goodsList.contains(selectedGoodData)}");

            return CustomDropdown<GoodVariantItem>.search(
              closeDropDownOnClearFilterSearch: true,
              items: isLoading ? [] : goodsList,
              searchHintText: AppLocalizations.of(context)!.translate('search'),
              overlayHeight: 400,
              enabled: !isLoading,
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
                if (kDebugMode) {
                  //debugPrint('🟣 GoodsWidget: listItemBuilder called for ${item.name}');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fullName ?? item.good?.name ?? 'Без имени',
                      style: const TextStyle(
                        color: Color(0xff1E2E52),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                    if (widget.showPrice && item.price?.price != null && item.price!.price != '0')
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Цена: ${item.price!.price}',
                          style: const TextStyle(
                            color: Color(0xff1E2E52),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                  ],
                );
              },
              headerBuilder: (context, selectedItem, enabled) {
                if (kDebugMode) {
                  //debugPrint('🟣 GoodsWidget: headerBuilder called - isLoading=$isLoading, selected=${selectedItem.name}');
                }

                if (isLoading) {
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedItem.fullName ?? selectedItem.good?.name ?? 'Без имени',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    if (widget.showPrice &&
                        selectedItem.price?.price != null &&
                        selectedItem.price!.price != '0')
                      Text(
                        'Цена: ${selectedItem.price!.price}',
                        style: const TextStyle(
                          color: Color(0xff1E2E52),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                  ],
                );
              },
              hintBuilder: (context, hint, enabled) {
                if (kDebugMode) {
                  //debugPrint('🟣 GoodsWidget: hintBuilder called - isLoading=$isLoading');
                }

                if (isLoading) {
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                      ),
                    ),
                  );
                }

                return Text(
                  AppLocalizations.of(context)!.translate('select_good'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                );
              },
              noResultFoundBuilder: (context, text) {
                if (kDebugMode) {
                  //debugPrint('🟣 GoodsWidget: noResultFoundBuilder called - isLoading=$isLoading, text=$text');
                }

                if (isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                      ),
                    ),
                  );
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      AppLocalizations.of(context)!.translate('no_results'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ),
                );
              },
              excludeSelected: false,
              // ИСПРАВЛЕНО: Используем actualInitialItem вместо прямой проверки
              initialItem: actualInitialItem,
              validator: (value) {
                if (value == null) {
                  return AppLocalizations.of(context)!.translate('field_required_project');
                }
                return null;
              },
              onChanged: (value) {
                if (kDebugMode) {
                  //debugPrint('🟢 GoodsWidget: onChanged - selected ${value?.name}');
                }

                if (value != null) {
                  widget.onSelectGood(value);
                  setState(() {
                    selectedGoodData = value;
                  });
                  FocusScope.of(context).unfocus();
                }
              },
            );
          },
        ),
      ],
    );
  }
}
