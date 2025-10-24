import '../../../../models/page_2/openings/client_openings_model.dart';

abstract class ClientOpeningsState {}

class ClientOpeningsInitial extends ClientOpeningsState {}

class ClientOpeningsLoading extends ClientOpeningsState {}

class ClientOpeningsLoaded extends ClientOpeningsState {
  final List<ClientOpening> clients;

  ClientOpeningsLoaded({
    required this.clients,
  });

  ClientOpeningsLoaded copyWith({
    List<ClientOpening>? clients,
  }) {
    return ClientOpeningsLoaded(
      clients: clients ?? this.clients,
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
