import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'manager_event.dart';
import 'manager_state.dart';

class ManagerBloc extends Bloc<ManagerEvent, ManagerState> {
  final ApiService apiService;

  ManagerBloc(this.apiService) : super(ManagerInitial()) {
    on<FetchManagers>((event, emit) async {
      emit(ManagerLoading());
      try {
        final managers = await apiService.getManager();
        emit(ManagerLoaded(managers));
      } catch (e) {
        emit(ManagerError('Ошибка при загрузке Менеджеров'));
      }
    });
  }
}
