import 'dart:convert';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_field_multi_select.dart';
import 'package:crm_task_manager/custom_widget/filter/common/multi_reason_for_refusal_list.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/lead_manager_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_manager_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_region_list.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/lead_multi_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/reason_for_refusal_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/page_2/order/order_details/payment_method_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/status_method_dropdown.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final String? initialClient;
  final String? initialStatus;
  final String? initialPaymentMethod;
  final String? initialDeliveryType;
  final List<int>? initialReasonForRefusalIds;
  final List<String>? initialManagers;
  final List<String>? initialRegions;
  final List<String>? initialLeads;
  final Map<String, List<String>>? initialCustomFieldSelections;

  const OrdersFilterScreen({
    super.key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialFromDate,
    this.initialToDate,
    this.initialClient,
    this.initialStatus,
    this.initialPaymentMethod,
    this.initialDeliveryType,
    this.initialReasonForRefusalIds,
    this.initialManagers,
    this.initialRegions,
    this.initialLeads,
    this.initialCustomFieldSelections,
  });

  @override
  State<OrdersFilterScreen> createState() => _OrdersFilterScreenState();
}

class _OrdersFilterScreenState extends State<OrdersFilterScreen> {
  static const String _pickupLabel = 'Самовывоз';
  static const String _deliveryLabel = 'Доставка';

  final ApiService _apiService = ApiService();
  final TextEditingController _clientController = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedStatus;
  String? _selectedPaymentMethod;
  String? _selectedDeliveryType;
  bool _askReasonForRefusal = false;

  List<ManagerData> _selectedManagers = [];
  List<RegionData> _selectedRegions = [];
  List<LeadData> _selectedLeads = [];
  List<ReasonForRefusalData> _selectedReasonForRefusals = [];

  Map<String, List<String>> _selectedCustomFieldValues = {};
  Map<String, List<String>> _customFieldValues = {};
  Map<String, bool> _customFieldLoadingStates = {};
  List<FieldConfiguration> _fieldConfigurations = [];

  bool _isLoading = true;

  Key _paymentDropdownKey = UniqueKey();
  Key _statusDropdownKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _clientController.text = widget.initialClient ?? '';
    _selectedStatus = widget.initialStatus;
    _selectedPaymentMethod = widget.initialPaymentMethod;
    _selectedDeliveryType = widget.initialDeliveryType;
    _selectedManagers = widget.initialManagers
            ?.map((id) => ManagerData(id: int.parse(id), name: ''))
            .toList() ??
        [];
    _selectedRegions = widget.initialRegions
            ?.map((id) => RegionData(id: int.parse(id), name: ''))
            .toList() ??
        [];
    _selectedLeads = widget.initialLeads
            ?.map((id) => LeadData(id: int.parse(id), name: ''))
            .toList() ??
        [];
    _selectedReasonForRefusals = widget.initialReasonForRefusalIds
            ?.map(
              (id) => ReasonForRefusalData(id: id, text: '', type: 'order'),
            )
            .toList() ??
        [];
    _selectedCustomFieldValues = {
      for (final entry
          in (widget.initialCustomFieldSelections ?? const {}).entries)
        entry.key: List<String>.from(entry.value),
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  String _deliveryTypeToLabel(BuildContext context, String? value) {
    if (value == 'pickup') {
      return _pickupLabel;
    }
    return _deliveryLabel;
  }

  String? _deliveryLabelToValue(BuildContext context, String? label) {
    if (label == null || label.isEmpty) return null;
    if (label == _pickupLabel) {
      return 'pickup';
    }
    if (label == _deliveryLabel) {
      return 'delivery';
    }
    return null;
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.ensureInitialized();
      await Future.wait([
        _loadFilterState(),
        _loadFieldConfiguration(),
        _loadAskReasonForRefusal(),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFieldConfiguration() async {
    try {
      final response = await _apiService.getFieldPositions(tableName: 'orders');
      final activeFields = response.result
          .where((field) => field.isActive)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));

      final customTitles = activeFields
          .where((field) => field.isCustomField)
          .map((field) => field.fieldName)
          .toSet()
          .toList();

      if (!mounted) return;

      setState(() {
        _fieldConfigurations = activeFields;
        for (final title in customTitles) {
          _selectedCustomFieldValues[title] =
              _selectedCustomFieldValues[title] ?? <String>[];
        }
      });

      await Future.wait([
        for (final title in customTitles) _loadSingleCustomField(title),
      ]);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fieldConfigurations = [];
      });
    }
  }

