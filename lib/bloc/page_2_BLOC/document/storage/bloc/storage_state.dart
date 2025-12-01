import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:equatable/equatable.dart';

abstract class WareHouseState extends Equatable {
  const WareHouseState();

  @override
  List<Object?> get props => [];
}

class WareHouseInitial extends WareHouseState {}

class WareHouseLoading extends WareHouseState {}

class WareHouseSuccess extends WareHouseState{}

class WareHouseLoaded extends WareHouseState {
  final List<WareHouse> storages;

  const WareHouseLoaded(this.storages);

  @override
  List<Object?> get props => [storages];
}

class WareHouseError extends WareHouseState {
  final String message;

  const WareHouseError(this.message);

  @override
  List<Object?> get props => [message];
}
