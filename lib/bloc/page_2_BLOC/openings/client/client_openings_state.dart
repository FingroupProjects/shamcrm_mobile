import '../../../../models/page_2/openings/client_openings_model.dart';

abstract class ClientOpeningsState {}

class ClientOpeningsInitial extends ClientOpeningsState {}

class ClientOpeningsLoading extends ClientOpeningsState {}

class ClientOpeningsLoaded extends ClientOpeningsState {
  final List<ClientOpening> clients;
  final String? search;

  ClientOpeningsLoaded({
    required this.clients,
    this.search,
  });

  ClientOpeningsLoaded copyWith({
    List<ClientOpening>? clients,
    String? search,
  }) {
    return ClientOpeningsLoaded(
      clients: clients ?? this.clients,
      search: search ?? this.search,
    );
  }
}

class ClientOpeningsError extends ClientOpeningsState {
  final String message;

  ClientOpeningsError({required this.message});
}

class ClientOpeningsPaginationError extends ClientOpeningsState {
  final String message;

  ClientOpeningsPaginationError({required this.message});
}

// Состояние для ошибок операций (создание, редактирование, удаление)
// Не влияет на отображение контента, используется только для snackbar
class ClientOpeningsOperationError extends ClientOpeningsState {
  final String message;
  final ClientOpeningsState previousState;

  ClientOpeningsOperationError({
    required this.message,
    required this.previousState,
  });
}

// Состояние загрузки для операции создания
class ClientOpeningCreating extends ClientOpeningsState {}

// Состояние успешного создания
class ClientOpeningCreateSuccess extends ClientOpeningsState {}

// Состояние ошибки создания
class ClientOpeningCreateError extends ClientOpeningsState {
  final String message;

  ClientOpeningCreateError({required this.message});
}

// Состояние загрузки для операции обновления
class ClientOpeningUpdating extends ClientOpeningsState {}

class ClientOpeningUpdateSuccess extends ClientOpeningsState {}

class ClientOpeningUpdateError extends ClientOpeningsState {
  final String message;

  ClientOpeningUpdateError({required this.message});
}

// Состояние успешного удаления
class ClientOpeningDeleteSuccess extends ClientOpeningsState {}

// Состояния для загрузки списка клиентов/лидов (для диалога выбора)
class ClientOpeningsLeadsLoading extends ClientOpeningsState {}

class ClientOpeningsLeadsLoaded extends ClientOpeningsState {
  final List<LeadForOpenings> leads;

  ClientOpeningsLeadsLoaded({required this.leads});
}

class ClientOpeningsLeadsError extends ClientOpeningsState {
  final String message;

  ClientOpeningsLeadsError({required this.message});
}
