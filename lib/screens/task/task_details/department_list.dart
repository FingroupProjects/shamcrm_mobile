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
          if (state is DepartmentLoaded) {
            List<Department> departmentList = state.departments;

            if (widget.selectedDepartment != null && departmentList.isNotEmpty) {
              try {
                selectedDepartmentData = departmentList.firstWhere(
                  (department) => department.id.toString() == widget.selectedDepartment,
                );
              } catch (e) {
                selectedDepartmentData = null;
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('Отделение'),
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
                  items: state is DepartmentLoaded ? state.departments : [],
                  searchHintText: AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
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
                    return Text(
                      item.name,
                      style: TextStyle(
                        color: Color(0xff1E2E52),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                      ),
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    if (state is DepartmentLoading) {
                      return Text(
                        AppLocalizations.of(context)!.translate('Выберите отделение'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                      );
                    }
                    return Text(
                      selectedItem.name ?? AppLocalizations.of(context)!.translate('Выберите отделение'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('Выберите отделение'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  excludeSelected: false,
                  initialItem: (state is DepartmentLoaded && state.departments.contains(selectedDepartmentData))
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