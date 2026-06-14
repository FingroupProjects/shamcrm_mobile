import 'dart:async';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_field_multi_select.dart';
import 'package:crm_task_manager/custom_widget/filter/common/multi_reason_for_refusal_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_manager_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_city_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_channel_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_advertising_campaign_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_source_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_directory_dropdown_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/state_single_select_widget.dart';
import 'package:crm_task_manager/models/advertising_campaign_model.dart';
import 'package:crm_task_manager/models/city_model.dart';
import 'package:crm_task_manager/models/lead_filter_channel_model.dart';
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
import 'package:crm_task_manager/models/reason_for_refusal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagerFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onManagersSelected;
  final List? initialManagers;
  final List? initialRegions;
  final RegionData? initialState;
  final List? initialCities;
  final List? initialSources;
  final List? initialChannels;
  final List? initialAdvertisingCampaigns;
  final List<int>? initialReasonForRefusalIds;
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
  final int? initialNumberOfDaysDeal;
  final VoidCallback? onResetFilters;
  final List<Map<String, dynamic>>? initialDirectoryValues;
  final List<String>? customFieldTitles;
  final Map<String, List<String>>? customFieldValues;
  final Map<String, List<String>>? initialCustomFieldSelections;

  const ManagerFilterScreen({
    super.key,
    this.onManagersSelected,
    this.initialManagers,
    this.initialRegions,
    this.initialState,
    this.initialCities,
    this.initialSources,
    this.initialChannels,
    this.initialAdvertisingCampaigns,
    this.initialReasonForRefusalIds,
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
    this.initialNumberOfDaysDeal,
    this.onResetFilters,
    this.initialDirectoryValues,
    this.customFieldTitles,
    this.customFieldValues,
    this.initialCustomFieldSelections,
  });

  @override
  State<ManagerFilterScreen> createState() => _ManagerFilterScreenState();
}

class _ManagerFilterScreenState extends State<ManagerFilterScreen> {
  List _selectedManagers = [];
  List _selectedRegions = [];
  RegionData? _selectedState;
  List _selectedCities = [];
  List _selectedSources = [];
  List _selectedChannels = [];
  List _selectedAdvertisingCampaigns = [];
  List<ReasonForRefusalData> _selectedReasonForRefusals = [];
  bool _askReasonForRefusal = false;

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
  int? _numberOfDaysDeal;

  Map<int, List<MainField>> _selectedDirectoryFields = {};
  List<DirectoryLink> _directoryLinks = [];
  Map<String, List<String>> _selectedCustomFieldValues = {};
  // Пользовательские поля лидов
  final ApiService _apiService = ApiService();
  List<String> _customFieldTitles = [];
  final Map<String, List<String>> _customFieldValues = {};
  final Map<String, bool> _customFieldLoadingStates = {};

  // Field configuration
  List<FieldConfiguration> _fieldConfigurations = [];
  bool _isConfigurationLoaded = false;

