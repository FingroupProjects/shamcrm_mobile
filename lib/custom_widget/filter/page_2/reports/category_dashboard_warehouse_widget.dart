import 'package:animated_custom_dropdown/custom_dropdown.dart';

import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/category_dashboard_warehouse/category_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/category_dashboard_warehouse/category_dashboard_warehouse_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/category_dashboard_warehouse/category_dashboard_warehouse_state.dart';
import 'package:crm_task_manager/models/page_2/category_dashboard_warehouse_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryDashboardWarehouseWidget extends StatefulWidget {
  final String? selectedCategoryDashboardWarehouse;
  final ValueChanged<String?> onChanged;

  const CategoryDashboardWarehouseWidget({
    required this.selectedCategoryDashboardWarehouse,
    required this.onChanged,
  });

  @override
  State<CategoryDashboardWarehouseWidget> createState() => _CategoryDashboardWarehouseWidgetState();
}

class _CategoryDashboardWarehouseWidgetState extends State<CategoryDashboardWarehouseWidget> {
  CategoryDashboardWarehouse? selectedCategoryData;

  @override
  void initState() {
    super.initState();
    context.read<CategoryDashboardWarehouseBloc>().add(FetchCategoryDashboardWarehouse());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryDashboardWarehouseBloc, CategoryDashboardWarehouseState>(
      listener: (context, state) {
        if (state is CategoryDashboardWarehouseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),  // Адаптировать ключ, если message не локализован
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.red,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: BlocBuilder<CategoryDashboardWarehouseBloc, CategoryDashboardWarehouseState>(
        builder: (context, state) {
          // Обновляем данные при успешной загрузке
          if (state is CategoryDashboardWarehouseLoaded) {
            final List<CategoryDashboardWarehouse> categoriesList = state.categoryDashboardWarehouse;
            
            if (widget.selectedCategoryDashboardWarehouse != null && categoriesList.isNotEmpty) {
              try {
                selectedCategoryData = categoriesList.firstWhere(
                  (category) => category.id.toString() == widget.selectedCategoryDashboardWarehouse,
                );
              } catch (e) {
                selectedCategoryData = null;
              }
            }
          }

          // Всегда отображаем поле
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('category'),  // Ключ для "Категория"
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 4),
              CustomDropdown<CategoryDashboardWarehouse>.search(
                closeDropDownOnClearFilterSearch: true,
                items: state is CategoryDashboardWarehouseLoaded ? state.categoryDashboardWarehouse : [],
                searchHintText: AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 400,
                enabled: true,  // Всегда enabled
                decoration:  CustomDropdownDecoration(
                  closedFillColor: Color(0xffF4F7FD),
                  expandedFillColor: Colors.white,
                  closedBorder: Border.all(
                    color: Color(0xffF4F7FD),
                    width: 1,
                  ),
                  closedBorderRadius: BorderRadius.circular(12),
                  expandedBorder: Border.all(
                    color: Color(0xffF4F7FD),
                    width: 1,
                  ),
                  expandedBorderRadius: BorderRadius.circular(12),
                ),
                listItemBuilder: (context, item, isSelected, onItemSelect) {
                  return Text(
                    item.name,
                    style: const TextStyle(
                      color: Color(0xff1E2E52),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
                headerBuilder: (context, selectedItem, enabled) {
                  if (state is CategoryDashboardWarehouseLoading) {
                    return Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('select_category'),  // Ключ для "Выберите категорию"
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ],
                    );
                  }
                  return Text(
                    selectedItem.name ?? AppLocalizations.of(context)!.translate('select_category'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  );
                },
                hintBuilder: (context, hint, enabled) => Text(
                  AppLocalizations.of(context)!.translate('select_category'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                excludeSelected: false,
                initialItem: (state is CategoryDashboardWarehouseLoaded && state.categoryDashboardWarehouse.contains(selectedCategoryData))
                    ? selectedCategoryData
                    : null,
                onChanged: (value) {
                  if (value != null) {
                    widget.onChanged(value.id.toString());
                    setState(() {
                      selectedCategoryData = value;
                    });
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}