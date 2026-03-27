import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/money/add_cash_desk_model.dart';
import 'package:equatable/equatable.dart';

part 'add_cash_desk_event.dart';
part 'add_cash_desk_state.dart';

class AddCashDeskBloc extends Bloc<AddCashDeskEvent, AddCashDeskState> {

  final apiService = ApiService();

  AddCashDeskBloc() : super(AddCashDeskInitial()) {
    on<AddCashDeskEvent>((event, emit) {
    });
    on<SubmitAddCashDesk>((event, emit) async {
      emit(AddCashDeskState(status: AddCashDeskStatus.loading));
      try {
       await apiService.postCashRegister(event.data);
       emit(AddCashDeskState(status: AddCashDeskStatus.loaded, message: "Money reference added successfully"));
      } catch (e) {
        emit(AddCashDeskState(
            status: AddCashDeskStatus.error,
            message: "Failed to add money reference")
        );
      }
    });
  }
}

enum AddCashDeskStatus {
  initial,

  loading,
  error,
  loaded,
}