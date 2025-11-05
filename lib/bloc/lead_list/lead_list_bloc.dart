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

  // Флаги для отслеживания фоновой загрузки
  bool _isBackgroundLoadingWithoutDebt = false;
  bool _isBackgroundLoadingWithDebt = false;

  GetAllLeadBloc() : super(GetAllLeadInitial()) {
    on<GetAllLeadEv>(_getLeads);
    on<RefreshAllLeadEv>(_refreshLeads);
    on<UpdateLeadsInBackground>(_updateLeadsInBackground);
  }

  // ИСПРАВЛЕНО: Проверка валидности кэша с учетом showDebt
  bool _isCacheValid(bool showDebt) {
    final cachedData = showDebt ? _cachedLeadsWithDebt : _cachedLeadsWithoutDebt;
    final lastLoadTime = showDebt ? _lastLoadTimeWithDebt : _lastLoadTimeWithoutDebt;

    if (cachedData == null || lastLoadTime == null) {
      return false;
    }
    return DateTime.now().difference(lastLoadTime) < _cacheExpiration;
  }

  Future<void> _getLeads(GetAllLeadEv event, Emitter<GetAllLeadState> emit) async {
    // ИСПРАВЛЕНО: Используем правильный кэш в зависимости от showDebt
    if (_isCacheValid(event.showDebt)) {
      final cachedData = event.showDebt ? _cachedLeadsWithDebt : _cachedLeadsWithoutDebt;
      if (kDebugMode) {
        //print('GetAllLeadBloc: Using cached leads data (showDebt=${event.showDebt})');
      }
      emit(GetAllLeadSuccess(dataLead: cachedData!));
      return;
    }

    await _loadLeadsProgressive(emit, event.showDebt);
  }

  Future<void> _refreshLeads(RefreshAllLeadEv event, Emitter<GetAllLeadState> emit) async {
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

      // Проверяем, есть ли еще страницы
      final hasMorePages = firstPageRes.pagination != null &&
          firstPageRes.pagination!.currentPage != null &&
          firstPageRes.pagination!.totalPages != null &&
          firstPageRes.pagination!.currentPage! < firstPageRes.pagination!.totalPages!;

      // ИСПРАВЛЕНО: Проверяем правильный флаг в зависимости от showDebt
      final isCurrentlyLoading = showDebt ? _isBackgroundLoadingWithDebt : _isBackgroundLoadingWithoutDebt;

      if (hasMorePages && !isCurrentlyLoading) {
        if (kDebugMode) {
          //print('GetAllLeadBloc: Starting background loading of remaining pages (showDebt=$showDebt)...');
        }
        // Загружаем остальные страницы в фоне
        _loadRemainingPagesInBackground(showDebt);
      }

    } catch (e) {
      if (kDebugMode) {
        //print('GetAllLeadBloc: Error loading leads: $e');
      }
      emit(GetAllLeadError(message: e.toString()));
    }
  }

  void _loadRemainingPagesInBackground(bool showDebt) {
    // ИСПРАВЛЕНО: Устанавливаем правильный флаг
    if (showDebt) {
      _isBackgroundLoadingWithDebt = true;
    } else {
      _isBackgroundLoadingWithoutDebt = true;
    }

    // Запускаем асинхронную загрузку без await
    _fetchRemainingPages(showDebt).then((_) {
      if (kDebugMode) {
        final cachedData = showDebt ? _cachedLeadsWithDebt : _cachedLeadsWithoutDebt;
        //print('GetAllLeadBloc: Background loading completed (showDebt=$showDebt). Total leads: ${cachedData?.result?.length ?? 0}');
      }
      if (showDebt) {
        _isBackgroundLoadingWithDebt = false;
      } else {
        _isBackgroundLoadingWithoutDebt = false;
      }
    }).catchError((error) {
      if (kDebugMode) {
        //print('GetAllLeadBloc: Error in background loading (showDebt=$showDebt): $error');
      }
      if (showDebt) {
        _isBackgroundLoadingWithDebt = false;
      } else {
        _isBackgroundLoadingWithoutDebt = false;
      }
    });
  }

  Future<void> _fetchRemainingPages(bool showDebt) async {
    try {
      // ИСПРАВЛЕНО: Берем данные из правильного кэша
      final cachedData = showDebt ? _cachedLeadsWithDebt : _cachedLeadsWithoutDebt;
      List<LeadData> allLeads = List.from(cachedData?.result ?? []);
      int currentPage = 2;
      bool hasMorePages = true;

      while (hasMorePages) {
        try {
          if (kDebugMode) {
            //print('GetAllLeadBloc: Loading page $currentPage in background (showDebt=$showDebt)...');
          }

          final pageResponse = await apiService.getLeadPage(currentPage, showDebt: showDebt);

          if (pageResponse.result != null && pageResponse.result!.isNotEmpty) {
            allLeads.addAll(pageResponse.result!);

            // ИСПРАВЛЕНО: Обновляем правильный кэш
            final updatedCache = LeadsDataResponse(
              result: allLeads,
              errors: null,
              pagination: pageResponse.pagination,
            );

            if (showDebt) {
              _cachedLeadsWithDebt = updatedCache;
            } else {
              _cachedLeadsWithoutDebt = updatedCache;
            }

            // Отправляем событие для обновления UI (необязательно)
            add(UpdateLeadsInBackground(updatedCache, showDebt));

            if (pageResponse.result!.length < 20 ||
                (pageResponse.pagination?.currentPage != null &&
                    pageResponse.pagination?.totalPages != null &&
                    pageResponse.pagination!.currentPage! >= pageResponse.pagination!.totalPages!)) {
              hasMorePages = false;
            } else {
              currentPage++;
            }

            if (kDebugMode) {
              //print('GetAllLeadBloc: Background loaded page $currentPage, total: ${allLeads.length} (showDebt=$showDebt)');
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
            //print('GetAllLeadBloc: Error loading page $currentPage in background: $e');
          }
          hasMorePages = false;
        }
      }

      // ИСПРАВЛЕНО: Обновляем правильное время загрузки
      if (showDebt) {
        _lastLoadTimeWithDebt = DateTime.now();
      } else {
        _lastLoadTimeWithoutDebt = DateTime.now();
      }

    } catch (e) {
      if (kDebugMode) {
        //print('GetAllLeadBloc: Error in _fetchRemainingPages: $e');
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

  // ИСПРАВЛЕНО: Метод теперь принимает параметр showDebt
  LeadsDataResponse? getCachedLeads(bool showDebt) {
    if (!_isCacheValid(showDebt)) return null;
    return showDebt ? _cachedLeadsWithDebt : _cachedLeadsWithoutDebt;
  }
}