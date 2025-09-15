import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/money/add_money_reference_model.dart';
import 'package:equatable/equatable.dart';

part 'add_money_references_event.dart';
part 'add_money_references_state.dart';

class AddMoneyReferencesBloc extends Bloc<AddMoneyReferencesEvent, AddMoneyReferencesState> {

  final apiService = ApiService();

  AddMoneyReferencesBloc() : super(AddMoneyReferencesInitial()) {
    on<AddMoneyReferencesEvent>((event, emit) {
    });
    on<SubmitAddMoneyReference>((event, emit) async {
      emit(AddMoneyReferencesState(status: AddMoneyReferencesStatus.loading));
      try {
       await apiService.postCashRegister(event.data);
       emit(AddMoneyReferencesState(status: AddMoneyReferencesStatus.loaded, message: "Money reference added successfully"));
      } catch (e) {
        emit(AddMoneyReferencesState(
            status: AddMoneyReferencesStatus.error,
            message: "Failed to add money reference")
        );
      }
    });
  }
}

enum AddMoneyReferencesStatus {
  initial,

  loading,
  error,
  loaded,
}