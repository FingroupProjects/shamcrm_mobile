import 'dart:async';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/custom_field_multi_select.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_manager_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_region_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_source_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_directory_dropdown_widget.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/models/source_list_model.dart';
import 'package:crm_task_manager/models/directory_link_model.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
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
  final bool? initialHasOrders;
  final bool? initialUnreadOnly;
  final int? initialDaysWithoutActivity;
  final VoidCallback? onResetFilters;
  final List<Map<String, dynamic>>? initialDirectoryValues;
  final List<String>? customFieldTitles;
  final Map<String, List<String>>? customFieldValues;
  final Map<String, List<String>>? initialCustomFieldSelections;


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
    this.initialHasOrders,
    this.initialUnreadOnly, // ИЗМЕНЕНО: Добавили параметр для фильтрации по непрочитанным сообщениям
    this.initialDaysWithoutActivity,
    this.onResetFilters,
    this.initialDirectoryValues, 
    this.customFieldTitles,
    this.customFieldValues,
    this.initialCustomFieldSelections,
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
  bool? _hasOrders;

  int? _daysWithoutActivity;

  Map<int, List<MainField>> _selectedDirectoryFields = {};
  List<DirectoryLink> _directoryLinks = [];
  Map<String, List<String>> _selectedCustomFieldValues = {};
  // Пользовательские поля лидов
  final ApiService _apiService = ApiService();
  List<String> _customFieldTitles = [];
  Map<String, List<String>> _customFieldValues = {};
  
  // Field configuration
  List<FieldConfiguration> _fieldConfigurations = [];
  bool _isConfigurationLoaded = false;

  void _initializeCustomFieldSelections(Map<String, List<String>> initialSelections) {
    final titles = _customFieldTitles;
    _selectedCustomFieldValues = {};
    for (final title in titles) {
      final initial = initialSelections[title];
      _selectedCustomFieldValues[title] =
          initial != null ? List<String>.from(initial) : <String>[];
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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFieldConfiguration();
    });
    
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
    _hasOrders = widget.initialHasOrders;
    _daysWithoutActivity = widget.initialDaysWithoutActivity;
    _fetchDirectoryLinks();
    _initializeCustomFieldSelections(
        widget.initialCustomFieldSelections ?? const <String, List<String>>{});
    _loadLeadCustomFields();
  }

  Future<void> _fetchDirectoryLinks() async {
    try {
      final response = await ApiService().getLeadDirectoryLinks();
      if (response.data != null) {
        setState(() {
          _directoryLinks = response.data!;
          final initialDirectoryValues = widget.initialDirectoryValues ?? const [];
          final Map<int, List<MainField>> updatedSelections = {};

          for (var link in _directoryLinks) {
            final existingSelection = _selectedDirectoryFields[link.id] ?? const <MainField>[];

            if (existingSelection.isNotEmpty) {
              updatedSelections[link.id] = List<MainField>.from(existingSelection);
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

  Future<void> _loadLeadCustomFields() async {
    try {
      final titles = await _apiService.getLeadCustomFields();
      if (!mounted) return;
      setState(() {
        _customFieldTitles = titles;
      });
      // Инициализируем выбранные значения на основе входящих selection'ов, когда появились заголовки
      _initializeCustomFieldSelections(
          widget.initialCustomFieldSelections ?? const <String, List<String>>{});
      for (final title in titles) {
        unawaited(_loadSingleCustomField(title));
      }
    } catch (e) {
      // проглатываем, показывать UI всё равно можно
    }
  }

  Future<void> _loadSingleCustomField(String title) async {
    try {
      final values = await _apiService.getLeadCustomFieldValues(title);
      if (!mounted) return;
      setState(() {
        _customFieldValues[title] = values;
      });
    } catch (e) {
      // игнорируем отдельные ошибки загрузки полей
    }
  }

  Future<void> _loadFieldConfiguration() async {
    try {
      final response = await _apiService.getFieldPositions(tableName: 'leads');
      if (!mounted) return;
      
      // Фильтруем только активные поля и сортируем по position
      final activeFields = response.result
          .where((field) => field.isActive)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));
      
      setState(() {
        _fieldConfigurations = activeFields;
        _isConfigurationLoaded = true;
      });
    } catch (e) {
      // В случае ошибки показываем поля в стандартном порядке
      if (mounted) {
        setState(() {
          _isConfigurationLoaded = true;
        });
      }
    }
  }

  Widget? _buildFieldWidgetByConfig(FieldConfiguration config) {
    switch (config.fieldName) {
      case 'manager_id':
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ManagerMultiSelectWidget(
              selectedManagers: _selectedManagers.map((m) => m.id.toString()).toList(),
              onSelectManagers: (List<ManagerData> selectedUsersData) {
                setState(() => _selectedManagers = selectedUsersData);
              },
            ),
          ),
        );
        
      case 'region_id':
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: RegionsMultiSelectWidget(
              selectedRegions: _selectedRegions.map((r) => r.id.toString()).toList(),
              onSelectRegions: (List<RegionData> selectedRegionsData) {
                setState(() => _selectedRegions = selectedRegionsData);
              },
            ),
          ),
        );
        
      case 'source_id':
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SourcesMultiSelectWidget(
              selectedSources: _selectedSources.map((s) => s.id.toString()).toList(),
              onSelectSources: (List<SourceData> selectedSourcesData) {
                setState(() => _selectedSources = selectedSourcesData);
              },
            ),
          ),
        );
        
      default:
        // Проверяем custom field
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
        
        // Проверяем directory
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
                child: MultiDirectoryDropdownWidget(
                  directoryId: link.directory.id,
                  directoryName: link.directory.name,
                  onSelectField: (List<MainField> fields) {
                    setState(() {
                      _selectedDirectoryFields[link.id] = List<MainField>.from(fields);
                    });
                  },
                  initialFields: _selectedDirectoryFields[link.id],
                ),
              ),
            );
          } catch (e) {
            // Директория не найдена в списке, пропускаем
            return null;
          }
        }
        
        return null;
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
                _hasOrders = false;
                _daysWithoutActivity = null;
                _selectedDirectoryFields.clear();
                for (var link in _directoryLinks) {
                  _selectedDirectoryFields[link.id] = <MainField>[];
                }
                _initializeCustomFieldSelections(const <String, List<String>>{});
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
              final directoryIdByLinkId = {
                for (var link in _directoryLinks) link.id: link.directory.id,
              };

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
                'hasOrders': _hasOrders,
                'daysWithoutActivity': _daysWithoutActivity,
                'directory_values': _selectedDirectoryFields.entries
                    .expand((entry) {
                      final directoryId = directoryIdByLinkId[entry.key];
                      if (directoryId == null || entry.value.isEmpty) {
                        return const Iterable<Map<String, dynamic>>.empty();
                      }
                      return entry.value.map((field) => {
                            'directory_id': directoryId,
                            'entry_id': field.id,
                          });
                    })
                    .toList(),
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
                  _hasOrders == true ||
                  _daysWithoutActivity != null ||
                  _selectedDirectoryFields.values.any((fields) => fields.isNotEmpty) ||
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
                    // Поля по position из field configuration
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
                      // Показываем loader пока грузится конфигурация
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      // Fallback: показываем поля в стандартном порядке если конфигурация пуста
                      ...[
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: ManagerMultiSelectWidget(
                              selectedManagers: _selectedManagers.map((m) => m.id.toString()).toList(),
                              onSelectManagers: (List<ManagerData> selectedUsersData) {
                                setState(() => _selectedManagers = selectedUsersData);
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
                              selectedRegions: _selectedRegions.map((r) => r.id.toString()).toList(),
                              onSelectRegions: (List<RegionData> selectedRegionsData) {
                                setState(() => _selectedRegions = selectedRegionsData);
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
                              selectedSources: _selectedSources.map((s) => s.id.toString()).toList(),
                              onSelectSources: (List<SourceData> selectedSourcesData) {
                                setState(() => _selectedSources = selectedSourcesData);
                              },
                            ),
                          ),
                        ),
                      ],
                    
                    // Switches - всегда в конце
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
                          _buildSwitchTile(
                            AppLocalizations.of(context)?.translate('withOrders') ?? 'С заказами',
                            _hasOrders ?? false,
                            (value) => setState(() => _hasOrders = value),
                          ),
                        ],
                      ),
                    ),
                    
                    // Days without activity slider - всегда последний
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