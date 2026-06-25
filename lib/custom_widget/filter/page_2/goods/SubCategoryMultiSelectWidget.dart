import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  }

  void resetSubCategories() {
    setState(() {
      selectedSubCategories = [];
      allSelected = false;
    });
    widget.onSelectSubCategories(selectedSubCategories);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        BlocBuilder<GoodsBloc, GoodsState>(
          builder: (context, state) {
            if (state is GoodsError) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!
                      .translate('error_loading_subcategories')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
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
              if (widget.initialSubCategoryIds != null &&
                  subCategoriesList.isNotEmpty &&
                  selectedSubCategories.isEmpty) {
                selectedSubCategories = subCategoriesList
                    .where((subCategory) => widget.initialSubCategoryIds!
                        .contains(subCategory.id))
                    .toList();
                allSelected =
                    selectedSubCategories.length == subCategoriesList.length;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('list_subcategories'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: colors.textPrimary,
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
                        closedFillColor: colors.backgroundSecondary,
                        expandedFillColor: colors.surfaceElevated,
                        closedBorder: Border.all(
                          color: widget.isValid
                              ? colors.borderSubtle
                              : colors.error,
                          width: 1,
                        ),
                        closedBorderRadius: BorderRadius.circular(12),
                        expandedBorder: Border.all(
                          color: widget.isValid
                              ? colors.borderSubtle
                              : colors.error,
                          width: 1,
                        ),
                        expandedBorderRadius: BorderRadius.circular(12),
                        listItemDecoration: ListItemDecoration(
                          selectedColor: colors.buttonPrimaryBg.withValues(alpha: 0.15),
                        ),
                      ),
                      listItemBuilder: (context, item, isSelected, onItemSelect) {
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
                                            color: colors.borderPrimary,
                                            width: 1),
                                        color: allSelected
                                            ? colors.buttonPrimaryBg
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: allSelected
                                          ? Icon(Icons.check,
                                              color: colors.textInverse, size: 16)
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .translate('select_all'),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Gilroy',
                                          color: colors.textPrimary,
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
                                  });
                                },
                              ),
                              Divider(
                                  height: 20,
                                  color: colors.borderSubtle),
                              _buildSubCategoryTile(item, isSelected, onItemSelect, colors),
                            ],
                          );
                        }
                        return _buildSubCategoryTile(item, isSelected, onItemSelect, colors);
                      },
                      headerListBuilder: (context, hint, enabled) {
                        final selectedCount = selectedSubCategories.length;
                        return Text(
                          selectedCount == 0
                              ? AppLocalizations.of(context)!
                                  .translate('list_select_subcategories')
                              : '${AppLocalizations.of(context)!.translate('selected_subcategories')} $selectedCount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: colors.textPrimary,
                          ),
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                        AppLocalizations.of(context)!
                            .translate('list_select_subcategories'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: colors.textPrimary,
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
                        style: TextStyle(
                            fontSize: 14,
                            color: colors.error,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                ],
              );
            }
            if (state is GoodsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _buildSubCategoryTile(SubCategoryAttributesData item, bool isSelected,
      VoidCallback onItemSelect, AppThemeColors colors) {
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
                border: Border.all(color: colors.borderPrimary, width: 1),
                color: isSelected ? colors.buttonPrimaryBg : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: colors.textInverse, size: 16)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
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
      },
    );
  }
}
