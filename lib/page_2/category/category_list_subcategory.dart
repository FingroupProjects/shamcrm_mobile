import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_state.dart';
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
  State<SubCategoryDropdownWidget> createState() => _SubCategoryDropdownWidgetState();
}

class _SubCategoryDropdownWidgetState extends State<SubCategoryDropdownWidget> {
  List<String> subCategoryNames = [];
  Map<String, int> nameToIdMap = {}; 
  String? subSelectedCategoryName;   

  @override
  void initState() {
    super.initState();
    subSelectedCategoryName = widget.subSelectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
        } else if (state is CategoryLoaded) {
          // Заполняем мапы названий и ID
          subCategoryNames = state.categories.map((category) => category.name).toList();
          nameToIdMap = {
            for (var category in state.categories) 
              category.name: category.id ?? 0
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('category_details'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 4),
              CustomDropdown<String>.search(
                closeDropDownOnClearFilterSearch: true,
                items: subCategoryNames, 
                searchHintText: AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 300,
                enabled: true,
                decoration: CustomDropdownDecoration(
                  closedFillColor: Color(0xffF4F7FD),
                  expandedFillColor: Colors.white,
                  closedBorder: Border.all(color: Color(0xffF4F7FD), width: 1),
                  closedBorderRadius: BorderRadius.circular(12),
                  expandedBorder: Border.all(color: Color(0xffF4F7FD), width: 1),
                  expandedBorderRadius: BorderRadius.circular(12),
                ),
                listItemBuilder: (context, item, isSelected, onItemSelect) {
                  return Text(
                    item,
                    style: TextStyle(
                      color: Color(0xff1E2E52),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                    ),
                  );
                },
                hintBuilder: (context, hint, enabled) => Text(
                  AppLocalizations.of(context)!.translate('select_category'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                initialItem: subSelectedCategoryName,
                onChanged: (selectedName) {
                  if (selectedName != null) {
                    final selectedId = nameToIdMap[selectedName]!; 
                    widget.onSelectCategory(selectedId.toString()); 
                    setState(() {
                      subSelectedCategoryName = selectedName; 
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
          return Center(child: Text('category_not_found'));
        }
      },
    );
  }
}