import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/page_2/goods/category_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

class GoodsFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;

  GoodsFilterScreen({
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters,
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
    }
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
        elevation: 0,
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
      body: BlocBuilder<GoodsBloc, GoodsState>(
        builder: (context, state) {
          List<SubCategoryAttributesData> subCategories = [];
          if (state is GoodsDataLoaded) {
            subCategories = state.subCategories;
            if (kDebugMode) {
              print('GoodsFilterScreen: Подкатегории из GoodsBloc: ${subCategories.length}');
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
                        const SizedBox(height: 8),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: TextField(
                              controller: discountPercentController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.translate('discount_percent'),
                                hintText: AppLocalizations.of(context)!.translate('enter_discount_percent'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xffE8ECF4)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xff1E2E52)),
                                ),
                                labelStyle: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: Color(0xff99A4BA),
                                  fontSize: 14,
                                ),
                              ),
                              onChanged: (value) {
                                if (kDebugMode) {
                                  print('GoodsFilterScreen: Введен процент скидки: $value');
                                }
                              },
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