part of 'add_cash_desk_bloc.dart';

sealed class AddCashDeskEvent extends Equatable {
  const AddCashDeskEvent();
}

class SubmitAddCashDesk extends AddCashDeskEvent {
  final AddCashDeskModel data;

  const SubmitAddCashDesk({required this.data});

  @override
  List<Object?> get props => [data];
}