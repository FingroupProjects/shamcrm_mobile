import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/page_2/goods/category_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

class GoodsFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final int? initialCategoryId;
  final double? initialDiscountPercent;

  GoodsFilterScreen({
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialCategoryId,
    this.initialDiscountPercent,
  }) : super(key: key);

  @override
  _GoodsFilterScreenState createState() => _GoodsFilterScreenState();
}

class _GoodsFilterScreenState extends State<GoodsFilterScreen> {
  final TextEditingController discountPercentController = TextEditingController();
  SubCategoryAttributesData? selectedCategory;
  bool isCategoryValid = true;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('GoodsFilterScreen: Инициализация экрана фильтров');
      print('GoodsFilterScreen: Начальные значения - category_id: ${widget.initialCategoryId}, discount_percent: ${widget.initialDiscountPercent}');
    }

    if (widget.initialDiscountPercent != null && widget.initialDiscountPercent! >= 0) {
      discountPercentController.text = widget.initialDiscountPercent!.toStringAsFixed(2);
      if (kDebugMode) {
        print('GoodsFilterScreen: Установлен начальный процент скидки: ${discountPercentController.text}');
      }
    } else {
      if (kDebugMode) {
        print('GoodsFilterScreen: Начальный процент скидки не установлен (null или некорректное значение)');
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
                selectedCategory = null;
                discountPercentController.clear();
                isCategoryValid = true;
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
              final filters = <String, dynamic>{};
              if (selectedCategory != null) {
                filters['category_id'] = selectedCategory!.parent.id;
                if (kDebugMode) {
                  print('GoodsFilterScreen: Добавлен category_id: ${selectedCategory!.parent.id}');
                }
              }
              if (discountPercentController.text.isNotEmpty) {
                filters['discount_percent'] = double.tryParse(discountPercentController.text);
                if (kDebugMode) {
                  print('GoodsFilterScreen: Добавлен discount_percent: ${filters['discount_percent']}');
                }
              }

              if (kDebugMode) {
                print('GoodsFilterScreen: Применение фильтров: $filters');
                print('GoodsFilterScreen: onSelectedDataFilter существует: ${widget.onSelectedDataFilter != null}');
              }

              if (filters.isNotEmpty) {
                widget.onSelectedDataFilter?.call(filters);
              } else {
                if (kDebugMode) {
                  print('GoodsFilterScreen: Фильтры пусты, ничего не отправлено');
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
          if (state is GoodsDataLoaded && widget.initialCategoryId != null && selectedCategory == null) {
            if (state.subCategories.isNotEmpty) {
              setState(() {
                selectedCategory = state.subCategories.firstWhere(
                  (subCategory) => subCategory.parent.id == widget.initialCategoryId,
                  orElse: () {
                    if (kDebugMode) {
                      print('GoodsFilterScreen: Подкатегория с category_id ${widget.initialCategoryId} не найдена, выбор не установлен');
                    }
                    return state.subCategories.first;
                  },
                );
                if (kDebugMode) {
                  print('GoodsFilterScreen: Установлена начальная подкатегория: ${selectedCategory?.name}, category_id: ${selectedCategory?.parent.id}');
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
              print('GoodsFilterScreen: Подкатегории из GoodsBloc: ${subCategories.length}');
              print('GoodsFilterScreen: ID подкатегорий: ${subCategories.map((c) => c.parent.id).toList()}');
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
              print('GoodsFilterScreen: Ошибка загрузки подкатегорий: ${state.message}');
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.translate('error_loading_subcategories')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (kDebugMode) {
                        print('GoodsFilterScreen: Повторная попытка загрузки подкатегорий');
                      }
                      context.read<GoodsBloc>().add(FetchSubCategories());
                    },
                    child: Text(AppLocalizations.of(context)!.translate('retry')),
                  ),
                ],
              ),
            );
          }

          if (kDebugMode) {
            print('GoodsFilterScreen: Отрисовка с подкатегориями: ${subCategories.length}');
          }

          return Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: CategoryDropdownWidget(
                              selectedCategory: selectedCategory?.name,
                              onSelectCategory: (category) {
                                setState(() {
                                  selectedCategory = category;
                                  isCategoryValid = true;
                                  if (kDebugMode) {
                                    print('GoodsFilterScreen: Выбрана подкатегория: ${category?.name}, category_id: ${category?.parent.id}');
                                  }
                                });
                              },
                              subCategories: subCategories,
                              isValid: isCategoryValid,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomTextField(
                                  controller: discountPercentController,
                                  hintText: AppLocalizations.of(context)!.translate('enter_discount_percent'),
                                  label: AppLocalizations.of(context)!.translate('discount_percent'),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return AppLocalizations.of(context)!.translate('field_required');
                                    }
                                    final number = double.tryParse(value);
                                    if (number == null || number < 0) {
                                      return AppLocalizations.of(context)!.translate('invalid_discount');
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    if (kDebugMode) {
                                      print('GoodsFilterScreen: Введен процент скидки: $value');
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
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