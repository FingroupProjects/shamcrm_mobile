import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/login_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_event.dart';
import 'login_state.dart';
import 'dart:io';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final ApiService apiService;

  LoginBloc(this.apiService) : super(LoginInitial()) {
    on<CheckLogin>((event, emit) async {
      emit(LoginLoading());
      if (await _checkInternetConnection()) {
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
          
          //print('LoginBloc: Используем baseUrl: ${apiService.baseUrl}');
          
          final loginModel = LoginModel(login: event.login, password: event.password);
          final loginResponse = await apiService.login(loginModel);
          
          // НОВОЕ: Получаем hasMiniApp из ответа
          // Предполагаем, что loginResponse содержит поле hasMiniApp
          bool hasMiniApp = loginResponse.hasMiniApp ?? false;
          
          emit(LoginLoaded(loginResponse.token, loginResponse.user, hasMiniApp));
        } catch (e) {
          //print('LoginBloc: Ошибка входа: $e');
          emit(LoginError('Неправильный логин или пароль'));
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