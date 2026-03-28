import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:equatable/equatable.dart';

abstract class WareHouseEvent extends Equatable {
  const WareHouseEvent();

  @override
  List<Object?> get props => [];
}

class FetchWareHouse extends WareHouseEvent {

  final String? query;

  const FetchWareHouse({this.query});

  @override
  List<Object?> get props => [query];
}

class CreateWareHouse extends WareHouseEvent {
  final WareHouse storage;
  final List<int> ids;
  const CreateWareHouse(this.storage, this.ids);

  @override
  List<Object?> get props => [storage, ids];
}

class UpdateWareHouse extends WareHouseEvent {
  final WareHouse storage;
  final List<int> ids;
  final int id;
  const UpdateWareHouse(this.storage, this.ids, this.id);

  @override
  List<Object?> get props => [storage, ids, id];
}

class DeleteWareHouse extends WareHouseEvent {
  final int id;

  const DeleteWareHouse(this.id);

  @override
  List<Object?> get props => [id];
}
