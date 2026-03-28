import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/money/add_expense_model.dart';
import 'package:equatable/equatable.dart';

part 'add_expense_event.dart';
part 'add_expense_state.dart';

class AddExpenseBloc extends Bloc<AddExpenseEvent, AddExpenseState> {

  final apiService = ApiService();

  AddExpenseBloc() : super(AddExpenseInitial()) {
    on<AddExpenseEvent>((event, emit) {
    });
    on<SubmitAddExpense>((event, emit) async {
      emit(AddExpenseState(status: AddExpenseStatus.loading));
      try {
       await apiService.postExpense(event.data);
       emit(AddExpenseState(status: AddExpenseStatus.loaded, message: "Расход добавлен успешно"));
      } catch (e) {
        emit(AddExpenseState(
            status: AddExpenseStatus.error,
            message: "Ошибка добавления расхода")
        );
      }
    });
  }
}

enum AddExpenseStatus {
  initial,

  loading,
  error,
  loaded,
}
