import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/call_type_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/operator_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/rating_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/status_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/lead_manager_list.dart';
import 'package:crm_task_manager/models/lead_multi_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:intl/intl.dart';

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
  }) : super(key: key);

  @override
  _CallCenterFilterScreenState createState() => _CallCenterFilterScreenState();
}

class _CallCenterFilterScreenState extends State<CallCenterFilterScreen> {
  List<CallTypeData> _selectedCallTypes = [];
  List<OperatorData> _selectedOperators = [];
  List<StatusData> _selectedStatuses = [];
  List<RatingData> _selectedRatings = [];
  bool? selectedRemarkStatus;
  List _selectedLeads = [];
  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  Key _callTypeSelectKey = UniqueKey();
  Key _operatorSelectKey = UniqueKey();
  Key _statusSelectKey = UniqueKey();
  Key _ratingSelectKey = UniqueKey();
  Key _remarkSelectKey = UniqueKey();
    bool _isOverdue = false;


  @override
  void initState() {
    super.initState();
    _selectedCallTypes = widget.initialCallTypes
            ?.map((id) => CallTypeData(id: int.parse(id), name: ''))
            .toList() ??
        [];
    _selectedOperators = widget.initialOperators
            ?.map((id) => OperatorData(id: int.parse(id), name: ''))
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
    selectedRemarkStatus = widget.initialRemarkStatus;
    if (widget.initialStartDate != null) {
      startDate = DateTime.tryParse(widget.initialStartDate!);
      _startDateController.text = startDate != null
          ? DateFormat('dd.MM.yyyy').format(startDate!)
          : '';
    }
    if (widget.initialEndDate != null) {
      endDate = DateTime.tryParse(widget.initialEndDate!);
      _endDateController.text = endDate != null
          ? DateFormat('dd.MM.yyyy').format(endDate!)
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
      final startDateString = prefs.getString('call_center_start_date');
      final endDateString = prefs.getString('call_center_end_date');

      if (callTypesJson != null) {
        _selectedCallTypes = (jsonDecode(callTypesJson) as List)
            .map((item) => CallTypeData(id: int.parse(item['id'].toString()), name: item['name'] ?? ''))
            .toList();
      }
      if (operatorsJson != null) {
        _selectedOperators = (jsonDecode(operatorsJson) as List)
            .map((item) => OperatorData(id: int.parse(item['id'].toString()), name: item['name'] ?? ''))
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
      selectedRemarkStatus = prefs.getBool('call_center_remark_status');
      if (startDateString != null) {
        startDate = DateTime.tryParse(startDateString);
        _startDateController.text = startDate != null
            ? DateFormat('dd.MM.yyyy').format(startDate!)
            : '';
      }
      if (endDateString != null) {
        endDate = DateTime.tryParse(endDateString);
        _endDateController.text = endDate != null
            ? DateFormat('dd.MM.yyyy').format(endDate!)
            : '';
      }
      _remarkSelectKey = UniqueKey();
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'call_center_call_types',
        jsonEncode(_selectedCallTypes.map((c) => {'id': c.id, 'name': c.name}).toList()));
    await prefs.setString(
        'call_center_operators',
        jsonEncode(_selectedOperators.map((o) => {'id': o.id, 'name': o.name}).toList()));
    await prefs.setString(
        'call_center_statuses',
        jsonEncode(_selectedStatuses.map((s) => {'id': s.id, 'name': s.name}).toList()));
    await prefs.setString(
        'call_center_ratings',
        jsonEncode(_selectedRatings.map((r) => {'id': r.id, 'name': r.name}).toList()));
    
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

  void _resetFilters() {
    setState(() {
      _selectedCallTypes.clear();
      _selectedOperators.clear();
      _selectedStatuses.clear();
      _selectedRatings.clear();
      selectedRemarkStatus = null;
      startDate = null;
      endDate = null;
      _startDateController.clear();
      _endDateController.clear();
      _callTypeSelectKey = UniqueKey();
      _operatorSelectKey = UniqueKey();
      _statusSelectKey = UniqueKey();
      _ratingSelectKey = UniqueKey();
      _remarkSelectKey = UniqueKey();
    });
    widget.onResetFilters?.call();
    _saveFilterState();
  }

  bool _isAnyFilterSelected() {
    return _selectedCallTypes.isNotEmpty ||
        _selectedOperators.isNotEmpty ||
        _selectedStatuses.isNotEmpty ||
        _selectedRatings.isNotEmpty ||
        selectedRemarkStatus != null ||
        startDate != null ||
        endDate != null;
  }

  void _handleRemarkStatusChanged(bool? status) {
    setState(() {
      selectedRemarkStatus = status;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
          _startDateController.text = DateFormat('dd.MM.yyyy').format(picked);
        } else {
          endDate = picked;
          _endDateController.text = DateFormat('dd.MM.yyyy').format(picked);
        }
      });
    }
  }

