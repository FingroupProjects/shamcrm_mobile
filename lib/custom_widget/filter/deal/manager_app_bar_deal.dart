import 'dart:async';
import 'dart:convert';

import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/deal_NamesMultiSelectWidget.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/deal_directory_dropdown_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/deal_status_list.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/lead_manager_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_manager_list.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/deal_name_list.dart';
import 'package:crm_task_manager/models/directory_link_model.dart';
import 'package:crm_task_manager/models/lead_multi_model.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/screens/deal/deal_cache.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_task_manager/custom_widget/custom_field_multi_select.dart';

class DealManagerFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onManagersSelected;
  final Function(Map<String, dynamic>)? onLeadsSelected;
  final Function(int?)? onStatusSelected;
  final Function(DateTime?, DateTime?)? onDateRangeSelected;
  final Function(int?, DateTime?, DateTime?)? onStatusAndDateRangeSelected;
  final List? initialManagers;
  final List? initialLeads;
  final int? initialStatuses;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final VoidCallback? onResetFilters;
  final int? initialDaysWithoutActivity;
  final bool? initialHasTasks;
  final List<Map<String, dynamic>>? initialDirectoryValues;
  final List<String>? initialDealNames;
  final List<String>? customFieldTitles;
  final Map<String, List<String>>? customFieldValues;
  final Map<String, List<String>>? initialCustomFieldSelections;

  DealManagerFilterScreen({
    Key? key,
    this.onManagersSelected,
    this.onLeadsSelected,
    this.onStatusSelected,
    this.onDateRangeSelected,
    this.onStatusAndDateRangeSelected,
    this.initialManagers,
    this.initialLeads,
    this.initialStatuses,
    this.initialFromDate,
    this.initialToDate,
    this.initialDaysWithoutActivity,
    this.onResetFilters,
    this.initialHasTasks,
    this.initialDirectoryValues,
    this.initialDealNames,
    this.customFieldTitles,
    this.customFieldValues,
    this.initialCustomFieldSelections,
  }) : super(key: key);

  @override
  _DealManagerFilterScreenState createState() => _DealManagerFilterScreenState();
}

class _DealManagerFilterScreenState extends State<DealManagerFilterScreen> {
  final ApiService _apiService = ApiService();

  // Custom fields (deal) loaded inside the filter screen
  List<String> _customFieldTitles = [];
  Map<String, List<String>> _customFieldValues = {};
  List<FieldConfiguration> _fieldConfigurations = [];
  bool _isConfigurationLoaded = false;

  List _selectedManagers = [];
  List _selectedLeads = [];
  int? _selectedStatuses;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool? _hasTasks;
  int? _daysWithoutActivity;
  DateTime? _createAt;
  Map<int, MainField?> _selectedDirectoryFields = {};
  List<DirectoryLink> _directoryLinks = [];
  List<DealNameData> _selectedDealNames = [];
  Map<String, List<String>> _selectedCustomFieldValues = {};

