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

  // Новый метод для проверки валидности сессии
  Future<bool> _validateSessionData() async {
    try {
      final token = await apiService.getToken();
      if (token == null || token.isEmpty) {
        print('DomainBloc: Token is null or empty');
        return false;
      }

      // Проверяем домен
      String? domain = await apiService.getVerifiedDomain();
      if (domain == null || domain.isEmpty) {
        // Пробуем QR данные
        Map<String, String?> qrData = await apiService.getQrData();
        String? qrDomain = qrData['domain'];
        String? qrMainDomain = qrData['mainDomain'];
        
        if (qrDomain == null || qrDomain.isEmpty || 
            qrMainDomain == null || qrMainDomain.isEmpty) {
          // Пробуем старую логику
          Map<String, String?> domains = await apiService.getEnteredDomain();
          String? enteredDomain = domains['enteredDomain'];
          String? enteredMainDomain = domains['enteredMainDomain'];
          
          if (enteredDomain == null || enteredDomain.isEmpty ||
              enteredMainDomain == null || enteredMainDomain.isEmpty) {
            print('DomainBloc: No valid domain found');
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      print('DomainBloc: Error validating session: $e');
      return false;
    }
  }

  // Новый метод для очистки данных при критической ошибке
  Future<void> _clearSessionData() async {
    try {
      await apiService.logout();
      await apiService.reset();
      print('DomainBloc: Session data cleared');
    } catch (e) {
      print('DomainBloc: Error clearing session data: $e');
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
        print('DomainBloc: Checking email: ${event.email}');
        
        final userInfo = await apiService.getUserByEmail(event.email);
        print('DomainBloc: User info received: $userInfo');
        
        // Проверяем полученные данные
        if (userInfo['domain'] == null || userInfo['domain']!.isEmpty) {
          emit(DomainError('Получены некорректные данные домена'));
          return;
        }
        
        if (userInfo['login'] == null || userInfo['login']!.isEmpty) {
          emit(DomainError('Получены некорректные данные логина'));
          return;
        }

        // Сохраняем полученную информацию
        await apiService.saveEmailVerificationData(
          userInfo['domain']!, 
          userInfo['login']!,
          organizationId: userInfo['organization_id']
        );
        
        print('DomainBloc: Data saved, initializing API');
        
        // Инициализируем API с новым доменом
        await apiService.initializeWithEmailFlow();
        
        // Добавим небольшую задержку для гарантии
        await Future.delayed(Duration(milliseconds: 200));
        
        // Проверяем, что инициализация прошла успешно
        final baseUrl = await apiService.getDynamicBaseUrl();
        if (baseUrl.isEmpty) {
          emit(DomainError('Не удалось инициализировать соединение с сервером'));
          return;
        }
        
        print('DomainBloc: API initialized successfully');
        emit(EmailVerified(userInfo['login']!));
        
      } catch (e) {
        print('DomainBloc: Error in CheckEmail: $e');
        
        // При критической ошибке очищаем данные
        await _clearSessionData();
        
        String errorMessage = 'Неправильный email или пользователь не найден';
        
        // Более детальная обработка ошибок
        if (e.toString().contains('SocketException') || 
            e.toString().contains('TimeoutException')) {
          errorMessage = 'Проблема с подключением к серверу';
        } else if (e.toString().contains('FormatException')) {
          errorMessage = 'Получены некорректные данные от сервера';
        } else if (e.toString().contains('404')) {
          errorMessage = 'Пользователь с указанным email не найден';
        } else if (e.toString().contains('500')) {
          errorMessage = 'Ошибка сервера, попробуйте позже';
        }
        
        emit(DomainError(errorMessage));
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
        print('DomainBloc: Checking domain: ${event.domain}');
        
        // Проверяем валидность сессии перед проверкой домена
        if (!await _validateSessionData()) {
          print('DomainBloc: Invalid session data detected');
          await _clearSessionData();
          emit(DomainError('Данные сессии повреждены, необходима повторная авторизация'));
          return;
        }

        final domainCheck = await apiService.checkDomain(event.domain);
        emit(DomainLoaded(domainCheck));
        
      } catch (e) {
        print('DomainBloc: Error in CheckDomain: $e');
        
        // При критической ошибке очищаем данные
        if (e.toString().contains('401') || 
            e.toString().contains('Неавторизованный доступ')) {
          await _clearSessionData();
          emit(DomainError('Сессия истекла, необходима повторная авторизация'));
        } else {
          emit(DomainError('Неправильный поддомен'));
        }
      }
    });

    // Новое событие для проверки валидности сессии
    on<ValidateSession>((event, emit) async {
      emit(DomainLoading());
      
      try {
        final isValid = await _validateSessionData();
        if (!isValid) {
          print('DomainBloc: Session validation failed');
          await _clearSessionData();
          emit(DomainError('Сессия недействительна, необходима повторная авторизация'));
        } else {
          emit(SessionValid());
        }
      } catch (e) {
        print('DomainBloc: Error validating session: $e');
        await _clearSessionData();
        emit(DomainError('Ошибка проверки сессии'));
      }
    });

    // Событие для принудительной очистки сессии
    on<ClearSession>((event, emit) async {
      try {
        await _clearSessionData();
        emit(SessionCleared());
      } catch (e) {
        print('DomainBloc: Error clearing session: $e');
        emit(DomainError('Ошибка очистки данных'));
      }
    });
  }
}