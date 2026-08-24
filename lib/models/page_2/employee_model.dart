import 'package:crm_task_manager/utils/safe_converters.dart';
import 'package:intl/intl.dart';

class EmployeeModel {
  final int id;
  final String fullName;
  final String? phone;
  final String? birthDate;
  final String? position;
  final String? address;
  final String? salary;
  final int? organizationId;
  final String? createdAt;
  final String? updatedAt;

  const EmployeeModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.birthDate,
    this.position,
    this.address,
    this.salary,
    this.organizationId,
    this.createdAt,
    this.updatedAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: SafeConverters.toInt(json['id']),
      fullName: SafeConverters.toSafeString(json['full_name']),
      phone: SafeConverters.toStringOrNull(json['phone']),
      birthDate: SafeConverters.toStringOrNull(json['birth_date']),
      position: SafeConverters.toStringOrNull(json['position']),
      address: SafeConverters.toStringOrNull(json['address']),
      salary: SafeConverters.toStringOrNull(json['salary']),
      organizationId: SafeConverters.toIntOrNull(json['organization_id']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
    );
  }

  DateTime? get birthDateTime {
    final raw = birthDate?.trim();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  String get displayBirthDate {
    final date = birthDateTime;
    if (date == null) return '';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String get displaySalary {
    final value = SafeConverters.toDoubleOrNull(salary);
    if (value == null) return '';
    return NumberFormat('#,##0.##', 'ru_RU').format(value);
  }

  Map<String, dynamic> toRequestBody() {
    final date = birthDateTime;
    final salaryValue = SafeConverters.toDoubleOrNull(salary);

    return {
      'full_name': fullName,
      'phone': phone,
      'birth_date': date?.toUtc().toIso8601String(),
      'position': position,
      'address': address,
      if (salaryValue != null) 'salary': salaryValue,
    };
  }
}
