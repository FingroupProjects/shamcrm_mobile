<<<<<<< HEAD
import 'package:crm_task_manager/models/deal_model.dart';

abstract class DealState {}

class DealInitial extends DealState {}

class DealLoading extends DealState {}

class DealLoaded extends DealState {
  final List<DealStatus> dealStatuses;

  DealLoaded(this.dealStatuses);
}

class DealDataLoaded extends DealState {
  final List<Deal> deals;
  final int currentPage;

  DealDataLoaded(this.deals, {this.currentPage = 1});

  // Метод для объединения с новыми сделками
  DealDataLoaded merge(List<Deal> newDeals) {
    return DealDataLoaded([...deals, ...newDeals],
        currentPage: currentPage + 1);
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
=======
import 'package:crm_task_manager/models/deal_model.dart';

abstract class DealState {}

class DealInitial extends DealState {}

class DealLoading extends DealState {}

class DealLoaded extends DealState {
  final List<DealStatus> dealStatuses;

  DealLoaded(this.dealStatuses);
}

class DealDataLoaded extends DealState {
  final List<Deal> deals;
  final int currentPage;

  DealDataLoaded(this.deals, {this.currentPage = 1});

  // Метод для объединения с новыми сделками
  DealDataLoaded merge(List<Deal> newDeals) {
    return DealDataLoaded([...deals, ...newDeals],
        currentPage: currentPage + 1);
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
>>>>>>> main
}