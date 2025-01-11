import 'package:crm_task_manager/models/deal_model.dart';

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
  final bool allDealsFetched;

  DealDataLoaded(this.deals, {this.currentPage = 1, this.allDealsFetched = false});

  // Метод для объединения с новыми сделками
  DealDataLoaded merge(List<Deal> newDeals, {bool? allFetched}) {
    return DealDataLoaded(
      [...deals, ...newDeals],
      currentPage: currentPage + 1,
      allDealsFetched: allFetched ?? this.allDealsFetched,
    );
  }

  // Метод copyWith для обновления состояния
  DealDataLoaded copyWith({
    List<Deal>? deals,
    int? currentPage,
    bool? allDealsFetched,
  }) {
    return DealDataLoaded(
      deals ?? this.deals,
      currentPage: currentPage ?? this.currentPage,
      allDealsFetched: allDealsFetched ?? this.allDealsFetched,
    );
  }
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

class DealStatusDeleted extends DealState {
  final String message;

  DealStatusDeleted(this.message);
}