  void _initializeCustomFieldSelections(Map<String, List<String>> initialSelections) {
    final titles = _customFieldTitles;

    if (titles.isEmpty) {
      _selectedCustomFieldValues = {
        for (final entry in initialSelections.entries)
          entry.key: List<String>.from(entry.value),
      };
      return;
    }

    _selectedCustomFieldValues = {};
    for (final title in titles) {
      final initial = initialSelections[title];
      _selectedCustomFieldValues[title] =
          initial != null ? List<String>.from(initial) : <String>[];
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFieldConfiguration();
    });
    _selectedManagers = widget.initialManagers ?? [];
    _selectedLeads = widget.initialLeads ?? [];
    _selectedStatuses = widget.initialStatuses;
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _daysWithoutActivity = widget.initialDaysWithoutActivity;
    _hasTasks = widget.initialHasTasks;
    _selectedDealNames = widget.initialDealNames
            ?.map((name) => DealNameData(id: 0, title: name))
            .toList() ?? [];
    _loadFilterState();
    _fetchDirectoryLinks();
    // Prefill from props if provided (backward compatible)
    if ((widget.customFieldTitles ?? const []).isNotEmpty) {
      _customFieldTitles = List<String>.from(widget.customFieldTitles!);
    }
    if ((widget.customFieldValues ?? const {}).isNotEmpty) {
      _customFieldValues = Map<String, List<String>>.from(widget.customFieldValues!);
    }
    _initializeCustomFieldSelections(widget.initialCustomFieldSelections ?? const {});
    _loadDealCustomFields();
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDirectoryFields = (jsonDecode(prefs.getString('deal_selected_directory_fields') ?? '{}') as Map)
          .map((key, value) => MapEntry(int.parse(key), value != null ? MainField.fromJson(jsonDecode(value)) : null));
      _selectedDealNames = (jsonDecode(prefs.getString('deal_selected_names') ?? '[]') as List)
          .map((name) => DealNameData(id: 0, title: name))
          .toList();
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deal_selected_directory_fields',
        jsonEncode(_selectedDirectoryFields.map((key, value) => MapEntry(key.toString(), value?.toJson()))));
    await prefs.setString('deal_selected_names',
        jsonEncode(_selectedDealNames.map((dealName) => dealName.title).toList()));
  }

  Future<void> _fetchDirectoryLinks() async {
    try {
      final response = await _apiService.getDealDirectoryLinks();
      if (response.data != null) {
        setState(() {
          _directoryLinks = response.data!;
          final initialDirectoryValues = widget.initialDirectoryValues ?? const [];
          final updatedSelections = <int, MainField?>{};

          for (var link in _directoryLinks) {
            if (_selectedDirectoryFields.containsKey(link.id)) {
              updatedSelections[link.id] = _selectedDirectoryFields[link.id];
              continue;
            }

            final initialSelections = initialDirectoryValues
                .where((value) => value['directory_id'] == link.directory.id)
                .map((value) {
                  final entryIdRaw = value['entry_id'];
                  final int? entryId = entryIdRaw is int
                      ? entryIdRaw
                      : int.tryParse(entryIdRaw?.toString() ?? '');
                  if (entryId == null) {
                    return null;
                  }
                  final entryValue = value['entry_name']?.toString() ??
                      value['entry_value']?.toString() ??
                      value['value']?.toString() ??
                      '';
                  if (entryValue.isEmpty) {
                    return null;
                  }
                  return MainField(id: entryId, value: entryValue);
                })
                .whereType<MainField>()
                .toList();

            updatedSelections[link.id] =
                initialSelections.isNotEmpty ? initialSelections.first : null;
          }

          _selectedDirectoryFields = updatedSelections;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке справочников: $e')),
      );
    }
  }

  // -------- DEAL custom fields loading (moved here from app bar) --------
  Future<void> _loadDealCustomFields() async {
    try {
      final titles = await _apiService.getDealCustomFields();
      if (!mounted) return;
      setState(() {
        _customFieldTitles = titles;
      });
      _initializeCustomFieldSelections(widget.initialCustomFieldSelections ?? const {});
      for (final title in titles) {
        unawaited(_loadSingleDealCustomField(title));
      }
    } catch (_) {
      // ignore errors silently to not break filter UI
    }
  }

  Future<void> _loadSingleDealCustomField(String title) async {
    try {
      final values = await _apiService.getDealCustomFieldValues(title);
      if (!mounted) return;
      setState(() {
        _customFieldValues[title] = values;
        _selectedCustomFieldValues[title] =
            _selectedCustomFieldValues[title] ?? <String>[];
      });
    } catch (_) {
      // ignore per-field loading errors
    }
  }

  Future<void> _loadFieldConfiguration() async {
    try {
      final response = await _apiService.getFieldPositions(tableName: 'deals');
      if (!mounted) return;

      final activeFields = response.result
          .where((field) => field.isActive)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));

      setState(() {
        _fieldConfigurations = activeFields;
        _isConfigurationLoaded = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isConfigurationLoaded = true;
        });
      }
    }
  }

  Widget? _buildFieldWidgetByConfig(FieldConfiguration config) {
    switch (config.fieldName) {
      case 'name':
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DealNamesMultiSelectWidget(
              selectedDealNames: _selectedDealNames.map((dealName) => dealName.title).toList(),
              onSelectDealNames: (List<DealNameData> selectedDealNamesData) {
                setState(() {
                  _selectedDealNames = selectedDealNamesData;
                });
              },
            ),
          ),
        );
      case 'manager_id':
        return Card(
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
        );
      case 'lead_id':
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: LeadMultiSelectWidget(
              selectedLeads: _selectedLeads.map((lead) => lead.id.toString()).toList(),
              onSelectLeads: (List<LeadData> selectedUsersData) {
                setState(() {
                  _selectedLeads = selectedUsersData;
                });
              },
            ),
          ),
        );
      case 'deal_status_id':
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DealStatusRadioGroupWidget(
              selectedStatus: _selectedStatuses?.toString(),
              onSelectStatus: (DealStatus selectedStatusData) {
                setState(() {
                  _selectedStatuses = selectedStatusData.id;
                });
              },
            ),
          ),
        );
      default:
        if (config.isCustomField && _customFieldTitles.contains(config.fieldName)) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CustomFieldMultiSelect(
                title: config.fieldName,
                items: List<String>.from(_customFieldValues[config.fieldName] ?? const []),
                initialSelectedValues: _selectedCustomFieldValues[config.fieldName],
                onChanged: (values) {
                  setState(() {
                    _selectedCustomFieldValues[config.fieldName] = List<String>.from(values);
                  });
                },
              ),
            ),
          );
        }

        if (config.isDirectory && config.directoryId != null) {
          try {
            final link = _directoryLinks.firstWhere(
              (l) => l.directory.id == config.directoryId,
            );

            return Card(
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
            );
          } catch (_) {
            return null;
          }
        }

        return null;
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
      inactiveTrackColor: const Color.fromARGB(255, 179, 179, 179).withOpacity(0.5),
      activeTrackColor: ChatSmsStyles.messageBubbleSenderColor,
      inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
    );
  }

  void _selectCreateAt() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _createAt ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            scaffoldBackgroundColor: Colors.white,
            dialogBackgroundColor: Colors.white,
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _createAt = picked;
      });
    }
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF4F7FD),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('filter'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
            fontFamily: 'Gilroy',
          ),
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
                _selectedLeads.clear();
                _selectedStatuses = null;
                _fromDate = null;
                _toDate = null;
                _daysWithoutActivity = null;
                _hasTasks = null;
                _selectedDirectoryFields.clear();
                _selectedDealNames.clear();
                _selectedCustomFieldValues.clear();
                for (var link in _directoryLinks) {
                  _selectedDirectoryFields[link.id] = null;
                }
                _initializeCustomFieldSelections(const {});
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
              await _saveFilterState();
              await DealCache.clearAllDeals();
              Map<String, dynamic> filterData = {
                'managers': _selectedManagers,
                'leads': _selectedLeads,
                'statuses': _selectedStatuses,
                'fromDate': _fromDate,
                'toDate': _toDate,
                'daysWithoutActivity': _daysWithoutActivity,
                'hasTask': _hasTasks,
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
                'names': _selectedDealNames.map((dealName) => dealName.title).toList(), // Добавляем names
              };
              final customFieldFilters = <String, List<String>>{};
              _selectedCustomFieldValues.forEach((key, values) {
                if (values.isNotEmpty) {
                  customFieldFilters[key] = List<String>.from(values);
                }
              });
              if (customFieldFilters.isNotEmpty) {
                filterData['custom_field_filters'] = customFieldFilters;
              }
              if (_selectedManagers.isNotEmpty ||
                  _selectedLeads.isNotEmpty ||
                  _selectedStatuses != null ||
                  _fromDate != null ||
                  _toDate != null ||
                  _daysWithoutActivity != null ||
                  _hasTasks != null ||
                  _selectedDirectoryFields.values.any((field) => field != null) ||
                  _selectedDealNames.isNotEmpty ||
                  customFieldFilters.isNotEmpty) {
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
                    if (_isConfigurationLoaded && _fieldConfigurations.isNotEmpty)
                      ..._fieldConfigurations.map((config) {
                        final widget = _buildFieldWidgetByConfig(config);
                        if (widget == null) return SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: widget,
                        );
                      })
                    else if (!_isConfigurationLoaded)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      ...[
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: DealNamesMultiSelectWidget(
                              selectedDealNames: _selectedDealNames.map((dealName) => dealName.title).toList(),
                              onSelectDealNames: (List<DealNameData> selectedDealNamesData) {
                                setState(() {
                                  _selectedDealNames = selectedDealNamesData;
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
                            child: LeadMultiSelectWidget(
                              selectedLeads: _selectedLeads.map((lead) => lead.id.toString()).toList(),
                              onSelectLeads: (List<LeadData> selectedUsersData) {
                                setState(() {
                                  _selectedLeads = selectedUsersData;
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
                            child: DealStatusRadioGroupWidget(
                              selectedStatus: _selectedStatuses?.toString(),
                              onSelectStatus: (DealStatus selectedStatusData) {
                                setState(() {
                                  _selectedStatuses = selectedStatusData.id;
                                });
                              },
                            ),
                          ),
                        ),
                        if (_customFieldTitles.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          for (final title in _customFieldTitles)
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: CustomFieldMultiSelect(
                                  title: title,
                                  items: List<String>.from(_customFieldValues[title] ?? const []),
                                  initialSelectedValues: _selectedCustomFieldValues[title],
                                  onChanged: (values) {
                                    setState(() {
                                      _selectedCustomFieldValues[title] = List<String>.from(values);
                                    });
                                  },
                                ),
                              ),
                            ),
                        ],
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
                      ],
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('hasTask'),
                            _hasTasks ?? false,
                            (value) => setState(() {
                              _hasTasks = value;
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.translate('daysWithoutActivity'),
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