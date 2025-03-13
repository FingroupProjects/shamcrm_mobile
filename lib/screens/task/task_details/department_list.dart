import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/department/department_bloc.dart';
import 'package:crm_task_manager/bloc/department/department_event.dart';
import 'package:crm_task_manager/bloc/department/department_state.dart';
import 'package:crm_task_manager/models/department.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DepartmentWidget extends StatefulWidget {
  final String? selectedDepartment;
  final ValueChanged<String?> onChanged;

  DepartmentWidget({required this.selectedDepartment, required this.onChanged});

  @override
  _DepartmentWidgetState createState() => _DepartmentWidgetState();
}

class _DepartmentWidgetState extends State<DepartmentWidget> {
  Department? selectedDepartmentData;

  @override
  void initState() {
    super.initState();
    context.read<DepartmentBloc>().add(FetchDepartment());
  }

  // Метод для вычисления высоты overlay в зависимости от количества элементов
  double _calculateOverlayHeight(List<Department> departments) {
    const double itemHeight = 80.0; // Примерная высота одного элемента (можно подстроить)
    const int maxItemsWithoutScroll = 5; // Максимум элементов без скролла
    const double maxHeight = 400.0; // Максимальная высота с прокруткой (5 элементов)

    if (departments.length <= maxItemsWithoutScroll) {
      // Если элементов меньше или равно 5, высота подстраивается под количество
      return departments.length * itemHeight;
    } else {
      // Если больше 5, фиксированная высота с прокруткой
      return maxHeight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DepartmentBloc, DepartmentState>(
      listener: (context, state) {
        if (state is DepartmentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.red,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      child: BlocBuilder<DepartmentBloc, DepartmentState>(
        builder: (context, state) {
          List<Department> departmentList = state is DepartmentLoaded ? state.departments : [];

          if (widget.selectedDepartment != null && departmentList.isNotEmpty) {
            try {
              selectedDepartmentData = departmentList.firstWhere(
                (department) => department.id.toString() == widget.selectedDepartment,
              );
            } catch (e) {
              selectedDepartmentData = null;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('department'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                child: CustomDropdown<Department>.search(
                  closeDropDownOnClearFilterSearch: true,
                  items: departmentList,
                  searchHintText: AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: _calculateOverlayHeight(departmentList), // Динамическая высота
                  enabled: true,
                  decoration: CustomDropdownDecoration(
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
                    return SizedBox(
                      height: 48.0, // Фиксированная высота элемента (должна совпадать с itemHeight)
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.name,
                          style: TextStyle(
                            color: Color(0xff1E2E52),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    if (state is DepartmentLoading) {
                      return Text(
                        AppLocalizations.of(context)!.translate('select_department'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                      );
                    }
                    return Text(
                      selectedItem?.name ?? AppLocalizations.of(context)!.translate('select_department'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_department'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  excludeSelected: false,
                  initialItem: (state is DepartmentLoaded && departmentList.contains(selectedDepartmentData))
                      ? selectedDepartmentData
                      : null,
                  onChanged: (value) {
                    if (value != null) {
                      widget.onChanged(value.id.toString());
                      setState(() {
                        selectedDepartmentData = value;
                      });
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}