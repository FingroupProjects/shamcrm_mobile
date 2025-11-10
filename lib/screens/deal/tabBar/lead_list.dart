import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_state.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

class LeadRadioGroupWidget extends StatefulWidget {
  final String? selectedLead;
  final Function(LeadData) onSelectLead;
  final bool showDebt;

  const LeadRadioGroupWidget({
    super.key,
    required this.onSelectLead,
    this.selectedLead,
    this.showDebt = false,
  });

  @override
  State<LeadRadioGroupWidget> createState() => _LeadRadioGroupWidgetState();
}

class _LeadRadioGroupWidgetState extends State<LeadRadioGroupWidget> {
  List<LeadData> leadsList = [];
  LeadData? selectedLeadData;
  bool _isInitialized = false;
  bool _initialLeadSet = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GetAllLeadBloc>().add(RefreshAllLeadEv(showDebt: widget.showDebt));
      }
    });
  }

  @override
  void didUpdateWidget(LeadRadioGroupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload when showDebt changes
    if (oldWidget.showDebt != widget.showDebt) {
      context.read<GetAllLeadBloc>().add(RefreshAllLeadEv(showDebt: widget.showDebt));
    }

    // React to external selectedLead change
    if (oldWidget.selectedLead != widget.selectedLead) {
      _updateSelectedLeadData();
    }
  }

  void _updateSelectedLeadData() {
    if (widget.selectedLead != null && leadsList.isNotEmpty) {
      try {
        selectedLeadData = leadsList.firstWhere(
              (lead) => lead.id.toString() == widget.selectedLead,
        );
        _initialLeadSet = true;
      } catch (e) {
        selectedLeadData = null;
        _initialLeadSet = true; // Processed even if not found
      }
    } else {
      selectedLeadData = null;
      _initialLeadSet = leadsList.isNotEmpty;
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
            final isLoading = state is GetAllLeadLoading;
            final isInitial = state is GetAllLeadInitial;

            // SUCCESS → fresh data
            if (state is GetAllLeadSuccess) {
              leadsList = state.dataLead.result ?? [];
              _isInitialized = true;
              _updateSelectedLeadData();
            }
            // ANY OTHER STATE → reset everything (no stale data, no validator)
            else {
              leadsList = [];
              selectedLeadData = null;
              _isInitialized = false;
              _initialLeadSet = false;
            }

            final isStillLoading = isLoading || isInitial || !_isInitialized || !_initialLeadSet;

            final actualInitialItem = isStillLoading
                ? null
                : (selectedLeadData != null && leadsList.contains(selectedLeadData))
                ? selectedLeadData
                : null;

            return CustomDropdown<LeadData>.search(
              key: ValueKey(selectedLeadData?.id), // ← Forces rebuild when pre-selected lead changes
              closeDropDownOnClearFilterSearch: true,
              items: leadsList,
              searchHintText: AppLocalizations.of(context)!.translate('search'),
              overlayHeight: 400,
              enabled: !isStillLoading,
              decoration: CustomDropdownDecoration(
                closedFillColor: const Color(0xffF4F7FD),
                expandedFillColor: Colors.white,
                closedBorder: Border.all(color: const Color(0xffF4F7FD), width: 1),
                closedBorderRadius: BorderRadius.circular(12),
                expandedBorder: Border.all(color: const Color(0xffF4F7FD), width: 1),
                expandedBorderRadius: BorderRadius.circular(12),
              ),
              listItemBuilder: (context, item, isSelected, onItemSelect) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name ?? '',
                      style: const TextStyle(
                        color: Color(0xff1E2E52),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                    if (widget.showDebt && item.debt != null && item.debt != 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Долг: ${item.debt!.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: item.debt! > 0 ? Colors.red : Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                  ],
                );
              },
              headerBuilder: (context, selectedItem, enabled) {
                if (isStillLoading) {
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedItem?.name ?? AppLocalizations.of(context)!.translate('select_lead'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    if (widget.showDebt && selectedItem?.debt != null && selectedItem!.debt! != 0)
                      Text(
                        'Долг: ${selectedItem.debt!.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: selectedItem.debt! > 0 ? Colors.red : Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                  ],
                );
              },
              hintBuilder: (context, hint, enabled) {
                if (isStillLoading) {
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
                  AppLocalizations.of(context)!.translate('select_lead'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                );
              },
              noResultFoundBuilder: (context, text) {
                if (isStillLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                      ),
                    ),
                  );
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      AppLocalizations.of(context)!.translate('no_results'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ),
                );
              },
              excludeSelected: false,
              initialItem: actualInitialItem,
              validator: (_isInitialized && _initialLeadSet)
                  ? (value) {
                if (value == null) {
                  return AppLocalizations.of(context)!.translate('field_required_project');
                }
                return null;
              }
                  : null,
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