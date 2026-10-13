// import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/calendar/create_add_screen/create_add_event.dart';
// import 'package:crm_task_manager/custom_widget/calendar/create_add_screen/create_add_myTask.dart';
// import 'package:crm_task_manager/custom_widget/calendar/create_add_screen/create_add_task.dart';
import 'package:crm_task_manager/screens/task/task_details/task_add_screen.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/helpful_empty_state.dart';
// import 'package:crm_task_manager/widgets/snackbar_widget.dart';
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

  /// Возврат к сегодняшнему месяцу. Кнопка живёт в шапке месяца,
  /// отдельно от заголовка экрана, чтобы не наезжать на «Календарь».
  final VoidCallback? onJumpToToday;

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
    this.onJumpToToday,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TableCalendar(
      rowHeight: MediaQuery.of(context).size.height * 0.065,
      daysOfWeekHeight: MediaQuery.of(context).size.height * 0.028,
      firstDay: DateTime.utc(2000, 1, 1),
      lastDay: DateTime.utc(2200, 12, 31),
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
        // Небольшой отступ, чтобы круг выбранного дня и точки событий
        // помещались в ячейку и не сливались.
        cellMargin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        weekendTextStyle: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.035,
          color: colors.error.withValues(alpha: 0.95),
          fontFamily: 'Gilroy',
        ),
        defaultTextStyle: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.035,
          color: colors.textPrimary.withValues(alpha: 0.96),
          fontFamily: 'Gilroy',
        ),
        outsideTextStyle: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.035,
          color: colors.textPrimary.withValues(alpha: 0.38),
          fontFamily: 'Gilroy',
        ),
        // Запасной стиль, если кастомный билдер не вернул виджет.
        // Выбранный день — плотный круг, сегодня — только обводка.
        todayDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.buttonPrimaryBg, width: 1.8),
        ),
        selectedDecoration: BoxDecoration(
          color: colors.buttonPrimaryBg,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: colors.buttonPrimaryBg,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.035,
          color: colors.buttonPrimaryBg,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w700,
        ),
        selectedTextStyle: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.035,
          color: colors.buttonPrimaryFg,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w700,
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: colors.textPrimary.withValues(alpha: 0.84),
          fontFamily: 'Gilroy',
          fontSize: MediaQuery.of(context).size.width * 0.03,
        ),
        weekendStyle: TextStyle(
          color: colors.error.withValues(alpha: 0.95),
          fontFamily: 'Gilroy',
          fontSize: MediaQuery.of(context).size.width * 0.03,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        dowBuilder: (context, day) {
          final colors = context.appColors;
          final isSunday = day.weekday == DateTime.sunday;
          final textColor = isSunday
              ? colors.error
              : colors.textInverse.withValues(alpha: 0.9);
          return Center(
            child: Text(
              DateFormat.E(AppLocalizations.of(context)!.locale.languageCode)
                  .format(day)
                  .toUpperCase(),
              style: TextStyle(
                color: textColor,
                fontFamily: 'Gilroy',
                fontSize: MediaQuery.of(context).size.width * 0.03,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
        // prioritizedBuilder заменял ячейку целиком и прятал
        // selectedDecoration, поэтому нажатый день ничем не отличался.
        selectedBuilder: (context, day, focusedDay) => _CalendarDayCell(
          day: day,
          kind: _CalendarDayKind.selected,
        ),
        todayBuilder: (context, day, focusedDay) => _CalendarDayCell(
          day: day,
          kind: _CalendarDayKind.today,
        ),
        defaultBuilder: (context, day, focusedDay) => _CalendarDayCell(
          day: day,
          kind: _CalendarDayKind.normal,
        ),
        outsideBuilder: (context, day, focusedDay) => _CalendarDayCell(
          day: day,
          kind: _CalendarDayKind.outside,
        ),
        disabledBuilder: (context, day, focusedDay) => _CalendarDayCell(
          day: day,
          kind: _CalendarDayKind.disabled,
        ),
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
        headerTitleBuilder: (context, day) {
          final title = DateFormat(
            'MMMM yyyy',
            AppLocalizations.of(context)!.locale.languageCode,
          ).format(day).capitalize();
          final now = DateTime.now();
          // Кнопка «Сегодня» только если открыт не текущий месяц.
          final showToday = onJumpToToday != null &&
              (day.year != now.year || day.month != now.month);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.045,
                    color: colors.textPrimary,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
              if (showToday) ...[
                const SizedBox(width: 8),
                CalendarTodayButton(onPressed: onJumpToToday!),
              ],
            ],
          );
        },
      ),
      headerStyle: HeaderStyle(
        titleTextStyle: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.045,
          color: colors.textPrimary,
          fontFamily: 'Gilroy',
        ),
        formatButtonVisible: false,
        titleCentered: true,
        titleTextFormatter: (date, locale) => DateFormat(
                'MMMM yyyy', AppLocalizations.of(context)!.locale.languageCode)
            .format(date)
            .capitalize(),
        leftChevronIcon: Icon(Icons.arrow_left, color: colors.iconPrimary),
        rightChevronIcon: Icon(Icons.arrow_right, color: colors.iconPrimary),
      ),
    );
  }
}

