import 'package:crm_task_manager/models/page_2/storage_model.dart';

abstract class StorageDashboardState {}

class StorageDashboardInitial extends StorageDashboardState {}

class StorageDashboardLoading extends StorageDashboardState {}

class StorageDashboardLoaded extends StorageDashboardState {
  final List<WareHouse> storageList;

  StorageDashboardLoaded(this.storageList);
}

class StorageDashboardError extends StorageDashboardState {
  final String message;

  StorageDashboardError(this.message);
}

class StorageDashboardSuccess extends StorageDashboardState {
  final String message;

  StorageDashboardSuccess(this.message);
}

