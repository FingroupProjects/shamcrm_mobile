import 'package:crm_task_manager/models/page_2/price_type_model.dart';
import 'package:equatable/equatable.dart';

abstract class PriceTypeEvent extends Equatable {
  const PriceTypeEvent();

  @override
  List<Object?> get props => [];
}

class FetchPriceType extends PriceTypeEvent {
  const FetchPriceType();
}

class RefreshPriceType extends PriceTypeEvent {
  const RefreshPriceType();
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
