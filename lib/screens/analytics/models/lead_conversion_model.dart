import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

/// Individual month conversion data
class MonthlyConversionData {
  final String monthName;
  final double percentage;

  MonthlyConversionData({
    required this.monthName,
    required this.percentage,
  });
}

/// Model for lead conversion chart from /api/dashboard/leadConversion-chart
/// Response: {result: [12 monthly conversion percentages]}
class LeadConversionResponse {
  final List<double> monthlyConversion;

  LeadConversionResponse({required this.monthlyConversion});

  factory LeadConversionResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];

    if (result is List) {
      final conversions =
          SafeConverters.toDoubleList(result, expectedLength: 12);
      return LeadConversionResponse(monthlyConversion: conversions);
    }

    // Return 12 months of zero conversion if parsing fails
    return LeadConversionResponse(
      monthlyConversion: List.filled(12, 0.0),
    );
  }

  // Month names in Russian (short form)
  static const List<String> _monthNames = [
    'Янв',
    'Фев',
    'Мар',
    'Апр',
    'Май',
    'Июн',
    'Июл',
    'Авг',
    'Сен',
    'Окт',
    'Ноя',
    'Дек'
  ];

  // Full month names for display
  static const List<String> _fullMonthNames = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь'
  ];

  List<MonthlyConversionData> get monthlyData {
    return List.generate(
      monthlyConversion.length,
      (index) => MonthlyConversionData(
        monthName:
            index < _monthNames.length ? _monthNames[index] : 'M${index + 1}',
        percentage: monthlyConversion[index],
      ),
    );
  }

  double get averageConversion {
    if (monthlyConversion.isEmpty) return 0.0;
    final sum = monthlyConversion.reduce((a, b) => a + b);
    return sum / monthlyConversion.length;
  }

  // Alias for chart usage
  double get averagePercentage => averageConversion;

  double get maxPercentage {
    if (monthlyConversion.isEmpty) return 0.0;
    return monthlyConversion.reduce((a, b) => a > b ? a : b);
  }

  int get bestMonthIndex {
    if (monthlyConversion.isEmpty) return 0;
    double maxValue = monthlyConversion[0];
    int maxIndex = 0;

    for (int i = 1; i < monthlyConversion.length; i++) {
      if (monthlyConversion[i] > maxValue) {
        maxValue = monthlyConversion[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

  String get bestMonth {
    final index = bestMonthIndex;
    return index < _fullMonthNames.length
        ? _fullMonthNames[index]
        : 'Неизвестно';
  }
}
