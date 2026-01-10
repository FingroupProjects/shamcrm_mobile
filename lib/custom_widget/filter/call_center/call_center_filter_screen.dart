import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/call_type_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/operator_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/rating_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/status_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/lead_manager_list.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_wh.dart';
import 'package:crm_task_manager/models/lead_multi_model.dart';
import 'package:crm_task_manager/models/page_2/operator_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_bloc.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_event.dart';

class CallCenterFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final List<String>? initialCallTypes;
  final List<String>? initialOperators;
  final List<String>? initialStatuses;
  final List<String>? initialRatings;
  final String? initialRemark;
  final bool? initialRemarkStatus;
  final String? initialStartDate;
  final String? initialEndDate;
  final List<String>? initialLeads;

  const CallCenterFilterScreen({
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialCallTypes,
    this.initialOperators,
    this.initialStatuses,
    this.initialRatings,
    this.initialRemark,
    this.initialRemarkStatus,
    this.initialStartDate,
    this.initialEndDate,
    this.initialLeads,
  }) : super(key: key);

  @override
  _CallCenterFilterScreenState createState() => _CallCenterFilterScreenState();
}

class CallCache {
  static Future<void> clearAllCalls() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('call_center_calls');
  }
}

class _CallCenterFilterScreenState extends State<CallCenterFilterScreen> {
  List<CallTypeData> _selectedCallTypes = [];
  List<Operator> _selectedOperators = [];
  List<StatusData> _selectedStatuses = [];
  List<RatingData> _selectedRatings = [];
  bool? selectedRemarkStatus;
  List<LeadData> _selectedLeads = [];
  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  Key _operatorSelectKey = UniqueKey();
  Key _ratingSelectKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _selectedCallTypes = widget.initialCallTypes
            ?.map((id) => CallTypeData(id: int.parse(id), name: ''))
            .toList() ??
        [];
    _selectedOperators = widget.initialOperators
            ?.map((id) => Operator(
                  id: int.parse(id),
                  name: '',
                  lastname: '',
                  login: '',
                  email: '',
                  phone: '',
                  image: '',
                  telegramUserId: null,
                  jobTitle: '',
                  fullName: '',
                  isFirstLogin: 0,
                  departmentId: null,
                  uniqueId: '',
                  operatorAvgRating: 0.0,
                ))
            .toList() ??
        [];
    _selectedStatuses = widget.initialStatuses
            ?.map((id) => StatusData(id: int.parse(id), name: ''))
            .toList() ??
        [];
    _selectedRatings = widget.initialRatings
            ?.map((id) => RatingData(id: int.parse(id), name: ''))
            .toList() ??
        [];
    _selectedLeads = widget.initialLeads
            ?.map((id) => LeadData(id: int.parse(id), name: ''))
            .toList() ??
        [];
    selectedRemarkStatus = widget.initialRemarkStatus;
    if (widget.initialStartDate != null) {
      startDate = DateTime.tryParse(widget.initialStartDate!);
      _startDateController.text = startDate != null
          ? DateFormat('dd/MM/yyyy').format(startDate!)
          : '';
    }
    if (widget.initialEndDate != null) {
      endDate = DateTime.tryParse(widget.initialEndDate!);
      _endDateController.text = endDate != null
          ? DateFormat('dd/MM/yyyy').format(endDate!)
          : '';
    }
    _loadFilterState();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final callTypesJson = prefs.getString('call_center_call_types');
      final operatorsJson = prefs.getString('call_center_operators');
      final statusesJson = prefs.getString('call_center_statuses');
      final ratingsJson = prefs.getString('call_center_ratings');
      final leadsJson = prefs.getString('call_center_leads');
      final startDateString = prefs.getString('call_center_start_date');
      final endDateString = prefs.getString('call_center_end_date');

