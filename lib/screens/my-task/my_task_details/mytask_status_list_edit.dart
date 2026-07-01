import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/my-task_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyTaskStatusEditWidget extends StatefulWidget {
  final String? selectedStatus;
  final Function(MyTaskStatus) onSelectStatus;
  final bool isSubmitted; // Новый параметр

  MyTaskStatusEditWidget({
    Key? key,
    required this.onSelectStatus,
    this.selectedStatus,
    required this.isSubmitted, // Добавляем в конструктор
  }) : super(key: key);

  @override
  State<MyTaskStatusEditWidget> createState() => _MyTaskStatusEditWidgetState();
}

class _MyTaskStatusEditWidgetState extends State<MyTaskStatusEditWidget> {
  List<MyTaskStatus> statusList = [];
  MyTaskStatus? selectedStatusData;

  @override
  void initState() {
    super.initState();
    context.read<MyTaskBloc>().add(FetchMyTaskStatuses());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'Gilroy',
      color: colors.textPrimary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<MyTaskBloc, MyTaskState>(
          builder: (context, state) {
            if (state is MyTaskLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MyTaskError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.translate(state.message),
                      style:
                          statusTextStyle.copyWith(color: colors.buttonPrimaryFg),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: colors.error,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
            }

            if (state is MyTaskLoaded) {
              statusList = state.taskStatuses;

              if (statusList.length == 1 && selectedStatusData == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onSelectStatus(statusList[0]);
                  setState(() {
                    selectedStatusData = statusList[0];
                  });
                });
              } else if (widget.selectedStatus != null &&
                  statusList.isNotEmpty) {
                try {
                  selectedStatusData = statusList.firstWhere(
                    (status) => status.id.toString() == widget.selectedStatus,
                  );
                } catch (e) {
                  selectedStatusData = null;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('task_statuses'),
                    style: statusTextStyle.copyWith(fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.fieldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.isSubmitted && selectedStatusData == null
                            ? colors.error
                            : colors.fieldBg,
                        width: 1.5,
                      ),
                    ),
                    child: CustomDropdown<MyTaskStatus>.search(
                      closeDropDownOnClearFilterSearch: true,
                      items: statusList,
                      searchHintText:
                          AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
                      decoration: CustomDropdownDecoration(
                        closedFillColor: colors.fieldBg,
                        expandedFillColor: colors.surfacePrimary,

                        closedBorderRadius: BorderRadius.circular(12),
                        expandedBorderRadius: BorderRadius.circular(12),
                      ),
                      listItemBuilder:
                          (context, item, isSelected, onItemSelect) {
                        return Text(
                          item.title,
                          style: statusTextStyle,
                        );
                      },
                      headerBuilder: (context, selectedItem, enabled) {
                        return Text(
                          selectedItem.title,
                          style: statusTextStyle,
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                        AppLocalizations.of(context)!.translate('select_status'),
                        style: statusTextStyle.copyWith(fontSize: 14),
                      ),
                      excludeSelected: false,
                      initialItem: statusList.contains(selectedStatusData)
                          ? selectedStatusData
                          : null,
                      onChanged: (value) {
                        if (value != null) {
                          widget.onSelectStatus(value);
                          setState(() {
                            selectedStatusData = value;
                          });
                          FocusScope.of(context).unfocus();
                        }
                      },
                    ),
                  ),
                  if (widget.isSubmitted && selectedStatusData == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 12),
                      child: Text(
                        AppLocalizations.of(context)!
                            .translate('field_required'),
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }
}
