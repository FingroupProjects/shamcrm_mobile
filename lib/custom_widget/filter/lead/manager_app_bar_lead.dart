import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/lead_status_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_manager_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_region_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_source_list.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/models/source_list_model.dart';
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class ManagerFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onManagersSelected;
  final List? initialManagers;
  final List? initialRegions;
  final List? initialSources;
  final int? initialStatuses;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final DateTime? initialDeadLineFromDate;
  final DateTime? initialDeadLineToDate;
  final bool? initialHasSuccessDeals;
  final bool? initialHasInProgressDeals;
  final bool? initialHasFailureDeals;
  final bool? initialHasNotices;
  final bool? initialHasContact;
  final bool? initialHasChat;
  final int? initialDaysWithoutActivity;
  final VoidCallback? onResetFilters;

  ManagerFilterScreen({
    Key? key,
    this.onManagersSelected,
    this.initialManagers,
    this.initialRegions,
    this.initialSources,
    this.initialStatuses,
    this.initialFromDate,
    this.initialToDate,
    this.initialDeadLineFromDate,
    this.initialDeadLineToDate,
    this.initialHasSuccessDeals,
    this.initialHasInProgressDeals,
    this.initialHasFailureDeals,
    this.initialHasNotices,
    this.initialHasContact,
    this.initialHasChat,
    this.initialDaysWithoutActivity,
    this.onResetFilters, 
  }) : super(key: key);

  @override
  _ManagerFilterScreenState createState() => _ManagerFilterScreenState();
}

class _ManagerFilterScreenState extends State<ManagerFilterScreen> {
  List _selectedManagers = [];
  List _selectedRegions = [];
  List _selectedSources = [];
  
  int? _selectedStatuses;
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _deadLineFromDate;
  DateTime? _deadLineToDate;

  bool? _hasSuccessDeals;
  bool? _hasInProgressDeals;
  bool? _hasFailureDeals;
  bool? _hasNotices ;
  bool? _hasContact;
  bool? _hasChat;

  int? _daysWithoutActivity;

  @override
  void initState() {
    super.initState();
    _selectedManagers = widget.initialManagers ?? [];
    _selectedRegions = widget.initialRegions ?? [];
    _selectedSources = widget.initialSources ?? [];
    _selectedStatuses = widget.initialStatuses;
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _deadLineFromDate = widget.initialDeadLineFromDate;
    _deadLineToDate = widget.initialDeadLineToDate;
    _hasSuccessDeals = widget.initialHasSuccessDeals;
    _hasInProgressDeals = widget.initialHasInProgressDeals;
    _hasFailureDeals = widget.initialHasFailureDeals;
    _hasNotices = widget.initialHasNotices;
    _hasContact = widget.initialHasContact;
    _hasChat = widget.initialHasChat;
    _daysWithoutActivity = widget.initialDaysWithoutActivity;
  }

