import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/login_model.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final ApiService apiService;

  LoginBloc(this.apiService) : super(LoginInitial()) {
    on<CheckLogin>((event, emit) async {
      emit(LoginLoading());
      try {
        final loginResponse = await apiService.login(
          LoginModel(login: event.login, password: event.password),
        );
        emit(LoginLoaded(loginResponse));
      } catch (e) {
        emit(LoginError('Неправильный логин или пароль'));
      }
    });

    on<CheckCode>((event, emit) async {
      emit(CodeChecking());
      try {
        final result = await apiService.checkCode(event.code);
        emit(CodeChecked(result['domain']!, result['login']!));
      } catch (e) {
        emit(LoginError('Не удалось проверить код'));
      }
    });
  }
}