// Добавим больше информации об ошибках для отладки
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/role/role_event.dart';
import 'package:crm_task_manager/bloc/role/role_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoleBloc extends Bloc<RoleEvent, RoleState> {
  final ApiService apiService;

  RoleBloc(this.apiService) : super(RoleInitial()) {
    on<FetchRoles>((event, emit) async {
      emit(RoleLoading());
      try {
        final roles = await apiService.getRoles();
        print('Получены роли: ${roles.length}'); // Для отладки
        emit(RoleLoaded(roles));
      } catch (e) {
        print('Ошибка при загрузке ролей: $e'); // Для отладки
        emit(RoleError('Ошибка при загрузке ролей: $e'));
      }
    });
  }
}