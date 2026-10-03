import 'dart:async';
import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/auth/login_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final ApiService apiService;

  LoginBloc(this.apiService) : super(LoginInitial()) {
    on<CheckLogin>((event, emit) async {
      emit(LoginLoading());
      try {
        // ВАЖНО: Убеждаемся что baseUrl установлен
        if (apiService.baseUrl == null || apiService.baseUrl!.isEmpty) {
          // Пытаемся инициализировать еще раз
          await apiService.initialize();

          // Если все еще null, значит проблема
          if (apiService.baseUrl == null || apiService.baseUrl!.isEmpty) {
            emit(LoginError('Ошибка инициализации. Попробуйте еще раз.'));
            return;
          }
        }

        // Запрос логина идёт сразу. Отдельная проверка example.com
        // раньше добавляла десятки секунд до самого входа.
        final loginModel =
            LoginModel(login: event.login, password: event.password);
        final loginResponse = await apiService.login(loginModel);

        // НОВОЕ: Получаем hasMiniApp из ответа
        // Предполагаем, что loginResponse содержит поле hasMiniApp
        bool hasMiniApp = loginResponse.hasMiniApp ?? false;

        emit(LoginLoaded(loginResponse.token, loginResponse.user, hasMiniApp));
      } catch (e) {
        //print('LoginBloc: Ошибка входа: $e');
        if (_isNetworkError(e)) {
          emit(LoginError('Нет подключения к интернету'));
          return;
        }
        emit(LoginError('Неправильный логин или пароль'));
      }
    });
  }

  bool _isNetworkError(Object error) {
    if (error is SocketException || error is TimeoutException) {
      return true;
    }
    final text = error.toString().toLowerCase();
    return text.contains('socket') ||
        text.contains('timeout') ||
        text.contains('network') ||
        text.contains('connection') ||
        text.contains('failed host lookup');
  }
}
