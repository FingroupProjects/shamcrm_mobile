import 'package:crm_task_manager/bloc/calendar/calendar_bloc.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_event.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_state.dart';
import 'package:crm_task_manager/screens/event/event_details/event_details_screen.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/task_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'calendar_components.dart';
import 'calendar_utils.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  Map<DateTime, List<CalendarEventData>> _events = {};
  bool _isInitialView = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  void _handleEventTap(int id, String type) {
    switch (type) {
      case 'task':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsScreen(
              taskId: id.toString(),
              taskName: '',
              taskStatus: '',
              statusId: 1,
              taskNumber: 0,
              taskCustomFields: [],
            ),
          ),
        );
        break;
      case 'my_task':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyTaskDetailsScreen(
              taskId: id.toString(),
              taskName: '',
              taskStatus: '',
              statusId: 0,
              taskNumber: 0,
            ),
          ),
        );
        break;
      case 'notice':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              noticeId: id,
            ),
          ),
        );
        break;
      default:
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<CalendarBloc>().add(FetchCalendarEvents(_focusedDate.month, _focusedDate.year));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _changeView(String view) {
    setState(() {
      switch (view) {
        case 'day':
          _calendarFormat = CalendarFormat.twoWeeks;
          break;
        case 'week':
          _calendarFormat = CalendarFormat.week;
          break;
        case 'month':
          _calendarFormat = CalendarFormat.month;
          break;
      }
      _selectedDate = null;
    });
  }

  void _onDateSelected(DateTime selectedDate, DateTime focusedDate) {
    setState(() {
      _selectedDate = selectedDate;
      _focusedDate = focusedDate;
    });
  }

  void _onSearchPressed() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        // Здесь можно добавить логику сброса поиска
      }
    });
  }

  void _onFilterPressed() {
    // Ваша логика фильтрации
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.translate('search'),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(bottom: 10),
                  ),
                  style: TextStyle(fontSize: 18, fontFamily: 'Gilroy',fontWeight: FontWeight.w500, color: Color(0xff1E2E52)),
                  onChanged: (value) {

                  },
                ),
              )
            : GestureDetector(
                onTap: () => _showYearPicker(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isInitialView
                          ? AppLocalizations.of(context)!.translate('calendar')
                          : DateFormat('yyyy', AppLocalizations.of(context)!.locale.languageCode)
                              .format(_focusedDate)
                              .capitalize(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, size: 24),
                  ],
                ),
              ),
        backgroundColor: Colors.white,
        leadingWidth: 50,
        leading: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Transform.translate(
            offset: const Offset(0, -2),
            child: IconButton(
              icon: Image.asset(
                'assets/icons/arrow-left.png',
                width: 24,
                height: 24,
              ),
              onPressed: () async {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: _isSearching
                ? Icon(Icons.close, size: 24)
                : Image.asset(
                    'assets/icons/AppBar/search.png',
                    width: 24,
                    height: 24,
                  ),
            onPressed: _onSearchPressed,
          ),
          IconButton(
            icon: Image.asset(
              'assets/icons/AppBar/filter.png', 
              width: 24,
              height: 24,
            ),
            onPressed: _onFilterPressed,
          ),
          if (!_isSearching)
            CalendarViewDropdown(
              currentFormat: _calendarFormat,
              onChange: _changeView,
            ),
        ],
      ),
      body: BlocConsumer<CalendarBloc, CalendarBlocState>(
        listener: (context, state) {
          if (state is CalendarLoaded) {
            setState(() {
              _events.clear();
              for (var event in state.events) {
                final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
                _events[eventDate] = _events[eventDate] ?? [];
                _events[eventDate]!.add(
                  CalendarEventData(
                    id: event.id,
                    title: event.name,
                    date: event.date,
                    startTime: event.date,
                    endTime: event.date.add(Duration(hours: 1)),
                    color: CalendarUtils.getEventColor(event.type),
                    type: event.type,
                  ),
                );
              }
            });
          } else if (state is CalendarError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is CalendarLoading) {
            return Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                CalendarWidget(
                  calendarFormat: _calendarFormat,
                  focusedDate: _focusedDate,
                  selectedDate: _selectedDate,
                  events: _events,
                  onDaySelected: _onDateSelected,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDate = focusedDay;
                      _selectedDate = null;
                    });
                    context.read<CalendarBloc>().add(FetchCalendarEvents(_focusedDate.month, _focusedDate.year));
                  },
                ),
                if (_selectedDate != null)
                  EventListForDate(
                    selectedDate: _selectedDate!,
                    events: _events,
                    onEventTap: (id, type) => _handleEventTap(id, type),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showOptionsBottomSheet(context, _focusedDate, _events, setState),
        backgroundColor: Color(0xff1E2E52),
        child: Image.asset(
          'assets/icons/tabBar/add.png',
          width: 24,
          height: 24,
        ),
      ),
    );
  }

  void _showYearPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => YearPickerDialog(
        focusedDate: _focusedDate,
        onYearSelected: (year) {
          Navigator.pop(context);
          _showMonthPicker(context, year);
        },
      ),
    );
  }

  void _showMonthPicker(BuildContext context, int selectedYear) {
    showDialog(
      context: context,
      builder: (context) => MonthPickerDialog(
        selectedYear: selectedYear,
        focusedDate: _focusedDate,
        onMonthSelected: (month) {
          setState(() {
            _focusedDate = DateTime(selectedYear, month, _focusedDate.day);
            _selectedDate = null;
            _isInitialView = false;
          });
          context.read<CalendarBloc>().add(FetchCalendarEvents(_focusedDate.month, _focusedDate.year));
          Navigator.pop(context);
        },
      ),
    );
  }
}