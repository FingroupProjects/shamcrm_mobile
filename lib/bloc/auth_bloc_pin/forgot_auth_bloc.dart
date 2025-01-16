// BLoC для запроса временного PIN-кода
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/forgot_auth_event.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/forgot_auth_state.dart';
import 'package:crm_task_manager/models/login_model.dart';

class ForgotPinBloc extends Bloc<ForgotPinEvent, ForgotPinState> {
  final ApiService apiService;

  ForgotPinBloc({required this.apiService}) : super(ForgotPinInitial()) {
    on<RequestForgotPin>(_onRequestForgotPin);
  }

  Future<void> _onRequestForgotPin(
    RequestForgotPin event,
    Emitter<ForgotPinState> emit,
  ) async {
    emit(ForgotPinLoading());
    try {
      // Логируем входящие данные для дебага
      print('Запрос на получение временного PIN для логина: ${event.login}');

      final loginModel = LoginModel(
        login: event.login,
        password: event.password,
      );

      // Запрос к API
      final pin = await apiService.forgotPin(loginModel);

      // Успешное завершение
      emit(ForgotPinSuccess(int.parse(pin)));
    } catch (error) {
      // Логируем ошибку и передаем её в состояние ошибки
      print('Ошибка при запросе временного PIN!rror');
      emit(ForgotPinFailure(error.toString()));
    }
  }
}
