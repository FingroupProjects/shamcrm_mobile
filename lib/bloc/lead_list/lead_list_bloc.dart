import 'dart:io';
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_state.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:flutter/foundation.dart';

class GetAllLeadBloc extends Bloc<GetAllLeadEvent, GetAllLeadState> {
  LeadsDataResponse? _cachedLeads;
  DateTime? _lastLoadTime;
  static const Duration _cacheExpiration = Duration(minutes: 5);
  final apiService = ApiService();

  // Флаг для отслеживания фоновой загрузки
  bool _isBackgroundLoading = false;

  GetAllLeadBloc() : super(GetAllLeadInitial()) {
    on<GetAllLeadEv>(_getLeads);
    on<RefreshAllLeadEv>(_refreshLeads);
    on<UpdateLeadsInBackground>(_updateLeadsInBackground);
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

    await _loadLeadsProgressive(emit, event.showDebt);
  }

  Future<void> _refreshLeads(RefreshAllLeadEv event, Emitter<GetAllLeadState> emit) async {
    _cachedLeads = null;
    _lastLoadTime = null;
    await _loadLeadsProgressive(emit, false);
  }

  Future<void> _loadLeadsProgressive(Emitter<GetAllLeadState> emit, bool showDebt) async {
    if (!await _checkInternetConnection()) {
      emit(GetAllLeadError(
          message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'
      ));
      return;
    }

    try {
      emit(GetAllLeadLoading());

      if (kDebugMode) {
        print('GetAllLeadBloc: Loading first page of leads...');
      }

      // Загружаем только первую страницу
      var firstPageRes = await apiService.getLeadPage(1, showDebt: showDebt);

      if (kDebugMode) {
        print('GetAllLeadBloc: First page loaded with ${firstPageRes.result?.length ?? 0} leads');
      }

      // Сразу показываем первую страницу пользователю
      _cachedLeads = firstPageRes;
      _lastLoadTime = DateTime.now();
      emit(GetAllLeadSuccess(dataLead: firstPageRes));

      // Проверяем, есть ли еще страницы
      final hasMorePages = firstPageRes.pagination != null &&
          firstPageRes.pagination!.currentPage != null &&
          firstPageRes.pagination!.totalPages != null &&
          firstPageRes.pagination!.currentPage! < firstPageRes.pagination!.totalPages!;

      if (hasMorePages && !_isBackgroundLoading) {
        if (kDebugMode) {
          print('GetAllLeadBloc: Starting background loading of remaining pages...');
        }
        // Загружаем остальные страницы в фоне
        _loadRemainingPagesInBackground(showDebt);
      }

    } catch (e) {
      if (kDebugMode) {
        print('GetAllLeadBloc: Error loading leads: $e');
      }
      emit(GetAllLeadError(message: e.toString()));
    }
  }

  void _loadRemainingPagesInBackground(bool showDebt) {
    _isBackgroundLoading = true;

    // Запускаем асинхронную загрузку без await
    _fetchRemainingPages(showDebt).then((_) {
      if (kDebugMode) {
        print('GetAllLeadBloc: Background loading completed. Total leads: ${_cachedLeads?.result?.length ?? 0}');
      }
      _isBackgroundLoading = false;
    }).catchError((error) {
      if (kDebugMode) {
        print('GetAllLeadBloc: Error in background loading: $error');
      }
      _isBackgroundLoading = false;
    });
  }

  Future<void> _fetchRemainingPages(bool showDebt) async {
    try {
      List<LeadData> allLeads = List.from(_cachedLeads?.result ?? []);
      int currentPage = 2;
      bool hasMorePages = true;

      while (hasMorePages) {
        try {
          if (kDebugMode) {
            print('GetAllLeadBloc: Loading page $currentPage in background...');
          }

          final pageResponse = await apiService.getLeadPage(currentPage, showDebt: showDebt);

          if (pageResponse.result != null && pageResponse.result!.isNotEmpty) {
            allLeads.addAll(pageResponse.result!);

            // Обновляем кэш
            _cachedLeads = LeadsDataResponse(
              result: allLeads,
              errors: null,
              pagination: pageResponse.pagination,
            );

            // Отправляем событие для обновления UI (необязательно)
            add(UpdateLeadsInBackground(_cachedLeads!));

            if (pageResponse.result!.length < 20 ||
                (pageResponse.pagination?.currentPage != null &&
                    pageResponse.pagination?.totalPages != null &&
                    pageResponse.pagination!.currentPage! >= pageResponse.pagination!.totalPages!)) {
              hasMorePages = false;
            } else {
              currentPage++;
            }

            if (kDebugMode) {
              print('GetAllLeadBloc: Background loaded page $currentPage, total: ${allLeads.length}');
            }
          } else {
            hasMorePages = false;
          }

          // Небольшая задержка между запросами
          if (hasMorePages) {
            await Future.delayed(const Duration(milliseconds: 100));
          }

        } catch (e) {
          if (kDebugMode) {
            print('GetAllLeadBloc: Error loading page $currentPage in background: $e');
          }
          hasMorePages = false;
        }
      }

      _lastLoadTime = DateTime.now();

    } catch (e) {
      if (kDebugMode) {
        print('GetAllLeadBloc: Error in _fetchRemainingPages: $e');
      }
    }
  }

  Future<void> _updateLeadsInBackground(UpdateLeadsInBackground event, Emitter<GetAllLeadState> emit) async {
    // Обновляем состояние без показа загрузки
    emit(GetAllLeadSuccess(dataLead: event.data));
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  LeadsDataResponse? getCachedLeads() {
    return _isCacheValid ? _cachedLeads : null;
  }
}