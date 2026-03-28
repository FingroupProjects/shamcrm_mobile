import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_state.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadWithManager extends StatefulWidget {
  final String? selectedLead;
  final Function(LeadData) onSelectLead;

  const LeadWithManager({
    super.key,
    required this.onSelectLead,
    this.selectedLead,
  });

  @override
  State<LeadWithManager> createState() => _LeadWithManagerState();
}

class _LeadWithManagerState extends State<LeadWithManager> {
  List<LeadData> leadsList = [];
  LeadData? selectedLeadData;

  @override
  void initState() {
    super.initState();
    //print('LeadWithManager: initState started');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<GetAllLeadBloc>().state;
        //print('LeadWithManager: Initial GetAllLeadBloc state: $state');
        if (state is GetAllLeadSuccess) {
          leadsList = state.dataLead.result ?? [];
          //print('LeadWithManager: Loaded ${leadsList.length} leads');
          _updateSelectedLeadData();
        }
        if (state is! GetAllLeadSuccess) {
          //print('LeadWithManager: Dispatching GetAllLeadEv');
          context.read<GetAllLeadBloc>().add(GetAllLeadEv());
        }
      }
    });
  }

void _updateSelectedLeadData() {
  //print('LeadWithManager: Updating selected lead, prop selectedLead: ${widget.selectedLead}');
  if (widget.selectedLead != null && leadsList.isNotEmpty) {
    try {
      final newSelectedLead = leadsList.firstWhere(
        (lead) => lead.id.toString() == widget.selectedLead,
      );
      if (selectedLeadData?.id != newSelectedLead.id) {
        selectedLeadData = newSelectedLead;
        //print('LeadWithManager: Found lead: ${newSelectedLead.id}, managerId: ${newSelectedLead.managerId}');
        widget.onSelectLead(newSelectedLead);
      } else {
        //print('LeadWithManager: Lead ${newSelectedLead.id} already selected, skipping onSelectLead');
      }
    } catch (e) {
      //print('LeadWithManager: Lead not found for ID ${widget.selectedLead}: $e');
      selectedLeadData = null;
    }
  } else {
    //print('LeadWithManager: No selected lead or empty leads list');
    selectedLeadData = null;
  }
}

@override
Widget build(BuildContext context) {
  //print('LeadWithManager: Building with selectedLeadData: ${selectedLeadData?.id}');
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
          //print('LeadWithManager: BlocBuilder state: $state');
          if (state is GetAllLeadSuccess) {
            leadsList = state.dataLead.result ?? [];
            //print('LeadWithManager: Updated leadsList with ${leadsList.length} leads');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateSelectedLeadData();
            });
          } else if (state is GetAllLeadLoading) {
            //print('LeadWithManager: Leads are loading');
          } else if (state is GetAllLeadError) {
            //print('LeadWithManager: Error loading leads: ${state.message}');
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
                closedBorder: Border.all(color: const Color(0xffF4F7FD), width: 1),
                closedBorderRadius: BorderRadius.circular(12),
                expandedBorder: Border.all(color: const Color(0xffF4F7FD), width: 1),
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
                    AppLocalizations.of(context)!.translate('select_leads'),
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
                  //print('LeadWithManager: User selected lead: ${value.id}, managerId: ${value.managerId}');
                  widget.onSelectLead(value);
                  setState(() {
                    selectedLeadData = value;
                    //print('LeadWithManager: Updated selectedLeadData to: ${value.id}');
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