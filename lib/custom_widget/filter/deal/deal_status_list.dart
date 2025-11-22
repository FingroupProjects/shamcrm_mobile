import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealStatusRadioGroupWidget extends StatefulWidget {
  final String? selectedStatus;
  final Function(DealStatus) onSelectStatus;

  DealStatusRadioGroupWidget({
    Key? key,
    required this.onSelectStatus,
    this.selectedStatus,
  }) : super(key: key);

  @override
  State<DealStatusRadioGroupWidget> createState() =>
      _DealStatusRadioGroupWidgetState();
}

class _DealStatusRadioGroupWidgetState extends State<DealStatusRadioGroupWidget> {
  List<DealStatus> statusList = [];
  DealStatus? selectedStatusData;

  final TextStyle statusTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    
    // Проверяем, есть ли уже загруженные статусы в блоке
    final currentState = context.read<DealBloc>().state;
    if (currentState is DealLoaded) {
      setState(() {
        statusList = currentState.dealStatuses;
      });
      _updateSelectedStatus();
    } else {
      context.read<DealBloc>().add(FetchDealStatuses());
    }
  }

  @override
  void didUpdateWidget(DealStatusRadioGroupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Если selectedStatus изменился, обновляем selectedStatusData
    if (oldWidget.selectedStatus != widget.selectedStatus) {
      _updateSelectedStatus();
    }
  }

  void _updateSelectedStatus() {
    if (widget.selectedStatus != null && statusList.isNotEmpty) {
      try {
        final foundStatus = statusList.firstWhere(
          (status) => status.id.toString() == widget.selectedStatus,
        );
        setState(() {
          selectedStatusData = foundStatus;
        });
      } catch (e) {
        setState(() {
          selectedStatusData = null;
        });
      }
    } else {
      // Если selectedStatus null, сбрасываем выбранный статус
      if (widget.selectedStatus == null && selectedStatusData != null) {
        setState(() {
          selectedStatusData = null;
        });
      } else if (statusList.length == 1 && selectedStatusData == null && widget.selectedStatus == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onSelectStatus(statusList[0]);
          setState(() {
            selectedStatusData = statusList[0];
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('deal_statuses'),
          style: statusTextStyle.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 4),
        BlocListener<DealBloc, DealState>(
          listener: (context, state) {
            if (state is DealLoaded) {
              setState(() {
                statusList = state.dealStatuses;
              });
              _updateSelectedStatus();
            }
            
            if (state is DealError) {
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
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                width: 1,
                color: const Color(0xFFF4F7FD),
              ),
            ),
            child: CustomDropdown<DealStatus>.search(
                    key: ValueKey(selectedStatusData?.id ?? 'no_selection'),
                    closeDropDownOnClearFilterSearch: true,
                    items: statusList,
                    searchHintText: AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: const Color(0xffF4F7FD),
                      expandedFillColor: Colors.white,
                      closedBorder: Border.all(
                        color: const Color(0xffF4F7FD),
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: const Color(0xffF4F7FD),
                        width: 1,
                      ),
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
                      if (statusList.isEmpty) {
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                            ),
                          ),
                        );
                      }
                      return Text(
                        selectedItem.title,
                        style: statusTextStyle,
                      );
                    },
                    hintBuilder: (context, hint, enabled) {
                      if (statusList.isEmpty) {
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                            ),
                          ),
                        );
                      }
                      return Text(
                        AppLocalizations.of(context)!.translate('select_status'),
                        style: statusTextStyle.copyWith(fontSize: 14),
                      );
                    },
                    excludeSelected: false,
                    initialItem: statusList.contains(selectedStatusData) ? selectedStatusData : null,
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
        ),
      ],
    );
  }
}
