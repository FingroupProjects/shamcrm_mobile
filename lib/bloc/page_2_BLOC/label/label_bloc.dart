// label_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'label_event.dart';
import 'label_state.dart';

class LabelBloc extends Bloc<LabelEvent, LabelState> {
  final ApiService apiService;
  bool allLabelsFetched = false;

  LabelBloc(this.apiService) : super(LabelInitial()) {
    on<FetchLabels>(_fetchLabels);
  }

  Future<void> _fetchLabels(FetchLabels event, Emitter<LabelState> emit) async {
    emit(LabelLoading());
    
    if (await _checkInternetConnection()) {
      try {
        final labels = await apiService.getLabels();
        allLabelsFetched = labels.isEmpty;
        emit(LabelLoaded(labels));
      } catch (e) {
        debugPrint('Ошибка при загрузке меток!'); // Для отладки
        emit(LabelError('Не удалось загрузить список меток!'));
      }
    } else {
      emit(LabelError('Нет подключения к интернету'));
    }
  }

  // Метод для проверки интернет-соединения
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      return false;
    }
  }
}