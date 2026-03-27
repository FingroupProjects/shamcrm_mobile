import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/money/add_cash_desk_model.dart';
import 'package:equatable/equatable.dart';

part 'edit_cash_desk_event.dart';
part 'edit_cash_desk_state.dart';

class EditCashDeskBloc extends Bloc<EditCashDeskEvent, EditCashDeskState> {

  final apiService = ApiService();

  EditCashDeskBloc() : super(EditCashDeskState()) {
    on<EditCashDeskEvent>((event, emit) {
    });
    on<SubmitEditCashDesk>((event, emit) async {
      emit(EditCashDeskState(status: EditCashDeskStatus.loading));
      try {
        await apiService.patchCashRegister(event.id!, event.data);
        emit(EditCashDeskState(status: EditCashDeskStatus.loaded, message: "Money reference edited successfully"));
      } catch (e) {
        emit(EditCashDeskState(
            status: EditCashDeskStatus.error,
            message: "Failed to edit money reference")
        );
      }
    });
  }
}

enum EditCashDeskStatus {
  initial,

  loading,
  error,
  loaded,
}