import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_state.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadRadioGroupWidget extends StatefulWidget {
  final String? selectedLead;
  final Function(LeadData) onSelectLead;

  const LeadRadioGroupWidget({
    super.key,
    required this.onSelectLead,
    this.selectedLead,
  });

  @override
  State<LeadRadioGroupWidget> createState() => _LeadRadioGroupWidgetState();
}

class _LeadRadioGroupWidgetState extends State<LeadRadioGroupWidget> {
  List<LeadData> leadsList = [];
  LeadData? selectedLeadData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<GetAllLeadBloc>().state;
        if (state is GetAllLeadSuccess) {
          leadsList = state.dataLead.result ?? [];
          _updateSelectedLeadData();
        }
        if (state is! GetAllLeadSuccess) {
          context.read<GetAllLeadBloc>().add(GetAllLeadEv());
        }
      }
    });
  }

  void _updateSelectedLeadData() {
    if (widget.selectedLead != null && leadsList.isNotEmpty) {
      try {
        selectedLeadData = leadsList.firstWhere(
          (lead) => lead.id.toString() == widget.selectedLead,
        );
      } catch (e) {
        // selectedLeadData остается null если не найден
      }
    }
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
            if (state is GetAllLeadSuccess) {
              leadsList = state.dataLead.result ?? [];
              _updateSelectedLeadData();
            }

            return CustomDropdown<LeadData>.search(
              closeDropDownOnClearFilterSearch: true,
              items: leadsList,
              searchHintText: AppLocalizations.of(context)!.translate('search'),
              overlayHeight: 400,
              enabled: true,
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
                if (state is GetAllLeadLoading) {
                  return Text(
                    AppLocalizations.of(context)!.translate('select_lead'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  );
                }
                return Text(
                  selectedItem?.name ?? AppLocalizations.of(context)!.translate('select_lead'),
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
              initialItem: leadsList.contains(selectedLeadData) ? selectedLeadData : null,
              validator: (value) {
                if (value == null) {
                  return AppLocalizations.of(context)!.translate('field_required_project');
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
            );
          },
        ),
      ],
    );
  }
}