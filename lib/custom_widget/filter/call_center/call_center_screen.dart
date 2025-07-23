
import 'package:crm_task_manager/custom_widget/filter/call_center/call_type_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/operator_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/rating_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/remark_text_field_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/status_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/deal/lead_manager_list.dart';
import 'package:crm_task_manager/models/lead_multi_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class CallCenterFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final List<String>? initialCallTypes;
  final List<String>? initialOperators;
  final List<String>? initialStatuses;
  final List<String>? initialRatings;
  final String? initialRemark;
    final List<String>? initialRemarks; // Изменено с String? на List<String>?


  const CallCenterFilterScreen({
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialCallTypes,
    this.initialOperators,
    this.initialStatuses,
        this.initialRemarks, // Изменено

    this.initialRatings,
    this.initialRemark,
  }) : super(key: key);


  @override
  _CallCenterFilterScreenState createState() => _CallCenterFilterScreenState();
}

class _CallCenterFilterScreenState extends State<CallCenterFilterScreen> {
  List<CallTypeData> _selectedCallTypes = [];
  List<OperatorData> _selectedOperators = [];
  List<StatusData> _selectedStatuses = [];
  List<RatingData> _selectedRatings = [];
    List<RemarkData> _selectedRemarks = []; // Изменено с TextEditingController
  List _selectedLeads = [];

  Key _callTypeSelectKey = UniqueKey();
  Key _operatorSelectKey = UniqueKey();
  Key _statusSelectKey = UniqueKey();
  Key _ratingSelectKey = UniqueKey();
   Key _remarkSelectKey = UniqueKey(); // Добавлен ключ для замечаний

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
    _selectedRemarks = widget.initialRemarks
            ?.map((id) => RemarkData(id: int.parse(id), name: ''))
            .toList() ??
        []; // Изменено
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final callTypesJson = prefs.getString('call_center_call_types');
      final operatorsJson = prefs.getString('call_center_operators');
      final statusesJson = prefs.getString('call_center_statuses');
      final ratingsJson = prefs.getString('call_center_ratings');
      final remarksJson = prefs.getString('call_center_remarks'); // Изменено


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
     await prefs.setString(
        'call_center_remarks',
        jsonEncode(_selectedRemarks.map((r) => {'id': r.id, 'name': r.name}).toList())); // Изменено
  }

  void _resetFilters() {
    setState(() {
      _selectedCallTypes.clear();
      _selectedOperators.clear();
      _selectedStatuses.clear();
      _selectedRatings.clear();
      _selectedRemarks.clear(); // Изменено
      _callTypeSelectKey = UniqueKey();
      _operatorSelectKey = UniqueKey();
      _statusSelectKey = UniqueKey();
      _ratingSelectKey = UniqueKey();
            _remarkSelectKey = UniqueKey(); // Добавлено

    });
    widget.onResetFilters?.call();
    _saveFilterState();
  }

  bool _isAnyFilterSelected() {
    return _selectedCallTypes.isNotEmpty ||
        _selectedOperators.isNotEmpty ||
        _selectedStatuses.isNotEmpty ||
        _selectedRatings.isNotEmpty ||
         _selectedRemarks.isNotEmpty; // Изменено
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
           'remarks': _selectedRemarks.isNotEmpty
            ? _selectedRemarks.map((remark) => remark.id.toString()).toList()
            : null, // Изменено
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: LeadMultiSelectWidget(
                          selectedLeads: _selectedLeads.map((lead) => lead.id.toString()).toList(),
                          onSelectLeads: (List<LeadData> selectedUsersData) {
                            setState(() {
                              _selectedLeads = selectedUsersData;
                              //print("Selected Leads updated: $_selectedLeads");
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
                        child: CallTypeMultiSelectWidget(
                          key: _callTypeSelectKey,
                          selectedCallTypes: _selectedCallTypes
                              .map((callType) => callType.id.toString())
                              .toList(),
                          onSelectCallTypes: (List<CallTypeData> selectedCallTypes) {
                            setState(() {
                              _selectedCallTypes = selectedCallTypes;
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
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: StatusMultiSelectWidget(
                          key: _statusSelectKey,
                          selectedStatuses: _selectedStatuses
                              .map((status) => status.id.toString())
                              .toList(),
                          onSelectStatuses: (List<StatusData> selectedStatuses) {
                            setState(() {
                              _selectedStatuses = selectedStatuses;
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
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: RemarkMultiSelectWidget(
                          key: _remarkSelectKey,
                          selectedRemarks: _selectedRemarks
                              .map((remark) => remark.id.toString())
                              .toList(),
                          onSelectRemarks: (List<RemarkData> selectedRemarks) {
                            setState(() {
                              _selectedRemarks = selectedRemarks;
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
