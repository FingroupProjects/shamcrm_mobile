import 'package:calendar_view/calendar_view.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_bloc.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_event.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_state.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final EventController _eventController = EventController();
  String _currentView = 'month'; // Default view: month, day, week, year
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Fetch events for the current month
    _fetchEventsForMonth();
  }

  void _fetchEventsForMonth() {
    context.read<CalendarBloc>().add(FetchCalendarEvents(
          _focusedDate.month,
          _focusedDate.year,
        ));
  }

  void _changeView(String view) {
    setState(() {
      _currentView = view;
      _selectedDate = null; // Reset selected date when view changes
    });
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _focusedDate = date;
      _selectedDate = null; // Reset selected date when focused date changes
      _fetchEventsForMonth();
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _showOptionsBottomSheet(BuildContext context, DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.task, color: Colors.blue),
                title: Text(
                  AppLocalizations.of(context)!.translate('task'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to Task screen (to be specified)
                },
              ),
              ListTile(
                leading: Icon(Icons.event, color: Colors.green),
                title: Text(
                  AppLocalizations.of(context)!.translate('event'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAddEventDialog(context, date);
                },
              ),
              ListTile(
                leading: Icon(Icons.assignment, color: Colors.purple),
                title: Text(
                  AppLocalizations.of(context)!.translate('my_tasks'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to My Tasks screen (to be specified)
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddEventDialog(BuildContext context, DateTime date) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime startTime = date;
    DateTime endTime = date.add(Duration(hours: 1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('add_event')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.translate('event_title'),
              ),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.translate('event_description'),
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('start_time')),
              subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(startTime)),
              onTap: () async {
                final picked = await showDateTimePicker(context, startTime);
                if (picked != null) {
                  setState(() {
                    startTime = picked;
                  });
                }
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.translate('end_time')),
              subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(endTime)),
              onTap: () async {
                final picked = await showDateTimePicker(context, endTime);
                if (picked != null) {
                  setState(() {
                    endTime = picked;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                _eventController.add(
                  CalendarEventData(
                    title: titleController.text,
                    description: descriptionController.text,
                    date: date,
                    startTime: startTime,
                    endTime: endTime,
                    color: Colors.blue,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.translate('save')),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> showDateTimePicker(BuildContext context, DateTime initialDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (time != null) {
        return DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      }
    }
    return null;
  }

  void _showYearPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.translate('select_year')),
        content: Container(
          width: double.maxFinite,
          height: 200,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12, // Years from 2025 to 2036
            itemBuilder: (context, index) {
              final year = 2025 + index;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showMonthPicker(context, year);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: year == _focusedDate.year ? Colors.blue : Colors.grey.withOpacity(0.2),
                  ),
                  child: Center(
                    child: Text(
                      year.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: year == _focusedDate.year ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context, int selectedYear) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.translate('select_month')),
        content: Container(
          width: double.maxFinite,
          height: 200,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final monthDate = DateTime(selectedYear, month, 1);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _focusedDate = DateTime(selectedYear, month, _focusedDate.day);
                    _selectedDate = null; // Reset selected date
                  });
                  _fetchEventsForMonth();
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: month == _focusedDate.month && selectedYear == _focusedDate.year
                        ? Colors.blue
                        : Colors.grey.withOpacity(0.2),
                  ),
                  child: Center(
                    child: Text(
                      DateFormat('MMM').format(monthDate).toLowerCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: month == _focusedDate.month && selectedYear == _focusedDate.year
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(DateTime date) {
    return GestureDetector(
      onTap: () => _showYearPicker(context),
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(date).capitalize(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_drop_down, color: Color(0xff1E2E52)),
          ],
        ),
      ),
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'task':
        return Colors.green; // Green for tasks
      case 'my_task':
        return Colors.blue; // Blue for my_tasks
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CalendarControllerProvider(
      controller: _eventController,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.translate('calendar')),
          elevation: 0,
          backgroundColor: Colors.white,
          actions: [
            DropdownButton<String>(
              value: _currentView,
              dropdownColor: Colors.white,
              items: [
                DropdownMenuItem(
                  value: 'day',
                  child: Text(AppLocalizations.of(context)!.translate('day')),
                ),
                DropdownMenuItem(
                  value: 'week',
                  child: Text(AppLocalizations.of(context)!.translate('week')),
                ),
                DropdownMenuItem(
                  value: 'month',
                  child: Text(AppLocalizations.of(context)!.translate('month')),
                ),
                DropdownMenuItem(
                  value: 'year',
                  child: Text(AppLocalizations.of(context)!.translate('year')),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  _changeView(value);
                }
              },
            ),
          ],
        ),
        body: BlocConsumer<CalendarBloc, CalendarBlocState>(
          listener: (context, state) {
            if (state is CalendarLoaded) {
              _eventController.removeWhere((event) => true); // Clear existing events
              for (var event in state.events) {
                _eventController.add(
                  CalendarEventData(
                    title: event.name,
                    date: event.date,
                    startTime: event.date,
                    endTime: event.date.add(Duration(hours: 1)),
                    color: _getEventColor(event.type),
                  ),
                );
              }
            } else if (state is CalendarError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is CalendarLoading) {
              return Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                _buildCustomHeader(_focusedDate),
                Expanded(
                  child: _buildCalendarContent(),
                ),
                if (_selectedDate != null) _buildEventListForSelectedDate(state),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showOptionsBottomSheet(context, _focusedDate),
          child: Icon(Icons.add),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildCalendarContent() {
    switch (_currentView) {
      case 'day':
        return DayView(
          controller: _eventController,
          heightPerMinute: 1.0,
          eventTileBuilder: _buildEventTile,
          onEventTap: (date, events) {
            _onDateSelected(date as DateTime);
          },
        );
      case 'week':
        return WeekView(
          controller: _eventController,
          heightPerMinute: 1.0,
          eventTileBuilder: _buildEventTile,
          onEventTap: (date, events) {
            _onDateSelected(date as DateTime);
          },
        );
      case 'month':
        return MonthView(
          controller: _eventController,
          cellAspectRatio: 1.0,
          headerStyle: HeaderStyle(
            decoration: BoxDecoration(color: Colors.white),
            headerTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
            leftIcon: IconButton(
              icon: Icon(Icons.arrow_left, color: Color(0xff1E2E52)),
              onPressed: () {
                setState(() {
                  _focusedDate = DateTime(
                      _focusedDate.year, _focusedDate.month - 1, _focusedDate.day);
                  _selectedDate = null; // Reset selected date
                });
                _fetchEventsForMonth();
              },
            ),
            rightIcon: IconButton(
              icon: Icon(Icons.arrow_right, color: Color(0xff1E2E52)),
              onPressed: () {
                setState(() {
                  _focusedDate = DateTime(
                      _focusedDate.year, _focusedDate.month + 1, _focusedDate.day);
                  _selectedDate = null; // Reset selected date
                });
                _fetchEventsForMonth();
              },
            ),
          ),
          // cellBuilder: (DateTime date, List<CalendarEventData<Object?>> events) {
          //   final isToday = date.day == DateTime.now().day &&
          //       date.month == DateTime.now().month &&
          //       date.year == DateTime.now().year;
          //   final isInMonth = date.month == _focusedDate.month;
          //   final isSelected = _selectedDate != null &&
          //       date.day == _selectedDate!.day &&
          //       date.month == _selectedDate!.month &&
          //       date.year == _selectedDate!.year;

          //   return GestureDetector(
          //     onTap: () => _onDateSelected(date),
          //     child: Container(
          //       margin: EdgeInsets.all(2.0),
          //       decoration: BoxDecoration(
          //         color: isSelected
          //             ? Colors.blue.withOpacity(0.3)
          //             : isToday
          //                 ? Colors.blue.withOpacity(0.1)
          //                 : Colors.transparent,
          //         borderRadius: BorderRadius.circular(6.0),
          //       ),
          //       child: Stack(
          //         children: [
          //           Center(
          //             child: Text(
          //               "${date.day}",
          //               style: TextStyle(
          //                 fontSize: 14,
          //                 color: isInMonth ? Colors.black : Colors.grey,
          //                 fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          //               ),
          //             ),
          //           ),
          //           if (events.isNotEmpty)
          //             Positioned(
          //               bottom: 2,
          //               left: 2,
          //               right: 2,
          //               child: Row(
          //                 mainAxisAlignment: MainAxisAlignment.center,
          //                 children: events.map((event) {
          //                   final color = event.color ?? Colors.grey;
          //                   return Container(
          //                     width: 6,
          //                     height: 6,
          //                     margin: EdgeInsets.symmetric(horizontal: 1),
          //                     decoration: BoxDecoration(
          //                       color: color,
          //                       shape: BoxShape.circle,
          //                     ),
          //                   );
          //                 }).toList(),
          //               ),
          //             ),
          //         ],
          //       ),
          //     ),
          //   );
          // },
          // onEventTap: (events, date) {
          //   if (events.isNotEmpty) {
          //     _onDateSelected(date);
          //   }
          // },
          onDateLongPress: (DateTime date) => _onDateChanged(date),
          onPageChange: (DateTime date, int page) {
            setState(() {
              _focusedDate = date;
              _selectedDate = null; // Reset selected date
            });
            _fetchEventsForMonth();
          },
        );
      case 'year':
        return _buildYearView();
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildEventTile(
    DateTime date,
    List<CalendarEventData<Object?>> events,
    Rect boundary,
    DateTime start,
    DateTime end,
  ) {
    final event = events.first;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: event.color?.withOpacity(0.8) ?? Colors.blue,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Text(
          event.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildYearView() {
    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final monthDate = DateTime(_focusedDate.year, month, 1);
        final hasEvents = _eventController.events.any(
          (event) =>
              event.date.year == _focusedDate.year && event.date.month == month,
        );
        return GestureDetector(
          onTap: () {
            setState(() {
              _focusedDate = monthDate;
              _currentView = 'month';
              _selectedDate = null; // Reset selected date
            });
            _fetchEventsForMonth();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    DateFormat('MMMM').format(monthDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
                if (hasEvents)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventListForSelectedDate(CalendarBlocState state) {
    if (state is! CalendarLoaded || _selectedDate == null) return SizedBox.shrink();

    final eventsOnSelectedDate = state.events.where((event) =>
        event.date.day == _selectedDate!.day &&
        event.date.month == _selectedDate!.month &&
        event.date.year == _selectedDate!.year).toList();

    if (eventsOnSelectedDate.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              DateFormat('d MMMM').format(_selectedDate!),
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          ...eventsOnSelectedDate.map((event) {
            return ListTile(
              leading: Container(
                width: 4,
                height: 40,
                color: _getEventColor(event.type),
              ),
              title: Text(
                event.name,
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                event.type == 'task'
                    ? AppLocalizations.of(context)!.translate('task')
                    : AppLocalizations.of(context)!.translate('my_task'),
                style: TextStyle(color: Colors.white70),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}