import 'dart:async';
import 'dart:convert';

import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

import 'package:crm_task_manager/custom_widget/filter/common/multi_reason_for_refusal_list.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/deal_NamesMultiSelectWidget.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/deal_status_list.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/multi_executor_list.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/multi_lead_status_list.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/lead_manager_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_city_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_manager_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_source_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_directory_dropdown_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/state_single_select_widget.dart';
import 'package:crm_task_manager/models/lead/LeadStatusForFilter.dart';
import 'package:crm_task_manager/models/lead/city_model.dart';
import 'package:crm_task_manager/models/deal/deal_model.dart';
import 'package:crm_task_manager/models/deal/deal_name_list.dart';
import 'package:crm_task_manager/models/task/directory_link_model.dart';
import 'package:crm_task_manager/models/lead/lead_multi_model.dart';
import 'package:crm_task_manager/models/field/field_configuration.dart';
import 'package:crm_task_manager/models/lead/manager_model.dart';
import 'package:crm_task_manager/models/lead/region_model.dart';
import 'package:crm_task_manager/models/field/main_field_model.dart';
import 'package:crm_task_manager/models/lead/reason_for_refusal_model.dart';
import 'package:crm_task_manager/models/lead/source_list_model.dart';
import 'package:crm_task_manager/models/user/user_data_response.dart';
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
  final List? initialRegions;
  final RegionData? initialState;
  final List? initialCities;
  final List? initialExecutors;
  final List? initialSources;
  final List? initialLeads;
  final int? initialStatuses;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final VoidCallback? onResetFilters;
  final int? initialDaysWithoutActivity;
  final bool? initialHasTasks;
  final bool? initialWithoutNotices;
  final bool? initialOverdueNotices;
  final List<int>? initialLeadStatuses;
  final List<int>? initialReasonForRefusalIds;
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
    this.initialRegions,
    this.initialState,
    this.initialCities,
    this.initialExecutors,
    this.initialSources,
    this.initialLeads,
    this.initialStatuses,
    this.initialFromDate,
    this.initialToDate,
    this.initialDaysWithoutActivity,
    this.onResetFilters,
    this.initialHasTasks,
    this.initialWithoutNotices,
    this.initialOverdueNotices,
    this.initialLeadStatuses,
    this.initialReasonForRefusalIds,
    this.initialDirectoryValues,
    this.initialDealNames,
    this.customFieldTitles,
    this.customFieldValues,
    this.initialCustomFieldSelections,
  }) : super(key: key);

  @override
  _DealManagerFilterScreenState createState() =>
      _DealManagerFilterScreenState();
}

class _DealManagerFilterScreenState extends State<DealManagerFilterScreen> {
  final ApiService _apiService = ApiService();

  // Custom fields (deal) loaded inside the filter screen
  List<String> _customFieldTitles = [];
  Map<String, List<String>> _customFieldValues = {};
  Map<String, bool> _customFieldLoadingStates = {};
  List<FieldConfiguration> _fieldConfigurations = [];
  bool _isConfigurationLoaded = false;
  bool _askReasonForRefusal = false;
  bool _isInitialScreenLoading = true;

  List _selectedManagers = [];
  List _selectedRegions = [];
  RegionData? _selectedState;
  List _selectedCities = [];
  List<UserData> _selectedExecutors = [];
  List<SourceData> _selectedSources = [];
  List _selectedLeads = [];
  int? _selectedStatuses;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool? _hasTasks;
  bool _withoutNotices = false;
  bool _overdueNotices = false;
  bool _createTaskInDealEnabled = false;
  int? _daysWithoutActivity;
  List<LeadStatusForFilter> _selectedLeadStatuses = [];
  List<ReasonForRefusalData> _selectedReasonForRefusals = [];
  Map<int, List<MainField>> _selectedDirectoryFields = {};
  List<DirectoryLink> _directoryLinks = [];
  List<DealNameData> _selectedDealNames = [];
  Map<String, List<String>> _selectedCustomFieldValues = {};

