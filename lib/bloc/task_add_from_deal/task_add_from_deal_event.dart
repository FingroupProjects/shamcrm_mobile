import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

abstract class TaskAddFromDealEvent {}
class FetchTaskDealStatuses extends TaskAddFromDealEvent {}

class CreateTaskFromDeal extends TaskAddFromDealEvent {
  final int dealId;
  final String name;
  final int statusId;
  final int? taskStatusId;
  final int? priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? projectId;
  final List<int>? userId;
  final String? description;
  final List<String>? filePaths; // Изменено на список путей к файлам
  final List<Map<String, String>>? customFields;
  // final AppLocalizations localizations;  // Add this to your event

  CreateTaskFromDeal({
    required this.dealId,
    required this.name,
    required this.statusId,
    required this.taskStatusId,
    this.priority,
    this.startDate,
    this.endDate,
    this.projectId,
    this.userId,
    this.description,
    this.customFields,
    this.filePaths, // Изменено на список путей к файлам
        // required this.localizations,  // Add this to constructor

  });
}