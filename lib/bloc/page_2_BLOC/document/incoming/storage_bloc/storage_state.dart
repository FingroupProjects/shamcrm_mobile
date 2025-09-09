import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';

abstract class StorageState {}

class StorageInitial extends StorageState {}

class StorageLoading extends StorageState {}

class StorageLoaded extends StorageState {
  final List<Storage> storageList;

  StorageLoaded(this.storageList);
}

class StorageError extends StorageState {
  final String message;

  StorageError(this.message);
}

class StorageSuccess extends StorageState {
  final String message;

  StorageSuccess(this.message);
}