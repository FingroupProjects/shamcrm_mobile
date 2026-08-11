import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:crm_task_manager/bloc/source_list/source_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/custom_widget/filter/chat/lead/LeadStatusForFilterWidget.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_manager_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_region_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_source_list.dart';
import 'package:crm_task_manager/models/LeadStatusForFilter.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/models/source_list_model.dart';
import 'package:crm_task_manager/models/directory_link_model.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/sales_funnel_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatLeadFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onManagersSelected;
  final List? initialManagers;
  final List? initialRegions;
  final List? initialSources;
  final List<String>? initialStatuses;
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
  final int? initialSalesFunnelId;

  const ChatLeadFilterScreen({
    super.key,
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
    this.initialSalesFunnelId,
  });

  @override
  State<ChatLeadFilterScreen> createState() => _ChatLeadFilterScreenState();
}

class _ChatLeadFilterScreenState extends State<ChatLeadFilterScreen> {
  List<ManagerData> _selectedManagers = [];
  List<RegionData> _selectedRegions = [];
  List<SourceData> _selectedSources = [];

  List<String>? _selectedStatuses;
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
  String? selectedSalesFunnel;

  final Map<int, MainField?> _selectedDirectoryFields = {};
  List<DirectoryLink> _directoryLinks = [];

  // ДОБАВЛЕНО: Вспомогательные методы для безопасного преобразования типов
  
  /// Преобразует dynamic в ManagerData
  ManagerData _parseManagerData(dynamic item) {
    if (item is ManagerData) {
      return item;
    }
    if (item is Map<String, dynamic>) {
      return ManagerData.fromJson(item);
    }
    if (item is Map) {
      Map<String, dynamic> stringKeyMap = {};
      item.forEach((key, value) {
        stringKeyMap[key.toString()] = value;
      });
      return ManagerData.fromJson(stringKeyMap);
    }
    throw Exception('Неподдерживаемый тип менеджера: ${item.runtimeType}');
  }

  /// Преобразует dynamic в RegionData
  RegionData _parseRegionData(dynamic item) {
    if (item is RegionData) {
      return item;
    }
    if (item is Map<String, dynamic>) {
      return RegionData.fromJson(item);
    }
    if (item is Map) {
      Map<String, dynamic> stringKeyMap = {};
      item.forEach((key, value) {
        stringKeyMap[key.toString()] = value;
      });
      return RegionData.fromJson(stringKeyMap);
    }
    throw Exception('Неподдерживаемый тип региона: ${item.runtimeType}');
  }

  /// Преобразует dynamic в SourceData
  SourceData _parseSourceData(dynamic item) {
    if (item is SourceData) {
      return item;
    }
    if (item is Map<String, dynamic>) {
      return SourceData.fromJson(item);
    }
    if (item is Map) {
      Map<String, dynamic> stringKeyMap = {};
      item.forEach((key, value) {
        stringKeyMap[key.toString()] = value;
      });
      return SourceData.fromJson(stringKeyMap);
    }
    throw Exception('Неподдерживаемый тип источника: ${item.runtimeType}');
  }

  /// Преобразует ManagerData в Map для отправки
  Map<String, dynamic> _managerToMap(ManagerData manager) {
    return {
      'id': manager.id,
      'name': manager.name,
      // Добавьте другие поля, если они есть в ManagerData
    };
  }

  /// Преобразует RegionData в Map для отправки
  Map<String, dynamic> _regionToMap(RegionData region) {
    return {
      'id': region.id,
      'name': region.name,
      // Добавьте другие поля, если они есть в RegionData
    };
  }