  Future<void> _loadSingleCustomField(String title) async {
    if (!mounted) return;
    setState(() {
      _customFieldLoadingStates[title] = true;
    });

    try {
      final values = await _apiService.getOrderCustomFieldValues(title);
      if (!mounted) return;
      setState(() {
        _customFieldValues[title] = values;
        _customFieldLoadingStates[title] = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _customFieldLoadingStates[title] = false;
      });
    }
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      final fromDateMillis = prefs.getInt('order_from_date');
      final toDateMillis = prefs.getInt('order_to_date');
      if (fromDateMillis != null) {
        _fromDate = DateTime.fromMillisecondsSinceEpoch(fromDateMillis);
      }
      if (toDateMillis != null) {
        _toDate = DateTime.fromMillisecondsSinceEpoch(toDateMillis);
      }

      _clientController.text =
          prefs.getString('order_client') ?? widget.initialClient ?? '';
      _selectedStatus = prefs.getString('order_status') ?? widget.initialStatus;
      _selectedPaymentMethod = prefs.getString('order_payment_method') ??
          widget.initialPaymentMethod;
      _selectedDeliveryType =
          prefs.getString('order_delivery_type') ?? widget.initialDeliveryType;

      final managersJson = prefs.getString('order_managers');
      final regionsJson = prefs.getString('order_regions');
      final leadsJson = prefs.getString('order_leads');
      final reasonForRefusalJson =
          prefs.getString('order_reason_for_refusal_ids');
      final customFieldsJson = prefs.getString('order_custom_field_filters');

      if (managersJson != null) {
        _selectedManagers = (jsonDecode(managersJson) as List)
            .map((item) => ManagerData(
                  id: int.parse(item['id'].toString()),
                  name: item['name'] ?? '',
                ))
            .toList();
      }
      if (regionsJson != null) {
        _selectedRegions = (jsonDecode(regionsJson) as List)
            .map((item) => RegionData(
                  id: int.parse(item['id'].toString()),
                  name: item['name'] ?? '',
                ))
            .toList();
      }
      if (leadsJson != null) {
        _selectedLeads = (jsonDecode(leadsJson) as List)
            .map((item) => LeadData(
                  id: int.parse(item['id'].toString()),
                  name: item['name'] ?? '',
                ))
            .toList();
      }
      if (reasonForRefusalJson != null) {
        _selectedReasonForRefusals = (jsonDecode(reasonForRefusalJson) as List)
            .map(
              (id) => ReasonForRefusalData(
                id: int.parse(id.toString()),
                text: '',
                type: 'order',
              ),
            )
            .toList();
      }
      if (customFieldsJson != null) {
        _selectedCustomFieldValues =
            (jsonDecode(customFieldsJson) as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, List<String>.from(value as List)),
        );
      }
    });
  }

  Future<void> _loadAskReasonForRefusal() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _askReasonForRefusal = prefs.getBool('ask_reason_for_refusal') ?? false;
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();

    if (_fromDate != null) {
      await prefs.setInt('order_from_date', _fromDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('order_from_date');
    }

    if (_toDate != null) {
      await prefs.setInt('order_to_date', _toDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('order_to_date');
    }

    await prefs.setString('order_client', _clientController.text);

    if (_selectedStatus != null) {
      await prefs.setString('order_status', _selectedStatus!);
    } else {
      await prefs.remove('order_status');
    }

    if (_selectedPaymentMethod != null) {
      await prefs.setString('order_payment_method', _selectedPaymentMethod!);
    } else {
      await prefs.remove('order_payment_method');
    }

    if (_selectedDeliveryType != null) {
      await prefs.setString('order_delivery_type', _selectedDeliveryType!);
    } else {
      await prefs.remove('order_delivery_type');
    }

    await prefs.setString(
      'order_managers',
      jsonEncode(
        _selectedManagers.map((m) => {'id': m.id, 'name': m.name}).toList(),
      ),
    );
    await prefs.setString(
      'order_regions',
      jsonEncode(
        _selectedRegions.map((r) => {'id': r.id, 'name': r.name}).toList(),
      ),
    );
    await prefs.setString(
      'order_leads',
      jsonEncode(
        _selectedLeads.map((l) => {'id': l.id, 'name': l.name}).toList(),
      ),
    );
    await prefs.setString(
      'order_reason_for_refusal_ids',
      jsonEncode(
        _selectedReasonForRefusals.map((reason) => reason.id).toList(),
      ),
    );

    final customFieldFilters = <String, List<String>>{};
    _selectedCustomFieldValues.forEach((key, value) {
      if (value.isNotEmpty) {
        customFieldFilters[key] = List<String>.from(value);
      }
    });

    if (customFieldFilters.isNotEmpty) {
      await prefs.setString(
        'order_custom_field_filters',
        jsonEncode(customFieldFilters),
      );
    } else {
      await prefs.remove('order_custom_field_filters');
    }
  }

  void _resetFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _clientController.text = '';
      _selectedStatus = null;
      _selectedPaymentMethod = null;
      _selectedDeliveryType = null;
      _selectedManagers.clear();
      _selectedRegions.clear();
      _selectedLeads.clear();
      _selectedReasonForRefusals.clear();
      _selectedCustomFieldValues = {
        for (final title in _selectedCustomFieldValues.keys) title: <String>[],
      };
      _paymentDropdownKey = UniqueKey();
      _statusDropdownKey = UniqueKey();
    });
    widget.onResetFilters?.call();
    _saveFilterState();
  }

  Future<void> _selectDateRange() async {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

    final pickerColorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.buttonPrimaryBg,
      onPrimary: colors.buttonPrimaryFg,
      secondary: colors.buttonSecondaryBg,
      onSecondary: colors.buttonPrimaryFg,
      error: colors.error,
      onError: colors.buttonPrimaryFg,
      surface: colors.surfacePrimary,
      onSurface: colors.textPrimary,
    );

    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            useMaterial3: theme.useMaterial3,
            brightness: brightness,
            colorScheme: pickerColorScheme,
            scaffoldBackgroundColor: colors.surfacePrimary,
            dialogTheme: DialogThemeData(
              backgroundColor: colors.surfacePrimary,
            ),
            textTheme: theme.textTheme.apply(
              bodyColor: colors.textPrimary,
              displayColor: colors.textPrimary,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: colors.surfacePrimary,
              dividerColor: colors.borderSubtle,
              headerBackgroundColor: colors.surfacePrimary,
              headerForegroundColor: colors.textPrimary,
              rangeSelectionBackgroundColor:
                  colors.buttonPrimaryBg.withValues(alpha: isDark ? 0.28 : 0.16),
              rangeSelectionOverlayColor:
                  WidgetStatePropertyAll(colors.buttonPrimaryBg.withValues(alpha: 0.14)),
              todayBackgroundColor:
                  WidgetStatePropertyAll(colors.buttonPrimaryBg.withValues(alpha: 0.22)),
              todayForegroundColor:
                  WidgetStatePropertyAll(colors.buttonPrimaryBg),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return colors.textSecondary.withValues(alpha: 0.38);
                }
                if (states.contains(WidgetState.selected)) {
                  return colors.buttonPrimaryFg;
                }
                return colors.textPrimary;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.buttonPrimaryBg;
                }
                return Colors.transparent;
              }),
              yearForegroundColor:
                  WidgetStatePropertyAll(colors.textPrimary),
              yearBackgroundColor:
                  WidgetStatePropertyAll(colors.surfacePrimary),
              weekdayStyle: context.appTextStyles.bodySm.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              dayStyle: context.appTextStyles.bodyMd.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              rangePickerHeaderForegroundColor: colors.textPrimary,
              rangePickerHeaderBackgroundColor: colors.surfacePrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: colors.buttonPrimaryBg,
              ),
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

  bool _isAnyFilterSelected() {
    final hasCustomFieldFilters =
        _selectedCustomFieldValues.values.any((values) => values.isNotEmpty);

    return _fromDate != null ||
        _toDate != null ||
        _clientController.text.isNotEmpty ||
        _selectedStatus != null ||
        _selectedPaymentMethod != null ||
        _selectedDeliveryType != null ||
        _selectedManagers.isNotEmpty ||
        _selectedRegions.isNotEmpty ||
        _selectedLeads.isNotEmpty ||
        _selectedReasonForRefusals.isNotEmpty ||
        hasCustomFieldFilters;
  }

  Future<void> _applyFilters() async {
    await _saveFilterState();

    if (!_isAnyFilterSelected()) {
      widget.onResetFilters?.call();
      Navigator.pop(context);
      return;
    }

    DateTime? fromDateWithTime = _fromDate;
    DateTime? toDateWithTime = _toDate;

    if (fromDateWithTime != null) {
      fromDateWithTime = DateTime(
        fromDateWithTime.year,
        fromDateWithTime.month,
        fromDateWithTime.day,
        0,
        0,
        0,
      );
    }
    if (toDateWithTime != null) {
      toDateWithTime = DateTime(
        toDateWithTime.year,
        toDateWithTime.month,
        toDateWithTime.day,
        23,
        59,
        59,
      );
    }

    final customFieldFilters = <String, List<String>>{};
    _selectedCustomFieldValues.forEach((key, value) {
      if (value.isNotEmpty) {
        customFieldFilters[key] = List<String>.from(value);
      }
    });

    widget.onSelectedDataFilter?.call({
      'fromDate': fromDateWithTime,
      'toDate': toDateWithTime,
      'client':
          _clientController.text.isNotEmpty ? _clientController.text : null,
      'status': _selectedStatus,
      'paymentMethod': _selectedPaymentMethod,
      'deliveryType': _selectedDeliveryType,
      'managers': _selectedManagers.isNotEmpty
          ? _selectedManagers.map((manager) => manager.id.toString()).toList()
          : null,
      'regions': _selectedRegions.isNotEmpty
          ? _selectedRegions.map((region) => region.id.toString()).toList()
          : null,
      'leads': _selectedLeads.isNotEmpty
          ? _selectedLeads.map((lead) => lead.id.toString()).toList()
          : null,
      'reason_for_refusal_ids': _selectedReasonForRefusals.isNotEmpty
          ? _selectedReasonForRefusals.map((reason) => reason.id).toList()
          : null,
      'custom_field_filters':
          customFieldFilters.isNotEmpty ? customFieldFilters : null,
    });

    Navigator.pop(context);
  }

  List<String> _orderCustomFieldTitles() {
    return _fieldConfigurations
        .where((field) => field.isCustomField)
        .map((field) => field.fieldName)
        .toSet()
        .toList();
  }

  Widget _buildFilterCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
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

  CustomDropdownDecoration _buildDropdownDecoration() {
    return CustomDropdownDecoration(
      closedFillColor: context.appColors.fieldBg,
      expandedFillColor: context.appColors.surfacePrimary,
      closedBorder: Border.all(color: context.appColors.fieldBg, width: 1),
      expandedBorder: Border.all(color: context.appColors.fieldBg, width: 1),
      closedBorderRadius: BorderRadius.circular(12),
      expandedBorderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildDeliveryTypeDropdown() {
    final List<String> deliveryMethods = [_pickupLabel, _deliveryLabel];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('delivery_method'),
          style: context.appTextStyles.bodyLg.copyWith(
            fontWeight: FontWeight.w500,
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<String>.search(
          closeDropDownOnClearFilterSearch: true,
          items: deliveryMethods,
          initialItem: _selectedDeliveryType != null
              ? _deliveryTypeToLabel(context, _selectedDeliveryType)
              : null,
          searchHintText: AppLocalizations.of(context)!.translate('search'),
          overlayHeight: 320,
          enabled: true,
          decoration: _buildDropdownDecoration(),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Text(
              item,
              style: context.appTextStyles.bodyMd.copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            );
          },
          headerBuilder: (context, selectedItem, enabled) {
            return Text(
              selectedItem.isNotEmpty
                  ? selectedItem
                  : AppLocalizations.of(context)!
                      .translate('select_delivery_method'),
              style: context.appTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_delivery_method'),
            style: context.appTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w500,
              color: context.appColors.textPrimary,
            ),
          ),
          excludeSelected: false,
          onChanged: (value) {
            setState(() {
              _selectedDeliveryType = _deliveryLabelToValue(context, value);
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final customFieldTitles = _orderCustomFieldTitles();

    return Scaffold(
      backgroundColor: context.appColors.backgroundSecondary,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('filter'),
          style: context.appTextStyles.titleLg.copyWith(
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
        backgroundColor: context.appColors.surfacePrimary,
        forceMaterialTransparency: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            style: _buildActionButtonStyle(),
            child: Text(
              AppLocalizations.of(context)!.translate('reset'),
              style: context.appTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appColors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _applyFilters,
            style: _buildActionButtonStyle(),
            child: Text(
              AppLocalizations.of(context)!.translate('apply'),
              style: context.appTextStyles.bodyLg.copyWith(
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isLoading
              ? Center(
                  key: const ValueKey('orders-filter-loader'),
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
                        style: context.appTextStyles.bodyLg.copyWith(
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  key: const ValueKey('orders-filter-content'),
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _fromDate != null && _toDate != null
                                            ? "${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year} - ${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}"
                                            : AppLocalizations.of(context)!
                                                .translate('select_date_range'),
                                        style: context.appTextStyles.bodyMd
                                            .copyWith(
                                          color: _fromDate != null &&
                                                  _toDate != null
                                              ? context.appColors.textPrimary
                                              : context.appColors.textSecondary,
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
                            _buildFilterCard(
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
                            _buildFilterCard(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
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
                            _buildFilterCard(
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
                            _buildFilterCard(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: PaymentMethodDropdown(
                                  key: _paymentDropdownKey,
                                  selectedPaymentMethod: _selectedPaymentMethod,
                                  onSelectPaymentMethod: (value) {
                                    setState(() {
                                      _selectedPaymentMethod = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildFilterCard(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: StatusMethodDropdown(
                                  key: _statusDropdownKey,
                                  selectedstatusMethod: _selectedStatus,
                                  onSelectstatusMethod: (value) {
                                    setState(() {
                                      _selectedStatus = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildFilterCard(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: _buildDeliveryTypeDropdown(),
                              ),
                            ),
                            if (_askReasonForRefusal) ...[
                              const SizedBox(height: 8),
                              _buildFilterCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: ReasonForRefusalMultiSelectWidget(
                                    type: 'order',
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
                            if (customFieldTitles.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              for (final title in customFieldTitles) ...[
                                _buildFilterCard(
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
                                const SizedBox(height: 8),
                              ],
                            ],
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
