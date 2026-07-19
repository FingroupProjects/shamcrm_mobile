import 'package:crm_task_manager/utils/user_friendly_error.dart';
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
    final loginModel = LoginModel(
      login: event.login,
      password: event.password,
    );

    // 👇 Теперь получаем ForgotPinResponse
    final response = await apiService.forgotPin(loginModel);

    // 👇 Передаём и код, и email
    emit(ForgotPinSuccess(
      pin: response.code,
      email: response.email,
    ));
  } catch (error) {
    emit(ForgotPinFailure(friendlyError(error)));
  }
}
}
