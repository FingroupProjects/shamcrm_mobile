import 'package:crm_task_manager/bloc/calendar/calendar_bloc.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_event.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_state.dart';
import 'package:crm_task_manager/custom_widget/filter/calendar/filter_calendar.dart';
import 'package:crm_task_manager/screens/event/event_details/event_details_screen.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/task_details_screen.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
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

class _CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  Map<DateTime, List<CalendarEventData>> _events = {};
  bool _isInitialView = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Set<DateTime> _filteredDates = {};
  List<String> _selectedTypes = [];
  List<String> _selectedUsers = [];
  late AnimationController _blinkController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _colorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.black,
    ).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    context.read<CalendarBloc>().add(FetchCalendarEvents(_focusedDate.month, _focusedDate.year));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

void _changeView(String view) {
  setState(() {
    switch (view) {
      case 'month':
        _calendarFormat = CalendarFormat.month;
        break;
      case 'week':
        _calendarFormat = CalendarFormat.week;
        break;
      case 'day':
        _calendarFormat = CalendarFormat.twoWeeks;
        break;
    }
    _selectedDate = _selectedDate ?? DateTime.now();
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
        _filteredDates.clear();
        context.read<CalendarBloc>().add(FetchCalendarEvents(
          _focusedDate.month,
          _focusedDate.year,
          search: null,
          types: _selectedTypes,
          usersId: _selectedUsers,
        ));
      }
    });
  }

  void _onFilterPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarFilterScreen(
          initialTypes: _selectedTypes,
          initialUsers: _selectedUsers,
          onTypesSelected: (types, users) {
            setState(() {
              _selectedTypes = types;
              _selectedUsers = users;
            });
            context.read<CalendarBloc>().add(FetchCalendarEvents(
              _focusedDate.month,
              _focusedDate.year,
              search: _searchController.text.isNotEmpty ? _searchController.text : null,
              types: _selectedTypes,
              usersId: _selectedUsers,
            ));
          },
        ),
      ),
    );
  }

 void _handleEventTap(int id, String type) {
  // Находим событие по ID из всех событий
  CalendarEventData? event;
  
  print('🔍 Ищем событие: id=$id, type=$type');
  print('📋 Всего дат с событиями: ${_events.length}');
  
  // Ищем событие в _events
  for (var eventList in _events.values) {
    print('  📦 Список событий, длина: ${eventList.length}');
    for (var e in eventList) {
      print('    🎯 Событие: id=${e.id}, type=${e.type}, title="${e.title}"');
      if (e.id == id && e.type == type) {
        event = e;
        print('✅ Найдено событие: "${e.title}"');
        break;
      }
    }
    if (event != null) break;
  }
  
  if (event == null) {
    print('❌ Событие НЕ найдено!');
  }
  
  switch (type) {
    case 'task':
      print('🚀 Переход в TaskDetailsScreen с taskName: "${event?.title ?? ''}"');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskDetailsScreen(
            taskId: id.toString(),
            taskName: event?.title ?? '',
            taskStatus: '',
            statusId: 1,
            taskNumber: 0,
            customFields: [],
            initialDate: _selectedDate,
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
            taskName: event?.title ?? '',
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
            initialDate: _selectedDate,
          ),
        ),
      );
      break;
      
    default:
      break;
  }
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
                    contentPadding: const EdgeInsets.only(bottom: 10),
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xff1E2E52),
                  ),
                  onChanged: (value) {
                    context.read<CalendarBloc>().add(FetchCalendarEvents(
                      _focusedDate.month,
                      _focusedDate.year,
                      search: value.isNotEmpty ? value : null,
                      types: _selectedTypes,
                      usersId: _selectedUsers,
                    ));
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 24),
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: _isSearching
                ? const Icon(Icons.close, size: 24)
                : Image.asset(
                    'assets/icons/AppBar/search.png',
                    width: 24,
                    height: 24,
                  ),
            onPressed: _onSearchPressed,
          ),
          AnimatedBuilder(
            animation: _colorAnimation,
            builder: (context, child) {
              return IconButton(
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    (_selectedTypes.isNotEmpty || _selectedUsers.isNotEmpty)
                        ? _colorAnimation.value ?? const Color(0xff1E2E52)
                        : const Color(0xff1E2E52),
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/icons/AppBar/filter.png',
                    width: 24,
                    height: 24,
                  ),
                ),
                onPressed: _onFilterPressed,
              );
            },
          ),
          const SizedBox(width: 10),
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
        _filteredDates.clear();

        print('📅 Загружено событий: ${state.events.length}');

        for (var event in state.events) {
          final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
          _events[eventDate] = _events[eventDate] ?? [];
          _events[eventDate]!.add(
            CalendarEventData(
              id: event.id,
              title: event.name,  // ← Проверьте, что event.name не пустое
              date: event.date,
              startTime: event.date,
              endTime: event.date.add(const Duration(hours: 1)),
              color: CalendarUtils.getEventColor(event.type),
              type: event.type,
              isFinished: event.isFinished,
            ),
          );
          
          print('  ✏️ Добавлено: id=${event.id}, name="${event.name}", type=${event.type}');
          
          if (_searchController.text.isNotEmpty || _selectedTypes.isNotEmpty || _selectedUsers.isNotEmpty) {
            _filteredDates.add(eventDate);
          }
        }
        
        print('📊 Итого в _events: ${_events.length} дат');
      });
    }
  },
        builder: (context, state) {
          if (state is CalendarLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
          }

          if (_isSearching && _searchController.text.isNotEmpty && _events.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.translate('nothing_found'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff1E2E52),
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                if (_calendarFormat != CalendarFormat.twoWeeks)
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
                      context.read<CalendarBloc>().add(FetchCalendarEvents(
                        _focusedDate.month,
                        _focusedDate.year,
                        search: _searchController.text.isNotEmpty ? _searchController.text : null,
                        types: _selectedTypes,
                        usersId: _selectedUsers,
                      ));
                    },
                    filteredDates: (_isSearching && _searchController.text.isNotEmpty) ||
                            _selectedTypes.isNotEmpty ||
                            _selectedUsers.isNotEmpty
                        ? _filteredDates
                        : null,
                  ),
                if (_calendarFormat == CalendarFormat.twoWeeks && _selectedDate != null)
                  DayViewEventList(
                    selectedDate: _selectedDate!,
                    events: _events,
                    onEventTap: (id, type) => _handleEventTap(id, type),
                  ),
                if (_calendarFormat != CalendarFormat.twoWeeks && _selectedDate != null)
                  EventListForDate(
                    selectedDate: _selectedDate!,
                    events: _events,
                    onEventTap: (id, type) => _handleEventTap(id, type),
                    calendarFormat: _calendarFormat,
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showOptionsBottomSheet(context, _focusedDate, _events, setState),
        backgroundColor: const Color(0xff1E2E52),
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
          context.read<CalendarBloc>().add(FetchCalendarEvents(
            _focusedDate.month,
            _focusedDate.year,
            search: _searchController.text.isNotEmpty ? _searchController.text : null,
            types: _selectedTypes,
            usersId: _selectedUsers,
          ));
          Navigator.pop(context);
        },
      ),
    );
  }
}