  void _initializeCustomFieldSelections(
      Map<String, List<String>> initialSelections) {
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
      _initializeFilterScreen();
    });
    _selectedManagers = widget.initialManagers ?? [];
    _selectedRegions = widget.initialRegions ?? [];
    _selectedState = widget.initialState;
    _selectedCities = widget.initialCities ?? [];
    _selectedExecutors =
        List<UserData>.from(widget.initialExecutors ?? const <UserData>[]);
    _selectedSources =
        List<SourceData>.from(widget.initialSources ?? const <SourceData>[]);
    _selectedLeads = widget.initialLeads ?? [];
    _selectedStatuses = widget.initialStatuses;
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _daysWithoutActivity = widget.initialDaysWithoutActivity;
    _hasTasks = widget.initialHasTasks;
    _withoutNotices = widget.initialWithoutNotices ?? false;
    _overdueNotices = widget.initialOverdueNotices ?? false;
    _selectedLeadStatuses = (widget.initialLeadStatuses ?? const [])
        .map((id) => LeadStatusForFilter(id: id, title: ''))
        .toList();
    if (widget.initialReasonForRefusalIds != null) {
      _selectedReasonForRefusals = widget.initialReasonForRefusalIds!
          .map((id) => ReasonForRefusalData(id: id, text: '', type: 'deal'))
          .toList();
    }
    _selectedDealNames = widget.initialDealNames
            ?.map((name) => DealNameData(id: 0, title: name))
            .toList() ??
        [];
    // Prefill from props if provided (backward compatible)
    if ((widget.customFieldTitles ?? const []).isNotEmpty) {
      _customFieldTitles = List<String>.from(widget.customFieldTitles!);
    }
    if ((widget.customFieldValues ?? const {}).isNotEmpty) {
      _customFieldValues =
          Map<String, List<String>>.from(widget.customFieldValues!);
    }
    _initializeCustomFieldSelections(
        widget.initialCustomFieldSelections ?? const {});
  }

  Future<void> _initializeFilterScreen() async {
    if (mounted) {
      setState(() {
        _isInitialScreenLoading = true;
      });
    }

    try {
      await _apiService.ensureInitialized();
      await Future.wait([
        _loadFieldConfiguration(),
        _loadAskReasonForRefusal(),
        _loadCreateTaskInDealSetting(),
        _loadFilterState(),
        _fetchDirectoryLinks(),
        _loadDealCustomFields(),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _isInitialScreenLoading = false;
        });
      }
    }
  }

  Future<void> _loadAskReasonForRefusal() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _askReasonForRefusal = prefs.getBool('ask_reason_for_refusal') ?? false;
    });
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDirectoryFields =
          (jsonDecode(prefs.getString('deal_selected_directory_fields') ?? '{}')
                  as Map)
              .map((key, value) {
        final list = value as List?;
        if (list == null) return MapEntry(int.parse(key), <MainField>[]);
        return MapEntry(
            int.parse(key),
            list
                .map((item) => MainField.fromJson(item as Map<String, dynamic>))
                .toList());
      });
      _selectedDealNames =
          (jsonDecode(prefs.getString('deal_selected_names') ?? '[]') as List)
              .map((name) => DealNameData(id: 0, title: name))
              .toList();
      final storedSources =
          (jsonDecode(prefs.getString('deal_selected_sources') ?? '[]') as List)
              .map((source) => SourceData.fromJson(source))
              .toList();
      if (_selectedSources.isEmpty) {
        _selectedSources = storedSources;
      }
      _selectedLeadStatuses =
          (jsonDecode(prefs.getString('deal_selected_lead_statuses') ?? '[]')
                  as List)
              .map((id) => LeadStatusForFilter(
                    id: int.tryParse(id.toString()) ?? 0,
                    title: '',
                  ))
              .where((status) => status.id != 0)
              .toList();
      _withoutNotices =
          prefs.getBool('deal_without_notices') ?? _withoutNotices;
      _overdueNotices =
          prefs.getBool('deal_overdue_notices') ?? _overdueNotices;
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'deal_selected_directory_fields',
        jsonEncode(_selectedDirectoryFields.map((key, value) => MapEntry(
            key.toString(), value.map((field) => field.toJson()).toList()))));
    await prefs.setString(
        'deal_selected_names',
        jsonEncode(
            _selectedDealNames.map((dealName) => dealName.title).toList()));
    await prefs.setString('deal_selected_sources',
        jsonEncode(_selectedSources.map((source) => source.toJson()).toList()));
    await prefs.setString(
      'deal_selected_lead_statuses',
      jsonEncode(_selectedLeadStatuses.map((status) => status.id).toList()),
    );
    await prefs.setBool('deal_without_notices', _withoutNotices);
    await prefs.setBool('deal_overdue_notices', _overdueNotices);
  }

  Future<void> _loadCreateTaskInDealSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _createTaskInDealEnabled = prefs.getBool('create_task_in_deal') ?? false;
    });
  }

  Future<void> _fetchDirectoryLinks() async {
    try {
      final response = await _apiService.getDealDirectoryLinks();
      if (response.data != null) {
        setState(() {
          _directoryLinks = response.data!;
          final initialDirectoryValues =
              widget.initialDirectoryValues ?? const [];
          final Map<int, List<MainField>> updatedSelections = {};

          for (var link in _directoryLinks) {
            final existingSelection =
                _selectedDirectoryFields[link.id] ?? const <MainField>[];

            if (existingSelection.isNotEmpty) {
              updatedSelections[link.id] =
                  List<MainField>.from(existingSelection);
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
                  return MainField(id: entryId, value: entryValue);
                })
                .whereType<MainField>()
                .toList();

            updatedSelections[link.id] = initialSelections;
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
      _initializeCustomFieldSelections(
          widget.initialCustomFieldSelections ?? const {});
      await Future.wait([
        for (final title in titles) _loadSingleDealCustomField(title),
      ]);
    } catch (_) {
      // ignore errors silently to not break filter UI
    }
  }

  Future<void> _loadSingleDealCustomField(String title) async {
    if (!mounted) return;
    setState(() {
      _customFieldLoadingStates[title] = true;
    });

    try {
      final values = await _apiService.getDealCustomFieldValues(title);
      if (!mounted) return;
      setState(() {
        _customFieldValues[title] = values;
        _selectedCustomFieldValues[title] =
            _selectedCustomFieldValues[title] ?? <String>[];
        _customFieldLoadingStates[title] = false;
      });
    } catch (_) {
      // ignore per-field loading errors
      if (mounted) {
        setState(() {
          _customFieldLoadingStates[title] = false;
        });
      }
    }
  }

  Future<void> _loadFieldConfiguration() async {
    try {
      final response = await _apiService.getFieldPositions(tableName: 'deals');
      if (!mounted) return;

      final activeFields = response.result
          // .where((field) => field.isActive)
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: context.appColors.surfacePrimary,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DealNamesMultiSelectWidget(
              selectedDealNames:
                  _selectedDealNames.map((dealName) => dealName.title).toList(),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: context.appColors.surfacePrimary,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ManagerMultiSelectWidget(
              selectedManagers: _selectedManagers
                  .map((manager) => manager.id.toString())
                  .toList(),
              onSelectManagers: (List<ManagerData> selectedUsersData) {
                setState(() {
                  _selectedManagers = selectedUsersData;
                });
              },
            ),
          ),
        );
      case 'region_id':
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: context.appColors.surfacePrimary,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: StateSingleSelectWidget(
              selectedState: _selectedState,
              onChanged: (selectedState) {
                setState(() {
                  _selectedState = selectedState;
                  _selectedCities = [];
                });
              },
            ),
          ),
        );
      case 'city_id':
      case 'city':
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: context.appColors.surfacePrimary,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CityMultiSelectWidget(
              parentId: _selectedState?.id,
              selectedCities:
                  _selectedCities.map((city) => city.id.toString()).toList(),
              onSelectCities: (List<CityData> selectedCitiesData) {
                setState(() {
                  _selectedCities = selectedCitiesData;
                });
              },
            ),
          ),
        );
      case 'users':
      case 'user_ids':
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: context.appColors.surfacePrimary,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DealExecutorsMultiSelectWidget(
              selectedExecutors:
                  _selectedExecutors.map((user) => user.id.toString()).toList(),
              onSelectExecutors: (List<UserData> selectedExecutorsData) {
                setState(() {
                  _selectedExecutors = selectedExecutorsData;
                });
              },
            ),
          ),
        );
      case 'lead_id':
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: context.appColors.surfacePrimary,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: LeadMultiSelectWidget(
              selectedLeads: _selectedLeads.map((lead) => lead.id).toList(),
              onSelectLeads: (List<LeadData> selectedUsersData) {
                setState(() {
                  _selectedLeads = selectedUsersData;
                });
              },
            ),
          ),
        );
      case 'source_id':
      case 'source':
        return _buildSourceFilterCard();
      case 'lead_status_id':
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: context.appColors.surfacePrimary,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DealLeadStatusMultiSelectWidget(
              selectedLeadStatuses: _selectedLeadStatuses
                  .map((status) => status.id.toString())
                  .toList(),
              onSelectStatuses: (selectedStatuses) {
                setState(() {
                  _selectedLeadStatuses = List<LeadStatusForFilter>.from(
                    selectedStatuses,
                  );
                });
              },
            ),
          ),
        );
      case 'deal_status_id':
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: context.appColors.surfacePrimary,
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
      case 'reason_for_refusal':
      case 'reason_for_refusal_id':
        if (!_askReasonForRefusal) return null;
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: context.appColors.surfacePrimary,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ReasonForRefusalMultiSelectWidget(
              type: 'deal',
              selectedReasonIds: _selectedReasonForRefusals
                  .map((reason) => reason.id)
                  .toList(),
              onSelectReasons: (selectedReasons) {
                setState(() {
                  _selectedReasonForRefusals = selectedReasons;
                });
              },
            ),
          ),
        );
      default:
        if (config.isCustomField &&
            _customFieldTitles.contains(config.fieldName)) {
          final isLoading = _customFieldLoadingStates[config.fieldName] == true;

          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: context.appColors.surfacePrimary,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CustomFieldMultiSelect(
                title: config.fieldName,
                items: List<String>.from(
                    _customFieldValues[config.fieldName] ?? const []),
                initialSelectedValues:
                    _selectedCustomFieldValues[config.fieldName],
                isLoading: isLoading,
                onChanged: (values) {
                  setState(() {
                    _selectedCustomFieldValues[config.fieldName] =
                        List<String>.from(values);
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: context.appColors.surfacePrimary,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: MultiDirectoryDropdownWidget(
                  directoryId: link.directory.id,
                  directoryName: link.directory.name,
                  onSelectField: (List<MainField> fields) {
                    setState(() {
                      _selectedDirectoryFields[link.id] =
                          List<MainField>.from(fields);
                    });
                  },
                  initialFields: _selectedDirectoryFields[link.id],
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

  Widget _buildLeadStatusFilterCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.appColors.surfacePrimary,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DealLeadStatusMultiSelectWidget(
          selectedLeadStatuses: _selectedLeadStatuses
              .map((status) => status.id.toString())
              .toList(),
          onSelectStatuses: (selectedStatuses) {
            setState(() {
              _selectedLeadStatuses =
                  List<LeadStatusForFilter>.from(selectedStatuses);
            });
          },
        ),
      ),
    );
  }

  Widget _buildSourceFilterCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.appColors.surfacePrimary,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SourcesMultiSelectWidget(
          selectedSources:
              _selectedSources.map((source) => source.id.toString()).toList(),
          onSelectSources: (List<SourceData> selectedSourcesData) {
            setState(() {
              _selectedSources = selectedSourcesData;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: context.appTextStyles.bodyLg.copyWith(
          color: context.appColors.textSecondary,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: context.appColors.buttonPrimaryFg,
      inactiveTrackColor: context.appColors.textMuted.withValues(alpha: 0.5),
      activeTrackColor: context.appColors.buttonPrimaryBg,
      inactiveThumbColor: context.appColors.buttonPrimaryFg,
    );
  }

  ButtonStyle _buildActionButtonStyle() {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      backgroundColor:
          context.appColors.buttonSecondaryBg.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide(color: context.appColors.buttonPrimaryBg, width: 0.5),
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
        final colors = context.appColors;
        return Theme(
          data: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: colors.surfacePrimary,
            canvasColor: colors.surfacePrimary,
            colorScheme: ColorScheme.dark(
              primary: colors.buttonPrimaryBg,
              onPrimary: colors.buttonPrimaryFg,
              surface: colors.surfacePrimary,
              onSurface: colors.textPrimary,
              secondary: colors.buttonSecondaryBg.withValues(alpha: 0.16),
              onSecondary: colors.textPrimary,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: colors.surfacePrimary,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: colors.surfacePrimary,
              foregroundColor: colors.textPrimary,
              surfaceTintColor: colors.surfacePrimary,
              elevation: 0,
            ),
            dividerColor: colors.borderSubtle,
            textTheme: ThemeData.dark().textTheme.apply(
                  bodyColor: colors.textPrimary,
                  displayColor: colors.textPrimary,
                ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: colors.surfacePrimary,
              surfaceTintColor: colors.surfacePrimary,
              headerBackgroundColor: colors.surfacePrimary,
              headerForegroundColor: colors.textPrimary,
              weekdayStyle: TextStyle(
                color: colors.textPrimary,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
              ),
              dayStyle: TextStyle(
                color: colors.textPrimary,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
              ),
              yearStyle: TextStyle(
                color: colors.textPrimary,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
              ),
              rangePickerHeaderForegroundColor: colors.textPrimary,
              rangePickerBackgroundColor: colors.surfacePrimary,
              rangeSelectionBackgroundColor:
                  colors.buttonPrimaryBg.withValues(alpha: 0.18),
              rangeSelectionOverlayColor: WidgetStatePropertyAll(
                  colors.buttonPrimaryBg.withValues(alpha: 0.10)),
              todayForegroundColor:
                  WidgetStatePropertyAll(colors.buttonPrimaryBg),
              todayBackgroundColor: WidgetStatePropertyAll(
                colors.buttonPrimaryBg.withValues(alpha: 0.12),
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.buttonPrimaryFg;
                }
                return colors.textPrimary;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.buttonPrimaryBg;
                }
                return null;
              }),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
              ),
              confirmButtonStyle: TextButton.styleFrom(
                foregroundColor: colors.buttonPrimaryBg,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: colors.buttonPrimaryBg,
              ),
            ),
          ),
          child: ColoredBox(
            color: colors.surfacePrimary,
            child: child!,
          ),
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
    final hasLeadStatusInConfig = _fieldConfigurations
        .any((config) => config.fieldName == 'lead_status_id');
    final hasRegionInConfig =
        _fieldConfigurations.any((config) => config.fieldName == 'region_id');
    final hasCityInConfig = _fieldConfigurations.any(
      (config) => config.fieldName == 'city_id' || config.fieldName == 'city',
    );
    final hasExecutorsInConfig = _fieldConfigurations.any(
      (config) => config.fieldName == 'users' || config.fieldName == 'user_ids',
    );
    final hasSourceInConfig = _fieldConfigurations.any(
      (config) =>
          config.fieldName == 'source_id' || config.fieldName == 'source',
    );
    final hasReasonForRefusalInConfig = _fieldConfigurations.any(
      (config) =>
          config.fieldName == 'reason_for_refusal' ||
          config.fieldName == 'reason_for_refusal_id',
    );

    return Scaffold(
      backgroundColor: context.appColors.backgroundSecondary,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('filter'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
            fontFamily: 'Gilroy',
          ),
        ),
        backgroundColor: context.appColors.surfacePrimary,
        forceMaterialTransparency: true,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                widget.onResetFilters?.call();
                _selectedManagers.clear();
                _selectedRegions.clear();
                _selectedState = null;
                _selectedCities.clear();
                _selectedExecutors.clear();
                _selectedSources.clear();
                _selectedLeads.clear();
                _selectedStatuses = null;
                _fromDate = null;
                _toDate = null;
                _daysWithoutActivity = null;
                _hasTasks = null;
                _withoutNotices = false;
                _overdueNotices = false;
                _selectedLeadStatuses.clear();
                _selectedReasonForRefusals.clear();
                _selectedDirectoryFields.clear();
                _selectedDealNames.clear();
                _selectedCustomFieldValues.clear();
                for (var link in _directoryLinks) {
                  _selectedDirectoryFields[link.id] = <MainField>[];
                }
                _initializeCustomFieldSelections(const {});
              });
            },
            style: _buildActionButtonStyle(),
            child: Text(
              AppLocalizations.of(context)!.translate('reset'),
              style: context.appTextStyles.labelLg.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appColors.buttonPrimaryBg,
              ),
            ),
          ),
          SizedBox(width: 10),
          TextButton(
            onPressed: () async {
              await _saveFilterState();
              await DealCache.clearAllDeals();
              final directoryIdByLinkId = {
                for (var link in _directoryLinks) link.id: link.directory.id,
              };

              Map<String, dynamic> filterData = {
                'managers': _selectedManagers,
                'regions': _selectedRegions,
                'state': _selectedState,
                'cities': _selectedCities,
                'executors': _selectedExecutors,
                'sources': _selectedSources,
                'leads': _selectedLeads,
                'statuses': _selectedStatuses,
                'fromDate': _fromDate,
                'toDate': _toDate,
                'daysWithoutActivity': _daysWithoutActivity,
                'hasTask': _hasTasks,
                'withoutNotices': _withoutNotices,
                'overdueNotices': _overdueNotices,
                'leadStatuses':
                    _selectedLeadStatuses.map((status) => status.id).toList(),
                'reason_for_refusal_ids': _selectedReasonForRefusals
                    .map((reason) => reason.id)
                    .toList(),
                'directory_values':
                    _selectedDirectoryFields.entries.expand((entry) {
                  final directoryId = directoryIdByLinkId[entry.key];
                  if (directoryId == null || entry.value.isEmpty) {
                    return const Iterable<Map<String, dynamic>>.empty();
                  }
                  return entry.value.map((field) => {
                        'directory_id': directoryId,
                        'entry_id': field.id,
                      });
                }).toList(),
                'names': _selectedDealNames
                    .map((dealName) => dealName.title)
                    .toList(), // Добавляем names
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
                  _selectedRegions.isNotEmpty ||
                  _selectedState != null ||
                  _selectedCities.isNotEmpty ||
                  _selectedExecutors.isNotEmpty ||
                  _selectedSources.isNotEmpty ||
                  _selectedLeads.isNotEmpty ||
                  _selectedStatuses != null ||
                  _fromDate != null ||
                  _toDate != null ||
                  _daysWithoutActivity != null ||
                  _hasTasks != null ||
                  _withoutNotices ||
                  _overdueNotices ||
                  _selectedLeadStatuses.isNotEmpty ||
                  _selectedReasonForRefusals.isNotEmpty ||
                  _selectedDirectoryFields.values
                      .any((fields) => fields.isNotEmpty) ||
                  _selectedDealNames.isNotEmpty ||
                  customFieldFilters.isNotEmpty) {
                widget.onManagersSelected?.call(filterData);
              }
              Navigator.pop(context);
            },
            style: _buildActionButtonStyle(),
            child: Text(
              AppLocalizations.of(context)!.translate('apply'),
              style: context.appTextStyles.labelLg.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appColors.buttonPrimaryBg,
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isInitialScreenLoading
              ? Center(
                  key: const ValueKey('deal-filter-loader'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.translate('loading'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  key: const ValueKey('deal-filter-content'),
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: context.appColors.surfacePrimary,
                      shadowColor: context.appColors.shadowColor,
                      child: GestureDetector(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.appColors.fieldBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.appColors.fieldBorder,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fromDate != null && _toDate != null
                                    ? "${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year} - ${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}"
                                    : AppLocalizations.of(context)!
                                        .translate('select_date_range'),
                                style: context.appTextStyles.bodyMd.copyWith(
                                  color: context.appColors.textSecondary,
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: context.appColors.iconSecondary,
                              ),
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
                            if (_isConfigurationLoaded &&
                                _fieldConfigurations.isNotEmpty)
                              ..._fieldConfigurations.map((config) {
                                final widget =
                                    _buildFieldWidgetByConfig(config);
                                if (widget == null) return SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: widget,
                                );
                              }),
                            if (_isConfigurationLoaded &&
                                _fieldConfigurations.isNotEmpty &&
                                !hasRegionInConfig)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  color: context.appColors.surfacePrimary,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: StateSingleSelectWidget(
                                      selectedState: _selectedState,
                                      onChanged: (selectedState) {
                                        setState(() {
                                          _selectedState = selectedState;
                                          _selectedCities = [];
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            if (_isConfigurationLoaded &&
                                _fieldConfigurations.isNotEmpty &&
                                !hasCityInConfig)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  color: context.appColors.surfacePrimary,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: CityMultiSelectWidget(
                                      parentId: _selectedState?.id,
                                      selectedCities: _selectedCities
                                          .map((city) => city.id.toString())
                                          .toList(),
                                      onSelectCities:
                                          (List<CityData> selectedCitiesData) {
                                        setState(() {
                                          _selectedCities = selectedCitiesData;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            if (_isConfigurationLoaded &&
                                _fieldConfigurations.isNotEmpty &&
                                !hasExecutorsInConfig)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  color: context.appColors.surfacePrimary,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: DealExecutorsMultiSelectWidget(
                                      selectedExecutors: _selectedExecutors
                                          .map((user) => user.id.toString())
                                          .toList(),
                                      onSelectExecutors: (List<UserData>
                                          selectedExecutorsData) {
                                        setState(() {
                                          _selectedExecutors =
                                              selectedExecutorsData;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            if (_isConfigurationLoaded &&
                                _fieldConfigurations.isNotEmpty &&
                                !hasSourceInConfig)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildSourceFilterCard(),
                              ),
                            if (_isConfigurationLoaded &&
                                _fieldConfigurations.isNotEmpty &&
                                _askReasonForRefusal &&
                                !hasReasonForRefusalInConfig)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  color: context.appColors.surfacePrimary,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: ReasonForRefusalMultiSelectWidget(
                                      type: 'deal',
                                      selectedReasonIds:
                                          _selectedReasonForRefusals
                                              .map((reason) => reason.id)
                                              .toList(),
                                      onSelectReasons: (selectedReasons) {
                                        setState(() {
                                          _selectedReasonForRefusals =
                                              selectedReasons;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            if (_isConfigurationLoaded &&
                                _fieldConfigurations.isNotEmpty &&
                                !hasLeadStatusInConfig) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildLeadStatusFilterCard(),
                              ),
                            ] else if (!_isConfigurationLoaded)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else ...[
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                color: context.appColors.surfacePrimary,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SourcesMultiSelectWidget(
                                    selectedSources: _selectedSources
                                        .map((source) => source.id.toString())
                                        .toList(),
                                    onSelectSources:
                                        (List<SourceData> selectedSourcesData) {
                                      setState(() {
                                        _selectedSources = selectedSourcesData;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                color: context.appColors.surfacePrimary,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: DealNamesMultiSelectWidget(
                                    selectedDealNames: _selectedDealNames
                                        .map((dealName) => dealName.title)
                                        .toList(),
                                    onSelectDealNames: (List<DealNameData>
                                        selectedDealNamesData) {
                                      setState(() {
                                        _selectedDealNames =
                                            selectedDealNamesData;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildLeadStatusFilterCard(),
                              if (_askReasonForRefusal) ...[
                                const SizedBox(height: 8),
                                Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  color: context.appColors.surfacePrimary,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: ReasonForRefusalMultiSelectWidget(
                                      type: 'deal',
                                      selectedReasonIds:
                                          _selectedReasonForRefusals
                                              .map((reason) => reason.id)
                                              .toList(),
                                      onSelectReasons: (selectedReasons) {
                                        setState(() {
                                          _selectedReasonForRefusals =
                                              selectedReasons;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                color: context.appColors.surfacePrimary,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: ManagerMultiSelectWidget(
                                    selectedManagers: _selectedManagers
                                        .map((manager) => manager.id.toString())
                                        .toList(),
                                    onSelectManagers:
                                        (List<ManagerData> selectedUsersData) {
                                      setState(() {
                                        _selectedManagers = selectedUsersData;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                color: context.appColors.surfacePrimary,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: LeadMultiSelectWidget(
                                    selectedLeads: _selectedLeads
                                        .map((lead) => lead.id)
                                        .toList(),
                                    onSelectLeads:
                                        (List<LeadData> selectedUsersData) {
                                      setState(() {
                                        _selectedLeads = selectedUsersData;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                color: context.appColors.surfacePrimary,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: DealStatusRadioGroupWidget(
                                    selectedStatus:
                                        _selectedStatuses?.toString(),
                                    onSelectStatus:
                                        (DealStatus selectedStatusData) {
                                      setState(() {
                                        _selectedStatuses =
                                            selectedStatusData.id;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              if (_customFieldTitles.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                for (final title in _customFieldTitles)
                                  Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    color: context.appColors.surfacePrimary,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: CustomFieldMultiSelect(
                                        title: title,
                                        items: List<String>.from(
                                            _customFieldValues[title] ??
                                                const []),
                                        initialSelectedValues:
                                            _selectedCustomFieldValues[title],
                                        isLoading:
                                            _customFieldLoadingStates[title] ==
                                                true,
                                        onChanged: (values) {
                                          setState(() {
                                            _selectedCustomFieldValues[title] =
                                                List<String>.from(values);
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                              if (_directoryLinks.isNotEmpty) ...[
                                for (var link in _directoryLinks)
                                  Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    color: context.appColors.surfacePrimary,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: MultiDirectoryDropdownWidget(
                                        directoryId: link.directory.id,
                                        directoryName: link.directory.name,
                                        onSelectField:
                                            (List<MainField> fields) {
                                          setState(() {
                                            _selectedDirectoryFields[link.id] =
                                                List<MainField>.from(fields);
                                          });
                                        },
                                        initialFields:
                                            _selectedDirectoryFields[link.id],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                              ],
                            ],
                            if (!_isConfigurationLoaded ||
                                _fieldConfigurations.isEmpty) ...[
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                color: context.appColors.surfacePrimary,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: StateSingleSelectWidget(
                                    selectedState: _selectedState,
                                    onChanged: (selectedState) {
                                      setState(() {
                                        _selectedState = selectedState;
                                        _selectedCities = [];
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                color: context.appColors.surfacePrimary,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: CityMultiSelectWidget(
                                    parentId: _selectedState?.id,
                                    selectedCities: _selectedCities
                                        .map((city) => city.id.toString())
                                        .toList(),
                                    onSelectCities:
                                        (List<CityData> selectedCitiesData) {
                                      setState(() {
                                        _selectedCities = selectedCitiesData;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                color: context.appColors.surfacePrimary,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: DealExecutorsMultiSelectWidget(
                                    selectedExecutors: _selectedExecutors
                                        .map((user) => user.id.toString())
                                        .toList(),
                                    onSelectExecutors:
                                        (List<UserData> selectedExecutorsData) {
                                      setState(() {
                                        _selectedExecutors =
                                            selectedExecutorsData;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              color: context.appColors.surfacePrimary,
                              child: Column(
                                children: [
                                  _buildSwitchTile(
                                    AppLocalizations.of(context)!
                                        .translate('hasTask'),
                                    _hasTasks ?? false,
                                    (value) => setState(() {
                                      _hasTasks = value;
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_createTaskInDealEnabled)
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                color: context.appColors.surfacePrimary,
                                child: _buildSwitchTile(
                                  AppLocalizations.of(context)!
                                      .translate('deals_without_next_stage'),
                                  _withoutNotices,
                                  (value) => setState(() {
                                    _withoutNotices = value;
                                  }),
                                ),
                              ),
                            if (_createTaskInDealEnabled)
                              const SizedBox(height: 8),
                            if (_createTaskInDealEnabled)
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                color: context.appColors.surfacePrimary,
                                child: _buildSwitchTile(
                                  AppLocalizations.of(context)!
                                      .translate('deals_with_overdue_tasks'),
                                  _overdueNotices,
                                  (value) => setState(() {
                                    _overdueNotices = value;
                                  }),
                                ),
                              ),
                            if (_createTaskInDealEnabled)
                              const SizedBox(height: 8),
                            Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              color: context.appColors.surfacePrimary,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 12, right: 12, top: 4, bottom: 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .translate('daysWithoutActivity'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Gilroy',
                                        color: context.appColors.textPrimary,
                                      ),
                                    ),
                                    Slider(
                                      value: (_daysWithoutActivity ?? 0)
                                          .toDouble(),
                                      min: 0,
                                      max: 100,
                                      divisions: 100,
                                      label: _daysWithoutActivity.toString(),
                                      onChanged: (double value) {
                                        setState(() {
                                          _daysWithoutActivity = value.toInt();
                                        });
                                      },
                                      activeColor: context.appColors.buttonPrimaryBg,
                                      inactiveColor: context.appColors.textMuted
                                          .withValues(alpha: 0.5),
                                    ),
                                    Center(
                                      child: Text(
                                        "${_daysWithoutActivity ?? '0'}",
                                        style: TextStyle(
                                          fontSize: 20, 
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Gilroy',
                                          color: context.appColors.textPrimary,
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
      ),
    );
  }
}
