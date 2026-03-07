import 'dart:io';
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_state.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:flutter/foundation.dart';

class GetAllLeadBloc extends Bloc<GetAllLeadEvent, GetAllLeadState> {
  // ИСПРАВЛЕНО: Два отдельных кэша для разных типов данных
  LeadsDataResponse? _cachedLeadsWithoutDebt;
  DateTime? _lastLoadTimeWithoutDebt;

  LeadsDataResponse? _cachedLeadsWithDebt;
  DateTime? _lastLoadTimeWithDebt;

  static const Duration _cacheExpiration = Duration(minutes: 5);
  final apiService = ApiService();

  GetAllLeadBloc() : super(GetAllLeadInitial()) {
    on<GetAllLeadEv>(_getLeads);
    on<RefreshAllLeadEv>(_refreshLeads);
  }

  // ИСПРАВЛЕНО: Проверка валидности кэша с учетом showDebt
  bool _isCacheValid(bool showDebt) {
    final cachedData =
        showDebt ? _cachedLeadsWithDebt : _cachedLeadsWithoutDebt;
    final lastLoadTime =
        showDebt ? _lastLoadTimeWithDebt : _lastLoadTimeWithoutDebt;

    if (cachedData == null || lastLoadTime == null) {
      return false;
    }
    return DateTime.now().difference(lastLoadTime) < _cacheExpiration;
  }

  Future<void> _getLeads(
      GetAllLeadEv event, Emitter<GetAllLeadState> emit) async {
    // ИСПРАВЛЕНО: Используем правильный кэш в зависимости от showDebt
    if (_isCacheValid(event.showDebt)) {
      final cachedData =
          event.showDebt ? _cachedLeadsWithDebt : _cachedLeadsWithoutDebt;
      if (kDebugMode) {
        //print('GetAllLeadBloc: Using cached leads data (showDebt=${event.showDebt})');
      }
      emit(GetAllLeadSuccess(dataLead: cachedData!));
      return;
    }

    await _loadLeadsProgressive(emit, event.showDebt);
  }

  Future<void> _refreshLeads(
      RefreshAllLeadEv event, Emitter<GetAllLeadState> emit) async {
    // ИСПРАВЛЕНО: Очищаем правильный кэш
    if (event.showDebt) {
      _cachedLeadsWithDebt = null;
      _lastLoadTimeWithDebt = null;
    } else {
      _cachedLeadsWithoutDebt = null;
      _lastLoadTimeWithoutDebt = null;
    }
    await _loadLeadsProgressive(emit, event.showDebt);
  }

  Future<void> _loadLeadsProgressive(
      Emitter<GetAllLeadState> emit, bool showDebt) async {
    if (!await _checkInternetConnection()) {
      emit(GetAllLeadError(
          message:
              'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
      return;
    }

    try {
      emit(GetAllLeadLoading());

      if (kDebugMode) {
        //print('GetAllLeadBloc: Loading first page of leads (showDebt=$showDebt)...');
      }

      // Загружаем только первую страницу
      var firstPageRes = await apiService.getLeadPage(1, showDebt: showDebt);

      if (kDebugMode) {
        //print('GetAllLeadBloc: First page loaded with ${firstPageRes.result?.length ?? 0} leads (showDebt=$showDebt)');
      }

      // ИСПРАВЛЕНО: Сохраняем в правильный кэш
      if (showDebt) {
        _cachedLeadsWithDebt = firstPageRes;
        _lastLoadTimeWithDebt = DateTime.now();
      } else {
        _cachedLeadsWithoutDebt = firstPageRes;
        _lastLoadTimeWithoutDebt = DateTime.now();
      }

      emit(GetAllLeadSuccess(dataLead: firstPageRes));
    } catch (e) {
      if (kDebugMode) {
        //print('GetAllLeadBloc: Error loading leads: $e');
      }
      emit(GetAllLeadError(message: e.toString()));
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

  // ИСПРАВЛЕНО: Метод теперь принимает параметр showDebt
  LeadsDataResponse? getCachedLeads(bool showDebt) {
    if (!_isCacheValid(showDebt)) return null;
    return showDebt ? _cachedLeadsWithDebt : _cachedLeadsWithoutDebt;
  }
}
