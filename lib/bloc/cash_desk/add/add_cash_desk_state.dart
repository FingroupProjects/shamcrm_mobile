part of 'add_cash_desk_bloc.dart';

class AddCashDeskState extends Equatable {
  const AddCashDeskState(
      {this.message, this.status = AddCashDeskStatus.initial});

  final String? message;
  final AddCashDeskStatus status;

  @override
  List<Object?> get props => [message, status];
}

final class AddCashDeskInitial extends AddCashDeskState {
  @override
  List<Object> get props => [];
}
