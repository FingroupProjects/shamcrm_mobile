import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_state.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadRadioGroupEventWidget extends StatefulWidget {
  final String? selectedLead;
  final Function(LeadData) onSelectLead;

  const LeadRadioGroupEventWidget({
    super.key,
    required this.onSelectLead,
    this.selectedLead,
  });

  @override
  State<LeadRadioGroupEventWidget> createState() => _LeadRadioGroupEventWidgetState();
}

class _LeadRadioGroupEventWidgetState extends State<LeadRadioGroupEventWidget> {
  List<LeadData> leadsList = [];
  LeadData? selectedLeadData;

  @override
  void initState() {
    super.initState();
    // Загружаем лиды
    context.read<GetAllLeadBloc>().add(GetAllLeadEv());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('lead'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        BlocBuilder<GetAllLeadBloc, GetAllLeadState>(
          builder: (context, state) {
            if (state is GetAllLeadLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xff1E2E52),
                ),
              );
            } else if (state is GetAllLeadSuccess) {
              leadsList = state.dataLead.result ?? [];
              // Устанавливаем selectedLeadData только если он еще не установлен или изменился
              if (widget.selectedLead != null && leadsList.isNotEmpty) {
                try {
                  selectedLeadData = leadsList.firstWhere(
                    (lead) => lead.id.toString() == widget.selectedLead,
                    orElse: () => leadsList.first, // Выбираем первый лид, если не найдено
                  );
                } catch (e) {
                  selectedLeadData = null; // Если не найдено, устанавливаем null
                }
              } else {
                selectedLeadData = null; // Если selectedLead не указан, устанавливаем null
              }
            } else if (state is GetAllLeadError) {
              return Text(
                AppLocalizations.of(context)!.translate('error_loading_leads'),
                style: const TextStyle(color: Colors.red),
              );
            }

            return Container(
              child: CustomDropdown<LeadData>.search(
                closeDropDownOnClearFilterSearch: true,
                items: leadsList,
                searchHintText: AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 400,
                enabled: leadsList.isNotEmpty, // Отключаем, если список пуст
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
                    item.name ?? '',
                    style: const TextStyle(
                      color: Color(0xff1E2E52),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                    ),
                  );
                },
                headerBuilder: (context, selectedItem, enabled) {
                  return Text(
                    selectedItem?.name ??
                        AppLocalizations.of(context)!.translate('select_leads'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  );
                },
                hintBuilder: (context, hint, enabled) => Text(
                  AppLocalizations.of(context)!.translate('select_lead'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                excludeSelected: false,
                initialItem: selectedLeadData, // Используем корректный selectedLeadData
                validator: (value) {
                  if (value == null) {
                    return AppLocalizations.of(context)!
                        .translate('field_required_project');
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value != null) {
                    widget.onSelectLead(value);
                    setState(() {
                      selectedLeadData = value;
                    });
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }
}