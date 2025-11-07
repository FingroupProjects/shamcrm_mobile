import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';

class FieldConfigurationBloc extends Bloc<FieldConfigurationEvent, FieldConfigurationState> {
  final ApiService apiService;

  FieldConfigurationBloc(this.apiService) : super(FieldConfigurationInitial()) {
    on<FetchFieldConfiguration>(_onFetchFieldConfiguration);
  }

  Future<void> _onFetchFieldConfiguration(
    FetchFieldConfiguration event,
    Emitter<FieldConfigurationState> emit,
  ) async {
    if (kDebugMode) {
      //print('FieldConfigurationBloc: Starting to fetch configuration for table: ${event.tableName}');
    }
    
    emit(FieldConfigurationLoading());
    
    try {
      // // СНАЧАЛА ПЫТАЕМСЯ ЗАГРУЗИТЬ ИЗ КЭША
      // if (kDebugMode) {
      //   //print('FieldConfigurationBloc: Checking cache...');
      // }
      // 
      // final cachedConfig = await apiService.getCachedFieldConfiguration(
      //   tableName: event.tableName,
      // );
      // 
      // if (cachedConfig != null) {
      //   if (kDebugMode) {
      //     //print('FieldConfigurationBloc: Found cached configuration with ${cachedConfig.result.length} fields');
      //   }
      //   
      //   // Получаем ВСЕ поля (не фильтруем по isActive) и сортируем по position
      //   final allFields = cachedConfig.result
      //       .toList()
      //     ..sort((a, b) => a.position.compareTo(b.position));
      //   
      //   if (kDebugMode) {
      //     //print('FieldConfigurationBloc: All fields count: ${allFields.length}');
      //     for (var field in allFields) {
      //       //print('FieldConfigurationBloc: Field - name: ${field.fieldName}, position: ${field.position}, isActive: ${field.isActive}, isCustom: ${field.isCustomField}, isDirectory: ${field.isDirectory}');
      //     }
      //   }
      //   
      //   emit(FieldConfigurationLoaded(allFields));
      //   
      //   if (kDebugMode) {
      //     //print('FieldConfigurationBloc: Successfully emitted FieldConfigurationLoaded state from cache');
      //   }
      //   
      //   return;
      // }
      
      // // ЕСЛИ КЭША НЕТ - ЗАГРУЖАЕМ С СЕРВЕРА
      // if (kDebugMode) {
      //   //print('FieldConfigurationBloc: No cache found, fetching from API...');
      // }
      
      final response = await apiService.getFieldPositions(
        tableName: event.tableName,
      );
      
      if (kDebugMode) {
        //print('FieldConfigurationBloc: API response received with ${response.result.length} fields');
      }
      
      // // Сохраняем в кэш
      // await apiService.cacheFieldConfiguration(
      //   tableName: event.tableName,
      //   configuration: response,
      // );
      
      // Получаем ВСЕ поля (не фильтруем по isActive) и сортируем по position
      final allFields = response.result
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));
      
      if (kDebugMode) {
        //print('FieldConfigurationBloc: All fields count: ${allFields.length}');
        // for (var field in allFields) {
        //   //print('FieldConfigurationBloc: Field - name: ${field.fieldName}, position: ${field.position}, isActive: ${field.isActive}, isCustom: ${field.isCustomField}, isDirectory: ${field.isDirectory}');
        // }
      }
      
      emit(FieldConfigurationLoaded(allFields));
      
      if (kDebugMode) {
        //print('FieldConfigurationBloc: Successfully emitted FieldConfigurationLoaded state from API');
      }
    } catch (e) {
      if (kDebugMode) {
        //print('FieldConfigurationBloc: Error occurred: $e');
      }
      emit(FieldConfigurationError(e.toString()));
    }
  }
}