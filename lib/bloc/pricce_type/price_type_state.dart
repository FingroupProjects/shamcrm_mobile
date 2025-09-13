import 'package:crm_task_manager/models/price_type_model.dart';

abstract class PriceTypeState {}

class PriceTypeInitial extends PriceTypeState {}

class PriceTypeLoading extends PriceTypeState {}

class PriceTypeLoaded extends PriceTypeState {
  final List<PriceType> priceTypes;

  PriceTypeLoaded(this.priceTypes);
}

class PriceTypeError extends PriceTypeState {
  final String message;

  PriceTypeError(this.message);
}

class PriceTypeSuccess extends PriceTypeState {
  final String message;

  PriceTypeSuccess(this.message);
}