      if (callTypesJson != null) {
        _selectedCallTypes = (jsonDecode(callTypesJson) as List)
            .map((item) => CallTypeData(id: int.parse(item['id'].toString()), name: item['name'] ?? ''))
            .toList();
      }
      if (operatorsJson != null) {
        _selectedOperators = (jsonDecode(operatorsJson) as List)
            .map((item) => Operator(
                  id: int.parse(item['id'].toString()),
                  name: '',
                  lastname: '',
                  login: '',
                  email: '',
                  phone: '',
                  image: '',
                  telegramUserId: null,
                  jobTitle: '',
                  fullName: item['name'] ?? '',
                  isFirstLogin: 0,
                  departmentId: null,
                  uniqueId: '',
                  operatorAvgRating: 0.0,
                ))
            .toList();
      }
      if (statusesJson != null) {
        _selectedStatuses = (jsonDecode(statusesJson) as List)
            .map((item) => StatusData(id: int.parse(item['id'].toString()), name: item['name'] ?? ''))
            .toList();
      }
      if (ratingsJson != null) {
        _selectedRatings = (jsonDecode(ratingsJson) as List)
            .map((item) => RatingData(id: int.parse(item['id'].toString()), name: item['name'] ?? ''))
            .toList();
      }
      if (leadsJson != null) {
        _selectedLeads = (jsonDecode(leadsJson) as List)
            .map((item) => LeadData(id: int.parse(item['id'].toString()), name: item['name'] ?? ''))
            .toList();
      }
      selectedRemarkStatus = prefs.getBool('call_center_remark_status');
      if (startDateString != null) {
        startDate = DateTime.tryParse(startDateString);
        _startDateController.text = startDate != null
            ? DateFormat('dd/MM/yyyy').format(startDate!)
            : '';
      }
      if (endDateString != null) {
        endDate = DateTime.tryParse(endDateString);
        _endDateController.text = endDate != null
            ? DateFormat('dd/MM/yyyy').format(endDate!)
            : '';
      }
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedCallTypes.isEmpty &&
        _selectedOperators.isEmpty &&
        _selectedStatuses.isEmpty &&
        _selectedRatings.isEmpty &&
        _selectedLeads.isEmpty &&
        selectedRemarkStatus == null &&
        startDate == null &&
        endDate == null) {
      // Очищаем все сохраненные фильтры
      await prefs.remove('call_center_call_types');
      await prefs.remove('call_center_operators');
      await prefs.remove('call_center_statuses');
      await prefs.remove('call_center_ratings');
      await prefs.remove('call_center_leads');
      await prefs.remove('call_center_remark_status');
      await prefs.remove('call_center_start_date');
      await prefs.remove('call_center_end_date');
    } else {
      // Сохраняем фильтры
      await prefs.setString(
          'call_center_call_types',
          jsonEncode(_selectedCallTypes.map((c) => {'id': c.id, 'name': c.name}).toList()));
      await prefs.setString(
          'call_center_operators',
          jsonEncode(_selectedOperators.map((o) => {'id': o.id, 'name': o.fullName}).toList()));
      await prefs.setString(
          'call_center_statuses',
          jsonEncode(_selectedStatuses.map((s) => {'id': s.id, 'name': s.name}).toList()));
      await prefs.setString(
          'call_center_ratings',
          jsonEncode(_selectedRatings.map((r) => {'id': r.id, 'name': r.name}).toList()));
      await prefs.setString(
          'call_center_leads',
          jsonEncode(_selectedLeads.map((l) => {'id': l.id, 'name': l.name}).toList()));
      if (selectedRemarkStatus != null) {
        await prefs.setBool('call_center_remark_status', selectedRemarkStatus!);
      } else {
        await prefs.remove('call_center_remark_status');
      }
      if (startDate != null) {
        await prefs.setString('call_center_start_date', startDate!.toIso8601String());
      } else {
        await prefs.remove('call_center_start_date');
      }
      if (endDate != null) {
        await prefs.setString('call_center_end_date', endDate!.toIso8601String());
      } else {
        await prefs.remove('call_center_end_date');
      }
    }
  }

void _resetFilters() {
  setState(() {
    _selectedCallTypes.clear();
    _selectedOperators.clear();
    _selectedStatuses.clear();
    _selectedRatings.clear();
    _selectedLeads.clear();
    selectedRemarkStatus = null;
    startDate = null;
    endDate = null;
    _startDateController.clear();
    _endDateController.clear();
    _operatorSelectKey = UniqueKey();
    _ratingSelectKey = UniqueKey();
  });

  widget.onResetFilters?.call();
  _saveFilterState();
  context.read<CallCenterBloc>().add(ResetFilters());

  // Уведомляем о сбросе фильтров
  widget.onSelectedDataFilter?.call({});
}

  bool _isAnyFilterSelected() {
    return _selectedCallTypes.isNotEmpty ||
        _selectedOperators.isNotEmpty ||
        _selectedStatuses.isNotEmpty ||
        _selectedRatings.isNotEmpty ||
        selectedRemarkStatus != null ||
        startDate != null ||
        endDate != null ||
        _selectedLeads.isNotEmpty;
  }

  void _handleRemarkStatusChanged(bool? status) {
    setState(() {
      selectedRemarkStatus = status;
      if (kDebugMode) {
        debugPrint('CallCenterFilterScreen: Remark status changed to: $selectedRemarkStatus');
      }
    });
  }