  void _applyFilters() async {
    await _saveFilterState();
    if (!_isAnyFilterSelected()) {
      widget.onResetFilters?.call();
    } else {
      widget.onSelectedDataFilter?.call({
        'callTypes': _selectedCallTypes.isNotEmpty
            ? _selectedCallTypes.map((callType) => callType.id.toString()).toList()
            : null,
        'operators': _selectedOperators.isNotEmpty
            ? _selectedOperators.map((operator) => operator.id.toString()).toList()
            : null,
        'statuses': _selectedStatuses.isNotEmpty
            ? _selectedStatuses.map((status) => status.id.toString()).toList()
            : null,
        'ratings': _selectedRatings.isNotEmpty
            ? _selectedRatings.map((rating) => rating.id.toString()).toList()
            : null,
        'remarks': selectedRemarkStatus != null 
            ? [selectedRemarkStatus == true ? "1" : "0"] 
            : null,
        'startDate': startDate != null ? startDate!.toIso8601String() : null,
        'endDate': endDate != null ? endDate!.toIso8601String() : null,
      });
    }
    Navigator.pop(context);
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
                    // Карточка для выбора диапазона дат
Card(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  color: Colors.white,
  child: Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('date_range'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _startDateController,
                readOnly: true,
                onTap: () => _selectDate(context, true),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate('from'),
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    color: Colors.blueAccent,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _endDateController,
                readOnly: true,
                onTap: () => _selectDate(context, false),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate('to'),
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    color: Colors.blueAccent,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
),

const SizedBox(height: 4),

// Отдельная карточка для мультиселекта лидов
Card(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  color: Colors.white,
  child: Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   AppLocalizations.of(context)!.translate('select_leads'),
        //   style: const TextStyle(
        //     fontSize: 16,
        //     fontWeight: FontWeight.w500,
        //     fontFamily: 'Gilroy',
        //     color: Color(0xff1E2E52),
        //   ),
        // ),
        // const SizedBox(height: 8),
        LeadMultiSelectWidget(
          selectedLeads: _selectedLeads.map((lead) => lead.id.toString()).toList(),
          onSelectLeads: (List<LeadData> selectedUsersData) {
            setState(() {
              _selectedLeads = selectedUsersData;
            });
          },
        ),
      ],
    ),
  ),
),

                    // const SizedBox(height: 8),
                    // Card(
                    //   shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(12)),
                    //   color: Colors.white,
                    //   child: Padding(
                    //     padding: const EdgeInsets.all(8),
                    //     child: CallTypeMultiSelectWidget(
                    //       key: _callTypeSelectKey,
                    //       selectedCallTypes: _selectedCallTypes
                    //           .map((callType) => callType.id.toString())
                    //           .toList(),
                    //       onSelectCallTypes: (List<CallTypeData> selectedCallTypes) {
                    //         setState(() {
                    //           _selectedCallTypes = selectedCallTypes;
                    //         });
                    //       },
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: OperatorMultiSelectWidget(
                          key: _operatorSelectKey,
                          selectedOperators: _selectedOperators
                              .map((operator) => operator.id.toString())
                              .toList(),
                          onSelectOperators: (List<OperatorData> selectedOperators) {
                            setState(() {
                              _selectedOperators = selectedOperators;
                            });
                          },
                        ),
                      ),
                    ),
                    // const SizedBox(height: 8),
                    // Card(
                    //   shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(12)),
                    //   color: Colors.white,
                    //   child: Padding(
                    //     padding: const EdgeInsets.all(8),
                    //     child: StatusMultiSelectWidget(
                    //       key: _statusSelectKey,
                    //       selectedStatuses: _selectedStatuses
                    //           .map((status) => status.id.toString())
                    //           .toList(),
                    //       onSelectStatuses: (List<StatusData> selectedStatuses) {
                    //         setState(() {
                    //           _selectedStatuses = selectedStatuses;
                    //         });
                    //       },
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('remark'),
                            _isOverdue,
                            (value) => setState(() => _isOverdue = value),
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

class RemarkStatusSelector extends StatefulWidget {
  final Function(bool?) onStatusChanged;
  final bool? initialStatus;

  const RemarkStatusSelector({
    Key? key,
    required this.onStatusChanged,
    this.initialStatus,
  }) : super(key: key);

  @override
  _RemarkStatusSelectorState createState() => _RemarkStatusSelectorState();
}

class _RemarkStatusSelectorState extends State<RemarkStatusSelector> {
  bool? selectedStatus;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.initialStatus;
  }

  @override
  void didUpdateWidget(covariant RemarkStatusSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatus != oldWidget.initialStatus) {
      setState(() {
        selectedStatus = widget.initialStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Checkbox(
                value: selectedStatus == true,
                onChanged: (bool? value) {
                  setState(() {
                    selectedStatus = value == true ? true : null;
                  });
                  widget.onStatusChanged(selectedStatus);
                },
                activeColor: Colors.blueAccent,
                checkColor: Colors.white,
              ),
              Text(
                AppLocalizations.of(context)!.translate('yes'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Checkbox(
                value: selectedStatus == false,
                onChanged: (bool? value) {
                  setState(() {
                    selectedStatus = value == true ? false : null;
                  });
                  widget.onStatusChanged(selectedStatus);
                },
                activeColor: Colors.blueAccent,
                checkColor: Colors.white,
              ),
              Text(
                AppLocalizations.of(context)!.translate('no'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}