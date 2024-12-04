import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_state.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadRadioGroupWidget extends StatefulWidget {
  final String? selectedLead;
  final Function(LeadData) onSelectLead;

  LeadRadioGroupWidget(
      {super.key, required this.onSelectLead, this.selectedLead});

  @override
  State<LeadRadioGroupWidget> createState() => _LeadRadioGroupWidgetState();
}

class _LeadRadioGroupWidgetState extends State<LeadRadioGroupWidget> {
  List<LeadData> leadsList = [];
  LeadData? selectedLeadData;

  @override
  void initState() {
    super.initState();
    context.read<GetAllLeadBloc>().add(GetAllLeadEv());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<GetAllLeadBloc, GetAllLeadState>(
          builder: (context, state) {
            if (state is GetAllLeadLoading) {
              // return Center(child: CircularProgressIndicator());
            }

            if (state is GetAllLeadError) {
              return Text(state.message);
            }
            if (state is GetAllLeadSuccess) {
              leadsList = state.dataLead.result ?? [];
              if (widget.selectedLead != null && leadsList.isNotEmpty) {
                try {
                  selectedLeadData = leadsList.firstWhere(
                    (lead) => lead.id.toString() == widget.selectedLead,
                  );
                } catch (e) {
                  selectedLeadData = null;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SizedBox(height: 8),
                  const Text(
                    'Лиды',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xfff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF4F7FD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(width: 1, color: Color(0xFFF4F7FD)),
                    ),
                    child: CustomDropdown<LeadData>.search(
                      closeDropDownOnClearFilterSearch: true,
                      items: leadsList,
                      searchHintText: 'Поиск',
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
                        return Text(item.name!);
                      },
                      headerBuilder: (context, selectedItem, enabled) {
                        return Text(
                          selectedItem.name ?? 'Выберите лида',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        );
                      },
                      hintBuilder: (context, hint, enabled) =>
                          Text('Выберите лид',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xff1E2E52),
                              )),
                      excludeSelected: false,
                      initialItem: selectedLeadData,
                      validator: (value) {
                        if (value == null) {
                          return 'Поле обязательно для заполнения';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value != null) {
                          widget.onSelectLead(value);
                          setState(() {
                            selectedLeadData = value;
                          });
                        }
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
