enum DocumentDatePeriod {
  today,
  yesterday,
  week,
  month,
  year,
  custom,
}

extension DocumentDatePeriodX on DocumentDatePeriod {
  String get localizationKey {
    switch (this) {
      case DocumentDatePeriod.today:
        return 'total_for_today';
      case DocumentDatePeriod.yesterday:
        return 'total_for_yesterday';
      case DocumentDatePeriod.week:
        return 'total_for_week';
      case DocumentDatePeriod.month:
        return 'total_for_month';
      case DocumentDatePeriod.year:
        return 'total_for_year';
      case DocumentDatePeriod.custom:
        return 'total';
    }
  }

  String get chipLocalizationKey {
    switch (this) {
      case DocumentDatePeriod.today:
        return 'today';
      case DocumentDatePeriod.yesterday:
        return 'yesterday';
      case DocumentDatePeriod.week:
        return 'week';
      case DocumentDatePeriod.month:
        return 'month';
      case DocumentDatePeriod.year:
        return 'year';
      case DocumentDatePeriod.custom:
        return 'total';
    }
  }

  static const selectable = [
    DocumentDatePeriod.yesterday,
    DocumentDatePeriod.today,
    DocumentDatePeriod.week,
    DocumentDatePeriod.month,
    DocumentDatePeriod.year,
  ];

  static DocumentDatePeriod? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final period in DocumentDatePeriod.values) {
      if (period.name == value) return period;
    }
    return null;
  }

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static ({DateTime start, DateTime end}) rangeFor(DocumentDatePeriod period) {
    final now = DateTime.now();
    final today = dateOnly(now);

    switch (period) {
      case DocumentDatePeriod.today:
        return (start: startOfDay(today), end: endOfDay(today));
      case DocumentDatePeriod.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return (start: startOfDay(yesterday), end: endOfDay(yesterday));
      case DocumentDatePeriod.week:
        final monday = today.subtract(Duration(days: today.weekday - 1));
        return (start: startOfDay(monday), end: endOfDay(today));
      case DocumentDatePeriod.month:
        final firstDay = DateTime(today.year, today.month, 1);
        return (start: startOfDay(firstDay), end: endOfDay(today));
      case DocumentDatePeriod.year:
        final firstDay = DateTime(today.year, 1, 1);
        return (start: startOfDay(firstDay), end: endOfDay(today));
      case DocumentDatePeriod.custom:
        return (start: startOfDay(today), end: endOfDay(today));
    }
  }

  static DocumentDatePeriod detect(DateTime? from, DateTime? to) {
    if (from == null || to == null) {
      return DocumentDatePeriod.custom;
    }

    final fromDay = dateOnly(from);
    final toDay = dateOnly(to);

    for (final period in selectable) {
      final range = rangeFor(period);
      if (isSameDay(fromDay, range.start) && isSameDay(toDay, range.end)) {
        return period;
      }
    }

    return DocumentDatePeriod.custom;
  }

  /// Как в продажах: без дат список без фильтра, итого — за сегодня.
  static ({
    DateTime? listFrom,
    DateTime? listTo,
    DateTime sumFrom,
    DateTime sumTo,
    DocumentDatePeriod period,
  }) resolveFromFilters(Map<String, dynamic>? filters) {
    final rawFrom = filters?['date_from'];
    final rawTo = filters?['date_to'];
    final from = rawFrom is DateTime ? rawFrom : null;
    final to = rawTo is DateTime ? rawTo : null;
    final todayRange = rangeFor(DocumentDatePeriod.today);

    if (from == null && to == null) {
      return (
        listFrom: null,
        listTo: null,
        sumFrom: todayRange.start,
        sumTo: todayRange.end,
        period: DocumentDatePeriod.today,
      );
    }

    late final DateTime dateFrom;
    late final DateTime dateTo;

    if (from != null && to == null) {
      dateFrom = startOfDay(from);
      dateTo = endOfDay(from);
    } else if (from == null && to != null) {
      dateFrom = startOfDay(to);
      dateTo = endOfDay(to);
    } else {
      dateFrom = startOfDay(from!);
      dateTo = endOfDay(to!);
    }

    final period = tryParse(filters?['date_period']?.toString()) ??
        detect(dateFrom, dateTo);

    return (
      listFrom: dateFrom,
      listTo: dateTo,
      sumFrom: dateFrom,
      sumTo: dateTo,
      period: period,
    );
  }
}