  void _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (pickedRange != null) {
      setState(() {
        _fromDate = pickedRange.start;
        _toDate = pickedRange.end;
      });
    }
  }

  void _selectDeadLineDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _deadLineFromDate != null && _deadLineToDate != null
          ? DateTimeRange(start: _deadLineFromDate!, end: _deadLineToDate!)
          : null,
    );
    if (pickedRange != null) {
      setState(() {
        _deadLineFromDate = pickedRange.start;
        _deadLineToDate = pickedRange.end;
      });
    }
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black54,
          fontFamily: 'Gilroy',
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color.fromARGB(255, 255, 255, 255),
      inactiveTrackColor:const Color.fromARGB(255, 179, 179, 179).withOpacity(0.5),
      activeTrackColor: ChatSmsStyles.messageBubbleSenderColor,
      inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF4F7FD),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
         AppLocalizations.of(context)!.translate('filter'),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xfff1E2E52), fontFamily: 'Gilroy'),
        ),
        backgroundColor: Colors.white,
        forceMaterialTransparency: true,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                widget.onResetFilters?.call(); 
                _selectedManagers.clear();
                _selectedRegions.clear();
                _selectedSources.clear();
                _selectedStatuses = null;
                _fromDate = null;
                _toDate = null;
                _deadLineFromDate = null;
                _deadLineToDate = null;
                _hasSuccessDeals = false;
                _hasInProgressDeals = false;
                _hasFailureDeals = false;
                _hasNotices = false;
                _hasContact = false;
                _hasChat = false;
                _daysWithoutActivity = null;
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
             AppLocalizations.of(context)!.translate('reset'),
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600, 
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          SizedBox(width: 10),
          TextButton(
            onPressed: () async {
              bool isAnyFilterSelected = 
                  _selectedManagers.isNotEmpty ||
                  _selectedRegions.isNotEmpty ||
                  _selectedSources.isNotEmpty ||
                  _selectedStatuses != null ||
                  _fromDate != null ||
                  _toDate != null ||
                  _deadLineFromDate != null ||
                  _deadLineToDate != null ||
                  _hasSuccessDeals == true ||
                  _hasInProgressDeals == true ||
                  _hasFailureDeals == true ||
                  _hasNotices == true ||
                  _hasContact == true ||
                  _hasChat == true ||
                  _daysWithoutActivity != null;

              if (isAnyFilterSelected) {
              await LeadCache.clearAllLeads();

                print('Start Filter');
                widget.onManagersSelected?.call({
                  'managers': _selectedManagers,
                  'regions': _selectedRegions,
                  'sources': _selectedSources,
                  'statuses': _selectedStatuses,
                  'fromDate': _fromDate,
                  'toDate': _toDate,
                  'deadLineFromDate': _deadLineFromDate,
                  'deadLineToDate': _deadLineToDate,
                  'hasSuccessDeals': _hasSuccessDeals,
                  'hasInProgressDeals': _hasInProgressDeals,
                  'hasFailureDeals': _hasFailureDeals,
                  'hasNotices': _hasNotices,
                  'hasContact': _hasContact,
                  'hasChat': _hasChat,
                  'daysWithoutActivity': _daysWithoutActivity,
                });
              } else {
                print('NOTHING!!!!!!');
              }
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
             AppLocalizations.of(context)!.translate('apply'),
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600, 
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
       body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: GestureDetector(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fromDate != null && _toDate != null
                                    ? "${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year} - ${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}"
                                    : AppLocalizations.of(context)!.translate('select_date_range'),
                                style: TextStyle(color: Colors.black54, fontSize: 14),
                              ),
                              Icon(Icons.calendar_today, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: GestureDetector(
                        onTap: _selectDeadLineDateRange,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _deadLineFromDate != null && _deadLineToDate != null
                                    ? "${_deadLineFromDate!.day.toString().padLeft(2, '0')}.${_deadLineFromDate!.month.toString().padLeft(2, '0')}.${_deadLineFromDate!.year} - ${_deadLineToDate!.day.toString().padLeft(2, '0')}.${_deadLineToDate!.month.toString().padLeft(2, '0')}.${_deadLineToDate!.year}"
                                    : AppLocalizations.of(context)!.translate('select_date_deadline'),
                                style: TextStyle(color: Colors.black54, fontSize: 14),
                              ),
                              Icon(Icons.calendar_today, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: ManagerMultiSelectWidget(
                          selectedManagers: _selectedManagers.map((manager) => manager.id.toString()).toList(),
                          onSelectManagers: (List<ManagerData> selectedUsersData) {
                            setState(() {
                              _selectedManagers = selectedUsersData;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: LeadStatusRadioGroupWidget(
                          selectedStatus: _selectedStatuses?.toString(),
                          onSelectStatus: (LeadStatus selectedStatusData) {
                            setState(() {
                              _selectedStatuses = selectedStatusData.id;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: RegionsMultiSelectWidget(
                          selectedRegions: _selectedRegions.map((region) => region.id.toString()).toList(),
                          onSelectRegions: (List<RegionData> selectedRegionsData) {
                            setState(() {
                              _selectedRegions = selectedRegionsData;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: SourcesMultiSelectWidget(
                          selectedSources: _selectedSources.map((source) => source.id.toString()).toList(),
                          onSelectSources: (List<SourceData> selectedSourcesData) {
                            setState(() {
                              _selectedSources = selectedSourcesData;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('C успешной сделкой'),
                            _hasSuccessDeals ?? false,
                            (value) => setState(() => _hasSuccessDeals = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('С сделкой в ожидании'),
                            _hasInProgressDeals ?? false,
                            (value) => setState(() => _hasInProgressDeals = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('C не успешной сделкой'),
                            _hasFailureDeals ?? false,
                            (value) => setState(() => _hasFailureDeals = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('C заметкой'),
                            _hasNotices ?? false,
                            (value) => setState(() => _hasNotices = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('C контаками'),
                            _hasContact ?? false,
                            (value) => setState(() => _hasContact = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('C чатом'),
                            _hasChat ?? false,
                            (value) => setState(() => _hasChat = value),
                          ),
                        ],
                      ),
                    ),
                     Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.translate('Количество дней без активности'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xfff1E2E52),
                              ),
                            ),
                            Slider(
                              value: (_daysWithoutActivity ?? 0).toDouble(),
                              min: 0,
                              max: 100,
                              divisions: 100,
                              label: _daysWithoutActivity.toString(), 
                              onChanged: (double value) {
                                setState(() {
                                  _daysWithoutActivity = value.toInt(); 
                                });
                              },
                              activeColor: ChatSmsStyles.messageBubbleSenderColor,
                              inactiveColor: Color.fromARGB(255, 179, 179, 179).withOpacity(0.5),
                            ),
                            Center(
                              child: Text(
                                "${_daysWithoutActivity ?? '0'}",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Gilroy',
                                  color: Color(0xfff1E2E52),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}