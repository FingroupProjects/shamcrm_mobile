import '../../../../models/page_2/openings/supplier_openings_model.dart';
import '../../../../models/page_2/supplier_model.dart' as supplier_model;

abstract class SupplierOpeningsState {}

class SupplierOpeningsInitial extends SupplierOpeningsState {}

class SupplierOpeningsLoading extends SupplierOpeningsState {}

class SupplierOpeningsLoaded extends SupplierOpeningsState {
  final List<SupplierOpening> suppliers;

  SupplierOpeningsLoaded({
    required this.suppliers,
  });

  SupplierOpeningsLoaded copyWith({
    List<SupplierOpening>? suppliers,
  }) {
    return SupplierOpeningsLoaded(
      suppliers: suppliers ?? this.suppliers,
    );
  }
}

class SupplierOpeningsError extends SupplierOpeningsState {
  final String message;

  SupplierOpeningsError({required this.message});
}

class SupplierOpeningsPaginationError extends SupplierOpeningsState {
  final String message;

  SupplierOpeningsPaginationError({required this.message});
}

// Состояние для ошибок операций (создание, редактирование, удаление)
// Не влияет на отображение контента, используется только для snackbar
class SupplierOpeningsOperationError extends SupplierOpeningsState {
  final String message;
  final SupplierOpeningsState previousState;

  SupplierOpeningsOperationError({
    required this.message,
    required this.previousState,
  });
}

// Состояние загрузки для операции создания
class SupplierOpeningCreating extends SupplierOpeningsState {}

// Состояние загрузки для операции обновления
class SupplierOpeningUpdating extends SupplierOpeningsState {}

class SupplierOpeningUpdateSuccess extends SupplierOpeningsState {}

class SupplierOpeningUpdateError extends SupplierOpeningsState {
  final String message;

  SupplierOpeningUpdateError({required this.message});
}

// Состояния для списка поставщиков (для диалога)
class SupplierOpeningsSuppliersInitial extends SupplierOpeningsState {}

class SupplierOpeningsSuppliersLoading extends SupplierOpeningsState {}

class SupplierOpeningsSuppliersLoaded extends SupplierOpeningsState {
  final List<supplier_model.Supplier> suppliers;

  SupplierOpeningsSuppliersLoaded({
    required this.suppliers,
  });

  SupplierOpeningsSuppliersLoaded copyWith({
    List<supplier_model.Supplier>? suppliers,
  }) {
    return SupplierOpeningsSuppliersLoaded(
      suppliers: suppliers ?? this.suppliers,
    );
  }
}

class SupplierOpeningsSuppliersError extends SupplierOpeningsState {
  final String message;

  SupplierOpeningsSuppliersError({required this.message});
}
