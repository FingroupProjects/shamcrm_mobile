import 'package:equatable/equatable.dart';

class EmployeeRemainingModel extends Equatable {
  final int id;
  final String fullName;
  final String? phone;
  final String? salary;
  final String? totalAccrued;
  final String? totalPaid;
  final double remaining;

  const EmployeeRemainingModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.salary,
    this.totalAccrued,
    this.totalPaid,
    required this.remaining,
  });

  factory EmployeeRemainingModel.fromJson(Map<String, dynamic> json) {
    return EmployeeRemainingModel(
      id: _parseInt(json['id']),
      fullName: _parseString(json['full_name']) ?? '',
      phone: _parseString(json['phone']),
      salary: _parseString(json['salary']),
      totalAccrued: _parseString(json['total_accrued']),
      totalPaid: _parseString(json['total_paid']),
      remaining: _parseDouble(json['remaining']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        phone,
        salary,
        totalAccrued,
        totalPaid,
        remaining,
      ];
}
