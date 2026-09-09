import 'package:crm_task_manager/utils/safe_converters.dart';
import 'package:equatable/equatable.dart';

class SalaryReportResponse extends Equatable {
  final List<SalaryEmployeeReport> result;
  final String? errors;

  const SalaryReportResponse({
    required this.result,
    this.errors,
  });

  factory SalaryReportResponse.fromJson(dynamic json) {
    final map = SafeConverters.toMap(json);
    return SalaryReportResponse(
      result: SafeConverters.toModelList(
        map['result'],
        SalaryEmployeeReport.fromJson,
      ),
      errors: SafeConverters.toStringOrNull(map['errors']),
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
    return SalaryEmployeeReport(
      employeeId: SafeConverters.toInt(json['employee_id']),
      employeeName: SafeConverters.toSafeString(json['employee_name']),
      months: SafeConverters.toModelList(
        json['months'],
        SalaryMonthReport.fromJson,
      ),
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
      month: SafeConverters.toSafeString(json['month']),
      accrued: SafeConverters.toDouble(json['accrued']),
      paid: SafeConverters.toDouble(json['paid']),
      remaining: SafeConverters.toDouble(json['remaining']),
    );
  }

  @override
  List<Object?> get props => [month, accrued, paid, remaining];
}

