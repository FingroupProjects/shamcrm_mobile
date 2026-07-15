import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_event.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_state.dart';
import 'package:crm_task_manager/models/page_2/call_center_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

class CallCenterBloc extends Bloc<CallCenterEvent, CallCenterState> {
  final ApiService apiService;
  final int perPage = 20;
  bool allCallsFetched = false;
  bool isLoadingMore = false;
  CallType? _currentCallType;
  String? _currentSearchQuery;
  Map<String, dynamic>? _currentFilters;
  List<CallLogEntry> _lastCalls = [];
  int _lastPage = 1;
  int _totalPages = 1;

  CallCenterBloc(this.apiService) : super(CallCenterInitial()) {
    if (kDebugMode) {
      //print("🚀 Initializing CallCenterBloc");
    }
    on<LoadCalls>(_onLoadCalls);
    on<LoadMoreCalls>(_onLoadMoreCalls);
    on<LoadCallById>(_onLoadCallById);
    on<SubmitCallRatingAndReport>(_onSubmitCallRatingAndReport);
    on<FilterCalls>(_onFilterCalls);
    on<ResetFilters>(_onResetFilters); // Добавляем обработчик
    if (kDebugMode) {
      //print("✅ Event handlers registered:");
      //print("  - LoadCalls: registered");
      //print("  - LoadMoreCalls: registered");
      //print("  - LoadCallById: registered");
      //print("  - SubmitCallRatingAndReport: registered");
      //print("  - FilterCalls: registered");
      //print("  - ResetFilters: registered");
    }
  }

  Future<bool> _checkInternetConnection() async {
    if (kDebugMode) {
      //print("Checking internet connection");
    }
    return true;
  }

