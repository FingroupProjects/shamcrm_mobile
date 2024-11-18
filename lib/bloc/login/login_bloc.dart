<<<<<<< HEAD
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/login_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_event.dart'; // Импортируйте ваш файл событий логина
import 'login_state.dart'; // Импортируйте ваш файл состояний логина

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final ApiService apiService;

  LoginBloc(this.apiService) : super(LoginInitial()) {
    on<CheckLogin>((event, emit) async {
      emit(LoginLoading());
      try {
        final loginModel =
            LoginModel(login: event.login, password: event.password);
        final loginResponse = await apiService.login(loginModel);
        emit(LoginLoaded(loginResponse.token,
            loginResponse.user)); // Передайте токен в LoginLoaded
      } catch (e) {
        emit(LoginError('Не правильный Логин или Пароль'));
      }
    });
  }
}
=======
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/login_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_event.dart'; // Импортируйте ваш файл событий логина
import 'login_state.dart'; // Импортируйте ваш файл состояний логина

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final ApiService apiService;

  LoginBloc(this.apiService) : super(LoginInitial()) {
    on<CheckLogin>((event, emit) async {
      emit(LoginLoading());
      try {
        final loginModel = LoginModel(login: event.login, password: event.password);
        final loginResponse = await apiService.login(loginModel);
        emit(LoginLoaded(loginResponse.token)); // Передайте токен в LoginLoaded
      } catch (e) {
        emit(LoginError('Не правильный Логин или Пароль')); 
      }
    });
  }
}
>>>>>>> main
