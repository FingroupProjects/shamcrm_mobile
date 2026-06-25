import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
  static const int _pageSize = 20;
  final ApiService _apiService = ApiService();
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
          debugPrint(
              '🟢 GoodsWidget: Selected good found - ${selectedGoodData?.fullName ?? selectedGoodData?.good?.name}');
        }
      } catch (e) {
        selectedGoodData = null; // ИСПРАВЛЕНО: обнуляем если не найден
        if (kDebugMode) {
          debugPrint(
              '🔴 GoodsWidget: Selected good NOT found - searching for ${widget.selectedGood}');
        }
      }
    }
  }

  Future<CustomDropdownPaginatedResponse<GoodVariantItem>> _searchGoods(
    String query,
    int page,
  ) async {
    final response = await _apiService.getGoodVariantsForDropdown(
      page: page,
      perPage: _pageSize,
      search: query,
    );
    final items = response.result?.data ?? <GoodVariantItem>[];
    final pagination = response.result?.pagination;

    return CustomDropdownPaginatedResponse<GoodVariantItem>(
      items: items,
      hasMore: (pagination?.currentPage ?? page) <
          (pagination?.totalPages ??
              (items.length >= _pageSize ? page + 1 : page)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (kDebugMode) {
      //debugPrint('🟡 GoodsWidget: build() called');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('good'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
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
            final actualInitialItem = (selectedGoodData != null &&
                    goodsList.contains(selectedGoodData))
                ? selectedGoodData
                : null;

            if (kDebugMode &&
                selectedGoodData != null &&
                !goodsList.contains(selectedGoodData)) {
              //debugPrint('⚠️ GoodsWidget: selectedGoodData not in list, resetting to null');
            }

            debugPrint("GoodsWidget dropdown items count: ${goodsList.length}");
            debugPrint(
                "goodsList ids : ${goodsList.map((e) => e.id).toList()}");
            debugPrint(
                "GoodsWidget selectedGoodData: ${selectedGoodData?.toString()}");
            debugPrint(
                "goodsList contains selectedGoodData: ${goodsList.contains(selectedGoodData)}");

            return CustomDropdown<GoodVariantItem>.searchRequestPaginated(
              paginatedRequest: _searchGoods,
              futureRequestDelay: const Duration(milliseconds: 350),
              closeDropDownOnClearFilterSearch: true,
              items: isLoading ? [] : goodsList,
              searchHintText: AppLocalizations.of(context)!.translate('search'),
              overlayHeight: 400,
              enabled: !isLoading,
              decoration: CustomDropdownDecoration(
                closedFillColor: colors.surfacePrimary,
                expandedFillColor: colors.surfacePrimary,
                closedBorder: Border.all(
                  color: colors.borderSubtle,
                  width: 1,
                ),
                closedBorderRadius: BorderRadius.circular(12),
                expandedBorder: Border.all(
                  color: colors.borderSubtle,
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
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                    if (widget.showPrice &&
                        item.price?.price != null &&
                        item.price!.price != '0')
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Цена: ${item.price!.price}',
                          style: TextStyle(
                            color: colors.textSecondary,
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
                  return Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.buttonPrimaryBg,
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedItem.fullName ??
                          selectedItem.good?.name ??
                          'Без имени',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: colors.textPrimary,
                      ),
                    ),
                    if (widget.showPrice &&
                        selectedItem.price?.price != null &&
                        selectedItem.price!.price != '0')
                      Text(
                        'Цена: ${selectedItem.price!.price}',
                        style: TextStyle(
                          color: colors.textSecondary,
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
                  return Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.buttonPrimaryBg,
                      ),
                    ),
                  );
                }

                return Text(
                  AppLocalizations.of(context)!.translate('select_good'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: colors.textPrimary,
                  ),
                );
              },
              noResultFoundBuilder: (context, text) {
                if (kDebugMode) {
                  //debugPrint('🟣 GoodsWidget: noResultFoundBuilder called - isLoading=$isLoading, text=$text');
                }

                if (isLoading) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.buttonPrimaryBg,
                      ),
                    ),
                  );
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      AppLocalizations.of(context)!.translate('no_results'),
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        color: colors.textPrimary,
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
                  return AppLocalizations.of(context)!
                      .translate('field_required_project');
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
