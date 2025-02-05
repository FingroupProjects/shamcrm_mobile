import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskStatusRadioGroupWidget extends StatefulWidget {
  final String? selectedStatus;
  final Function(TaskStatus) onSelectStatus;

  TaskStatusRadioGroupWidget({
    Key? key,
    required this.onSelectStatus,
    this.selectedStatus,
  }) : super(key: key);

  @override
  State<TaskStatusRadioGroupWidget> createState() =>
      _TaskStatusRadioGroupWidgetState();
}

class _TaskStatusRadioGroupWidgetState
    extends State<TaskStatusRadioGroupWidget> {
  List<TaskStatus> statusList = [];
  TaskStatus? selectedStatusData;

  final TextStyle statusTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(FetchTaskStatuses());
  }

@override
Widget build(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          // if (state is TaskLoading) {
          //   return const Center(child: CircularProgressIndicator());
          // }
          
          if (state is TaskError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.translate(state.message),
                    style: statusTextStyle.copyWith(color: Colors.white),
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
            });
          }

          if (state is TaskLoaded) {
            statusList = state.taskStatuses;

            if (statusList.length == 1 && selectedStatusData == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onSelectStatus(statusList[0]);
                setState(() {
                  selectedStatusData = statusList[0];
                });
              });
            } else if (widget.selectedStatus != null && statusList.isNotEmpty) {
              try {
                selectedStatusData = statusList.firstWhere(
                  (status) => status.id.toString() == widget.selectedStatus,
                );
              } catch (e) {
                selectedStatusData = null;
              }
            }

            return FormField<TaskStatus>(
              validator: (value) {
                if (selectedStatusData == null) {
                  return AppLocalizations.of(context)!.translate('field_required');
                }
                return null;
              },
              builder: (FormFieldState<TaskStatus> field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('task_statuses'),
                      style: statusTextStyle.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: 1,
                          color: field.hasError 
                              ? Colors.red 
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: CustomDropdown<TaskStatus>.search(
                        closeDropDownOnClearFilterSearch: true,
                        items: statusList,
                        searchHintText: AppLocalizations.of(context)!.translate('search'),
                        overlayHeight: 400,
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
                          // textPadding: const EdgeInsets.symmetric(
                          //   horizontal: 16,
                          //   vertical: 12,
                          // ),
                        ),
                        listItemBuilder: (context, item, isSelected, onItemSelect) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              item.taskStatus?.name ?? "",
                              style: statusTextStyle,
                            ),
                          );
                        },
                        headerBuilder: (context, selectedItem, enabled) {
                          return Text(
                            selectedItem?.taskStatus?.name ?? 
                                AppLocalizations.of(context)!.translate('select_status'),
                            style: statusTextStyle,
                          );
                        },
                        hintBuilder: (context, hint, enabled) => Text(
                          AppLocalizations.of(context)!.translate('select_status'),
                          style: statusTextStyle.copyWith(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        excludeSelected: false,
                        initialItem: selectedStatusData,
                        onChanged: (value) {
                          if (value != null) {
                            widget.onSelectStatus(value);
                            setState(() {
                              selectedStatusData = value;
                            });
                            field.didChange(value);
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(
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
          return const SizedBox();
        },
      ),
    ],
  );
}}