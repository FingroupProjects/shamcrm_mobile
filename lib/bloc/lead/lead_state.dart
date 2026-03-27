import 'package:crm_task_manager/models/lead_model.dart'; // Модель для Lead

abstract class LeadState {}

class LeadInitial extends LeadState {}

class LeadLoading extends LeadState {}

class LeadLoaded extends LeadState {
  final List<LeadStatus> leadStatuses;
  final Map<int, int> leadCounts;

  LeadLoaded(this.leadStatuses, {Map<int, int>? leadCounts})
      : this.leadCounts = leadCounts ?? {};

  // Метод copyWith для обновления состояния
  LeadLoaded copyWith({
    List<LeadStatus>? leadStatuses,
    Map<int, int>? leadCounts,
  }) {
    print("-------------------------TaskLoaded------------------");
    return LeadLoaded(
      leadStatuses ?? this.leadStatuses,
      leadCounts: leadCounts ?? this.leadCounts,
    );
  }
}

class LeadStatusLoaded extends LeadState {
  final LeadStatus leadStatus;
  LeadStatusLoaded(this.leadStatus);
}

class LeadDataLoaded extends LeadState {
  final List<Lead> leads;
  final int currentPage;
  final Map<int, int> leadCounts;
  final DateTime timestamp; // Добавляем временную метку для гарантии уникальности

  LeadDataLoaded(
    this.leads, {
    this.currentPage = 1,
    required this.leadCounts,
    DateTime? timestamp,
  }) : this.timestamp = timestamp ?? DateTime.now();

  LeadDataLoaded merge(List<Lead> newLeads) {
    return LeadDataLoaded(
      [...leads, ...newLeads],
      currentPage: currentPage + 1,
      leadCounts: leadCounts,
      timestamp: DateTime.now(), // Обновляем временную метку
    );
  }

  // Метод для создания нового состояния с обновлёнными данными
  LeadDataLoaded refresh(List<Lead> newLeads, {Map<int, int>? newCounts}) {
    return LeadDataLoaded(
      newLeads,
      currentPage: 1, // Сбрасываем пагинацию
      leadCounts: newCounts ?? leadCounts,
      timestamp: DateTime.now(), // Новая временная метка
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeadDataLoaded &&
        other.timestamp == timestamp; // Сравниваем по timestamp
  }

  @override
  int get hashCode => timestamp.hashCode;
}

class LeadError extends LeadState {
  final String message;

  LeadError(this.message);
}

class LeadSuccess extends LeadState {
  final String message;

  LeadSuccess(this.message);
}

class LeadDeleted extends LeadState {
  final String message;

  LeadDeleted(this.message);
}

class LeadStatusDeleted extends LeadState {
  final String message;

  LeadStatusDeleted(this.message);
}

// State для успешного обновления статуса лида
class LeadStatusUpdatedEdit extends LeadState {
  final String message;

  LeadStatusUpdatedEdit(this.message);
}
