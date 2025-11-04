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
  bool _isInitialized = false; // ✅ NEW: Track if data has been loaded at least once

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      //print('🟢 LeadWidget: initState - showDebt=${widget.showDebt}');
    }

    // ✅ КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Используем RefreshAllLeadEv для загрузки свежих данных
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (kDebugMode) {
          //print('🔥 LeadWidget: Forcing fresh data load (ignoring cache)');
        }
        context.read<GetAllLeadBloc>().add(RefreshAllLeadEv(showDebt: widget.showDebt));
      }
    });
  }

  @override
  void didUpdateWidget(LeadRadioGroupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Перезагружаем данные если изменился параметр showDebt
    if (oldWidget.showDebt != widget.showDebt) {
      if (kDebugMode) {
        //print('🔄 LeadWidget: showDebt changed, reloading data');
      }
      _isInitialized = false; // ✅ Reset initialization flag when reloading
      context.read<GetAllLeadBloc>().add(RefreshAllLeadEv(showDebt: widget.showDebt));
    }

    // Обновляем выбранный лид если изменился извне
    if (oldWidget.selectedLead != widget.selectedLead && leadsList.isNotEmpty) {
      _updateSelectedLeadData();
    }
  }

  void _updateSelectedLeadData() {
    if (kDebugMode) {
      //print('🔄 LeadWidget: _updateSelectedLeadData started');
    }

    if (widget.selectedLead != null && leadsList.isNotEmpty) {
      try {
        selectedLeadData = leadsList.firstWhere(
              (lead) => lead.id.toString() == widget.selectedLead,
        );
        if (kDebugMode) {
          //print('🟢 LeadWidget: Selected lead found - ${selectedLeadData?.name}');
        }
      } catch (e) {
        selectedLeadData = null;
        if (kDebugMode) {
          //print('🔴 LeadWidget: Selected lead NOT found - searching for ${widget.selectedLead}');
        }
      }
    } else {
      selectedLeadData = null;
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
            final isInitial = state is GetAllLeadInitial; // ✅ NEW: Check for initial state

            // ✅ ИСПРАВЛЕНИЕ: Обновляем список только при Success
            if (state is GetAllLeadSuccess) {
              leadsList = state.dataLead.result ?? [];
              _isInitialized = true; // ✅ Mark as initialized after first successful load
              if (kDebugMode) {
                //print('🔵 LeadWidget BlocBuilder: SUCCESS - ${leadsList.length} leads loaded');
                if (leadsList.isNotEmpty) {
                  //print('🔵 LeadWidget BlocBuilder: First lead = ${leadsList.first.name}');
                }
              }
              _updateSelectedLeadData();
            }

            if (state is GetAllLeadError) {
              if (kDebugMode) {
                //print('🔴 LeadWidget BlocBuilder: ERROR - ${state.message}');
              }
            }

            // ✅ КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Если загрузка ИЛИ начальное состояние, не показываем initialItem
            // Это предотвращает ошибку "initialItem must match with one of the item in items list"
            final actualInitialItem = (isLoading || isInitial || !_isInitialized)
                ? null
                : (selectedLeadData != null &&
                leadsList.isNotEmpty &&
                leadsList.contains(selectedLeadData))
                ? selectedLeadData
                : null;

            if (kDebugMode) {
              //print('🔵 LeadWidget: Rendering dropdown - items=${leadsList.length}, isLoading=$isLoading, isInitial=$isInitial');
              //print('🔵 LeadWidget: actualInitialItem=${actualInitialItem?.name}');
            }

            return CustomDropdown<LeadData>.search(
              closeDropDownOnClearFilterSearch: true,
              items: leadsList.isEmpty ? [] : leadsList, // ✅ Provide empty list during initial state
              searchHintText: AppLocalizations.of(context)!.translate('search'),
              overlayHeight: 400,
              enabled: !isLoading && !isInitial, // ✅ Disable during initial state too
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
                if (isLoading || isInitial) { // ✅ Show loading for both states
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
                if (isLoading || isInitial) { // ✅ Show loading for both states
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
                if (isLoading || isInitial) { // ✅ Show loading for both states
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
              initialItem: actualInitialItem, // ✅ null во время загрузки И начального состояния
              validator: _isInitialized ? (value) { // ✅ CRITICAL FIX: Only validate after initialization
                if (value == null) {
                  return AppLocalizations.of(context)!.translate('field_required_project');
                }
                return null;
              } : null, // ✅ No validator during initialization = no red error
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