import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/lead_status_for_filter/lead_status_for_filter_bloc.dart';
import 'package:crm_task_manager/bloc/lead_status_for_filter/lead_status_for_filter_event.dart';
import 'package:crm_task_manager/bloc/lead_status_for_filter/lead_status_for_filter_state.dart';
import 'package:crm_task_manager/models/LeadStatusForFilter.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadStatusForFilterMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedLeadStatuses;
  final Function(List<LeadStatusForFilter>) onSelectStatuses;

  LeadStatusForFilterMultiSelectWidget({
    super.key,
    required this.selectedLeadStatuses,
    required this.onSelectStatuses,
  });

  @override
  State<LeadStatusForFilterMultiSelectWidget> createState() => _LeadStatusForFilterMultiSelectWidgetState();
}

class _LeadStatusForFilterMultiSelectWidgetState extends State<LeadStatusForFilterMultiSelectWidget> {
  List<LeadStatusForFilter> statusList = [];
  List<LeadStatusForFilter> selectedStatusesData = [];

  @override
  void initState() {
    super.initState();
    context.read<LeadStatusForFilterBloc>().add(FetchLeadStatusForFilter());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocListener<LeadStatusForFilterBloc, LeadStatusForFilterState>(
          listener: (context, state) {
            if (state is LeadStatusForFilterError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.translate(state.message),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.red,
                  elevation: 3,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
          child: BlocBuilder<LeadStatusForFilterBloc, LeadStatusForFilterState>(
            builder: (context, state) {
              if (state is LeadStatusForFilterError) {
                return Text(state.message);
              }
              if (state is LeadStatusForFilterLoaded) {
                statusList = state.leadStatusForFilter;
                if (widget.selectedLeadStatuses != null && statusList.isNotEmpty) {
                  selectedStatusesData = statusList
                      .where((status) => widget.selectedLeadStatuses!.contains(status.id.toString()))
                      .toList();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('status'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      child: CustomDropdown<LeadStatusForFilter>.multiSelectSearch(
                        items: statusList,
                        initialItems: selectedStatusesData,
                        searchHintText: AppLocalizations.of(context)!.translate('search'),
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
                        listItemBuilder: (context, item, isSelected, onItemSelect) {
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
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Gilroy',
                                      color: Color(0xff1E2E52),
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
                        headerListBuilder: (context, selectedItems, enabled) {
                          int selectedStatusesCount = selectedStatusesData.length;
                          return Text(
                            selectedStatusesCount == 0
                                ? AppLocalizations.of(context)!
                                    .translate('select_status')
                                : '${AppLocalizations.of(context)!.translate('select_status')} $selectedStatusesCount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Gilroy',
                              color: Color(0xff1E2E52),
                            ),
                          );
                        },
                        hintBuilder: (context, hint, enabled) => Text(
                          AppLocalizations.of(context)!.translate('select_status'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        ),
                        onListChanged: (values) {
                          widget.onSelectStatuses(values);
                          setState(() {
                            selectedStatusesData = values;
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
        ),
      ],
    );
  }
}