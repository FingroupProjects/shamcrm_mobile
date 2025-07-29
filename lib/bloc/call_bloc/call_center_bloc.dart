import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_event.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_state.dart';
import 'package:crm_task_manager/models/page_2/call_center_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CallCenterBloc extends Bloc<CallCenterEvent, CallCenterState> {
  final ApiService apiService;
  final int perPage = 20;
  bool allCallsFetched = false;
  bool isLoadingMore = false;
  CallType? _currentCallType;
  String? _currentSearchQuery;
  List<CallLogEntry> _lastCalls = [];
  int _lastPage = 1;
  int _totalPages = 1;

  CallCenterBloc(this.apiService) : super(CallCenterInitial()) {
    print("🚀 Initializing CallCenterBloc");
    on<LoadCalls>(_onLoadCalls);
    on<LoadMoreCalls>(_onLoadMoreCalls);
    on<LoadCallById>(_onLoadCallById);
    print("✅ Event handlers registered:");
    print("  - LoadCalls: registered");
    print("  - LoadMoreCalls: registered");
    print("  - LoadCallById: registered");
  }

  Future<bool> _checkInternetConnection() async {
    print("Checking internet connection");
    return true; // Замените на реальную логику
  }

  Future<void> _onLoadCalls(LoadCalls event, Emitter<CallCenterState> emit) async {
    print("Handling LoadCalls event: callType=${event.callType}, page=${event.page}, searchQuery=${event.searchQuery}");
    emit(CallCenterLoading());
    _currentCallType = event.callType;
    _currentSearchQuery = event.searchQuery;
    isLoadingMore = false;
    allCallsFetched = false;

    if (!await _checkInternetConnection()) {
      print("No internet connection");
      emit(CallCenterError('Нет подключения к интернету'));
      return;
    }

    try {
      final response = await _fetchCalls(event.callType, event.page, event.searchQuery);
      final calls = response['calls'] as List<CallLogEntry>;
      final pagination = response['pagination'] as Map<String, dynamic>;
      final currentPage = pagination['current_page'] as int;
      final totalPages = pagination['total_pages'] as int;

      if (calls.isEmpty) {
        print("No calls returned from API. callType=${event.callType}, page=$currentPage, searchQuery=${event.searchQuery}");
      } else {
        print("Loaded calls: ${calls.length}, currentPage: $currentPage, totalPages: $totalPages");
      }

      _lastCalls = calls;
      _lastPage = currentPage;
      _totalPages = totalPages;

      allCallsFetched = calls.isEmpty || currentPage >= totalPages;

      emit(CallCenterLoaded(
        calls: calls,
        currentPage: currentPage,
        totalPages: totalPages,
      ));
    } catch (e) {
      print("Error loading calls: $e");
      emit(CallCenterError('Не удалось загрузить звонки: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMoreCalls(LoadMoreCalls event, Emitter<CallCenterState> emit) async {
    if (allCallsFetched || isLoadingMore) {
      print("All calls fetched or already loading, skipping LoadMoreCalls");
      return;
    }

    isLoadingMore = true;
    final nextPage = event.currentPage + 1;
    print("🚀 Handling LoadMoreCalls event: callType=${event.callType}, nextPage=$nextPage");

    if (!await _checkInternetConnection()) {
      print("No internet connection for LoadMoreCalls");
      isLoadingMore = false;
      emit(CallCenterError('Нет подключения к интернету'));
      return;
    }

    try {
      final response = await _fetchCalls(_currentCallType ?? event.callType, nextPage, _currentSearchQuery);
      final newCalls = response['calls'] as List<CallLogEntry>;
      final pagination = response['pagination'] as Map<String, dynamic>;
      final currentPage = pagination['current_page'] as int;
      final totalPages = pagination['total_pages'] as int;

      print("Loaded more calls: ${newCalls.length}, currentPage: $currentPage, totalPages: $totalPages");

      allCallsFetched = newCalls.isEmpty || currentPage >= totalPages;

      if (state is CallCenterLoaded && !isClosed) {
        final currentState = state as CallCenterLoaded;
        final uniqueNewCalls = newCalls.where((newCall) => !currentState.calls.any((call) => call.id == newCall.id)).toList();
        emit(currentState.merge(uniqueNewCalls, newPage: currentPage));
      } else {
        print("Current state is not CallCenterLoaded or BLoC is closed, skipping merge");
      }
    } catch (e) {
      print("Error loading more calls: $e");
      emit(CallCenterError('Не удалось загрузить дополнительные звонки: ${e.toString()}'));
    } finally {
      isLoadingMore = false;
    }
  }

  Future<void> _onLoadCallById(LoadCallById event, Emitter<CallCenterState> emit) async {
    print("Handling LoadCallById event: callId=${event.callId}");
    emit(CallCenterLoading());

    if (!await _checkInternetConnection()) {
      print("No internet connection");
      emit(CallCenterError('Нет подключения к интернету'));
      return;
    }

    try {
      final call = await apiService.getCallById(callId: event.callId);
      print("Loaded call by ID: ${call.id}");
      emit(CallByIdLoaded(call: call));
    } catch (e) {
      print("Error loading call by ID: $e");
      if (_lastCalls.isNotEmpty) {
        emit(CallCenterLoaded(
          calls: _lastCalls,
          currentPage: _lastPage,
          totalPages: _totalPages,
        ));
      } else {
        emit(CallCenterError('Не удалось загрузить данные звонка: ${e.toString()}'));
      }
    }
  }

  Future<Map<String, dynamic>> _fetchCalls(CallType? callType, int page, String? searchQuery) async {
  print("Fetching calls: callType=$callType, page=$page, searchQuery=$searchQuery");
  Map<String, dynamic> response;
  switch (callType) {
    case CallType.incoming:
      response = await apiService.getIncomingCalls(page: page, perPage: perPage, searchQuery: searchQuery);
      break;
    case CallType.outgoing:
      response = await apiService.getOutgoingCalls(page: page, perPage: perPage, searchQuery: searchQuery);
      break;
    case CallType.missed:
      response = await apiService.getMissedCalls(page: page, perPage: perPage, searchQuery: searchQuery);
      break;
    default:
      response = await apiService.getAllCalls(page: page, perPage: perPage, searchQuery: searchQuery);
      break;
  }
  print("API response: calls=${(response['calls'] as List).length}, pagination=${response['pagination']}");
  return response;
}
}