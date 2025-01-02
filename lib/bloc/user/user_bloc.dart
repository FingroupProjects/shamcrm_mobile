import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/user_model.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserTaskBloc extends Bloc<UserTaskEvent, UserTaskState> {
  final ApiService apiService;

  UserTaskBloc(this.apiService) : super(UserTaskInitial()) {
    on<FetchUsers>((event, emit) async {
      emit(UserTaskLoading());

      if (await _checkInternetConnection()) {
        try {
          final user = await apiService.getUserTask();
          emit(UserTaskLoaded(user.cast<UserTask>()));  
        } catch (e) {
          print('Ошибка при загрузке клиентов: $e'); // For debugging
          emit(UserTaskError('Ошибка при загрузке клиентов!'));
        }
      } else {
        emit(UserTaskError('Нет подключения к интернету'));
      }
    });
  }

  // Method to check internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      print('Нет интернета: $e'); // For debugging
      return false;
    }
  }
}


// // bloc/user/user_bloc.dart
// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'user_event.dart';
// import 'user_state.dart';

// class UserBloc extends Bloc<UserEvent, UserState> {
//   final ApiService apiService;

//   UserBloc(this.apiService) : super(UserInitial()) {
//     on<FetchUsers>((event, emit) async {
//       emit(UserLoading());
//       try {
//         final users = await apiService.getUsers();
//         print('Получено пользователей: ${users.length}'); // Для отладки
//         emit(UserLoaded(users));
//       } catch (e) {
//         print('Ошибка при загрузке пользователей: $e'); // Для отладки
//         emit(UserError('Ошибка при загрузке пользователей: $e'));
//       }
//     });
//   }
// }
