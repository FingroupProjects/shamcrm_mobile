import 'package:crm_task_manager/bloc/Task_Status_Name/statusName_bloc.dart';
import 'package:crm_task_manager/bloc/Task_Status_Name/statusName_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/task/task_Status_Name_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StatusList extends StatefulWidget {
  final String? selectedTaskStatus;
  final Function(String? value, int? id) onChanged;
  final String? errorText;

  const StatusList({
    Key? key,
    required this.selectedTaskStatus,
    required this.onChanged,
    this.errorText,
  }) : super(key: key);

  @override
  _TaskStatusListState createState() => _TaskStatusListState();
}

class _TaskStatusListState extends State<StatusList> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocBuilder<TaskStatusNameBloc, StatusNameState>(
      builder: (context, state) {
        List<DropdownMenuItem<String>> dropdownItems = [];
        if (state is StatusNameLoading) {
          dropdownItems = [
            DropdownMenuItem(
              value: null,
              child: Text(
                AppLocalizations.of(context)!.translate('loading'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
                ),
              ),
            ),
          ];
        } else if (state is StatusNameLoaded) {
          dropdownItems = state.statusName
              .map<DropdownMenuItem<String>>((StatusName status) {
            return DropdownMenuItem<String>(
              value: status.id.toString(),
              child: Text(
                status.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
                ),
              ),
            );
          }).toList();
        } else if (state is StatusNameError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.translate(state.message),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: colors.textInverse,
                  ),
                ),
                backgroundColor: colors.error,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                duration: const Duration(seconds: 3),
              ),
            );
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('task_status'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: colors.fieldBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                menuMaxHeight: 400,
                value: dropdownItems
                        .any((item) => item.value == widget.selectedTaskStatus)
                    ? widget.selectedTaskStatus
                    : null,
                hint: Text(
                  AppLocalizations.of(context)!.translate('select_status_task'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: colors.textSecondary,
                  ),
                ),
                items: dropdownItems,
                onChanged: (String? value) {
                  if (state is StatusNameLoaded && value != null) {
                    final selectedStatus = state.statusName
                        .firstWhere((status) => status.id.toString() == value);
                    widget.onChanged(selectedStatus.name, selectedStatus.id);
                  } else {
                    widget.onChanged(null, null);
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return AppLocalizations.of(context)!
                        .translate('field_required');
                  }
                  return null;
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  errorText: widget.errorText,
                  errorStyle: TextStyle(
                    fontSize: 14,
                    color: colors.error,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Gilroy',
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: widget.errorText != null
                          ? colors.error
                          : colors.borderSubtle,
                      width: widget.errorText != null ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: widget.errorText != null
                          ? colors.error
                          : colors.borderSubtle,
                      width: widget.errorText != null ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: widget.errorText != null
                          ? colors.error
                          : colors.buttonPrimaryBg,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: colors.error,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: colors.error,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colors.fieldBg,
                ),
                dropdownColor: colors.surfaceElevated,
                iconSize: 20,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: colors.iconPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
