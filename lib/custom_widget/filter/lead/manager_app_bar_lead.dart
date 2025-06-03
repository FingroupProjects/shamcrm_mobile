import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/lead_status_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_manager_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_region_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_source_list.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/deal_directory_dropdown_widget.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/models/source_list_model.dart';
import 'package:crm_task_manager/models/directory_link_model.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class ManagerFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onManagersSelected;
  final List? initialManagers;
  final List? initialRegions;
  final List? initialSources;
  final int? initialStatuses;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final bool? initialHasSuccessDeals;
  final bool? initialHasInProgressDeals;
  final bool? initialHasFailureDeals;
  final bool? initialHasNotices;
  final bool? initialHasContact;
  final bool? initialHasChat;
  final bool? initialHasNoReplies;
  final bool? initialHasUnreadMessages;
  final bool? initialHasDeal;
  final int? initialDaysWithoutActivity;
  final VoidCallback? onResetFilters;
  final List<Map<String, dynamic>>? initialDirectoryValues;

  ManagerFilterScreen({
    Key? key,
    this.onManagersSelected,
    this.initialManagers,
    this.initialRegions,
    this.initialSources,
    this.initialStatuses,
    this.initialFromDate,
    this.initialToDate,
    this.initialHasSuccessDeals,
    this.initialHasInProgressDeals,
    this.initialHasFailureDeals,
    this.initialHasNotices,
    this.initialHasContact,
    this.initialHasChat,
    this.initialHasNoReplies,
    this.initialHasUnreadMessages,
    this.initialHasDeal,
    this.initialDaysWithoutActivity,
    this.onResetFilters,
    this.initialDirectoryValues, 
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

  bool? _hasSuccessDeals;
  bool? _hasInProgressDeals;
  bool? _hasFailureDeals;
  bool? _hasNotices;
  bool? _hasContact;
  bool? _hasChat;
  bool? _hasNoReplies;
  bool? _hasUnreadMessages;
  bool? _hasDeal;

  int? _daysWithoutActivity;

  Map<int, MainField?> _selectedDirectoryFields = {};
  List<DirectoryLink> _directoryLinks = [];

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
      inactiveTrackColor: const Color.fromARGB(255, 179, 179, 179).withOpacity(0.5),
      activeTrackColor: ChatSmsStyles.messageBubbleSenderColor,
      inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
    );
  }

  void _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            scaffoldBackgroundColor: Colors.white,
            dialogBackgroundColor: Colors.white,
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
              secondary: Colors.blue.withOpacity(0.1),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedRange != null) {
      setState(() {
        _fromDate = pickedRange.start;
        _toDate = pickedRange.end;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedManagers = widget.initialManagers ?? [];
    _selectedRegions = widget.initialRegions ?? [];
    _selectedSources = widget.initialSources ?? [];
    _selectedStatuses = widget.initialStatuses;
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _hasSuccessDeals = widget.initialHasSuccessDeals;
    _hasInProgressDeals = widget.initialHasInProgressDeals;
    _hasFailureDeals = widget.initialHasFailureDeals;
    _hasNotices = widget.initialHasNotices;
    _hasContact = widget.initialHasContact;
    _hasChat = widget.initialHasChat;
    _hasNoReplies = widget.initialHasNoReplies;
    _hasUnreadMessages = widget.initialHasUnreadMessages;
    _hasDeal = widget.initialHasDeal;
    _daysWithoutActivity = widget.initialDaysWithoutActivity;
    _fetchDirectoryLinks();
  }

  Future<void> _fetchDirectoryLinks() async {
    try {
      final response = await ApiService().getLeadDirectoryLinks();
      if (response.data != null) {
        setState(() {
          _directoryLinks = response.data!;
          for (var link in _directoryLinks) {
            _selectedDirectoryFields[link.id] = null;
          }
          // Восстановление начальных значений справочников
          if (widget.initialDirectoryValues != null) {
            for (var value in widget.initialDirectoryValues!) {
              final directoryId = value['directory_id'];
              final entryId = value['entry_id'];
              final link = _directoryLinks.firstWhere(
                (link) => link.directory.id == directoryId,
                orElse: () => _directoryLinks[0],
              );
              final field = MainField(id: entryId, value: '');
              _selectedDirectoryFields[link.id] = field;
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке справочников: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF4F7FD),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('filter'),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xff1E2E52), fontFamily: 'Gilroy'),
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
                _hasSuccessDeals = false;
                _hasInProgressDeals = false;
                _hasFailureDeals = false;
                _hasNotices = false;
                _hasContact = false;
                _hasChat = false;
                _hasNoReplies = false;
                _hasUnreadMessages = false;
                _hasDeal = false;
                _daysWithoutActivity = null;
                _selectedDirectoryFields.clear();
                for (var link in _directoryLinks) {
                  _selectedDirectoryFields[link.id] = null;
                }
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
              await LeadCache.clearAllLeads();
              Map<String, dynamic> filterData = {
                'managers': _selectedManagers,
                'regions': _selectedRegions,
                'sources': _selectedSources,
                'statuses': _selectedStatuses,
                'fromDate': _fromDate,
                'toDate': _toDate,
                'hasSuccessDeals': _hasSuccessDeals,
                'hasInProgressDeals': _hasInProgressDeals,
                'hasFailureDeals': _hasFailureDeals,
                'hasNotices': _hasNotices,
                'hasContact': _hasContact,
                'hasChat': _hasChat,
                'hasNoReplies': _hasNoReplies,
                'hasUnreadMessages': _hasUnreadMessages,
                'hasDeal': _hasDeal,
                'daysWithoutActivity': _daysWithoutActivity,
                'directory_values': _selectedDirectoryFields.entries
                    .where((entry) => entry.value != null)
                    .map((entry) => {
                          'directory_id': _directoryLinks
                              .firstWhere((link) => link.id == entry.key)
                              .directory
                              .id,
                          'entry_id': entry.value!.id,
                        })
                    .toList(),
              };
              if (_selectedManagers.isNotEmpty ||
                  _selectedRegions.isNotEmpty ||
                  _selectedSources.isNotEmpty ||
                  _selectedStatuses != null ||
                  _fromDate != null ||
                  _toDate != null ||
                  _hasSuccessDeals == true ||
                  _hasInProgressDeals == true ||
                  _hasFailureDeals == true ||
                  _hasNotices == true ||
                  _hasContact == true ||
                  _hasChat == true ||
                  _hasNoReplies == true ||
                  _hasUnreadMessages == true ||
                  _hasDeal == true ||
                  _daysWithoutActivity != null ||
                  _selectedDirectoryFields.values.any((field) => field != null)) {
                widget.onManagersSelected?.call(filterData);
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
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
                    if (_directoryLinks.isNotEmpty) ...[
                      for (var link in _directoryLinks)
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: DirectoryDropdownWidget(
                              directoryId: link.directory.id,
                              directoryName: link.directory.name,
                              onSelectField: (MainField? field) {
                                setState(() {
                                  _selectedDirectoryFields[link.id] = field;
                                });
                              },
                              initialField: _selectedDirectoryFields[link.id],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('with_successful_deal'),
                            _hasSuccessDeals ?? false,
                            (value) => setState(() => _hasSuccessDeals = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('with_deal_in_progress'),
                            _hasInProgressDeals ?? false,
                            (value) => setState(() => _hasInProgressDeals = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('with_unsuccessful_deal'),
                            _hasFailureDeals ?? false,
                            (value) => setState(() => _hasFailureDeals = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('with_note'),
                            _hasNotices ?? false,
                            (value) => setState(() => _hasNotices = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('with_contacts'),
                            _hasContact ?? false,
                            (value) => setState(() => _hasContact = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('with_chat'),
                            _hasChat ?? false,
                            (value) => setState(() => _hasChat = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('without_replies'),
                            _hasNoReplies ?? false,
                            (value) => setState(() => _hasNoReplies = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('with_unread_messages'),
                            _hasUnreadMessages ?? false,
                            (value) => setState(() => _hasUnreadMessages = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('withoutDeal'),
                            _hasDeal ?? false,
                            (value) => setState(() => _hasDeal = value),
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
                              AppLocalizations.of(context)!.translate('days_without_activity'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xff1E2E52),
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
                                  color: Color(0xff1E2E52),
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