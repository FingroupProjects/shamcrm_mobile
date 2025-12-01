import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';
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

  final TextStyle statusTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    context.read<MyTaskBloc>().add(FetchMyTaskStatuses());
  }

  @override
  Widget build(BuildContext context) {
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
                      style: statusTextStyle.copyWith(color: Colors.white),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.red,
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
                      color: const Color(0xFFF4F7FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.isSubmitted && selectedStatusData == null
                            ? Colors.red
                            : const Color(0xFFF4F7FD),
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
                        closedFillColor: const Color(0xffF4F7FD),
                        expandedFillColor: Colors.white,

                        closedBorderRadius: BorderRadius.circular(12),
                        expandedBorderRadius: BorderRadius.circular(12),
                      ),
                      listItemBuilder:
                          (context, item, isSelected, onItemSelect) {
                        return Text(
                          item.title ?? '',
                          style: statusTextStyle,
                        );
                      },
                      headerBuilder: (context, selectedItem, enabled) {
                        return Text(
                          selectedItem?.title ??
                              AppLocalizations.of(context)!
                                  .translate('select_status'),
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