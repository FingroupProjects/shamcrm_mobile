import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/money/add_money_reference_model.dart';
import 'package:equatable/equatable.dart';

part 'edit_money_references_event.dart';
part 'edit_money_references_state.dart';

class EditMoneyReferencesBloc extends Bloc<EditMoneyReferencesEvent, EditMoneyReferencesState> {

  final apiService = ApiService();

  EditMoneyReferencesBloc() : super(EditMoneyReferencesState()) {
    on<EditMoneyReferencesEvent>((event, emit) {
    });
    on<SubmitEditMoneyReference>((event, emit) async {
      emit(EditMoneyReferencesState(status: EditMoneyReferencesStatus.loading));
      try {
        await apiService.patchCashRegister(event.id!, event.data);
        emit(EditMoneyReferencesState(status: EditMoneyReferencesStatus.loaded, message: "Money reference edited successfully"));
      } catch (e) {
        emit(EditMoneyReferencesState(
            status: EditMoneyReferencesStatus.error,
            message: "Failed to edit money reference")
        );
      }
    });
  }
}

enum EditMoneyReferencesStatus {
  initial,

  loading,
  error,
  loaded,
}