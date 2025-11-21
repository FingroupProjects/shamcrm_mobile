import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'operator_event.dart';
import 'operator_state.dart';

class OperatorBloc extends Bloc<OperatorEvent, OperatorState> {
  final ApiService apiService;

  OperatorBloc(this.apiService) : super(OperatorInitial()) {
    on<FetchOperators>((event, emit) async {
      emit(OperatorLoading());
      try {
        final operatorList = await apiService.getOperators();
        emit(OperatorLoaded(operatorList.result));
      } catch (e) {
        emit(OperatorError(e.toString()));
      }
    });
  }
}