  Future<void> _onLoadCalls(LoadCalls event, Emitter<CallCenterState> emit) async {
    if (kDebugMode) {
      //print("Handling LoadCalls event: callType=${event.callType}, page=${event.page}, searchQuery=${event.searchQuery}, filters=$_currentFilters");
    }
    emit(CallCenterLoading());
    _currentCallType = event.callType;
    _currentSearchQuery = event.searchQuery;
    isLoadingMore = false;
    allCallsFetched = false;

    if (!await _checkInternetConnection()) {
      if (kDebugMode) {
        //print("No internet connection");
      }
      emit(CallCenterError('Нет подключения к интернету'));
      return;
    }

    try {
      final response = await _fetchCalls(event.callType, event.page, event.searchQuery, _currentFilters);
      final calls = response['calls'] as List<CallLogEntry>;
      final pagination = response['pagination'] as Map<String, dynamic>;
      final currentPage = pagination['current_page'] as int;
      final totalPages = pagination['total_pages'] as int;

      if (calls.isEmpty) {
        if (kDebugMode) {
          //print("No calls returned from API. callType=${event.callType}, page=$currentPage, searchQuery=${event.searchQuery}");
        }
      } else {
        if (kDebugMode) {
          //print("Loaded calls: ${calls.length}, currentPage: $currentPage, totalPages: $totalPages");
        }
      }

      _lastCalls = calls;
      _lastPage = currentPage;
      _totalPages = totalPages;

      allCallsFetched = calls.isEmpty || currentPage >= totalPages;

      emit(CallCenterLoaded(
        calls: calls,
        currentPage: currentPage,
        totalPages: totalPages,
        currentFilter: event.callType,
      ));
    } catch (e) {
      if (kDebugMode) {
        //print("Error loading calls: $e");
      }
      emit(CallCenterError('Не удалось загрузить звонки: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMoreCalls(LoadMoreCalls event, Emitter<CallCenterState> emit) async {
    if (allCallsFetched || isLoadingMore) {
      if (kDebugMode) {
        //print("All calls fetched or already loading, skipping LoadMoreCalls");
      }
      return;
    }

    isLoadingMore = true;
    final nextPage = event.currentPage + 1;
    if (kDebugMode) {
      //print("🚀 Handling LoadMoreCalls event: callType=${event.callType}, nextPage=$nextPage");
    }

    if (!await _checkInternetConnection()) {
      if (kDebugMode) {
        //print("No internet connection for LoadMoreCalls");
      }
      isLoadingMore = false;
      emit(CallCenterError('Нет подключения к интернету'));
      return;
    }

    try {
      final response = await _fetchCalls(_currentCallType ?? event.callType, nextPage, _currentSearchQuery, _currentFilters);
      final newCalls = response['calls'] as List<CallLogEntry>;
      final pagination = response['pagination'] as Map<String, dynamic>;
      final currentPage = pagination['current_page'] as int;
      final totalPages = pagination['total_pages'] as int;

      if (kDebugMode) {
        //print("Loaded more calls: ${newCalls.length}, currentPage: $currentPage, totalPages: $totalPages");
      }

      allCallsFetched = newCalls.isEmpty || currentPage >= totalPages;

      if (state is CallCenterLoaded && !isClosed) {
        final currentState = state as CallCenterLoaded;
        final uniqueNewCalls = newCalls.where((newCall) => !currentState.calls.any((call) => call.id == newCall.id)).toList();
        emit(currentState.merge(uniqueNewCalls, newPage: currentPage));
      } else {
        if (kDebugMode) {
          //print("Current state is not CallCenterLoaded or BLoC is closed, skipping merge");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        //print("Error loading more calls: $e");
      }
      emit(CallCenterError('Не удалось загрузить дополнительные звонки: ${e.toString()}'));
    } finally {
      isLoadingMore = false;
    }
  }

  Future<void> _onFilterCalls(FilterCalls event, Emitter<CallCenterState> emit) async {
    if (kDebugMode) {
      //print("Handling FilterCalls event: filters=${event.filters}");
    }
    emit(CallCenterLoading());
    _currentFilters = event.filters.isEmpty ? null : Map.from(event.filters);
    if (kDebugMode) {
      //print('CallCenterBloc: Применение фильтров: $_currentFilters, поиск: $_currentSearchQuery');
    }

    if (!await _checkInternetConnection()) {
      if (kDebugMode) {
        //print('CallCenterBloc: Нет подключения к интернету при применении фильтров');
      }
      emit(CallCenterError('Нет подключения к интернету'));
      return;
    }

    try {
      final response = await _fetchCalls(_currentCallType, 1, _currentSearchQuery, _currentFilters);
      final calls = response['calls'] as List<CallLogEntry>;
      final pagination = response['pagination'] as Map<String, dynamic>;
      final currentPage = pagination['current_page'] as int;
      final totalPages = pagination['total_pages'] as int;

      _lastCalls = calls;
      _lastPage = currentPage;
      _totalPages = totalPages;

      allCallsFetched = calls.isEmpty || currentPage >= totalPages;

      if (calls.isEmpty) {
        if (kDebugMode) {
          //print('CallCenterBloc: Звонки не найдены после применения фильтров');
        }
        emit(CallCenterEmpty());
      } else {
        if (kDebugMode) {
          //print('CallCenterBloc: Найдено ${calls.length} звонков после применения фильтров');
        }
        emit(CallCenterLoaded(
          calls: calls,
          currentPage: currentPage,
          totalPages: totalPages,
          currentFilter: _currentCallType,
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        //print('CallCenterBloc: Ошибка применения фильтров: $e');
      }
      emit(CallCenterError('Не удалось применить фильтры: ${e.toString()}'));
    }
  }

  Future<void> _onResetFilters(ResetFilters event, Emitter<CallCenterState> emit) async {
    if (kDebugMode) {
      //print("Handling ResetFilters event");
    }
    emit(CallCenterLoading());
    _currentCallType = null;
    _currentSearchQuery = null;
    _currentFilters = null;
    _lastCalls = [];
    _lastPage = 1;
    _totalPages = 1;
    allCallsFetched = false;

    try {
      final response = await _fetchCalls(null, 1, null, null);
      final calls = response['calls'] as List<CallLogEntry>;
      final pagination = response['pagination'] as Map<String, dynamic>;
      final currentPage = pagination['current_page'] as int;
      final totalPages = pagination['total_pages'] as int;

      _lastCalls = calls;
      _lastPage = currentPage;
      _totalPages = totalPages;

      allCallsFetched = calls.isEmpty || currentPage >= totalPages;

      if (calls.isEmpty) {
        if (kDebugMode) {
          //print('CallCenterBloc: Звонки не найдены после сброса фильтров');
        }
        emit(CallCenterEmpty());
      } else {
        if (kDebugMode) {
          //print('CallCenterBloc: Найдено ${calls.length} звонков после сброса фильтров');
        }
        emit(CallCenterLoaded(
          calls: calls,
          currentPage: currentPage,
          totalPages: totalPages,
          currentFilter: _currentCallType,
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        //print('CallCenterBloc: Ошибка сброса фильтров: $e');
      }
      emit(CallCenterError('Не удалось сбросить фильтры: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCallById(LoadCallById event, Emitter<CallCenterState> emit) async {
    if (kDebugMode) {
      //print("Handling LoadCallById event: callId=${event.callId}");
    }
    emit(CallCenterLoading());

    if (!await _checkInternetConnection()) {
      if (kDebugMode) {
        //print("No internet connection");
      }
      emit(CallCenterError('Нет подключения к интернету'));
      return;
    }

    try {
      final call = await apiService.getCallById(callId: event.callId);
      if (kDebugMode) {
        //print("Loaded call by ID: ${call.id}");
      }
      emit(CallByIdLoaded(call: call));
    } catch (e) {
      if (kDebugMode) {
        //print("Error loading call by ID: $e");
      }
      if (_lastCalls.isNotEmpty) {
        emit(CallCenterLoaded(
          calls: _lastCalls,
          currentPage: _lastPage,
          totalPages: _totalPages,
          currentFilter: _currentCallType,
        ));
      } else {
        emit(CallCenterError('Не удалось загрузить данные звонка: ${e.toString()}'));
      }
    }
  }

  Future<void> _onSubmitCallRatingAndReport(
      SubmitCallRatingAndReport event,
      Emitter<CallCenterState> emit,
      ) async {
    if (kDebugMode) {
      //print("Handling SubmitCallRatingAndReport event: callId=${event.callId}, rating=${event.rating}, report=${event.report}");
    }
    emit(CallCenterLoading());

    if (!await _checkInternetConnection()) {
      if (kDebugMode) {
        //print("No internet connection");
      }
      emit(CallCenterError('Нет подключения к интернету'));
      return;
    }

    try {
      await apiService.setCallRating(
        callId: event.callId,
        rating: event.rating,
        organizationId: event.organizationId,
      );
      if (kDebugMode) {
        //print("Rating set successfully for callId=${event.callId}");
      }

      await apiService.addCallReport(
        callId: event.callId,
        report: event.report,
        organizationId: event.organizationId,
      );
      if (kDebugMode) {
        //print("Report added successfully for callId=${event.callId}");
      }

      final call = await apiService.getCallById(callId: event.callId);
      if (kDebugMode) {
        //print("Reloaded call by ID: ${call.id}");
      }
      emit(CallByIdLoaded(call: call));
    } catch (e) {
      if (kDebugMode) {
        //print("Error submitting rating and report: $e");
      }
      emit(CallCenterError('Не удалось сохранить оценку и замечание: ${e.toString()}'));
    }
  }

  Future<Map<String, dynamic>> _fetchCalls(CallType? callType, int page, String? searchQuery, Map<String, dynamic>? filters) async {
    if (kDebugMode) {
      //print("Fetching calls: callType=$callType, page=$page, searchQuery=$searchQuery, filters=$filters");
    }
    Map<String, dynamic> response;
    switch (callType) {
      case CallType.incoming:
        response = await apiService.getIncomingCalls(page: page, perPage: perPage, searchQuery: searchQuery, filters: filters);
        break;
      case CallType.outgoing:
      case CallType.outgoingMissed:
        response = await apiService.getOutgoingCalls(page: page, perPage: perPage, searchQuery: searchQuery, filters: filters);
        break;
      case CallType.missed:
        response = await apiService.getMissedCalls(page: page, perPage: perPage, searchQuery: searchQuery, filters: filters);
        break;
      default:
        response = await apiService.getAllCalls(page: page, perPage: perPage, searchQuery: searchQuery, filters: filters);
        break;
    }
    if (kDebugMode) {
      //print("API response: calls=${(response['calls'] as List).length}, pagination=${response['pagination']}");
    }
    return response;
  }
}