/// Как выглядит число в сетке. Выбранный и сегодняшний дни
/// рисуются отдельно, чтобы их нельзя было спутать.
enum _CalendarDayKind { normal, outside, today, selected, disabled }

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.kind,
  });

  final DateTime day;
  final _CalendarDayKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSunday = day.weekday == DateTime.sunday;

    final Color textColor;
    BoxDecoration? decoration;
    var weight = FontWeight.w600;

    switch (kind) {
      case _CalendarDayKind.selected:
        // Плотный круг цвета кнопки. Текст контрастный, день сразу виден.
        decoration = BoxDecoration(
          color: colors.buttonPrimaryBg,
          shape: BoxShape.circle,
        );
        textColor = colors.buttonPrimaryFg;
        weight = FontWeight.w700;
      case _CalendarDayKind.today:
        // Сегодня, если оно не выбрано: только обводка, без заливки.
        decoration = BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.buttonPrimaryBg, width: 1.8),
        );
        textColor = colors.buttonPrimaryBg;
        weight = FontWeight.w700;
      case _CalendarDayKind.outside:
        decoration = null;
        textColor = isSunday
            ? colors.error.withValues(alpha: 0.4)
            : colors.textPrimary.withValues(alpha: 0.38);
      case _CalendarDayKind.disabled:
        decoration = null;
        textColor = colors.textMuted.withValues(alpha: 0.55);
      case _CalendarDayKind.normal:
        decoration = null;
        textColor = isSunday
            ? colors.error
            : colors.textPrimary.withValues(alpha: 0.96);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        // Круг чуть выше центра, снизу остаётся место для точек событий.
        final circle = (side * 0.72).clamp(26.0, 36.0);

        return Align(
          alignment: const Alignment(0, -0.22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: circle,
            height: circle,
            alignment: Alignment.center,
            decoration: decoration,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: (circle * 0.42).clamp(12.0, 16.0),
                color: textColor,
                fontFamily: 'Gilroy',
                fontWeight: weight,
                height: 1,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Дата выбранного дня и короткая плашка «Через 74 дня».
/// Плашка справа, список событий под ней не сдвигается в сторону.
class CalendarSelectedDateTitle extends StatelessWidget {
  const CalendarSelectedDateTitle({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final locale = AppLocalizations.of(context)!;
    final label = DateFormat(
      'd MMMM yyyy',
      locale.locale.languageCode,
    ).format(date).capitalize();
    final distance = relativeCalendarDistance(
      date,
      DateTime.now(),
      locale.locale.languageCode,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.buttonPrimaryBg.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            distance,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.buttonPrimaryBg,
            ),
          ),
        ),
      ],
    );
  }
}

