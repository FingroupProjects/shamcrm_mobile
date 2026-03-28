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

  DepartmentWidget({super.key, required this.selectedDepartment, required this.onChanged});

  @override
  _DepartmentWidgetState createState() => _DepartmentWidgetState();
}

class _DepartmentWidgetState extends State<DepartmentWidget> {
  Department? selectedDepartmentData;
  List<Department> departmentList = [];

  final TextStyle departmentTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    context.read<DepartmentBloc>().add(FetchDepartment());
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.selectedDepartment,
      validator: (value) {
        if (selectedDepartmentData == null) {
          return AppLocalizations.of(context)!.translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<String> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('department'),
              style: departmentTextStyle.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError ? Colors.red : const Color(0xFFE5E7EB),
                ),
              ),
              child: BlocBuilder<DepartmentBloc, DepartmentState>(
                builder: (context, state) {
                  if (state is DepartmentLoaded) {
                    departmentList = state.departments;
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

                  return CustomDropdown<Department>.search(
                    closeDropDownOnClearFilterSearch: true,
                    items: departmentList,
                    searchHintText: AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    enabled: true,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: const Color(0xffF4F7FD),
                      expandedFillColor: Colors.white,
                      closedBorder: Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: GestureDetector(
                          onTap: onItemSelect,
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xff1E2E52),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: departmentTextStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    headerBuilder: (context, selectedItem, enabled) {
                      return Text(
                        selectedItem?.name ?? AppLocalizations.of(context)!.translate('select_department'),
                        style: departmentTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!.translate('select_department'),
                      style: departmentTextStyle.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    excludeSelected: false,
                    initialItem: selectedDepartmentData,
                    onChanged: (value) {
                      widget.onChanged(value?.id.toString());
                      setState(() {
                        selectedDepartmentData = value;
                      });
                      field.didChange(value?.id.toString());
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 0),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}