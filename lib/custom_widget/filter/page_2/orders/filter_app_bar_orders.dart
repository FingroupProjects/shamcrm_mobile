import 'dart:convert';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
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

  Widget _buildDeliveryTypeDropdown() {
    final List<String> deliveryMethods = [_pickupLabel, _deliveryLabel];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('delivery_method'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
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
          decoration: CustomDropdownDecoration(
            closedFillColor: const Color(0xffF4F7FD),
            expandedFillColor: Colors.white,
            closedBorder: Border.all(color: const Color(0xffF4F7FD), width: 1),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder:
                Border.all(color: const Color(0xffF4F7FD), width: 1),
            expandedBorderRadius: BorderRadius.circular(12),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Text(
              item,
              style: const TextStyle(
                color: Color(0xff1E2E52),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
            );
          },
          headerBuilder: (context, selectedItem, enabled) {
            return Text(
              selectedItem.isNotEmpty
                  ? selectedItem
                  : AppLocalizations.of(context)!
                      .translate('select_delivery_method'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_delivery_method'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
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
      backgroundColor: const Color(0xffF4F7FD),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('filter'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
            fontFamily: 'Gilroy',
          ),
        ),
        backgroundColor: Colors.white,
        forceMaterialTransparency: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('reset'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _applyFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('apply'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
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
                            Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _fromDate != null && _toDate != null
                                            ? "${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year} - ${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}"
                                            : AppLocalizations.of(context)!
                                                .translate('select_date_range'),
                                        style: TextStyle(
                                          fontFamily: 'Gilroy',
                                          color: _fromDate != null &&
                                                  _toDate != null
                                              ? Colors.black
                                              : const Color(0xff99A4BA),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Color(0xff99A4BA),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              color: Colors.white,
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
                              color: Colors.white,
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
                            Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: LeadMultiSelectWidget(
                                  selectedLeads: _selectedLeads
                                      .map((lead) => lead.id.toString())
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
                              color: Colors.white,
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
                            Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              color: Colors.white,
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
                            Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: _buildDeliveryTypeDropdown(),
                              ),
                            ),
                            if (_askReasonForRefusal) ...[
                              const SizedBox(height: 8),
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                color: Colors.white,
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
                                Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  color: Colors.white,
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
