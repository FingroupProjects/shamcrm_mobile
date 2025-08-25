import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'domain_event.dart';
import '../../api/service/api_service.dart';
import 'domain_state.dart';

class DomainBloc extends Bloc<DomainEvent, DomainState> {
  final ApiService apiService;

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  DomainBloc(this.apiService) : super(DomainInitial()) {
    // Событие для проверки email
    on<CheckEmail>((event, emit) async {
      emit(DomainLoading());
      // Проверка подключения к интернету
      if (!await _checkInternetConnection()) {
        emit(DomainError('Нет подключения к интернету'));
        return;
      }
      try {
        final userInfo = await apiService.getUserByEmail(event.email);
        // Сохраняем полученную информацию
        await apiService.saveEmailVerificationData(userInfo['domain']!, userInfo['login']!);
        // ВАЖНО: Обязательно инициализируем API с новым доменом
        await apiService.initializeWithEmailFlow();
        
        // Добавим небольшую задержку для гарантии
        await Future.delayed(Duration(milliseconds: 100));
        
        emit(EmailVerified(userInfo['login']!));
      } catch (e) {
        emit(DomainError('Неправильный email или пользователь не найден'));
      }
    });

    // Старое событие для обратной совместимости (если нужно)
    on<CheckDomain>((event, emit) async {
      emit(DomainLoading());
      if (!await _checkInternetConnection()) {
        emit(DomainError('Нет подключения к интернету'));
        return;
      }
      try {
        final domainCheck = await apiService.checkDomain(event.domain);
        emit(DomainLoaded(domainCheck));
      } catch (e) {
        emit(DomainError('Не правильный поддомен'));
      }
    });
  }
}