import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

class SubCategoryMultiSelectWidget extends StatefulWidget {
  final List<int>? initialSubCategoryIds;
  final Function(List<SubCategoryAttributesData>) onSelectSubCategories;
  final bool isValid;
  final VoidCallback? onValidationChanged;

  const SubCategoryMultiSelectWidget({
    super.key,
    required this.onSelectSubCategories,
    this.initialSubCategoryIds,
    this.isValid = true,
    this.onValidationChanged,
  });

  @override
  State<SubCategoryMultiSelectWidget> createState() =>
      _SubCategoryMultiSelectWidgetState();
}

class _SubCategoryMultiSelectWidgetState
    extends State<SubCategoryMultiSelectWidget> {
  List<SubCategoryAttributesData> subCategoriesList = [];
  List<SubCategoryAttributesData> selectedSubCategories = [];
  bool allSelected = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      // print(
      //     'SubCategoryMultiSelectWidget: Инициализация, начальные ID: ${widget.initialSubCategoryIds}');
    }
  }

  // Метод для сброса выбранных подкатегорий
  void resetSubCategories() {
    setState(() {
      selectedSubCategories = [];
      allSelected = false;
      if (kDebugMode) {
        // print('SubCategoryMultiSelectWidget: Подкатегории сброшены');
      }
    });
    widget.onSelectSubCategories(selectedSubCategories);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<GoodsBloc, GoodsState>(
          builder: (context, state) {
            if (state is GoodsError) {
              if (kDebugMode) {
                // print(
                //     'SubCategoryMultiSelectWidget: Ошибка загрузки подкатегорий: ${state.message}');
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!
                      .translate('error_loading_subcategories')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (kDebugMode) {
                        // print(
                        //     'SubCategoryMultiSelectWidget: Повторная попытка загрузки подкатегорий');
                      }
                      context.read<GoodsBloc>().add(FetchSubCategories());
                    },
                    child:
                        Text(AppLocalizations.of(context)!.translate('retry')),
                  ),
                ],
              );
            }
            if (state is GoodsDataLoaded) {
              subCategoriesList = state.subCategories;
              if (kDebugMode) {
                // print(
                //     'SubCategoryMultiSelectWidget: Загружено подкатегорий: ${subCategoriesList.length}');
              }
              if (widget.initialSubCategoryIds != null &&
                  subCategoriesList.isNotEmpty &&
                  selectedSubCategories.isEmpty) {
                selectedSubCategories = subCategoriesList
                    .where((subCategory) => widget.initialSubCategoryIds!
                        .contains(subCategory.id))
                    .toList();
                allSelected =
                    selectedSubCategories.length == subCategoriesList.length;
                if (kDebugMode) {
                  // print(
                  //     'SubCategoryMultiSelectWidget: Инициализировано выбранных подкатегорий: ${selectedSubCategories.length}, allSelected: $allSelected');
                }
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('list_subcategories'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    child: CustomDropdown<SubCategoryAttributesData>.multiSelectSearch(
                      items: subCategoriesList,
                      initialItems: selectedSubCategories,
                      searchHintText:
                          AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
                      decoration: CustomDropdownDecoration(
                        closedFillColor: const Color(0xffF4F7FD),
                        expandedFillColor: Colors.white,
                        closedBorder: Border.all(
                          color: widget.isValid
                              ? const Color(0xffF4F7FD)
                              : Colors.red,
                          width: 1,
                        ),
                        closedBorderRadius: BorderRadius.circular(12),
                        expandedBorder: Border.all(
                          color: widget.isValid
                              ? const Color(0xffF4F7FD)
                              : Colors.red,
                          width: 1,
                        ),
                        expandedBorderRadius: BorderRadius.circular(12),
                      ),
                      listItemBuilder: (context, item, isSelected, onItemSelect) {
                        // Добавляем "Выделить всех" как первый элемент
                        if (subCategoriesList.indexOf(item) == 0) {
                          return Column(
                            children: [
                              ListTile(
                                minTileHeight: 1,
                                minVerticalPadding: 2,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                dense: true,
                                title: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: const Color(0xff1E2E52),
                                            width: 1),
                                        color: allSelected
                                            ? const Color(0xff1E2E52)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: allSelected
                                          ? const Icon(Icons.check,
                                              color: Colors.white, size: 16)
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .translate('select_all'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Gilroy',
                                          color: Color(0xff1E2E52),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    allSelected = !allSelected;
                                    if (allSelected) {
                                      selectedSubCategories =
                                          List.from(subCategoriesList);
                                    } else {
                                      selectedSubCategories = [];
                                    }
                                    widget
                                        .onSelectSubCategories(selectedSubCategories);
                                    if (kDebugMode) {
                                      // print(
                                      //     'SubCategoryMultiSelectWidget: Выбрано всех: $allSelected, подкатегорий: ${selectedSubCategories.length}');
                                    }
                                  });
                                },
                              ),
                              const Divider(
                                  height: 20,
                                  color: Color(0xffF4F7FD)), // Разделитель
                              _buildSubCategoryTile(item, isSelected, onItemSelect),
                            ],
                          );
                        }
                        // Обычные элементы списка
                        return _buildSubCategoryTile(item, isSelected, onItemSelect);
                      },
                      headerListBuilder: (context, hint, enabled) {
                        final selectedCount = selectedSubCategories.length;
                        return Text(
                          selectedCount == 0
                              ? AppLocalizations.of(context)!
                                  .translate('list_select_subcategories')
                              : '${AppLocalizations.of(context)!.translate('selected_subcategories')} $selectedCount',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                        AppLocalizations.of(context)!
                            .translate('list_select_subcategories'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      onListChanged: (values) {
                        setState(() {
                          selectedSubCategories = values;
                          allSelected = values.length == subCategoriesList.length;
                          if (values.isEmpty) {
                            selectedSubCategories = [];
                            allSelected = false;
                          }
                          if (kDebugMode) {
                            // print(
                            //     'SubCategoryMultiSelectWidget: Изменён список подкатегорий: ${selectedSubCategories.length}, allSelected: $allSelected');
                          }
                        });
                        widget.onSelectSubCategories(selectedSubCategories);
                      },
                    ),
                  ),
                  if (!widget.isValid)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '    ${AppLocalizations.of(context)!.translate('field_required')}',
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                ],
              );
            }
            if (state is GoodsLoading) {
              if (kDebugMode) {
                // print('SubCategoryMultiSelectWidget: Загрузка подкатегорий');
              }
              return const Center(child: CircularProgressIndicator());
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _buildSubCategoryTile(SubCategoryAttributesData item, bool isSelected,
      VoidCallback onItemSelect) {
    return ListTile(
      minTileHeight: 1,
      minVerticalPadding: 2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
      title: Padding(
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xff1E2E52), width: 1),
                color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        onItemSelect();
        FocusScope.of(context).unfocus();
        if (kDebugMode) {
          // print(
          //     'SubCategoryMultiSelectWidget: Выбрана подкатегория: ${item.name}, ID: ${item.id}');
        }
      },
    );
  }
}