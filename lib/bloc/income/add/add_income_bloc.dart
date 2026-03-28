import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/money/add_income_model.dart';
import 'package:equatable/equatable.dart';

part 'add_income_event.dart';
part 'add_income_state.dart';

class AddIncomeBloc extends Bloc<AddIncomeEvent, AddIncomeState> {

  final apiService = ApiService();

  AddIncomeBloc() : super(AddIncomeInitial()) {
    on<AddIncomeEvent>((event, emit) {
    });
    on<SubmitAddIncome>((event, emit) async {
      emit(AddIncomeState(status: AddIncomeStatus.loading));
      try {
       await apiService.postIncome(event.data);
       emit(AddIncomeState(status: AddIncomeStatus.loaded, message: "Доход добавлен успешно"));
      } catch (e) {
        emit(AddIncomeState(
            status: AddIncomeStatus.error,
            message: "Ошибка добавления дохода")
        );
      }
    });
  }
}

enum AddIncomeStatus {
  initial,

  loading,
  error,
  loaded,
}