  void _initializeCustomFieldSelections(
      Map<String, List<String>> initialSelections) {
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

  Widget _buildFilterCard(
      {required Widget child, EdgeInsetsGeometry? padding}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.appColors.surfacePrimary,
      shadowColor: context.appColors.shadowColor,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(8),
        child: child,
      ),
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
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFieldConfiguration();
    });

    _selectedManagers = widget.initialManagers ?? [];
    _selectedRegions = widget.initialRegions ?? [];
    _selectedState = widget.initialState;
    _selectedCities = widget.initialCities ?? [];
    _selectedSources = widget.initialSources ?? [];
    _selectedChannels = widget.initialChannels ?? [];
    _selectedAdvertisingCampaigns = widget.initialAdvertisingCampaigns ?? [];
    if (widget.initialReasonForRefusalIds != null) {
      _selectedReasonForRefusals = widget.initialReasonForRefusalIds!
          .map((id) => ReasonForRefusalData(id: id, text: '', type: 'lead'))
          .toList();
    }
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
    _numberOfDaysDeal = widget.initialNumberOfDaysDeal;
    _loadAskReasonForRefusal();
    _fetchDirectoryLinks();
    _initializeCustomFieldSelections(
        widget.initialCustomFieldSelections ?? const <String, List<String>>{});
    _loadLeadCustomFields();
  }

  Future<void> _loadAskReasonForRefusal() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _askReasonForRefusal = prefs.getBool('ask_reason_for_refusal') ?? false;
    });
  }

  Future<void> _fetchDirectoryLinks() async {
    try {
      final response = await ApiService().getLeadDirectoryLinks();
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
        SnackBar(
          backgroundColor: context.appColors.surfaceElevated,
          content: Text(
            'Ошибка при загрузке справочников: $e',
            style: context.appTextStyles.bodyMd.copyWith(
              color: context.appColors.textInverse,
            ),
          ),
        ),
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
      _initializeCustomFieldSelections(widget.initialCustomFieldSelections ??
          const <String, List<String>>{});
      for (final title in titles) {
        unawaited(_loadSingleCustomField(title));
      }
    } catch (e) {
      // проглатываем, показывать UI всё равно можно
    }
  }

  Future<void> _loadSingleCustomField(String title) async {
    if (!mounted) return;
    setState(() {
      _customFieldLoadingStates[title] = true;
    });

    try {
      final values = await _apiService.getLeadCustomFieldValues(title);
      if (!mounted) return;
      setState(() {
        _customFieldValues[title] = values;
        _customFieldLoadingStates[title] = false;
      });
    } catch (e) {
      // игнорируем отдельные ошибки загрузки полей
      if (mounted) {
        setState(() {
          _customFieldLoadingStates[title] = false;
        });
      }
    }
  }

  Future<void> _loadFieldConfiguration() async {
    try {
      final response = await _apiService.getFieldPositions(tableName: 'leads');
      if (!mounted) return;

      // Фильтруем только активные поля и сортируем по position
      final activeFields = response.result
          // .where((field) => field.isActive)
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
        return _buildFilterCard(
          child: ManagerMultiSelectWidget(
            selectedManagers:
                _selectedManagers.map((m) => m.id.toString()).toList(),
            onSelectManagers: (List<ManagerData> selectedUsersData) {
              setState(() => _selectedManagers = selectedUsersData);
            },
          ),
        );

      case 'region_id':
        return _buildFilterCard(
          child: StateSingleSelectWidget(
            selectedState: _selectedState,
            onChanged: (selectedState) {
              setState(() {
                _selectedState = selectedState;
                _selectedCities = [];
              });
            },
          ),
        );

      case 'city_id':
      case 'city':
        return _buildFilterCard(
          child: CityMultiSelectWidget(
            parentId: _selectedState?.id,
            selectedCities:
                _selectedCities.map((c) => c.id.toString()).toList(),
            onSelectCities: (List<CityData> selectedCitiesData) {
              setState(() => _selectedCities = selectedCitiesData);
            },
          ),
        );

      case 'source_id':
        return _buildFilterCard(
          child: SourcesMultiSelectWidget(
            selectedSources:
                _selectedSources.map((s) => s.id.toString()).toList(),
            onSelectSources: (List<SourceData> selectedSourcesData) {
              setState(() => _selectedSources = selectedSourcesData);
            },
          ),
        );

      case 'channels':
      case 'channel':
      case 'integration_id':
        return _buildFilterCard(
          child: ChannelsMultiSelectWidget(
            selectedChannels:
                _selectedChannels.map((c) => c.id.toString()).toList(),
            onSelectChannels:
                (List<LeadFilterChannelData> selectedChannelsData) {
              setState(() => _selectedChannels = selectedChannelsData);
            },
          ),
        );

      case 'advertising_campaign_id':
        return _buildFilterCard(
          child: AdvertisingCampaignMultiSelectWidget(
            selectedCampaigns: _selectedAdvertisingCampaigns
                .map((campaign) => campaign.id.toString())
                .toList(),
            onSelectCampaigns:
                (List<AdvertisingCampaignData> selectedCampaignsData) {
              setState(
                  () => _selectedAdvertisingCampaigns = selectedCampaignsData);
            },
          ),
        );

      case 'reason_for_refusal':
      case 'reason_for_refusal_id':
        if (!_askReasonForRefusal) return null;
        return _buildFilterCard(
          child: ReasonForRefusalMultiSelectWidget(
            type: 'lead',
            selectedReasonIds:
                _selectedReasonForRefusals.map((reason) => reason.id).toList(),
            onSelectReasons: (selectedReasons) {
              setState(() => _selectedReasonForRefusals = selectedReasons);
            },
          ),
        );

      default:
        // Проверяем custom field
        if (config.isCustomField &&
            _customFieldTitles.contains(config.fieldName)) {
          final isLoading = _customFieldLoadingStates[config.fieldName] == true;

          return _buildFilterCard(
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
          );
        }

        // Проверяем directory
        if (config.isDirectory && config.directoryId != null) {
          try {
            final link = _directoryLinks.firstWhere(
              (l) => l.directory.id == config.directoryId,
            );

            return _buildFilterCard(
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
      backgroundColor: context.appColors.backgroundSecondary,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('filter'),
          style: context.appTextStyles.titleLg.copyWith(
            color: context.appColors.textPrimary,
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
                _selectedSources.clear();
                _selectedChannels.clear();
                _selectedAdvertisingCampaigns.clear();
                _selectedReasonForRefusals.clear();
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
                _numberOfDaysDeal = null;
                _selectedDirectoryFields.clear();
                for (var link in _directoryLinks) {
                  _selectedDirectoryFields[link.id] = <MainField>[];
                }
                _initializeCustomFieldSelections(
                    const <String, List<String>>{});
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
          const SizedBox(width: 10),
          TextButton(
            onPressed: () async {
              await LeadCache.clearAllLeads();
              final directoryIdByLinkId = {
                for (var link in _directoryLinks) link.id: link.directory.id,
              };

              Map<String, dynamic> filterData = {
                'managers': _selectedManagers,
                'regions': _selectedRegions,
                'state': _selectedState,
                'cities': _selectedCities,
                'sources': _selectedSources,
                'channels': _selectedChannels,
                'advertising_campaigns': _selectedAdvertisingCampaigns,
                'reason_for_refusal_ids': _selectedReasonForRefusals
                    .map((reason) => reason.id)
                    .toList(),
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
                'numberOfDaysDeal': _numberOfDaysDeal,
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
                  _selectedSources.isNotEmpty ||
                  _selectedChannels.isNotEmpty ||
                  _selectedAdvertisingCampaigns.isNotEmpty ||
                  _selectedReasonForRefusals.isNotEmpty ||
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
                  _numberOfDaysDeal != null ||
                  _selectedDirectoryFields.values
                      .any((fields) => fields.isNotEmpty) ||
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
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
        child: Column(
          children: [
            _buildFilterCard(
              padding: EdgeInsets.zero,
              child: GestureDetector(
                onTap: _selectDateRange,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.appColors.surfacePrimary,
                    borderRadius: BorderRadius.circular(12),
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
                    // Поля по position из field configuration
                    if (_isConfigurationLoaded &&
                        _fieldConfigurations.isNotEmpty)
                      ..._fieldConfigurations.map((config) {
                        final widget = _buildFieldWidgetByConfig(config);
                        if (widget == null) return SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: widget,
                        );
                      }),
                    if (_isConfigurationLoaded &&
                        _fieldConfigurations.isNotEmpty &&
                        !_fieldConfigurations.any(
                          (config) => config.fieldName == 'region_id',
                        ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildFilterCard(
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
                    if (_isConfigurationLoaded &&
                        _fieldConfigurations.isNotEmpty &&
                        !_fieldConfigurations.any(
                          (config) =>
                              config.fieldName == 'city_id' ||
                              config.fieldName == 'city',
                        ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildFilterCard(
                          child: CityMultiSelectWidget(
                            parentId: _selectedState?.id,
                            selectedCities: _selectedCities
                                .map((c) => c.id.toString())
                                .toList(),
                            onSelectCities:
                                (List<CityData> selectedCitiesData) {
                              setState(
                                  () => _selectedCities = selectedCitiesData);
                            },
                          ),
                        ),
                      ),
                    if (_isConfigurationLoaded &&
                        _fieldConfigurations.isNotEmpty &&
                        !_fieldConfigurations.any(
                          (config) =>
                              config.fieldName == 'channels' ||
                              config.fieldName == 'channel' ||
                              config.fieldName == 'integration_id',
                        ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildFilterCard(
                          child: ChannelsMultiSelectWidget(
                            selectedChannels: _selectedChannels
                                .map((c) => c.id.toString())
                                .toList(),
                            onSelectChannels: (List<LeadFilterChannelData>
                                selectedChannelsData) {
                              setState(() =>
                                  _selectedChannels = selectedChannelsData);
                            },
                          ),
                        ),
                      ),
                    if (_isConfigurationLoaded &&
                        _fieldConfigurations.isNotEmpty &&
                        _askReasonForRefusal &&
                        !_fieldConfigurations.any(
                          (config) =>
                              config.fieldName == 'reason_for_refusal' ||
                              config.fieldName == 'reason_for_refusal_id',
                        ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildFilterCard(
                          child: ReasonForRefusalMultiSelectWidget(
                            type: 'lead',
                            selectedReasonIds: _selectedReasonForRefusals
                                .map((reason) => reason.id)
                                .toList(),
                            onSelectReasons: (selectedReasons) {
                              setState(() =>
                                  _selectedReasonForRefusals = selectedReasons);
                            },
                          ),
                        ),
                      ),
                    if (_isConfigurationLoaded &&
                        _fieldConfigurations.isNotEmpty &&
                        !_fieldConfigurations.any(
                          (config) =>
                              config.fieldName == 'advertising_campaign_id',
                        ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildFilterCard(
                          child: AdvertisingCampaignMultiSelectWidget(
                            selectedCampaigns: _selectedAdvertisingCampaigns
                                .map((campaign) => campaign.id.toString())
                                .toList(),
                            onSelectCampaigns: (List<AdvertisingCampaignData>
                                selectedCampaignsData) {
                              setState(() => _selectedAdvertisingCampaigns =
                                  selectedCampaignsData);
                            },
                          ),
                        ),
                      )
                    else if (!_isConfigurationLoaded)
                      // Показываем loader пока грузится конфигурация
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: context.appColors.buttonPrimaryBg,
                          ),
                        ),
                      )
                    else
                      // Fallback: показываем поля в стандартном порядке если конфигурация пуста
                      ...[
                      _buildFilterCard(
                        child: ManagerMultiSelectWidget(
                          selectedManagers: _selectedManagers
                              .map((m) => m.id.toString())
                              .toList(),
                          onSelectManagers:
                              (List<ManagerData> selectedUsersData) {
                            setState(
                                () => _selectedManagers = selectedUsersData);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFilterCard(
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
                      const SizedBox(height: 8),
                      _buildFilterCard(
                        child: CityMultiSelectWidget(
                          parentId: _selectedState?.id,
                          selectedCities: _selectedCities
                              .map((c) => c.id.toString())
                              .toList(),
                          onSelectCities: (List<CityData> selectedCitiesData) {
                            setState(
                                () => _selectedCities = selectedCitiesData);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFilterCard(
                        child: ChannelsMultiSelectWidget(
                          selectedChannels: _selectedChannels
                              .map((c) => c.id.toString())
                              .toList(),
                          onSelectChannels: (List<LeadFilterChannelData>
                              selectedChannelsData) {
                            setState(
                                () => _selectedChannels = selectedChannelsData);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFilterCard(
                        child: SourcesMultiSelectWidget(
                          selectedSources: _selectedSources
                              .map((s) => s.id.toString())
                              .toList(),
                          onSelectSources:
                              (List<SourceData> selectedSourcesData) {
                            setState(
                                () => _selectedSources = selectedSourcesData);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFilterCard(
                        child: AdvertisingCampaignMultiSelectWidget(
                          selectedCampaigns: _selectedAdvertisingCampaigns
                              .map((campaign) => campaign.id.toString())
                              .toList(),
                          onSelectCampaigns: (List<AdvertisingCampaignData>
                              selectedCampaignsData) {
                            setState(() {
                              _selectedAdvertisingCampaigns =
                                  selectedCampaignsData;
                            });
                          },
                        ),
                      ),
                      if (_askReasonForRefusal) ...[
                        const SizedBox(height: 8),
                        _buildFilterCard(
                          child: ReasonForRefusalMultiSelectWidget(
                            type: 'lead',
                            selectedReasonIds: _selectedReasonForRefusals
                                .map((reason) => reason.id)
                                .toList(),
                            onSelectReasons: (selectedReasons) {
                              setState(() =>
                                  _selectedReasonForRefusals = selectedReasons);
                            },
                          ),
                        ),
                      ],
                    ],

                    // Switches - всегда в конце
                    _buildFilterCard(
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            AppLocalizations.of(context)!
                                .translate('with_successful_deal'),
                            _hasSuccessDeals ?? false,
                            (value) => setState(() => _hasSuccessDeals = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!
                                .translate('with_deal_in_progress'),
                            _hasInProgressDeals ?? false,
                            (value) =>
                                setState(() => _hasInProgressDeals = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!
                                .translate('with_unsuccessful_deal'),
                            _hasFailureDeals ?? false,
                            (value) => setState(() => _hasFailureDeals = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!
                                .translate('with_note'),
                            _hasNotices ?? false,
                            (value) => setState(() => _hasNotices = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!
                                .translate('with_contacts'),
                            _hasContact ?? false,
                            (value) => setState(() => _hasContact = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!
                                .translate('with_chat'),
                            _hasChat ?? false,
                            (value) => setState(() => _hasChat = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!
                                .translate('without_replies'),
                            _hasNoReplies ?? false,
                            (value) => setState(() => _hasNoReplies = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!
                                .translate('with_unread_messages'),
                            _hasUnreadMessages ?? false,
                            (value) =>
                                setState(() => _hasUnreadMessages = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!
                                .translate('withoutDeal'),
                            _hasDeal ?? false,
                            (value) => setState(() => _hasDeal = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)
                                    ?.translate('withOrders') ??
                                'С заказами',
                            _hasOrders ?? false,
                            (value) => setState(() => _hasOrders = value),
                          ),
                        ],
                      ),
                    ),

                    _buildFilterCard(
                      padding: const EdgeInsets.only(
                          left: 12, right: 12, top: 4, bottom: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!
                                .translate('days_without_deal'),
                            style: context.appTextStyles.bodyLg.copyWith(
                              fontWeight: FontWeight.w500,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                          Slider(
                            value: (_numberOfDaysDeal ?? 0).toDouble(),
                            min: 0,
                            max: 100,
                            divisions: 100,
                            label: _numberOfDaysDeal.toString(),
                            onChanged: (double value) {
                              setState(() {
                                _numberOfDaysDeal = value.toInt();
                              });
                            },
                            activeColor: context.appColors.buttonPrimaryBg,
                            inactiveColor: context.appColors.textMuted
                                .withValues(alpha: 0.5),
                          ),
                          Center(
                            child: Text(
                              "${_numberOfDaysDeal ?? '0'}",
                              style: context.appTextStyles.titleLg.copyWith(
                                fontWeight: FontWeight.w500,
                                color: context.appColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Days without activity slider - всегда последний
                    _buildFilterCard(
                      padding: const EdgeInsets.only(
                          left: 12, right: 12, top: 4, bottom: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!
                                .translate('days_without_activity'),
                            style: context.appTextStyles.bodyLg.copyWith(
                              fontWeight: FontWeight.w500,
                              color: context.appColors.textPrimary,
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
                            activeColor: context.appColors.buttonPrimaryBg,
                            inactiveColor: context.appColors.textMuted
                                .withValues(alpha: 0.5),
                          ),
                          Center(
                            child: Text(
                              "${_daysWithoutActivity ?? '0'}",
                              style: context.appTextStyles.titleLg.copyWith(
                                fontWeight: FontWeight.w500,
                                color: context.appColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
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
