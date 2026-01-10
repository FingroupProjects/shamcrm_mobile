part of 'edit_cash_desk_bloc.dart';

sealed class EditCashDeskEvent extends Equatable {
  const EditCashDeskEvent();
}

class SubmitEditCashDesk extends EditCashDeskEvent {
  final AddCashDeskModel data;
  final int? id;

  const SubmitEditCashDesk({required this.data, this.id});

  @override
  List<Object?> get props => [data, id];
}