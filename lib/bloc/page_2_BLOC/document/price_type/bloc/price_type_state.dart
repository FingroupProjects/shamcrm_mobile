import 'package:crm_task_manager/models/page_2/price_type_model.dart';
import 'package:equatable/equatable.dart';

sealed class PriceTypeState extends Equatable {
  const PriceTypeState();

  @override
  List<Object?> get props => [];
}

final class PriceTypeInitial extends PriceTypeState {}

final class PriceTypeLoading extends PriceTypeState {}

final class PriceTypeLoaded extends PriceTypeState {
  final List<PriceTypeModel> priceTypes;

  const PriceTypeLoaded(this.priceTypes);

  @override
  List<Object?> get props => [priceTypes];
}

final class PriceTypeEmpty extends PriceTypeState {}

final class PriceTypeError extends PriceTypeState {
  final String message;

  const PriceTypeError(this.message);

  @override
  List<Object?> get props => [message];
}

class PriceTypeSuccess extends PriceTypeState {
  final String message;

  const PriceTypeSuccess(this.message);
}
