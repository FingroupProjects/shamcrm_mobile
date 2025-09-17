part of 'cash_desk_bloc.dart';

sealed class CashDeskEvent extends Equatable {
  const CashDeskEvent();
}

class FetchCashRegisters extends CashDeskEvent {
  final String? query;

  const FetchCashRegisters({this.query});

  @override
  List<Object?> get props => [query];
}

class LoadMoreCashRegisters extends CashDeskEvent {
  const LoadMoreCashRegisters();

  @override
  List<Object?> get props => [];
}

class RefreshCashRegisters extends CashDeskEvent {
  const RefreshCashRegisters();

  @override
  List<Object?> get props => [];
}

class SearchCashRegisters extends CashDeskEvent {
  final String? query;

  const SearchCashRegisters(this.query);

  @override
  List<Object?> get props => [query];
}

class DeleteCashDesk extends CashDeskEvent {
  final int id;

  const DeleteCashDesk(this.id);

  @override
  List<Object?> get props => [id];
}
