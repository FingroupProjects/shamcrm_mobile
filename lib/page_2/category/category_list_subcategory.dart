import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SubCategoryDropdownWidget extends StatefulWidget {
  final String? subSelectedCategory;
  final Function(String) onSelectCategory;

  const SubCategoryDropdownWidget({
    super.key,
    required this.onSelectCategory,
    this.subSelectedCategory,
  });

  @override
  State<SubCategoryDropdownWidget> createState() =>
      _SubCategoryDropdownWidgetState();
}

class _SubCategoryDropdownWidgetState extends State<SubCategoryDropdownWidget> {
  final ApiService _apiService = ApiService();
  List<CategoryData> categories = [];
  CategoryData? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _findById(widget.subSelectedCategory, categories);
  }

  Future<List<CategoryData>> _searchCategories(String query) async {
    return _apiService.getCategory(search: query);
  }

  // Parent screen stores the selected id as a string.
  CategoryData? _findById(String? rawId, List<CategoryData> items) {
    final selectedId = int.tryParse(rawId ?? '');
    if (selectedId == null) return _selectedCategory;
    for (final category in items) {
      if (category.id == selectedId) return category;
    }
    return _selectedCategory;
  }

  List<CategoryData> _itemsWithSelected(
    List<CategoryData> items,
    CategoryData? selected,
  ) {
    if (selected == null) return items;
    if (items.any((item) => item.id == selected.id)) return items;
    return [selected, ...items];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return Center(
            child: CircularProgressIndicator(color: colors.buttonPrimaryBg),
          );
        } else if (state is CategoryLoaded) {
          categories = state.categories;
          final selected = _findById(widget.subSelectedCategory, categories);
          final items = _itemsWithSelected(categories, selected);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!
                    .translate('parent_category_details'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              CustomDropdown<CategoryData>.searchRequest(
                futureRequest: _searchCategories,
                futureRequestDelay: const Duration(milliseconds: 350),
                closeDropDownOnClearFilterSearch: true,
                items: items,
                searchHintText:
                    AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 300,
                enabled: true,
                excludeSelected: false,
                decoration: AppFieldStyle.dropdownDecoration(context),
                listItemBuilder: (context, item, isSelected, onItemSelect) {
                  return Text(
                    item.name,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                    ),
                  );
                },
                // Show the category name, not "Instance of CategoryData".
                headerBuilder: (context, selectedItem, enabled) {
                  return Text(
                    selectedItem.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: colors.textPrimary,
                    ),
                  );
                },
                hintBuilder: (context, hint, enabled) => Text(
                  AppLocalizations.of(context)!
                      .translate('select_parent_category'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: colors.textSecondary,
                  ),
                ),
                initialItem: selected != null &&
                        items.any((item) => item.id == selected.id)
                    ? items.firstWhere((item) => item.id == selected.id)
                    : null,
                onChanged: (selectedCategory) {
                  if (selectedCategory != null) {
                    widget.onSelectCategory(selectedCategory.id.toString());
                    setState(() {
                      _selectedCategory = selectedCategory;
                    });
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            ],
          );
        } else if (state is CategoryError) {
          return Center(child: Text(state.message));
        } else {
          return Center(
              child: Text(AppLocalizations.of(context)!
                  .translate('category_not_found')));
        }
      },
    );
  }
}
