import 'package:crm_task_manager/models/dealById_model.dart';

abstract class DealByIdState {}

class DealByIdInitial extends DealByIdState {}

class DealByIdLoading extends DealByIdState {}

class DealByIdLoaded extends DealByIdState {
  final DealById deal;
  DealByIdLoaded(this.deal);
}

class DealByIdError extends DealByIdState {
  final String message;
  DealByIdError(this.message);
}