void _applyFilters() async {
  final prefs = await SharedPreferences.getInstance();

  if (!_isAnyFilterSelected()) {
    await prefs.setBool('call_center_filters_active', false);
    Navigator.pop(context);
    return;
  }


  await _saveFilterState();
  await CallCache.clearAllCalls();

  final filters = {
    'callTypes': _selectedCallTypes.isNotEmpty
        ? _selectedCallTypes.map((callType) => callType.id).toList()
        : null,
    'operators': _selectedOperators.isNotEmpty
        ? _selectedOperators.map((operator) => operator.id).toList()
        : null,
    'statuses': _selectedStatuses.isNotEmpty
        ? _selectedStatuses.map((status) => status.id).toList()
        : null,
    'ratings': _selectedRatings.isNotEmpty
        ? _selectedRatings.map((rating) => rating.id).toList()
        : null,
    'leads': _selectedLeads.isNotEmpty
        ? _selectedLeads.map((lead) => lead.id).toList()
        : null,
    'remarks': selectedRemarkStatus != null
        ? [selectedRemarkStatus == true ? 1 : 0]
        : null,
    'startDate': startDate != null ? startDate!.toIso8601String() : null,
    'endDate': endDate != null ? endDate!.toIso8601String() : null,
  };

  if (kDebugMode) {
    debugPrint('CallCenterFilterScreen: Applying filters: $filters');
  }

  widget.onSelectedDataFilter?.call(filters);
  context.read<CallCenterBloc>().add(FilterCalls(filters));
  Navigator.pop(context);
}
 void _handleBackPressed() {
  // Просто закрываем экран без дополнительных действий
  Navigator.pop(context);
}

@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      _handleBackPressed();
      return false; // Возвращаем false, так как мы сами управляем навигацией
    },
      child: Scaffold(
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
          leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _handleBackPressed,
        ),
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
                      // From Date
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: DateFieldWithFromTo(
                            isFrom: true,
                            controller: _startDateController,
                            label: AppLocalizations.of(context)!.translate('date'),
                            withTime: false,
                            onDateSelected: (date) {
                              if (mounted) {
                                setState(() {
                                  _startDateController.text = date;
                                  List<String> parts = date.split('/');
                                  if (parts.length == 3) {
                                    startDate = DateTime(
                                      int.parse(parts[2]),
                                      int.parse(parts[1]),
                                      int.parse(parts[0]),
                                    );
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // To Date
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: DateFieldWithFromTo(
                            isFrom: false,
                            controller: _endDateController,
                            label: AppLocalizations.of(context)!.translate('date') ?? 'До даты',
                            withTime: false,
                            onDateSelected: (date) {
                              if (mounted) {
                                setState(() {
                                  _endDateController.text = date;
                                  List<String> parts = date.split('/');
                                  if (parts.length == 3) {
                                    endDate = DateTime(
                                      int.parse(parts[2]),
                                      int.parse(parts[1]),
                                      int.parse(parts[0]),
                                    );
                                  }
                                });
                              }
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LeadMultiSelectWidget(
                                selectedLeads: _selectedLeads.map((lead) => lead.id.toString()).toList(),
                                onSelectLeads: (List<LeadData> selectedUsersData) {
                                  setState(() {
                                    _selectedLeads = selectedUsersData;
                                    if (kDebugMode) {
                                      debugPrint('CallCenterFilterScreen: Selected leads: ${_selectedLeads.map((l) => l.id).toList()}');
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: OperatorMultiSelectWidget(
                            key: _operatorSelectKey,
                            selectedOperators: _selectedOperators
                                .map((operator) => operator.id.toString())
                                .toList(),
                            onSelectOperators: (List<Operator> selectedOperators) {
                              setState(() {
                                _selectedOperators = selectedOperators;
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
                          child: RatingMultiSelectWidget(
                            key: _ratingSelectKey,
                            selectedRatings: _selectedRatings
                                .map((rating) => rating.id.toString())
                                .toList(),
                            onSelectRatings: (List<RatingData> selectedRatings) {
                              setState(() {
                                _selectedRatings = selectedRatings;
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
                              AppLocalizations.of(context)!.translate('with_remarks'),
                              selectedRemarkStatus ?? false,
                              _handleRemarkStatusChanged,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
           ] ),

        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black54,
          fontFamily: 'Gilroy',
        ),
      ),
      value: selectedRemarkStatus ?? false,
      onChanged: _handleRemarkStatusChanged,
      activeColor: const Color.fromARGB(255, 255, 255, 255),
      inactiveTrackColor: const Color.fromARGB(255, 179, 179, 179).withOpacity(0.5),
      activeTrackColor: ChatSmsStyles.messageBubbleSenderColor,
      inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
    );
  }
}