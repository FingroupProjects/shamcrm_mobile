import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/My-Task_Status_Name/statusName_event.dart';
import 'package:crm_task_manager/bloc/My-Task_Status_Name/statusName_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyTaskMyStatusNameBloc extends Bloc<MyStatusNameEvent, MyStatusNameState> {
  final ApiService apiService;

  MyTaskMyStatusNameBloc(this.apiService) : super(MyStatusNameInitial()) {
    on<FetchMyStatusNames>((event, emit) async {
      emit(MyStatusNameLoading());

      if (await _checkInternetConnection()) {
        try {
          final statuses = await apiService.getMyStatusName();
          print('Полученные статусы в блоке: $statuses');

          emit(MyStatusNameLoaded(statuses));
        } catch (e) {
          print('Ошибка при загрузке статусов!'); // For debugging
          emit(MyStatusNameError('Ошибка при загрузке имен статусов!'));
        }
      } else {
        emit(MyStatusNameError('Нет подключения к интернету'));
      }
    });
  }

  // Method to check internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      print('Нет интернета!'); // For debugging
      return false;
    }
  }
}
