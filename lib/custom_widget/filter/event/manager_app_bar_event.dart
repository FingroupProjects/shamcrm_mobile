import 'package:crm_task_manager/custom_widget/filter/event/event_status_list.dart';
import 'package:crm_task_manager/custom_widget/filter/event/multi_manager_list.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';


class EventManagerFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onManagersSelected;
  final Function(int?)? onStatusSelected;
  final Function(DateTime?, DateTime?)? onDateRangeSelected;
  final Function(int?, DateTime?, DateTime?)? onStatusAndDateRangeSelected;
  final Function(DateTime?, DateTime?)? onNoticeDateRangeSelected;
  final Function(int?, DateTime?, DateTime?)? onNoticeStatusAndDateRangeSelected;
  final Function(int?, DateTime?, DateTime?, DateTime?, DateTime?)? onDateNoticeStatusAndDateRangeSelected;
  final Function(DateTime?, DateTime?, DateTime?, DateTime?)? onDateNoticeAndDateRangeSelected;
  final List? initialManagers;
  final int? initialStatuses;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final DateTime? initialNoticeFromDate;
  final DateTime? initialNoticeToDate;
  final VoidCallback? onResetFilters;

  EventManagerFilterScreen({
    Key? key,
    this.onManagersSelected,
    this.onStatusSelected,
    this.onDateRangeSelected,
    this.onStatusAndDateRangeSelected,
    this.onNoticeDateRangeSelected,
    this.onNoticeStatusAndDateRangeSelected,
    this.onDateNoticeStatusAndDateRangeSelected,
    this.onDateNoticeAndDateRangeSelected,
    this.initialManagers,
    this.initialStatuses,
    this.initialFromDate,
    this.initialToDate,
    this.initialNoticeFromDate,
    this.initialNoticeToDate,
    this.onResetFilters, 
  }) : super(key: key);

  @override
  _EventManagerFilterScreenState createState() => _EventManagerFilterScreenState();
}

class _EventManagerFilterScreenState extends State<EventManagerFilterScreen> {
  List _selectedManagers = [];
  int? _selectedStatuses;
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _NoticefromDate;
  DateTime? _NoticetoDate;

  @override
  void initState() {
    super.initState();
    _selectedManagers = widget.initialManagers ?? [];
    _selectedStatuses = widget.initialStatuses;
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _NoticefromDate = widget.initialNoticeFromDate;
    _NoticetoDate = widget.initialNoticeToDate;
  }

void _selectDateRange() async {
  final screenWidth = MediaQuery.of(context).size.width;
  final double dialogWidth = screenWidth > 600 ? 400 : screenWidth * 0.8;
  final DateTimeRange? pickedRange = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
    initialDateRange: _fromDate != null && _toDate != null
        ? DateTimeRange(start: _fromDate!, end: _toDate!)
        : null,
    builder: (context, child) {
      return Dialog(
        child: Container(
          width: dialogWidth, 
          child: child,
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

void _selectNoticeDateRange() async {
  final screenWidth = MediaQuery.of(context).size.width;
  final double dialogWidth = screenWidth > 600 ? 400 : screenWidth * 0.8;

  final DateTimeRange? pickedRange = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
    initialDateRange: _NoticefromDate != null && _NoticetoDate != null
        ? DateTimeRange(start: _NoticefromDate!, end: _NoticetoDate!)
        : null,
    builder: (context, child) {
      return Dialog(
        child: Container(
          width: dialogWidth,
          child: child,
        ),
      );
    },
  );

  if (pickedRange != null) {
    setState(() {
      _NoticefromDate = pickedRange.start;
      _NoticetoDate = pickedRange.end;
    });
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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xfff1E2E52), fontFamily: 'Gilroy'),
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
                _selectedStatuses = null;
                _fromDate = null;
                _toDate = null;
                _NoticefromDate = null;
                _NoticetoDate = null;
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
              if (_selectedManagers.isNotEmpty) {
                print('MANAGER');
                widget.onManagersSelected?.call({
                  'managers': _selectedManagers,
                  'statuses': _selectedStatuses,
                  'fromDate': _fromDate,
                  'toDate': _toDate,
                  'noticefromDate': _NoticefromDate,
                  'noticetoDate': _NoticetoDate,
                });
              } else if (_selectedStatuses != null && _fromDate == null && _toDate == null && _NoticefromDate == null && _NoticetoDate == null) {
                print('STATUS');
          
                widget.onStatusSelected?.call(_selectedStatuses);
              } else if (_fromDate != null && _toDate != null && _selectedStatuses == null && _NoticefromDate == null && _NoticetoDate == null) {
                print('DATE');
          
                widget.onDateRangeSelected?.call(_fromDate, _toDate);

              } else if (_NoticefromDate != null && _NoticetoDate != null && _selectedStatuses == null && _fromDate == null && _toDate == null) {
                print('DATE NOTICE');
          
                widget.onNoticeDateRangeSelected?.call(_NoticefromDate, _NoticetoDate);
              } else if (_fromDate != null && _toDate != null && _selectedStatuses != null && _NoticefromDate == null && _NoticetoDate == null) {
                print('STATUS + DATE');

                widget.onStatusAndDateRangeSelected?.call(_selectedStatuses, _toDate, _fromDate);
              } else if (_NoticefromDate != null && _NoticetoDate != null && _selectedStatuses != null && _fromDate == null && _toDate == null) {
                print('STATUS + NOTICE DATE');

                widget.onNoticeStatusAndDateRangeSelected?.call(_selectedStatuses, _NoticefromDate, _NoticetoDate);
              } else if (_NoticefromDate != null && _NoticetoDate != null && _selectedStatuses != null && _fromDate != null && _toDate != null) {
                print('STATUS + DATE+ NOTICE DATE');

                widget.onDateNoticeStatusAndDateRangeSelected?.call(_selectedStatuses, _fromDate,_toDate ,_NoticefromDate, _NoticetoDate);
              } else if (_NoticefromDate != null && _NoticetoDate != null && _selectedStatuses == null && _fromDate != null && _toDate != null) {
                print('DATE + NOTICE DATE');

                widget.onDateNoticeAndDateRangeSelected?.call(_fromDate,_toDate ,_NoticefromDate, _NoticetoDate);
              } else {
                
                print('NOTHING!!!!!!');
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
                            : AppLocalizations.of(context)!.translate('enter_date_range_create'),
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                      Icon(Icons.calendar_today, color: Colors.black54),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: GestureDetector(
                onTap: _selectNoticeDateRange,
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
                        _NoticefromDate != null && _NoticetoDate != null
                            ? "${_NoticefromDate!.day.toString().padLeft(2, '0')}.${_NoticefromDate!.month.toString().padLeft(2, '0')}.${_NoticefromDate!.year} - ${_NoticetoDate!.day.toString().padLeft(2, '0')}.${_NoticetoDate!.month.toString().padLeft(2, '0')}.${_NoticetoDate!.year}"
                            : AppLocalizations.of(context)!.translate('enter_date_range_notice'),
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                      Icon(Icons.calendar_today, color: Colors.black54),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: EventManagerMultiSelectWidget(
                          selectedManagers: _selectedManagers.map((manager) => manager.id.toString()).toList(),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: EventStatusRadioGroupWidget(
                          key: ValueKey(_selectedStatuses),
                          selectedStatus: _selectedStatuses?.toString(), 
                          onSelectStatus: (int selectedStatusId) {        
                            setState(() {
                              _selectedStatuses = selectedStatusId;       
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