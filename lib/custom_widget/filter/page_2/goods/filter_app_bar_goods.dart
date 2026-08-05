import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/goods/SubCategoryMultiSelectWidget.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/goods/labels_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/goods/status.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/models/page_2/category_dashboard_warehouse_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoodsFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final List<int>? initialCategoryIds;
  final double? initialDiscountPercent;
  final List<String>? initialLabels; // Оставляем List<String> для label_id
  final bool? initialIsActive;
  final bool isTojsokhtmontjTenant;

  const GoodsFilterScreen({
    super.key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialCategoryIds,
    this.initialDiscountPercent,
    this.initialLabels,
    this.initialIsActive,
    this.isTojsokhtmontjTenant = false,
  });

  @override
  State<GoodsFilterScreen> createState() => _GoodsFilterScreenState();
}

class _GoodsFilterScreenState extends State<GoodsFilterScreen> {
  final TextEditingController discountPercentController =
      TextEditingController();
  List<SubCategoryAttributesData> selectedCategories = [];
  List<String> selectedLabels = []; // Храним label_id как строки
  bool isCategoryValid = true;
  bool? isActive;
  final ApiService _apiService = ApiService();
  List<CategoryDashboardWarehouse> categories = [];
  int? selectedCategoryId;
  bool isCategoriesLoading = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('GoodsFilterScreen: Инициализация экрана фильтров');
      debugPrint(
          'GoodsFilterScreen: Начальные значения - category_ids: ${widget.initialCategoryIds}, '
          'discount_percent: ${widget.initialDiscountPercent}, label_id: ${widget.initialLabels}, '
          'is_active: ${widget.initialIsActive}');
    }

    if (widget.initialDiscountPercent != null &&
        widget.initialDiscountPercent! >= 0) {
      discountPercentController.text =
          widget.initialDiscountPercent!.toStringAsFixed(2);
      if (kDebugMode) {
        debugPrint(
            'GoodsFilterScreen: Установлен начальный процент скидки: ${discountPercentController.text}');
      }
    }

    if (widget.initialLabels != null) {
      selectedLabels = List.from(widget.initialLabels!);
      if (kDebugMode) {
        debugPrint(
            'GoodsFilterScreen: Установлены начальные label_id: $selectedLabels');
      }
    }

    if (widget.initialIsActive != null) {
      isActive = widget.initialIsActive;
      if (kDebugMode) {
        debugPrint(
            'GoodsFilterScreen: Установлено начальное значение is_active: $isActive');
      }
    }

    context.read<GoodsBloc>().add(FetchSubCategories());
    if (widget.isTojsokhtmontjTenant) {
      _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      isCategoriesLoading = true;
      selectedCategoryId = widget.initialCategoryIds != null &&
              widget.initialCategoryIds!.isNotEmpty
          ? widget.initialCategoryIds!.first
          : null;
    });

    try {
      final loadedCategories =
          await _apiService.getCategoryDashboardWarehouse();
      if (!mounted) return;
      setState(() {
        categories = loadedCategories;
        isCategoriesLoading = false;
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('GoodsFilterScreen: Ошибка загрузки категорий: $error');
      }
      if (!mounted) return;
      setState(() {
        isCategoriesLoading = false;
      });
    }
  }

  @override
  void dispose() {
    discountPercentController.dispose();
    if (kDebugMode) {
      debugPrint('GoodsFilterScreen: Очистка ресурсов');
    }
    super.dispose();
  }

  void _handleStatusChanged(bool? status) {
    setState(() {
      isActive = status;
      if (kDebugMode) {
        debugPrint('GoodsFilterScreen: Изменено значение is_active: $isActive');
      }
    });
  }

  Widget _buildTenantCategoryField() {
    CategoryDashboardWarehouse? selectedCategory;
    for (final category in categories) {
      if (category.id == selectedCategoryId) {
        selectedCategory = category;
        break;
      }
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.appColors.surfacePrimary,
      shadowColor: context.appColors.shadowColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Категория',
              style: context.appTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            CustomDropdown<CategoryDashboardWarehouse>.search(
              closeDropDownOnClearFilterSearch: true,
              items: categories,
              searchHintText: AppLocalizations.of(context)!.translate('search'),
              overlayHeight: 300,
              enabled: !isCategoriesLoading,
              decoration: CustomDropdownDecoration(
                closedFillColor: context.appColors.fieldBg,
                expandedFillColor: context.appColors.surfacePrimary,
                closedBorder: Border.all(
                  color: context.appColors.borderSubtle,
                  width: 1.5,
                ),
                closedBorderRadius: BorderRadius.circular(12),
                expandedBorder: Border.all(
                  color: context.appColors.borderSubtle,
                  width: 1.5,
                ),
                expandedBorderRadius: BorderRadius.circular(12),
              ),
              listItemBuilder: (context, item, isSelected, onItemSelect) {
                return Text(
                  item.name,
                  style: context.appTextStyles.bodyMd.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
              headerBuilder: (context, selectedItem, enabled) {
                return Text(
                  selectedItem.name,
                  style: context.appTextStyles.bodyMd.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
              hintBuilder: (context, hint, enabled) => Text(
                'Все категории',
                style: context.appTextStyles.bodyMd.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              initialItem: selectedCategory,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedCategoryId = value.id;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.backgroundSecondary,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('filter'),
          style: context.appTextStyles.titleLg.copyWith(
            color: context.appColors.textPrimary,
          ),
        ),
        backgroundColor: context.appColors.surfacePrimary,
        forceMaterialTransparency: true,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (kDebugMode) {
                  debugPrint('GoodsFilterScreen: Сброс фильтров');
                }
                widget.onResetFilters?.call();
                selectedCategories = [];
                selectedCategoryId = null;
                selectedLabels = [];
                discountPercentController.clear();
                isCategoryValid = true;
                isActive = null;
              });
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor:
                  context.appColors.buttonSecondaryBg.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(
                color: context.appColors.buttonPrimaryBg,
                width: 0.5,
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('reset'),
              style: context.appTextStyles.labelLg.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appColors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () {
              final filters = <String, dynamic>{
                'lead_id': null,
                'page': '1',
                'per_page': '20',
                'organization_id': '2',
                'category_id': widget.isTojsokhtmontjTenant
                    ? selectedCategoryId
                    : selectedCategories.isNotEmpty
                        ? selectedCategories
                            .map((category) => category.id.toString())
                            .toList()
                        : [],
              };

              if (!widget.isTojsokhtmontjTenant) {
                filters['label_id'] =
                    selectedLabels.isNotEmpty ? selectedLabels : [];
              }

              if (!widget.isTojsokhtmontjTenant && isActive != null) {
                filters['is_active'] = isActive;
              }

              if (!widget.isTojsokhtmontjTenant &&
                  discountPercentController.text.isNotEmpty) {
                final discount =
                    double.tryParse(discountPercentController.text);
                if (discount != null) {
                  filters['discount_percent'] = discount;
                  if (kDebugMode) {
                    debugPrint(
                        'GoodsFilterScreen: Добавлен discount_percent: ${filters['discount_percent']}');
                  }
                }
              }

              if (kDebugMode) {
                debugPrint('GoodsFilterScreen: Применение фильтров: $filters');
                debugPrint(
                    'GoodsFilterScreen: onSelectedDataFilter существует: ${widget.onSelectedDataFilter != null}');
              }

              final hasCategory = widget.isTojsokhtmontjTenant
                  ? selectedCategoryId != null
                  : (filters['category_id'] as List).isNotEmpty;
              if (hasCategory ||
                  (!widget.isTojsokhtmontjTenant &&
                      (filters.containsKey('discount_percent') ||
                          (filters['label_id'] as List).isNotEmpty ||
                          filters.containsKey('is_active')))) {
                widget.onSelectedDataFilter?.call(filters);
              } else if (widget.isTojsokhtmontjTenant) {
                widget.onResetFilters?.call();
              } else {
                if (kDebugMode) {
                  debugPrint(
                      'GoodsFilterScreen: Фильтры пусты, ничего не отправлено');
                }
              }
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor:
                  context.appColors.buttonSecondaryBg.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(
                color: context.appColors.buttonPrimaryBg,
                width: 0.5,
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('apply'),
              style: context.appTextStyles.labelLg.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appColors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: BlocConsumer<GoodsBloc, GoodsState>(
        listener: (context, state) {
          if (state is GoodsDataLoaded &&
              widget.initialCategoryIds != null &&
              widget.initialCategoryIds!.isNotEmpty &&
              selectedCategories.isEmpty) {
            if (state.subCategories.isNotEmpty) {
              setState(() {
                selectedCategories = state.subCategories
                    .where((subCategory) => widget.initialCategoryIds!
                        .contains(subCategory.parent?.id))
                    .toList();
                if (kDebugMode) {
                  debugPrint(
                      'GoodsFilterScreen: Установлены начальные подкатегории: ${selectedCategories.map((c) => c.name).toList()}, category_ids: ${selectedCategories.map((c) => c.parent?.id).toList()}');
                }
              });
            } else {
              if (kDebugMode) {
                debugPrint(
                    'GoodsFilterScreen: Список подкатегорий пуст в listener');
              }
            }
          }
        },
        builder: (context, state) {
          List<SubCategoryAttributesData> subCategories = [];
          if (state is GoodsDataLoaded) {
            subCategories = state.subCategories;
            if (kDebugMode) {
              debugPrint(
                  'GoodsFilterScreen: Подкатегории из GoodsBloc: ${subCategories.length}');
              debugPrint(
                  'GoodsFilterScreen: ID подкатегорий: ${subCategories.map((c) => c.parent?.id).toList()}');
            }
          } else if (state is GoodsLoading) {
            if (kDebugMode) {
              debugPrint('GoodsFilterScreen: Состояние загрузки подкатегорий');
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is GoodsError) {
            if (kDebugMode) {
              debugPrint(
                  'GoodsFilterScreen: Ошибка загрузки подкатегорий: ${state.message}');
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!
                      .translate('error_loading_subcategories')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (kDebugMode) {
                        debugPrint(
                            'GoodsFilterScreen: Повторная попытка загрузки подкатегорий');
                      }
                      context.read<GoodsBloc>().add(FetchSubCategories());
                    },
                    child:
                        Text(AppLocalizations.of(context)!.translate('retry')),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        if (!widget.isTojsokhtmontjTenant) ...[
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: context.appColors.surfacePrimary,
                            shadowColor: context.appColors.shadowColor,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: SubCategoryMultiSelectWidget(
                                initialSubCategoryIds:
                                    widget.initialCategoryIds,
                                onSelectSubCategories: (categories) {
                                  setState(() {
                                    selectedCategories = categories;
                                    isCategoryValid = true;
                                    if (kDebugMode) {
                                      debugPrint(
                                          'GoodsFilterScreen: Выбраны подкатегории: ${categories.map((c) => c.name).toList()}, category_ids: ${categories.map((c) => c.parent?.id).toList()}');
                                    }
                                  });
                                },
                                isValid: isCategoryValid,
                              ),
                            ),
                          ),
                        ],
                        if (widget.isTojsokhtmontjTenant)
                          _buildTenantCategoryField(),
                        if (!widget.isTojsokhtmontjTenant) ...[
                          const SizedBox(height: 8),
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: context.appColors.surfacePrimary,
                            shadowColor: context.appColors.shadowColor,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: LabelsMultiSelectWidget(
                                selectedLabels: selectedLabels,
                                onSelectLabels: (labelIds) {
                                  // Изменено на labelIds
                                  setState(() {
                                    selectedLabels = labelIds;
                                    if (kDebugMode) {
                                      debugPrint(
                                          'GoodsFilterScreen: Выбраны label_id: $labelIds');
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: context.appColors.surfacePrimary,
                            shadowColor: context.appColors.shadowColor,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 12, right: 12, top: 4, bottom: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTextField(
                                    controller: discountPercentController,
                                    hintText: AppLocalizations.of(context)!
                                        .translate('enter_discount_percent'),
                                    label: AppLocalizations.of(context)!
                                        .translate('discount_percent'),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return null;
                                      }
                                      final number = double.tryParse(value);
                                      if (number == null || number < 0) {
                                        return AppLocalizations.of(context)!
                                            .translate('invalid_discount');
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      if (kDebugMode) {
                                        debugPrint(
                                            'GoodsFilterScreen: Введен процент скидки: $value');
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: context.appColors.surfacePrimary,
                            shadowColor: context.appColors.shadowColor,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .translate('active_status'),
                                    style:
                                        context.appTextStyles.bodyLg.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: context.appColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  StatusSelector(
                                      onStatusChanged: _handleStatusChanged),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
