import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/money/add_expense_model.dart';
import 'package:equatable/equatable.dart';

part 'edit_expense_event.dart';
part 'edit_expense_state.dart';

class EditExpenseBloc extends Bloc<EditExpenseEvent, EditExpenseState> {

  final apiService = ApiService();

  EditExpenseBloc() : super(EditExpenseState()) {
    on<EditExpenseEvent>((event, emit) {
    });
    on<SubmitEditExpense>((event, emit) async {
      emit(EditExpenseState(status: EditExpenseStatus.loading));
      try {
        await apiService.patchExpense(event.id!, event.data);
        emit(EditExpenseState(status: EditExpenseStatus.loaded, message: "Расход обновлен успешно"));
      } catch (e) {
        emit(EditExpenseState(
            status: EditExpenseStatus.error,
            message: "Ошибка обновления расхода")
        );
      }
    });
  }
}

enum EditExpenseStatus {
  initial,

  loading,
  error,
  loaded,
}
