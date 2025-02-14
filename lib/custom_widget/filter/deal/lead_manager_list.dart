import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/lead_multi_list/lead_multi_bloc.dart';
import 'package:crm_task_manager/models/lead_multi_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedLeads;
  final Function(List<LeadData>) onSelectLeads;

  LeadMultiSelectWidget({
    super.key,
    required this.onSelectLeads,
    this.selectedLeads,
  });

  @override
  State<LeadMultiSelectWidget> createState() => _LeadsMultiSelectWidgetState();
}

class _LeadsMultiSelectWidgetState extends State<LeadMultiSelectWidget> {
  List<LeadData> leadsList = [];
  List<LeadData> selectedLeadsData = [];

  @override
  void initState() {
    super.initState();
    context.read<GetAllLeadMultiBloc>().add(GetAllLeadEv());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<GetAllLeadMultiBloc, GetAllLeadState>(
          builder: (context, state) {
            if (state is GetAllLeadLoading) {
              // return Center(child: CircularProgressIndicator());
            }
            if (state is GetAllLeadError) {
              return Text(state.message);
            }
            if (state is GetAllLeadSuccess) {
              leadsList = state.dataLead.result ?? [];
              if (widget.selectedLeads != null && leadsList.isNotEmpty) {
                selectedLeadsData = leadsList
                    .where((lead) =>
                        widget.selectedLeads!.contains(lead.id.toString()))
                    .toList();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('lead'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xfff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    child: CustomDropdown<LeadData>.multiSelectSearch(
                      items: leadsList,
                      initialItems: selectedLeadsData,
                      searchHintText:
                          AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
                      decoration: CustomDropdownDecoration(
                        closedFillColor: Color(0xffF4F7FD),
                        expandedFillColor: Colors.white,
                        closedBorder: Border.all(
                          color: Color(0xffF4F7FD),
                          width: 1,
                        ),
                        closedBorderRadius: BorderRadius.circular(12),
                        expandedBorder: Border.all(
                          color: Color(0xffF4F7FD),
                          width: 1,
                        ),
                        expandedBorderRadius: BorderRadius.circular(12),
                      ),
                      listItemBuilder:
                          (context, item, isSelected, onItemSelect) {
                        return ListTile(
                          minTileHeight: 1,
                          minVerticalPadding: 2,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Padding(
                            padding: EdgeInsets.zero,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Color(0xff1E2E52), width: 1),
                                    color: isSelected
                                        ? Color(0xff1E2E52)
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? Icon(Icons.check,
                                          color: Colors.white, size: 16)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${item.name} ${item.lastname}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Gilroy',
                                      color: Color(0xff1E2E52),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            onItemSelect();
                            FocusScope.of(context).unfocus();
                          },
                        );
                      },
                      headerListBuilder: (context, hint, enabled) {
                        int selectedLeadsCount = selectedLeadsData.length;

                        return Text(
                          selectedLeadsCount == 0
                              ? AppLocalizations.of(context)!
                                  .translate('select_lead')
                              : '${AppLocalizations.of(context)!.translate('select_leads')} $selectedLeadsCount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                          AppLocalizations.of(context)!
                              .translate('select_leads'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          )),
                      onListChanged: (values) {
                        widget.onSelectLeads(values);
                        setState(() {
                          selectedLeadsData = values;
                        });
                      },
                    ),
                  ),
                ],
              );
            }
            return SizedBox();
          },
        ),
      ],
    );
  }
}