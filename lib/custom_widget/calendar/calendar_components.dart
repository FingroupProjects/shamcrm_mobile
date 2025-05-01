import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/calendar/create_add_screen/create_add_event.dart';
import 'package:crm_task_manager/custom_widget/calendar/create_add_screen/create_add_myTask.dart';
import 'package:crm_task_manager/custom_widget/calendar/create_add_screen/create_add_task.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'calendar_utils.dart';

class CalendarWidget extends StatelessWidget {
  final CalendarFormat calendarFormat;
  final DateTime focusedDate;
  final DateTime? selectedDate;
  final Map<DateTime, List<CalendarEventData>> events;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onPageChanged;
  final Set<DateTime>? filteredDates;

  const CalendarWidget({
    super.key,
    required this.calendarFormat,
    required this.focusedDate,
    required this.selectedDate,
    required this.events,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
    this.filteredDates,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      rowHeight: MediaQuery.of(context).size.height * 0.065,
      daysOfWeekHeight: MediaQuery.of(context).size.height * 0.028,
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: focusedDate,
      calendarFormat: calendarFormat,
      selectedDayPredicate: (day) => isSameDay(selectedDate, day),
      onDaySelected: onDaySelected,
      onFormatChanged: onFormatChanged,
      startingDayOfWeek: StartingDayOfWeek.monday,
      onPageChanged: onPageChanged,
       availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.week: 'Week',
        CalendarFormat.twoWeeks: '2 weeks',
      },
      enabledDayPredicate: (day) {
        if (filteredDates == null || filteredDates!.isEmpty) return true;
        final dayDate = DateTime(day.year, day.month, day.day);
        return filteredDates!.contains(dayDate);
      },
      eventLoader: (day) {
        final eventDate = DateTime(day.year, day.month, day.day);
        return events[eventDate] ?? [];
      },
      locale: AppLocalizations.of(context)!.locale.languageCode,
      calendarStyle: CalendarStyle(
        cellMargin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
        defaultTextStyle: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.035,
          color: const Color(0xff1E2E52),
          fontFamily: 'Gilroy',
        ),
        todayDecoration: const BoxDecoration(
          color: Color(0xff1E2E52),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(
        titleTextStyle: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.045,
          color: const Color(0xff1E2E52),
          fontFamily: 'Gilroy',
        ),
        formatButtonVisible: false,
        titleCentered: true,
        titleTextFormatter: (date, locale) => DateFormat('MMMM yyyy', AppLocalizations.of(context)!.locale.languageCode)
            .format(date)
            .capitalize(),
        leftChevronIcon: const Icon(Icons.arrow_left, color: Color(0xff1E2E52)),
        rightChevronIcon: const Icon(Icons.arrow_right, color: Color(0xff1E2E52)),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isNotEmpty) {
            return Positioned(
              bottom: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: events.take(3).map((event) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: (event as CalendarEventData).color,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}

class EventListForDate extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, List<CalendarEventData>> events;
  final Function(int id, String type)? onEventTap;
  final CalendarFormat calendarFormat;

  const EventListForDate({
    super.key,
    required this.selectedDate,
    required this.events,
    this.onEventTap,
    required this.calendarFormat,
  });

  @override
  Widget build(BuildContext context) {
    final eventDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final eventsOnSelectedDate = events[eventDate] ?? [];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: eventsOnSelectedDate.isEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffF4F7FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppLocalizations.of(context)!.translate('no_events'),
                style: const TextStyle(
                  color: Color(0xff1E2E52),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                ),
              ),
            )
          : ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: calendarFormat == CalendarFormat.month
                    ? MediaQuery.of(context).size.height * 0.4
                    : MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('d MMMM yyyy', AppLocalizations.of(context)!.locale.languageCode)
                            .format(selectedDate)
                            .capitalize(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      ...eventsOnSelectedDate.map((event) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: const Color(0xffF4F7FD),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              if (onEventTap != null) {
                                onEventTap!(event.id, event.type);
                              }
                            },
                            child: Stack(
                              children: [
                                ListTile(
                                  leading: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: event.color,
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Icon(
                                          event.type == 'notice'
                                              ? Icons.event
                                              : event.type == 'task'
                                                  ? Icons.task
                                                  : Icons.assignment,
                                          color: event.type == 'notice'
                                              ? Colors.orange
                                              : event.type == 'task'
                                                  ? Colors.green
                                                  : Colors.blue,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xff1E2E52),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    event.type == 'task'
                                        ? AppLocalizations.of(context)!.translate('task')
                                        : event.type == 'my_task'
                                            ? AppLocalizations.of(context)!.translate('my_task')
                                            : '${AppLocalizations.of(context)!.translate('notice')}: ${DateFormat('HH:mm').format(event.date.add(const Duration(hours: 5)))}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontFamily: 'Gilroy',
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (event.isFinished)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 0,
                                  bottom: MediaQuery.of(context).size.height * 0.020,
                                  child: Center(
                                    child: FractionallySizedBox(
                                      widthFactor: 0.7, 
                                      child: Container(
                                        height: 1.5,
                                        color: Color(0xff1E2E52).withOpacity(0.9),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class DayViewEventList extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, List<CalendarEventData>> events;
  final Function(int id, String type)? onEventTap;

  const DayViewEventList({
    super.key,
    required this.selectedDate,
    required this.events,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final eventDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final eventsOnSelectedDate = events[eventDate] ?? [];
    final sortedEvents = eventsOnSelectedDate..sort((a, b) => a.date.compareTo(b.date));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: sortedEvents.isEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffF4F7FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppLocalizations.of(context)!.translate('no_events'),
                style: const TextStyle(
                  color: Color(0xff1E2E52),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                ),
              ),
            )
          : ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('d MMMM yyyy', AppLocalizations.of(context)!.locale.languageCode)
                          .format(selectedDate)
                          .capitalize(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...sortedEvents.map((event) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 60,
                              child: event.type == 'notice'
                                  ? Text(
                                      DateFormat('HH:mm').format(event.date.add(const Duration(hours: 5))),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xff1E2E52),
                                      ),
                                    )
                                  : const SizedBox.shrink(), 
                            ),
                            Expanded(
                              child: Card(
                                color: const Color(0xffF4F7FD),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    if (onEventTap != null) {
                                      onEventTap!(event.id, event.type);
                                    }
                                  },
                                  child: Stack(
                                    children: [
                                      ListTile(
                                        leading: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: event.color,
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: Icon(
                                                event.type == 'notice'
                                                    ? Icons.event
                                                    : event.type == 'task'
                                                        ? Icons.task
                                                        : Icons.assignment,
                                                color: event.type == 'notice'
                                                    ? Colors.orange
                                                    : event.type == 'task'
                                                        ? Colors.green
                                                        : Colors.blue,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                        title: Text(
                                          event.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Gilroy',
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xff1E2E52),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          event.type == 'task'
                                              ? AppLocalizations.of(context)!.translate('task')
                                              : event.type == 'my_task'
                                                  ? AppLocalizations.of(context)!.translate('my_task')
                                                  : '${AppLocalizations.of(context)!.translate('notice')}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontFamily: 'Gilroy',
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                   if (event.isFinished)
                                     Positioned(
                                       left: 0,
                                       right: 0,
                                       top: 0,
                                       bottom: MediaQuery.of(context).size.height * 0.020,
                                       child: Center(
                                         child: FractionallySizedBox(
                                           widthFactor: 0.65, 
                                           child: Container(
                                             height: 1.5,
                                             color: Color(0xff1E2E52).withOpacity(0.9),
                                           ),
                                         ),
                                       ),
                                     ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}

class CalendarViewDropdown extends StatelessWidget {
  final CalendarFormat currentFormat;
  final Function(String) onChange;

  const CalendarViewDropdown({
    super.key,
    required this.currentFormat,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      decoration: BoxDecoration(
        color: const Color(0xffF4F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentFormat == CalendarFormat.month
              ? 'month'
              : currentFormat == CalendarFormat.week
                  ? 'week'
                  : 'day',
          dropdownColor: Colors.white,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xff1E2E52)),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xff1E2E52),
          ),
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
          ],
          onChanged: (value) {
            if (value != null) {
              onChange(value);
            }
          },
        ),
      ),
    );
  }
}

class YearPickerDialog extends StatelessWidget {
  final DateTime focusedDate;
  final Function(int) onYearSelected;

  const YearPickerDialog({
    super.key,
    required this.focusedDate,
    required this.onYearSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = screenHeight * 0.4;

    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(AppLocalizations.of(context)!.translate('select_year')),
      content: SizedBox(
        width: double.maxFinite,
        height: dialogHeight,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final year = 2020 + index;
            return GestureDetector(
              onTap: () => onYearSelected(year),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: year == focusedDate.year ? const Color(0xff1E2E52) : Colors.grey.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    year.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: year == focusedDate.year ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
     actions: [
  ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xff1E2E52),
      minimumSize: const Size(double.infinity, 48),
    ),
    onPressed: () => Navigator.pop(context),
    child: Text(
      AppLocalizations.of(context)!.translate('close'),
      style: const TextStyle(color: Colors.white),
    ),
  ),
],
    );
  }
}

class MonthPickerDialog extends StatelessWidget {
  final int selectedYear;
  final DateTime focusedDate;
  final Function(int) onMonthSelected;

  const MonthPickerDialog({
    super.key,
    required this.selectedYear,
    required this.focusedDate,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = screenHeight * 0.4;

    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(AppLocalizations.of(context)!.translate('select_month')),
      content: SizedBox(
        width: double.maxFinite,
        height: dialogHeight,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
              onTap: () => onMonthSelected(month),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: month == focusedDate.month && selectedYear == focusedDate.year
                      ? const Color(0xff1E2E52)
                      : Colors.grey.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    DateFormat('MMM', AppLocalizations.of(context)!.locale.languageCode)
                        .format(monthDate)
                        .capitalize(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: month == focusedDate.month && selectedYear == focusedDate.year
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
  ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xff1E2E52),
      minimumSize: const Size(double.infinity, 48),
    ),
    onPressed: () => Navigator.pop(context),
    child: Text(
      AppLocalizations.of(context)!.translate('close'),
      style: const TextStyle(color: Colors.white),
    ),
  ),
],
    );
  }
}

void showOptionsBottomSheet(
  BuildContext context,
  DateTime date,
  Map<DateTime, List<CalendarEventData>> events,
  Function(void Function()) setState,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => OptionsBottomSheet(date: date, events: events, setState: setState),
  );
}

Future<bool> _checkTaskStatuses(BuildContext context) async {
  try {
    final apiService = ApiService();
    final statuses = await apiService.getTaskStatuses();
    return statuses != null && statuses.isNotEmpty;
  } catch (e) {
    return false;
  }
}

class OptionsBottomSheet extends StatelessWidget {
  final DateTime date;
  final Map<DateTime, List<CalendarEventData>> events;
  final Function(void Function()) setState;

  const OptionsBottomSheet({
    super.key,
    required this.date,
    required this.events,
    required this.setState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.task, color: Colors.green),
            title: Text(
              AppLocalizations.of(context)!.translate('task'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateTaskFromCalendare(
                    initialDate: date,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.event, color: Colors.orange),
            title: Text(
              AppLocalizations.of(context)!.translate('events'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateEventFromCalendare(
                    initialDate: date,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment, color: Colors.blue),
            title: Text(
              AppLocalizations.of(context)!.translate('appbar_my_tasks'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () async {
              bool hasStatuses = await _checkTaskStatuses(context);
              if (hasStatuses) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateMyTaskFromCalendare(
                      initialDate: date,
                    ),
                  ),
                );
              } else {
                Navigator.pop(context);
                showCustomSnackBar(
                  context: context,
                  message: AppLocalizations.of(context)!.translate('please_create_status'),
                  isSuccess: false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class AddEventDialog extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final DateTime startTime;
  final DateTime endTime;
  final Function(DateTime) onStartTimeChanged;
  final Function(DateTime) onEndTimeChanged;
  final VoidCallback onSave;

  const AddEventDialog({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.startTime,
    required this.endTime,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
                onStartTimeChanged(picked);
              }
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.translate('end_time')),
            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(endTime)),
            onTap: () async {
              final picked = await showDateTimePicker(context, endTime);
              if (picked != null) {
                onEndTimeChanged(picked);
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
          onPressed: onSave,
          child: Text(AppLocalizations.of(context)!.translate('save')),
        ),
      ],
    );
  }
}

Future<DateTime?> showDateTimePicker(
    BuildContext context, DateTime initialDate) async {
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