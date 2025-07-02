import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/goods/SubCategoryMultiSelectWidget.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/goods/status.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/label_multiselect_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

class GoodsFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final List<int>? initialCategoryIds;
  final double? initialDiscountPercent;
  final List<String>? initialLabels;
  final bool? initialIsActive;

  const GoodsFilterScreen({
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialCategoryIds,
    this.initialDiscountPercent,
    this.initialLabels,
    this.initialIsActive,
  }) : super(key: key);

  @override
  _GoodsFilterScreenState createState() => _GoodsFilterScreenState();
}

class _GoodsFilterScreenState extends State<GoodsFilterScreen> {
  final TextEditingController discountPercentController = TextEditingController();
  List<SubCategoryAttributesData> selectedCategories = [];
  List<String> selectedLabels = [];
  bool isCategoryValid = true;
  bool? isActive; // Может быть null, если оба флага включены

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('GoodsFilterScreen: Инициализация экрана фильтров');
      print(
          'GoodsFilterScreen: Начальные значения - category_ids: ${widget.initialCategoryIds}, '
          'discount_percent: ${widget.initialDiscountPercent}, labels: ${widget.initialLabels}, '
          'is_active: ${widget.initialIsActive}');
    }

    if (widget.initialDiscountPercent != null &&
        widget.initialDiscountPercent! >= 0) {
      discountPercentController.text =
          widget.initialDiscountPercent!.toStringAsFixed(2);
      if (kDebugMode) {
        print(
            'GoodsFilterScreen: Установлен начальный процент скидки: ${discountPercentController.text}');
      }
    }

    if (widget.initialLabels != null) {
      selectedLabels = List.from(widget.initialLabels!);
      if (kDebugMode) {
        print('GoodsFilterScreen: Установлены начальные метки: $selectedLabels');
      }
    }

    if (widget.initialIsActive != null) {
      isActive = widget.initialIsActive;
      if (kDebugMode) {
        print('GoodsFilterScreen: Установлено начальное значение is_active: $isActive');
      }
    }

    context.read<GoodsBloc>().add(FetchSubCategories());
  }

  @override
  void dispose() {
    discountPercentController.dispose();
    if (kDebugMode) {
      print('GoodsFilterScreen: Очистка ресурсов');
    }
    super.dispose();
  }

  void _handleStatusChanged(bool? status) {
    setState(() {
      isActive = status;
      if (kDebugMode) {
        print('GoodsFilterScreen: Изменено значение is_active: $isActive');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FD),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('filter'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
            fontFamily: 'Gilroy',
          ),
        ),
        backgroundColor: Colors.white,
        forceMaterialTransparency: true,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (kDebugMode) {
                  print('GoodsFilterScreen: Сброс фильтров');
                }
                widget.onResetFilters?.call();
                selectedCategories = [];
                selectedLabels = [];
                discountPercentController.clear();
                isCategoryValid = true;
                isActive = null; // Сбрасываем isActive до null
              });
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('reset'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
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
                'category_id': selectedCategories.isNotEmpty
                    ? selectedCategories
                        .map((category) => category.id.toString())
                        .toList()
                    : [],
                'labels': selectedLabels.isNotEmpty ? selectedLabels : [],
              };

              // Добавляем is_active только если он не null
              if (isActive != null) {
                filters['is_active'] = isActive;
              }

              if (discountPercentController.text.isNotEmpty) {
                final discount =
                    double.tryParse(discountPercentController.text);
                if (discount != null) {
                  filters['discount_percent'] = discount;
                  if (kDebugMode) {
                    print(
                        'GoodsFilterScreen: Добавлен discount_percent: ${filters['discount_percent']}');
                  }
                }
              }

              if (kDebugMode) {
                print('GoodsFilterScreen: Применение фильтров: $filters');
                print(
                    'GoodsFilterScreen: onSelectedDataFilter существует: ${widget.onSelectedDataFilter != null}');
              }

              if (filters['category_id'].isNotEmpty ||
                  filters.containsKey('discount_percent') ||
                  filters['labels'].isNotEmpty ||
                  filters.containsKey('is_active')) {
                widget.onSelectedDataFilter?.call(filters);
              } else {
                if (kDebugMode) {
                  print(
                      'GoodsFilterScreen: Фильтры пусты, ничего не отправлено');
                }
              }
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('apply'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
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
                  print(
                      'GoodsFilterScreen: Установлены начальные подкатегории: ${selectedCategories.map((c) => c.name).toList()}, category_ids: ${selectedCategories.map((c) => c.parent?.id).toList()}');
                }
              });
            } else {
              if (kDebugMode) {
                print('GoodsFilterScreen: Список подкатегорий пуст в listener');
              }
            }
          }
        },
        builder: (context, state) {
          List<SubCategoryAttributesData> subCategories = [];
          if (state is GoodsDataLoaded) {
            subCategories = state.subCategories;
            if (kDebugMode) {
              print(
                  'GoodsFilterScreen: Подкатегории из GoodsBloc: ${subCategories.length}');
              print(
                  'GoodsFilterScreen: ID подкатегорий: ${subCategories.map((c) => c.parent?.id).toList()}');
            }
          } else if (state is GoodsLoading) {
            if (kDebugMode) {
              print('GoodsFilterScreen: Состояние загрузки подкатегорий');
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is GoodsError) {
            if (kDebugMode) {
              print(
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
                        print(
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
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: SubCategoryMultiSelectWidget(
                              initialSubCategoryIds: widget.initialCategoryIds,
                              onSelectSubCategories: (categories) {
                                setState(() {
                                  selectedCategories = categories;
                                  isCategoryValid = true;
                                  if (kDebugMode) {
                                    print(
                                        'GoodsFilterScreen: Выбраны подкатегории: ${categories.map((c) => c.name).toList()}, category_ids: ${categories.map((c) => c.parent?.id).toList()}');
                                  }
                                });
                              },
                              isValid: isCategoryValid,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: LabelMultiSelectWidget(
                              selectedLabels: selectedLabels,
                              onSelectLabels: (labels) {
                                setState(() {
                                  selectedLabels = labels;
                                  if (kDebugMode) {
                                    print(
                                        'GoodsFilterScreen: Выбраны метки: $labels');
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
                          color: Colors.white,
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
                                  keyboardType: TextInputType.number,
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
                                      print(
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
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!
                                      .translate('active_status'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Gilroy',
                                    color: Color(0xff1E2E52),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                StatusSelector(onStatusChanged: _handleStatusChanged),
                              ],
                            ),
                          ),
                        ),
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