  /// Преобразует SourceData в Map для отправки
  Map<String, dynamic> _sourceToMap(SourceData source) {
    return {
      'id': source.id,
      'name': source.name,
      'created_at': source.createdAt?.toIso8601String(),
      'updated_at': source.updatedAt?.toIso8601String(),
      'default': source.isDefault,
    };
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: context.appTextStyles.bodyMd.copyWith(
          fontSize: 16,
          color: context.appColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: context.appColors.buttonPrimaryFg,
      inactiveTrackColor: context.appColors.borderSubtle.withValues(alpha: 0.55),
      activeTrackColor: context.appColors.buttonPrimaryBg,
      inactiveThumbColor: context.appColors.surfacePrimary,
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    final colors = context.appColors;
    // Material (not colored DecoratedBox) so SwitchListTile/ListTile ink
    // is not hidden — avoids "background color or ink splashes may be invisible".
    return Material(
      color: colors.surfacePrimary.withValues(alpha: 0.88),
      elevation: 2,
      shadowColor: colors.shadow.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colors.borderSubtle.withValues(alpha: 0.38),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildDateRangeCard({
    required String label,
    required VoidCallback onTap,
  }) {
    return _buildSectionCard(
      child:
      InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.appTextStyles.bodyMd.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.appColors.buttonPrimaryBg.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: context.appColors.buttonPrimaryBg,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        backgroundColor: isPrimary
            ? context.appColors.buttonPrimaryBg.withValues(alpha: 0.16)
            : context.appColors.surfacePrimary.withValues(alpha: 0.78),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        side: BorderSide(
          color: isPrimary
              ? context.appColors.buttonPrimaryBg.withValues(alpha: 0.45)
              : context.appColors.borderSubtle.withValues(alpha: 0.42),
        ),
      ),
      child: Text(
        label,
        style: context.appTextStyles.labelMd.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isPrimary
              ? context.appColors.buttonPrimaryBg
              : context.appColors.textSecondary,
        ),
      ),
    );
  }

  void _selectDateRange() async {
    final colors = context.appColors;
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: colors.backgroundPrimary,
            dialogTheme: DialogThemeData(backgroundColor: colors.surfacePrimary),
            colorScheme: ColorScheme.dark(
              primary: colors.buttonPrimaryBg,
              onPrimary: colors.buttonPrimaryFg,
              surface: colors.surfacePrimary,
              onSurface: colors.textPrimary,
              secondary: colors.buttonPrimaryBg.withValues(alpha: 0.18),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: colors.buttonPrimaryBg),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: colors.surfacePrimary,
              foregroundColor: colors.textPrimary,
              elevation: 0,
            ),
            dividerColor: colors.borderSubtle.withValues(alpha: 0.3),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: colors.surfacePrimary,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: colors.surfacePrimary,
              headerForegroundColor: colors.textPrimary,
              rangePickerBackgroundColor: colors.surfacePrimary,
              rangePickerHeaderBackgroundColor: colors.surfacePrimary,
              rangePickerHeaderForegroundColor: colors.textPrimary,
              weekdayStyle: TextStyle(color: colors.textSecondary),
              dayStyle: TextStyle(color: colors.textPrimary),
              todayForegroundColor:
                  WidgetStatePropertyAll(colors.buttonPrimaryBg),
              todayBorder: BorderSide(color: colors.buttonPrimaryBg),
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
              rangeSelectionBackgroundColor:
                  colors.buttonPrimaryBg.withValues(alpha: 0.18),
              rangeSelectionOverlayColor:
                  WidgetStatePropertyAll(colors.buttonPrimaryBg.withValues(alpha: 0.12)),
              yearForegroundColor: WidgetStatePropertyAll(colors.textPrimary),
              yearBackgroundColor:
                  WidgetStatePropertyAll(colors.surfacePrimary.withValues(alpha: 0.8)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;
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
    
    // ИСПРАВЛЕНО: Безопасная инициализация всех списков
    try {
      _selectedManagers = widget.initialManagers?.map((item) => _parseManagerData(item)).toList() ?? [];
    } catch (e) {
      //print('ChatLeadFilterScreen: Error parsing managers: $e');
      _selectedManagers = [];
    }

    try {
      _selectedRegions = widget.initialRegions?.map((item) => _parseRegionData(item)).toList() ?? [];
    } catch (e) {
      //print('ChatLeadFilterScreen: Error parsing regions: $e');
      _selectedRegions = [];
    }

    try {
      _selectedSources = widget.initialSources?.map((item) => _parseSourceData(item)).toList() ?? [];
    } catch (e) {
      //print('ChatLeadFilterScreen: Error parsing sources: $e');
      _selectedSources = [];
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
    _daysWithoutActivity = widget.initialDaysWithoutActivity;
    selectedSalesFunnel = widget.initialSalesFunnelId?.toString();
    
    context.read<GetAllRegionBloc>().add(GetAllRegionEv());
    context.read<GetAllSourceBloc>().add(GetAllSourceEv());
    _fetchDirectoryLinks();
    _loadCurrentSalesFunnel();
  }

  Future<void> _fetchDirectoryLinks() async {
    try {
      final response = await ApiService().getLeadDirectoryLinks();
      if (!mounted) return;
      if (response.data != null) {
        setState(() {
          _directoryLinks = response.data!;
          for (var link in _directoryLinks) {
            _selectedDirectoryFields[link.id] = null;
          }
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке справочников: $e')),
      );
    }
  }

  Future<void> _loadCurrentSalesFunnel() async {
    try {
      final savedFunnelId = await ApiService().getSelectedChatSalesFunnel();
      if (savedFunnelId != null && mounted) {
        setState(() {
          selectedSalesFunnel = savedFunnelId;
        });
        //print('ChatLeadFilterScreen: Loaded saved funnel ID: $savedFunnelId');
      }
    } catch (e) {
      //print('ChatLeadFilterScreen: Error loading saved funnel: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.backgroundPrimary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 84,
        titleSpacing: 16,
        forceMaterialTransparency: true,
        elevation: 0,
        title: AppBarShell(
          leading: AppBarShell.capsule(
            context,
            width: AppBarShell.orbSize,
            padding: EdgeInsets.zero,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: context.appColors.iconPrimary,
              ),
            ),
          ),
          center: AppBarShell.capsule(
            context,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.translate('filter'),
                style: context.appTextStyles.titleLg.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          trailing: AppBarShell.capsule(
            context,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  label: AppLocalizations.of(context)!.translate('reset'),
                  isPrimary: false,
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
                    widget.onManagersSelected?.call({
                      'managers': [],
                      'regions': [],
                      'sources': [],
                      'statuses': null,
                      'fromDate': null,
                      'toDate': null,
                      'hasSuccessDeals': false,
                      'hasInProgressDeals': false,
                      'hasFailureDeals': false,
                      'hasNotices': false,
                      'hasContact': false,
                      'hasChat': false,
                      'hasNoReplies': false,
                      'hasUnreadMessages': false,
                      'hasDeal': false,
                      'daysWithoutActivity': null,
                      'directory_values': [],
                    });
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  label: AppLocalizations.of(context)!.translate('apply'),
                  isPrimary: true,
                  onPressed: () async {
                    await LeadCache.clearAllLeads();
                    if (!mounted) return;

                    Map<String, dynamic> filterData = {
                      'managers':
                          _selectedManagers.map((m) => _managerToMap(m)).toList(),
                      'regions':
                          _selectedRegions.map((r) => _regionToMap(r)).toList(),
                      'sources':
                          _selectedSources.map((s) => _sourceToMap(s)).toList(),
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

                    if (selectedSalesFunnel != null) {
                      filterData['sales_funnel_id'] = selectedSalesFunnel;
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
                        _daysWithoutActivity != null ||
                        _selectedDirectoryFields.values.any((field) => field != null)) {
                      widget.onManagersSelected?.call(filterData);
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          children: [
            _buildDateRangeCard(
              label: _fromDate != null && _toDate != null
                  ? "${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year} - ${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}"
                  : AppLocalizations.of(context)!.translate('select_date_range'),
              onTap: _selectDateRange,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSectionCard(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
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
                    _buildSectionCard(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: RegionsMultiSelectWidget(
                          selectedRegions: _selectedRegions
                              .map((region) => region.id.toString())
                              .toList(),
                          onSelectRegions:
                              (List<RegionData> selectedRegionsData) {
                            setState(() {
                              _selectedRegions = selectedRegionsData;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSectionCard(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
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
                    _buildSectionCard(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: LeadStatusForFilterMultiSelectWidget(
                          selectedLeadStatuses: _selectedStatuses,
                          onSelectStatuses:
                              (List<LeadStatusForFilter> selectedStatuses) {
                            setState(() {
                              _selectedStatuses = selectedStatuses
                                  .map((status) => status.id.toString())
                                  .toList();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSectionCard(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: SalesFunnelWidget(
                          selectedSalesFunnel: selectedSalesFunnel,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedSalesFunnel = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSectionCard(
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSectionCard(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, top: 10, bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .translate('days_without_activity'),
                              style: context.appTextStyles.labelLg.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
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
                              inactiveColor: context.appColors.borderSubtle
                                  .withValues(alpha: 0.5),
                            ),
                            Center(
                              child: Text(
                                "${_daysWithoutActivity ?? '0'}",
                                style: context.appTextStyles.titleLg.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
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
    );
  }
}
