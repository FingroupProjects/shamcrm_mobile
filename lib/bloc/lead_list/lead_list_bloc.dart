import 'dart:io';
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_state.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:flutter/foundation.dart';

class GetAllLeadBloc extends Bloc<GetAllLeadEvent, GetAllLeadState> {
  // Кэшируем данные, чтобы не перезагружать их постоянно
  LeadsDataResponse? _cachedLeads;
  DateTime? _lastLoadTime;
  static const Duration _cacheExpiration = Duration(minutes: 5);
  
  GetAllLeadBloc() : super(GetAllLeadInitial()) {
    on<GetAllLeadEv>(_getLeads);
    on<RefreshAllLeadEv>(_refreshLeads);
  }

  bool get _isCacheValid {
    if (_cachedLeads == null || _lastLoadTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastLoadTime!) < _cacheExpiration;
  }

  Future<void> _getLeads(GetAllLeadEv event, Emitter<GetAllLeadState> emit) async {
    // Если у нас есть валидный кэш, используем его
    if (_isCacheValid && _cachedLeads != null) {
      if (kDebugMode) {
        print('GetAllLeadBloc: Using cached leads data');
      }
      emit(GetAllLeadSuccess(dataLead: _cachedLeads!));
      return;
    }
    
    await _loadLeads(emit);
  }

  Future<void> _refreshLeads(RefreshAllLeadEv event, Emitter<GetAllLeadState> emit) async {
    // Принудительное обновление - игнорируем кэш
    _cachedLeads = null;
    _lastLoadTime = null;
    await _loadLeads(emit);
  }

  Future<void> _loadLeads(Emitter<GetAllLeadState> emit) async {
    if (await _checkInternetConnection()) {
      try {
        emit(GetAllLeadLoading());
        
        if (kDebugMode) {
          print('GetAllLeadBloc: Starting to load all leads...');
        }
        
        var res = await ApiService().getAllLead();
        
        if (kDebugMode) {
          print('GetAllLeadBloc: Successfully loaded ${res.result?.length ?? 0} leads');
        }
        
        // Кэшируем результат
        _cachedLeads = res;
        _lastLoadTime = DateTime.now();
        
        emit(GetAllLeadSuccess(dataLead: res));
      } catch (e) {
        if (kDebugMode) {
          print('GetAllLeadBloc: Error loading leads: $e');
        }
        emit(GetAllLeadError(message: e.toString()));
      }
    } else {
      emit(GetAllLeadError(
        message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'
      ));
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
  
  // Метод для получения кэшированных данных без эмита состояния
  LeadsDataResponse? getCachedLeads() {
    return _isCacheValid ? _cachedLeads : null;
  }
}