/// Отдельная кнопка «Сегодня». Своя заливка и обводка,
/// чтобы она не сливалась с заголовком.
class CalendarTodayButton extends StatelessWidget {
  const CalendarTodayButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: colors.buttonPrimaryBg,
        backgroundColor: colors.buttonPrimaryBg.withValues(alpha: 0.14),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colors.buttonPrimaryBg.withValues(alpha: 0.55),
          ),
        ),
      ),
      child: Text(
        AppLocalizations.of(context)!.translate('today'),
        style: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
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
    final colors = context.appColors;
    final eventDate =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final eventsOnSelectedDate = events[eventDate] ?? [];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: eventsOnSelectedDate.isEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Дата видна и когда событий нет: иначе выбранный день
                // можно узнать только по кругу в сетке.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: CalendarSelectedDateTitle(date: selectedDate),
                ),
                HelpfulEmptyState.section(
                  l10n: AppLocalizations.of(context)!,
                  icon: Icons.event_available_outlined,
                  titleKey: 'empty_calendar_title',
                  subtitleKey: 'empty_calendar_subtitle',
                ),
              ],
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
                  decoration: BoxDecoration(
                    color: colors.surfacePrimary.withValues(alpha: 0.72),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CalendarSelectedDateTitle(date: selectedDate),
                      ...eventsOnSelectedDate.map((event) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: colors.surfacePrimary.withValues(alpha: 0.8),
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
                                          borderRadius:
                                              BorderRadius.circular(30),
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
                                              ? colors.warning
                                              : event.type == 'task'
                                                  ? colors.buttonPrimaryBg
                                                  : colors.surfaceAccent,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    event.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w500,
                                      color: colors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    event.type == 'task'
                                        ? AppLocalizations.of(context)!
                                            .translate('task')
                                        // : event.type == 'my_task'
                                        //     ? AppLocalizations.of(context)!
                                        //         .translate('my_task')
                                        : '${AppLocalizations.of(context)!.translate('notice')}: ${DateFormat('HH:mm').format(event.date.toLocal())}',
                                    style: TextStyle(
                                      color: colors.textSecondary,
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
                                    bottom: MediaQuery.of(context).size.height *
                                        0.020,
                                    child: Center(
                                      child: FractionallySizedBox(
                                        widthFactor: 0.7,
                                        child: Container(
                                          height: 1.5,
                                          color: colors.textPrimary
                                              .withOpacity(0.9),
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
    final colors = context.appColors;
    final eventDate =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final eventsOnSelectedDate = events[eventDate] ?? [];
    final sortedEvents = eventsOnSelectedDate
      ..sort((a, b) => a.date.compareTo(b.date));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: sortedEvents.isEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CalendarSelectedDateTitle(date: selectedDate),
                const SizedBox(height: 12),
                HelpfulEmptyState.section(
                  l10n: AppLocalizations.of(context)!,
                  icon: Icons.event_available_outlined,
                  titleKey: 'empty_calendar_title',
                  subtitleKey: 'empty_calendar_subtitle',
                ),
              ],
            )
          : ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CalendarSelectedDateTitle(date: selectedDate),
                    const SizedBox(height: 16),
                    ...sortedEvents.map((event) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (event.type == 'notice')
                              SizedBox(
                                width: 60,
                                child: Text(
                                  DateFormat('HH:mm').format(
                                      event.date.toLocal()),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Card(
                                color: colors.surfacePrimary
                                    .withValues(alpha: 0.8),
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
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8),
                                              child: Icon(
                                                event.type == 'notice'
                                                    ? Icons.event
                                                    : event.type == 'task'
                                                        ? Icons.task
                                                        : Icons.assignment,
                                                color: event.type == 'notice'
                                                    ? colors.warning
                                                    : event.type == 'task'
                                                        ? colors.buttonPrimaryBg
                                                        : colors.surfaceAccent,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                        title: Text(
                                          event.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Gilroy',
                                            fontWeight: FontWeight.w500,
                                            color: colors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          event.type == 'task'
                                              ? AppLocalizations.of(context)!
                                                  .translate('task')
                                              // : event.type == 'my_task'
                                              //     ? AppLocalizations.of(
                                              //             context)!
                                              //         .translate('my_task')
                                              : '${AppLocalizations.of(context)!.translate('notice')}: ${DateFormat('HH:mm').format(event.date.toLocal())}',
                                          style: TextStyle(
                                            color: colors.textSecondary,
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
                                          bottom: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.020,
                                          child: Center(
                                            child: FractionallySizedBox(
                                              widthFactor: 0.65,
                                              child: Container(
                                                height: 1.5,
                                                color: colors.textPrimary
                                                    .withValues(alpha: 0.9),
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
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentFormat == CalendarFormat.month
              ? 'month'
              : currentFormat == CalendarFormat.week
                  ? 'week'
                  : 'day',
          dropdownColor: colors.surfacePrimary,
          icon: Icon(Icons.arrow_drop_down, color: colors.iconPrimary),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
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
    final colors = context.appColors;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = screenHeight * 0.4;

    return AlertDialog(
      backgroundColor: colors.surfacePrimary,
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
          itemCount: 100,
          itemBuilder: (context, index) {
            final year = 2015 + index;
            return GestureDetector(
              onTap: () => onYearSelected(year),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: year == focusedDate.year
                      ? colors.buttonPrimaryBg
                      : colors.fieldBg,
                ),
                child: Center(
                  child: Text(
                    year.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: year == focusedDate.year
                          ? colors.textInverse
                          : colors.textPrimary,
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
            backgroundColor: colors.buttonPrimaryBg,
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.translate('close'),
            style: TextStyle(color: colors.textInverse),
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
    final colors = context.appColors;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = screenHeight * 0.4;

    return AlertDialog(
      backgroundColor: colors.surfacePrimary,
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
                  color: month == focusedDate.month &&
                          selectedYear == focusedDate.year
                      ? colors.buttonPrimaryBg
                      : colors.fieldBg,
                ),
                child: Center(
                  child: Text(
                    DateFormat('MMM',
                            AppLocalizations.of(context)!.locale.languageCode)
                        .format(monthDate)
                        .capitalize(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: month == focusedDate.month &&
                              selectedYear == focusedDate.year
                          ? colors.textInverse
                          : colors.textPrimary,
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
            backgroundColor: colors.buttonPrimaryBg,
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.translate('close'),
            style: TextStyle(color: colors.textInverse),
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
    backgroundColor: context.appColors.surfacePrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) =>
        OptionsBottomSheet(date: date, events: events, setState: setState),
  );
}

// Future<bool> _checkTaskStatuses(BuildContext context) async {
//   try {
//     final apiService = ApiService();
//     final statuses = await apiService.getTaskStatuses();
//     return statuses != null && statuses.isNotEmpty;
//   } catch (e) {
//     return false;
//   }
// }

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
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.task, color: colors.buttonPrimaryBg),
            title: Text(
              AppLocalizations.of(context)!.translate('task'),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskAddScreen(
                    statusId: 0,
                    fromCalendar: true,
                    initialEndDate: date,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.event, color: colors.warning),
            title: Text(
              AppLocalizations.of(context)!.translate('events'),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary),
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
          // Мои задачи в календаре скрыты.
          // ListTile(
          //   leading: Icon(Icons.assignment, color: colors.surfaceAccent),
          //   title: Text(
          //     AppLocalizations.of(context)!.translate('appbar_my_tasks'),
          //     style: TextStyle(
          //         fontSize: 16,
          //         fontWeight: FontWeight.w500,
          //         color: colors.textPrimary),
          //   ),
          //   onTap: () async {
          //     bool hasStatuses = await _checkTaskStatuses(context);
          //     if (hasStatuses) {
          //       Navigator.pop(context);
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => CreateMyTaskFromCalendare(
          //             initialDate: date,
          //           ),
          //         ),
          //       );
          //     } else {
          //       Navigator.pop(context);
          //       showCustomSnackBar(
          //         context: context,
          //         message: AppLocalizations.of(context)!
          //             .translate('please_create_status'),
          //         isSuccess: false,
          //       );
          //     }
          //   },
          // ),
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
              labelText:
                  AppLocalizations.of(context)!.translate('event_description'),
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
    firstDate: DateTime(2000),
    lastDate: DateTime(2200),
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
