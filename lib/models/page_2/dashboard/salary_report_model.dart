import 'package:equatable/equatable.dart';

class SalaryReportResponse extends Equatable {
  final List<SalaryEmployeeReport> result;
  final String? errors;

  const SalaryReportResponse({
    required this.result,
    this.errors,
  });

  factory SalaryReportResponse.fromJson(Map<String, dynamic> json) {
    final rawResult = json['result'];

    return SalaryReportResponse(
      result: rawResult is List
          ? rawResult
              .whereType<Map<String, dynamic>>()
              .map(SalaryEmployeeReport.fromJson)
              .toList()
          : const [],
      errors: json['errors']?.toString(),
    );
  }

  @override
  List<Object?> get props => [result, errors];
}

class SalaryEmployeeReport extends Equatable {
  final int employeeId;
  final String employeeName;
  final List<SalaryMonthReport> months;

  const SalaryEmployeeReport({
    required this.employeeId,
    required this.employeeName,
    required this.months,
  });

  factory SalaryEmployeeReport.fromJson(Map<String, dynamic> json) {
    final rawMonths = json['months'];

    return SalaryEmployeeReport(
      employeeId: _parseInt(json['employee_id']),
      employeeName: json['employee_name']?.toString() ?? '',
      months: rawMonths is List
          ? rawMonths
              .whereType<Map<String, dynamic>>()
              .map(SalaryMonthReport.fromJson)
              .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [employeeId, employeeName, months];
}

class SalaryMonthReport extends Equatable {
  final String month;
  final double accrued;
  final double paid;
  final double remaining;

  const SalaryMonthReport({
    required this.month,
    required this.accrued,
    required this.paid,
    required this.remaining,
  });

  factory SalaryMonthReport.fromJson(Map<String, dynamic> json) {
    return SalaryMonthReport(
      month: json['month']?.toString() ?? '',
      accrued: _parseDouble(json['accrued']),
      paid: _parseDouble(json['paid']),
      remaining: _parseDouble(json['remaining']),
    );
  }

  @override
  List<Object?> get props => [month, accrued, paid, remaining];
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _parseDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
