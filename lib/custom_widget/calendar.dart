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
  String _currentView = 'month';
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
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
      _selectedDate = null;
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
      builder: (context) => _buildBottomSheet(context, date),
    );
  }

  Widget _buildBottomSheet(BuildContext context, DateTime date) {
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
              // TODO: Navigate to Task screen
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
              // TODO: Navigate to My Tasks screen
            },
          ),
        ],
      ),
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

  Color _getEventColor(String type) {
    switch (type) {
      case 'task':
        return Colors.green;
      case 'my_task':
        return Colors.blue;
      case 'notice':
        return Colors.orange;
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
              _eventController.removeWhere((event) => true);
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
          onEventTap: (events, date) {
            _onDateSelected(date);
          },
        );
      case 'week':
        return WeekView(
          controller: _eventController,
          heightPerMinute: 1.0,
          eventTileBuilder: _buildEventTile,
          onEventTap: (events, date) {
            _onDateSelected(date);
          },
        );
      case 'month':
        return MonthView(
          controller: _eventController,
          cellAspectRatio: 1.0,
          headerBuilder: (date) => _buildCustomHeader(date),
          cellBuilder: (date, events, isToday, isInMonth, hideDaysNotInMonth) {
            final isSelected = _selectedDate != null &&
                date.day == _selectedDate!.day &&
                date.month == _selectedDate!.month &&
                date.year == _selectedDate!.year;

            return GestureDetector(
              onTap: () {
                _onDateSelected(date);
                _showOptionsBottomSheet(context, date);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                margin: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.2)
                      : isToday
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                        "${date.day}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: isInMonth ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                    if (events.isNotEmpty)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        right: 4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: events.take(3).map((event) {
                            return Container(
                              width: 6,
                              height: 6,
                              margin: EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: event.color ?? Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          onPageChange: (date, page) {
            setState(() {
              _focusedDate = date;
              _selectedDate = null;
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

  Widget _buildCustomHeader(DateTime date) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_left, color: Color(0xff1E2E52)),
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(
                    _focusedDate.year, _focusedDate.month - 1, _focusedDate.day);
                _selectedDate = null;
              });
              _fetchEventsForMonth();
            },
          ),
          GestureDetector(
            onTap: () => _showYearPicker(context),
            child: Text(
              DateFormat('MMMM yyyy').format(_focusedDate).capitalize(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_right, color: Color(0xff1E2E52)),
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(
                    _focusedDate.year, _focusedDate.month + 1, _focusedDate.day);
                _selectedDate = null;
              });
              _fetchEventsForMonth();
            },
          ),
        ],
      ),
    );
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
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            event.color?.withOpacity(0.8) ?? Colors.blue,
            event.color?.withOpacity(0.6) ?? Colors.blueAccent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          event.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildYearView() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
              _selectedDate = null;
            });
            _fetchEventsForMonth();
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                    DateFormat('MMMM').format(monthDate).capitalize(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
                if (hasEvents)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
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

    if (eventsOnSelectedDate.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        color: Colors.grey[100],
        child: Text(
          AppLocalizations.of(context)!.translate('no_events'),
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('d MMMM yyyy').format(_selectedDate!).capitalize(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          SizedBox(height: 8),
          ...eventsOnSelectedDate.map((event) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 4),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getEventColor(event.type),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    if (event.type == 'notice')
                      Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.notification_important, color: Colors.orange, size: 20),
                      ),
                  ],
                ),
                title: Text(
                  event.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff1E2E52),
                  ),
                ),
                subtitle: Text(
                  event.type == 'task'
                      ? AppLocalizations.of(context)!.translate('task')
                      : event.type == 'my_task'
                          ? AppLocalizations.of(context)!.translate('my_task')
                          : '${AppLocalizations.of(context)!.translate('notice')} • ${DateFormat('HH:mm').format(event.date)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
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
            itemCount: 12,
            itemBuilder: (context, index) {
              final year = 2025 + index;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showMonthPicker(context, year);
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: year == _focusedDate.year
                        ? Colors.blue
                        : Colors.grey.withOpacity(0.2),
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
                    _selectedDate = null;
                  });
                  _fetchEventsForMonth();
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: month == _focusedDate.month && selectedYear == _focusedDate.year
                        ? Colors.blue
                        : Colors.grey.withOpacity(0.2),
                  ),
                  child: Center(
                    child: Text(
                      DateFormat('MMM').format(monthDate).capitalize(),
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

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}