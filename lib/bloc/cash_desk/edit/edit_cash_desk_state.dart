part of 'edit_cash_desk_bloc.dart';

class EditCashDeskState extends Equatable {
  const EditCashDeskState({this.message, this.status = EditCashDeskStatus.initial});

  final String? message;
  final EditCashDeskStatus status;

  @override
  List<Object?> get props => [message, status];
}