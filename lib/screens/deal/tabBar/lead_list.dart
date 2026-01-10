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

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      //print('🟢 LeadWidget: initState - showDebt=${widget.showDebt}');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<GetAllLeadBloc>().state;

        if (kDebugMode) {
          //print('🟢 LeadWidget: postFrameCallback - state=${state.runtimeType}');
        }

        if (state is GetAllLeadSuccess) {
          leadsList = state.dataLead.result ?? [];
          if (kDebugMode) {
            //print('🟢 LeadWidget: Found cached data - ${leadsList.length} leads');
          }
          _updateSelectedLeadData();
        }

        if (state is! GetAllLeadSuccess) {
          if (kDebugMode) {
            //print('🟢 LeadWidget: Dispatching GetAllLeadEv(showDebt=${widget.showDebt})');
          }
          context.read<GetAllLeadBloc>().add(GetAllLeadEv(showDebt: widget.showDebt));
        }
      }
    });
  }

  void _updateSelectedLeadData() {
    debugPrint("_updateSelectedLeadData started");
    if (widget.selectedLead != null && leadsList.isNotEmpty) {
      try {
        // ИСПРАВЛЕНО: Ищем в текущем списке leadsList
        selectedLeadData = leadsList.firstWhere(
          (lead) => lead.id.toString() == widget.selectedLead,
        );
        if (kDebugMode) {
          print('🟢 LeadWidget: Selected lead found - ${selectedLeadData?.name}');
        }
      } catch (e) {
        selectedLeadData = null; // ИСПРАВЛЕНО: обнуляем если не найден
        if (kDebugMode) {
          print('🔴 LeadWidget: Selected lead NOT found - searching for ${widget.selectedLead}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      //print('🟡 LeadWidget: build() called');
    }

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
            if (kDebugMode) {
              //print('🔵 LeadWidget BlocBuilder: state=${state.runtimeType}');
            }

            final isLoading = state is GetAllLeadLoading;

            if (state is GetAllLeadSuccess) {
              leadsList = state.dataLead.result ?? [];
              if (kDebugMode) {
                //print('🔵 LeadWidget BlocBuilder: SUCCESS - ${leadsList.length} leads loaded');
                if (leadsList.isNotEmpty) {
                  //print('🔵 LeadWidget BlocBuilder: First lead = ${leadsList.first.name}, debt=${leadsList.first.debt}');
                }
              }
              // ИСПРАВЛЕНО: Обновляем selectedLeadData из текущего списка
              _updateSelectedLeadData();
            }

            if (state is GetAllLeadError) {
              if (kDebugMode) {
                //print('🔴 LeadWidget BlocBuilder: ERROR - ${state.message}');
              }
            }

            if (kDebugMode) {
              //print('🔵 LeadWidget BlocBuilder: Rendering dropdown - items=${leadsList.length}, isLoading=$isLoading');
              //print('🔵 LeadWidget BlocBuilder: selectedLeadData=${selectedLeadData?.name}, id=${selectedLeadData?.id}');
            }

            // ИСПРАВЛЕНО: Проверяем что selectedLeadData действительно в списке
            final actualInitialItem = (selectedLeadData != null && leadsList.contains(selectedLeadData))
                ? selectedLeadData
                : null;

            if (kDebugMode && selectedLeadData != null && !leadsList.contains(selectedLeadData)) {
              //print('⚠️ LeadWidget: selectedLeadData not in list, resetting to null');
            }

            debugPrint("LeadWidget dropdown items count: ${leadsList.length}");
            debugPrint("leadlist ids : ${leadsList.map((e) => e.id).toList()}");
            debugPrint("LeadWidget selectedLeadData: ${selectedLeadData?.toString()}");
            debugPrint("leadsList contains selectedLeadData: ${leadsList.contains(selectedLeadData)}");

            return CustomDropdown<LeadData>.search(
              closeDropDownOnClearFilterSearch: true,
              items: isLoading ? [] : leadsList,
              searchHintText: AppLocalizations.of(context)!.translate('search'),
              overlayHeight: 400,
              enabled: !isLoading,
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
                if (kDebugMode) {
                  //print('🟣 LeadWidget: listItemBuilder called for ${item.name}');
                }

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
                if (kDebugMode) {
                  //print('🟣 LeadWidget: headerBuilder called - isLoading=$isLoading, selected=${selectedItem?.name}');
                }

                if (isLoading) {
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
                    if (widget.showDebt &&
                        selectedItem?.debt != null &&
                        selectedItem!.debt! != 0)
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
                if (kDebugMode) {
                  //print('🟣 LeadWidget: hintBuilder called - isLoading=$isLoading');
                }

                if (isLoading) {
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
                if (kDebugMode) {
                  //print('🟣 LeadWidget: noResultFoundBuilder called - isLoading=$isLoading, text=$text');
                }

                if (isLoading) {
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
              // ИСПРАВЛЕНО: Используем actualInitialItem вместо прямой проверки
              initialItem: actualInitialItem,
              validator: (value) {
                if (value == null) {
                  return AppLocalizations.of(context)!.translate('field_required_project');
                }
                return null;
              },
              onChanged: (value) {
                if (kDebugMode) {
                  //print('🟢 LeadWidget: onChanged - selected ${value?.name}');
                }

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