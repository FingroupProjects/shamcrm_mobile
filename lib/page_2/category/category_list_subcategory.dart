import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
  List<String> subCategoryNames = [];
  Map<String, int> nameToIdMap = {};
  String? subSelectedCategoryName;
  List<CategoryData> categories = [];

  @override
  void initState() {
    super.initState();
    subSelectedCategoryName = widget.subSelectedCategory;
  }

  Future<List<CategoryData>> _searchCategories(String query) async {
    return _apiService.getCategory(search: query);
  }

  CategoryData? _getInitialCategory() {
    for (final category in categories) {
      if (category.name == subSelectedCategoryName) {
        return category;
      }
    }
    return null;
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
          subCategoryNames =
              state.categories.map((category) => category.name).toList();
          nameToIdMap = {
            for (var category in state.categories) category.name: category.id
          };

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
              const SizedBox(height: 4),
              CustomDropdown<CategoryData>.searchRequest(
                futureRequest: _searchCategories,
                futureRequestDelay: const Duration(milliseconds: 350),
                closeDropDownOnClearFilterSearch: true,
                items: categories,
                searchHintText:
                    AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 300,
                enabled: true,
                decoration: CustomDropdownDecoration(
                  closedFillColor: colors.fieldBg,
                  expandedFillColor: colors.surfacePrimary,
                  closedBorder: Border.all(color: colors.borderSubtle, width: 1),
                  closedBorderRadius: BorderRadius.circular(12),
                  expandedBorder:
                      Border.all(color: colors.borderSubtle, width: 1),
                  expandedBorderRadius: BorderRadius.circular(12),
                ),
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
                hintBuilder: (context, hint, enabled) => Text(
                  AppLocalizations.of(context)!
                      .translate('select_parent_category'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: colors.textPrimary,
                  ),
                ),
                initialItem: _getInitialCategory(),
                onChanged: (selectedCategory) {
                  if (selectedCategory != null) {
                    final selectedId = selectedCategory.id;
                    widget.onSelectCategory(selectedId.toString());
                    setState(() {
                      subSelectedCategoryName = selectedCategory.name;
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
