import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/money/add_income_model.dart';
import 'package:equatable/equatable.dart';

part 'edit_income_event.dart';
part 'edit_income_state.dart';

class EditIncomeBloc extends Bloc<EditIncomeEvent, EditIncomeState> {

  final apiService = ApiService();

  EditIncomeBloc() : super(EditIncomeState()) {
    on<EditIncomeEvent>((event, emit) {
    });
    on<SubmitEditIncome>((event, emit) async {
      emit(EditIncomeState(status: EditIncomeStatus.loading));
      try {
        await apiService.patchIncome(event.id!, event.data);
        emit(EditIncomeState(status: EditIncomeStatus.loaded, message: "Доход обновлен успешно"));
      } catch (e) {
        emit(EditIncomeState(
            status: EditIncomeStatus.error,
            message: "Ошибка обновления дохода")
        );
      }
    });
  }
}

enum EditIncomeStatus {
  initial,

  loading,
  error,
  loaded,
}
