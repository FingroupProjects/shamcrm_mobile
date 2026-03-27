import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/lead_manager_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_manager_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_region_list.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/models/lead_multi_model.dart';
import 'package:crm_task_manager/page_2/order/order_details/payment_method_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/status_method_dropdown.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OrdersFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final String? initialClient;
  final String? initialStatus;
  final String? initialPaymentMethod;
  final List<String>? initialManagers;
  final List<String>? initialRegions;
  final List<String>? initialLeads;

  const OrdersFilterScreen({
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialFromDate,
    this.initialToDate,
    this.initialClient,
    this.initialStatus,
    this.initialPaymentMethod,
    this.initialManagers,
    this.initialRegions,
    this.initialLeads,
  }) : super(key: key);

  @override
  _OrdersFilterScreenState createState() => _OrdersFilterScreenState();
}

class _OrdersFilterScreenState extends State<OrdersFilterScreen> {
  final TextEditingController _clientController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedStatus;
  String? _selectedPaymentMethod;
  List<ManagerData> _selectedManagers = [];
  List<RegionData> _selectedRegions = [];
  List<LeadData> _selectedLeads = [];
  Key _paymentDropdownKey = UniqueKey();
  Key _statusDropdownKey = UniqueKey();
  Key _managerSelectKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _clientController.text = widget.initialClient ?? '';
    _selectedStatus = widget.initialStatus;
    _selectedPaymentMethod = widget.initialPaymentMethod;
    _selectedManagers = widget.initialManagers?.map((id) => ManagerData(id: int.parse(id), name: '')).toList() ?? [];
    _selectedRegions = widget.initialRegions?.map((id) => RegionData(id: int.parse(id), name: '')).toList() ?? [];
    _selectedLeads = widget.initialLeads?.map((id) => LeadData(id: int.parse(id), name: '')).toList() ?? [];
    _loadFilterState();
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final fromDateMillis = prefs.getInt('order_from_date');
      final toDateMillis = prefs.getInt('order_to_date');
      if (fromDateMillis != null) _fromDate = DateTime.fromMillisecondsSinceEpoch(fromDateMillis);
      if (toDateMillis != null) _toDate = DateTime.fromMillisecondsSinceEpoch(toDateMillis);
      _clientController.text = prefs.getString('order_client') ?? widget.initialClient ?? '';
      _selectedStatus = prefs.getString('order_status') ?? widget.initialStatus;
      _selectedPaymentMethod = prefs.getString('order_payment_method') ?? widget.initialPaymentMethod;
      final managersJson = prefs.getString('order_managers');
      final regionsJson = prefs.getString('order_regions');
      final leadsJson = prefs.getString('order_leads');
      if (managersJson != null) {
        _selectedManagers = (jsonDecode(managersJson) as List)
            .map((item) => ManagerData(id: int.parse(item['id'].toString()), name: item['name'] ?? ''))
            .toList();
      }
      if (regionsJson != null) {
        _selectedRegions = (jsonDecode(regionsJson) as List)
            .map((item) => RegionData(id: int.parse(item['id'].toString()), name: item['name'] ?? ''))
            .toList();
      }
      if (leadsJson != null) {
        _selectedLeads = (jsonDecode(leadsJson) as List)
            .map((item) => LeadData(id: int.parse(item['id'].toString()), name: item['name'] ?? ''))
            .toList();
      }
      ////print('Loaded filter state: fromDate=$_fromDate, toDate=$_toDate, client=${_clientController.text}, status=$_selectedStatus, paymentMethod=$_selectedPaymentMethod, managers=$_selectedManagers, leads=$_selectedLeads');
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    ////print('Saving filter state...');
    if (_fromDate != null) {
      await prefs.setInt('order_from_date', _fromDate!.millisecondsSinceEpoch);
      ////print('Saved order_from_date: ${_fromDate!.millisecondsSinceEpoch}');
    } else {
      await prefs.remove('order_from_date');
      ////print('Removed order_from_date');
    }
    if (_toDate != null) {
      await prefs.setInt('order_to_date', _toDate!.millisecondsSinceEpoch);
      ////print('Saved order_to_date: ${_toDate!.millisecondsSinceEpoch}');
    } else {
      await prefs.remove('order_to_date');
      ////print('Removed order_to_date');
    }
    await prefs.setString('order_client', _clientController.text);
    ////print('Saved order_client: ${_clientController.text}');
    if (_selectedStatus != null) {
      await prefs.setString('order_status', _selectedStatus!);
      ////print('Saved order_status: $_selectedStatus');
    } else {
      await prefs.remove('order_status');
      ////print('Removed order_status');
    }
    if (_selectedPaymentMethod != null) {
      await prefs.setString('order_payment_method', _selectedPaymentMethod!);
      ////print('Saved order_payment_method: $_selectedPaymentMethod');
    } else {
      await prefs.remove('order_payment_method');
      ////print('Removed order_payment_method');
    }
    await prefs.setString('order_managers', jsonEncode(_selectedManagers.map((m) => {'id': m.id, 'name': m.name}).toList()));
    ////print('Saved order_managers: ${_selectedManagers.map((m) => {'id': m.id, 'name': m.name}).toList()}');
    await prefs.setString('order_regions', jsonEncode(_selectedRegions.map((r) => {'id': r.id, 'name': r.name}).toList()));
    ////print('Saved order_regions: ${_selectedRegions.map((r) => {'id': r.id, 'name': r.name}).toList()}');
    await prefs.setString('order_leads', jsonEncode(_selectedLeads.map((l) => {'id': l.id, 'name': l.name}).toList()));
    ////print('Saved order_leads: ${_selectedLeads.map((l) => {'id': l.id, 'name': l.name}).toList()}');
  }

  void _resetFilters() {
    ////print('Resetting filters...');
    setState(() {
      _fromDate = null;
      _toDate = null;
      _clientController.text = '';
      _selectedStatus = null;
      _selectedPaymentMethod = null;
      _selectedManagers.clear();
      _selectedRegions.clear();
      _selectedLeads.clear();
      _paymentDropdownKey = UniqueKey();
      _statusDropdownKey = UniqueKey();
      _managerSelectKey = UniqueKey();
      ////print('After reset: fromDate=$_fromDate, toDate=$_toDate, client=${_clientController.text}, status=$_selectedStatus, paymentMethod=$_selectedPaymentMethod, managers=$_selectedManagers, leads=$_selectedLeads');
    });
    widget.onResetFilters?.call();
    _saveFilterState();
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

  bool _isAnyFilterSelected() {
    return _fromDate != null ||
        _toDate != null ||
        _clientController.text.isNotEmpty ||
        _selectedStatus != null ||
        _selectedPaymentMethod != null ||
        _selectedManagers.isNotEmpty ||
        _selectedRegions.isNotEmpty ||
        _selectedLeads.isNotEmpty;
  }

  void _applyFilters() async {
    await _saveFilterState();
    if (!_isAnyFilterSelected()) {
      ////print('No filters selected, resetting filters');
      widget.onResetFilters?.call();
    } else {
      // Set from date to 00:00:00 and to date to 23:59:59
      DateTime? fromDateWithTime = _fromDate;
      DateTime? toDateWithTime = _toDate;
      
      if (fromDateWithTime != null) {
        fromDateWithTime = DateTime(fromDateWithTime.year, fromDateWithTime.month, fromDateWithTime.day, 0, 0, 0);
      }
      if (toDateWithTime != null) {
        toDateWithTime = DateTime(toDateWithTime.year, toDateWithTime.month, toDateWithTime.day, 23, 59, 59);
      }
      
      widget.onSelectedDataFilter?.call({
        'fromDate': fromDateWithTime,
        'toDate': toDateWithTime,
        'client': _clientController.text.isNotEmpty ? _clientController.text : null,
        'status': _selectedStatus,
        'paymentMethod': _selectedPaymentMethod,
        'managers': _selectedManagers.isNotEmpty
            ? _selectedManagers.map((manager) => manager.id.toString()).toList()
            : null,
        'regions': _selectedRegions.isNotEmpty
            ? _selectedRegions.map((region) => region.id.toString()).toList()
            : null,
        'leads': _selectedLeads.isNotEmpty
            ? _selectedLeads.map((lead) => lead.id.toString()).toList()
            : null,
      });
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fromDate != null && _toDate != null
                                    ? "${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year} - ${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}"
                                    : AppLocalizations.of(context)!
                                        .translate('select_date_range'),
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: _fromDate != null && _toDate != null
                                      ? Colors.black
                                      : const Color(0xff99A4BA),
                                  fontSize: 14,
                                ),
                              ),
                              const Icon(Icons.calendar_today,
                                  color: Color(0xff99A4BA)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: ManagerMultiSelectWidget(
                          // key: _managerSelectKey,
                          selectedManagers: _selectedManagers
                              .map((manager) => manager.id.toString()).toList(),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: RegionsMultiSelectWidget(
                          selectedRegions: _selectedRegions
                              .map((region) => region.id.toString()).toList(),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: LeadMultiSelectWidget(
                          selectedLeads: _selectedLeads
                              .map((lead) => lead.id.toString()).toList(),
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