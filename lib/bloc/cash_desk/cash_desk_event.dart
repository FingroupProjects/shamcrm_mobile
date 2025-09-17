part of 'cash_desk_bloc.dart';

sealed class CashDeskEvent extends Equatable {
  const CashDeskEvent();
}

class FetchCashRegisters extends CashDeskEvent {
  const FetchCashRegisters();

  @override
  List<Object?> get props => [];
}

class DeleteCashDesk extends CashDeskEvent {
  final int id;

  const DeleteCashDesk(this.id);

  @override
  List<Object?> get props => [id];
}
