import 'package:crm_task_manager/models/deal_model.dart'; // Модель для Deal

abstract class DealState {}

class DealInitial extends DealState {}

class DealLoading extends DealState {}

class DealLoaded extends DealState {
  final List<DealStatus> dealStatuses;
  final Map<int, int> dealCounts;

  DealLoaded(this.dealStatuses, {Map<int, int>? dealCounts})
      : this.dealCounts = dealCounts ?? {};

  // Метод copyWith для обновления состояния
  DealLoaded copyWith({
    List<DealStatus>? dealStatuses,
    Map<int, int>? dealCounts,
  }) {
    return DealLoaded(
      dealStatuses ?? this.dealStatuses,
      dealCounts: dealCounts ?? this.dealCounts,
    );
  }
}

class DealDataLoaded extends DealState {
  final List<Deal> deals;
  final int currentPage;
  final Map<int, int> dealCounts;

  DealDataLoaded(this.deals, {this.currentPage = 1, required this.dealCounts});

  // Метод для объединения с новыми сделками
  DealDataLoaded merge(List<Deal> newDeals) {
    return DealDataLoaded(
      [...deals, ...newDeals],
      currentPage: currentPage + 1,
      dealCounts: dealCounts,
    );
  }

  // Метод copyWith для обновления состояния
  DealDataLoaded copyWith({
    List<Deal>? deals,
    int? currentPage,
    Map<int, int>? dealCounts,
  }) {
    return DealDataLoaded(
      deals ?? this.deals,
      currentPage: currentPage ?? this.currentPage,
      dealCounts: dealCounts ?? this.dealCounts,
    );
  }
}
class DealWarning extends DealState {
  final String message;

  DealWarning(this.message);
}

class DealError extends DealState {
  final String message;

  DealError(this.message);
}

class DealSuccess extends DealState {
  final String message;

  DealSuccess(this.message);
}

class DealDeleted extends DealState {
  final String message;

  DealDeleted(this.message);
}
class DealStatusLoaded extends DealState {
  final DealStatus dealStatus;
  DealStatusLoaded(this.dealStatus);
}

class DealStatusDeleted extends DealState {
  final String message;

  DealStatusDeleted(this.message);
}
// State для успешного обновления статуса лида
class DealStatusUpdatedEdit extends DealState {
  final String message;

  DealStatusUpdatedEdit(this.message);
}
