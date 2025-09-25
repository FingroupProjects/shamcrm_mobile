import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadStatusEditpWidget extends StatefulWidget {
  final String? selectedStatus;
  final Function(LeadStatus) onSelectStatus;
  final String? salesFunnelId; // Новый параметр

  LeadStatusEditpWidget({
    Key? key,
    required this.onSelectStatus,
    this.selectedStatus,
    this.salesFunnelId,
  }) : super(key: key);

  @override
  State<LeadStatusEditpWidget> createState() => _LeadStatusEditpWidgetState();
}

class _LeadStatusEditpWidgetState extends State<LeadStatusEditpWidget> {
  List<LeadStatus> statusList = [];
  LeadStatus? selectedStatusData;

  final TextStyle statusTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    // Добавляем загрузку статусов, если они еще не загружены
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = context.read<LeadBloc>().state;
      if (currentState is! LeadLoaded || currentState.leadStatuses.isEmpty) {
        context.read<LeadBloc>().add(FetchLeadStatuses());
      } else {
        // Если данные уже есть, сразу инициализируем
        _initializeFromState(currentState);
      }
    });
  }

  void _initializeFromState(LeadLoaded state) {
    setState(() {
      statusList = state.leadStatuses;
      if (widget.selectedStatus != null && statusList.isNotEmpty) {
        try {
          selectedStatusData = statusList.firstWhere(
            (status) => status.id.toString() == widget.selectedStatus,
          );
        } catch (e) {
          selectedStatusData = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocListener<LeadBloc, LeadState>(
          listener: (context, state) {
            if (state is LeadError) {
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
            } else if (state is LeadLoaded) {
              setState(() {
                statusList = state.leadStatuses;
                // Сбрасываем текущий статус, если он не входит в новый список
                if (widget.selectedStatus != null && statusList.isNotEmpty) {
                  try {
                    selectedStatusData = statusList.firstWhere(
                      (status) => status.id.toString() == widget.selectedStatus,
                    );
                  } catch (e) {
                    selectedStatusData = null; // Сбрасываем, если статус не найден
                  }
                } 
              });
            }
          },
          child: BlocBuilder<LeadBloc, LeadState>(
            builder: (context, state) {
              // Убираем отображение загрузки - всегда показываем поле
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('Статус лида'),
                    style: statusTextStyle.copyWith(fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 1,
                        color: const Color(0xFFF4F7FD),
                      ),
                    ),
                    child: CustomDropdown<LeadStatus>.search(
                      closeDropDownOnClearFilterSearch: true,
                      items: statusList, // Используем локальный список
                      searchHintText: AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
                      enabled: true, // Всегда включено
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
                      listItemBuilder: (context, item, isSelected, onItemSelect) {
                        return Text(
                          item.title,
                          style: statusTextStyle,
                        );
                      },
                      headerBuilder: (context, selectedItem, enabled) {
                        return Text(
                          selectedItem?.title ?? AppLocalizations.of(context)!.translate('select_status'),
                          style: statusTextStyle,
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                        AppLocalizations.of(context)!.translate('select_status'),
                        style: statusTextStyle.copyWith(fontSize: 14),
                      ),
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
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}