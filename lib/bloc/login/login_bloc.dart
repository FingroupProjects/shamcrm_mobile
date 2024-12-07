import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/login_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_event.dart'; // Импортируйте ваш файл событий логина
import 'login_state.dart'; // Импортируйте ваш файл состояний логина
import 'dart:io';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final ApiService apiService;

  LoginBloc(this.apiService) : super(LoginInitial()) {
    on<CheckLogin>((event, emit) async {
      emit(LoginLoading());
      if (await _checkInternetConnection()) {
        try {
          final loginModel = LoginModel(login: event.login, password: event.password);
          final loginResponse = await apiService.login(loginModel);
          emit(LoginLoaded(loginResponse.token, loginResponse.user)); // Передайте токен в LoginLoaded
        } catch (e) {
          emit(LoginError('Не правильный Логин или Пароль'));
        }
      } else {
        emit(LoginError('Нет подключения к интернету'));
      }
    });
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}
