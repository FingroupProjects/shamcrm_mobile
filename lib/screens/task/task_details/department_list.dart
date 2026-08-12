import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/department/department_bloc.dart';
import 'package:crm_task_manager/bloc/department/department_event.dart';
import 'package:crm_task_manager/bloc/department/department_state.dart';
import 'package:crm_task_manager/models/user/department.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DepartmentWidget extends StatefulWidget {
  final String? selectedDepartment;
  final ValueChanged<String?> onChanged;

  DepartmentWidget(
      {super.key, required this.selectedDepartment, required this.onChanged});

  @override
  _DepartmentWidgetState createState() => _DepartmentWidgetState();
}

class _DepartmentWidgetState extends State<DepartmentWidget> {
  Department? selectedDepartmentData;
  List<Department> departmentList = [];

  @override
  void initState() {
    super.initState();
    context.read<DepartmentBloc>().add(FetchDepartment());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final departmentTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'Gilroy',
      color: colors.textPrimary,
    );
    return FormField<String>(
      initialValue: widget.selectedDepartment,
      validator: (value) {
        if (selectedDepartmentData == null) {
          return AppLocalizations.of(context)!
              .translate('field_required_project');
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
                color: colors.fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError ? colors.error : colors.fieldBorder,
                ),
              ),
              child: BlocBuilder<DepartmentBloc, DepartmentState>(
                builder: (context, state) {
                  if (state is DepartmentLoaded) {
                    departmentList = state.departments;
                    if (widget.selectedDepartment != null &&
                        departmentList.isNotEmpty) {
                      try {
                        selectedDepartmentData = departmentList.firstWhere(
                          (department) =>
                              department.id.toString() ==
                              widget.selectedDepartment,
                        );
                      } catch (e) {
                        selectedDepartmentData = null;
                      }
                    }
                  }

                  return CustomDropdown<Department>.search(
                    closeDropDownOnClearFilterSearch: true,
                    items: departmentList,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    enabled: true,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: colors.fieldBg,
                      expandedFillColor: colors.surfacePrimary,
                      closedBorder: Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: colors.fieldBorder,
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                      hintStyle: departmentTextStyle.copyWith(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                      headerStyle: departmentTextStyle,
                      listItemStyle: departmentTextStyle,
                      listItemDecoration: ListItemDecoration(
                        selectedColor:
                            colors.buttonPrimaryBg.withValues(alpha: 0.14),
                        highlightColor:
                            colors.buttonPrimaryBg.withValues(alpha: 0.08),
                        splashColor: Colors.transparent,
                      ),
                      searchFieldDecoration: SearchFieldDecoration(
                        fillColor: colors.fieldBg,
                        textStyle: departmentTextStyle.copyWith(fontSize: 14),
                        hintStyle: departmentTextStyle.copyWith(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                        prefixIcon:
                            Icon(Icons.search, color: colors.iconSecondary),
                        suffixIcon: (onClear) => IconButton(
                          onPressed: onClear,
                          icon: Icon(Icons.close_rounded,
                              color: colors.iconSecondary),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.fieldBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.buttonPrimaryBg),
                        ),
                      ),
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: GestureDetector(
                          onTap: onItemSelect,
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: colors.buttonPrimaryBg,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  color: isSelected
                                      ? colors.buttonPrimaryBg
                                      : Colors.transparent,
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
                        selectedItem?.name ??
                            AppLocalizations.of(context)!
                                .translate('select_department'),
                        style: departmentTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!
                          .translate('select_department'),
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
                  style: TextStyle(
                    color: colors.error,
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
