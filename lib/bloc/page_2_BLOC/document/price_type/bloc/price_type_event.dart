import 'package:crm_task_manager/models/page_2/price_type_model.dart';
import 'package:equatable/equatable.dart';

abstract class PriceTypeEvent extends Equatable {
  const PriceTypeEvent();

  @override
  List<Object?> get props => [];
}

class FetchPriceType extends PriceTypeEvent {
  final String? query;
  
  const FetchPriceType({this.query});
  
  @override
  List<Object?> get props => [query];
}

class RefreshPriceType extends PriceTypeEvent {
  final String? query;
  
  const RefreshPriceType({this.query});
  
  @override
  List<Object?> get props => [query];
}

class AddPriceType extends PriceTypeEvent {
  final PriceTypeModel priceType;
  const AddPriceType(this.priceType);
}

class EditPriceTypeEvent extends PriceTypeEvent {
  final int id;
  final PriceTypeModel priceType;
  const EditPriceTypeEvent(this.priceType, this.id);
}

class DeletePriceType extends PriceTypeEvent {
  final int id;

  const DeletePriceType(this.id);
}
