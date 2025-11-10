import 'dart:io';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/good_dashboard_warehouse/good_dashboard_warehouse_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/good_dashboard_warehouse/good_dashboard_warehouse_state.dart';
import 'package:crm_task_manager/models/page_2/good_dashboard_warehouse_model.dart';
import 'package:flutter/foundation.dart';

class GoodDashboardWarehouseBloc extends Bloc<GoodDashboardWarehouseEvent, GoodDashboardWarehouseState> {
  final ApiService apiService;

  // Cache management
  List<GoodDashboardWarehouse>? _cachedGoods;
  DateTime? _lastLoadTime;
  static const Duration _cacheExpiration = Duration(minutes: 5);

  // Background loading flag
  bool _isBackgroundLoading = false;

  GoodDashboardWarehouseBloc(this.apiService) : super(GoodDashboardWarehouseInitial()) {
    on<FetchGoodDashboardWarehouse>(_fetchGoodDashboardWarehouse);
    on<RefreshGoodDashboardWarehouse>(_refreshGoodDashboardWarehouse);
    on<UpdateGoodsInBackground>(_updateGoodsInBackground);
  }

  bool _isCacheValid() {
    if (_cachedGoods == null || _lastLoadTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastLoadTime!) < _cacheExpiration;
  }

  Future<void> _fetchGoodDashboardWarehouse(
      FetchGoodDashboardWarehouse event,
      Emitter<GoodDashboardWarehouseState> emit,
      ) async {
    // Use cache if valid
    if (_isCacheValid()) {
      if (kDebugMode) {
        print('GoodDashboardWarehouseBloc: Using cached data');
      }
      emit(GoodDashboardWarehouseLoaded(_cachedGoods!));
      return;
    }

    await _loadGoodsProgressive(emit);
  }

  Future<void> _refreshGoodDashboardWarehouse(
      RefreshGoodDashboardWarehouse event,
      Emitter<GoodDashboardWarehouseState> emit,
      ) async {
    // Clear cache
    _cachedGoods = null;
    _lastLoadTime = null;
    await _loadGoodsProgressive(emit);
  }

  Future<void> _loadGoodsProgressive(Emitter<GoodDashboardWarehouseState> emit) async {
    if (!await _checkInternetConnection()) {
      emit(GoodDashboardWarehouseError('Нет подключения к интернету'));
      return;
    }

    try {
      emit(GoodDashboardWarehouseLoading());

      if (kDebugMode) {
        print('GoodDashboardWarehouseBloc: Loading first page...');
      }

      // Load first page
      final firstPageResponse = await apiService.getGoodDashboardWarehousePage(1);

      if (kDebugMode) {
        print('GoodDashboardWarehouseBloc: First page loaded with ${firstPageResponse.data.length} items');
        if (firstPageResponse.pagination != null) {
          print('GoodDashboardWarehouseBloc: Current page: ${firstPageResponse.pagination!.currentPage}, Total pages: ${firstPageResponse.pagination!.totalPages}');
        }
      }

      // Cache first page
      _cachedGoods = firstPageResponse.data;
      _lastLoadTime = DateTime.now();

      emit(GoodDashboardWarehouseLoaded(_cachedGoods!));

      // Check if there are more pages
      final hasMorePages = firstPageResponse.pagination != null &&
          firstPageResponse.pagination!.currentPage != null &&
          firstPageResponse.pagination!.totalPages != null &&
          firstPageResponse.pagination!.currentPage! < firstPageResponse.pagination!.totalPages!;

      if (kDebugMode) {
        print('GoodDashboardWarehouseBloc: hasMorePages=$hasMorePages, isBackgroundLoading=$_isBackgroundLoading');
      }

      if (hasMorePages && !_isBackgroundLoading) {
        if (kDebugMode) {
          print('GoodDashboardWarehouseBloc: Starting background loading of ${firstPageResponse.pagination!.totalPages! - 1} remaining pages...');
        }
        _loadRemainingPagesInBackground(firstPageResponse.pagination!.totalPages!);
      } else {
        if (kDebugMode) {
          print('GoodDashboardWarehouseBloc: No additional pages to load');
        }
      }

    } catch (e) {
      if (kDebugMode) {
        print('GoodDashboardWarehouseBloc: Error loading goods: $e');
      }
      emit(GoodDashboardWarehouseError('Не удалось загрузить список Товаров!'));
    }
  }

  void _loadRemainingPagesInBackground(int totalPages) {
    _isBackgroundLoading = true;

    if (kDebugMode) {
      print('GoodDashboardWarehouseBloc: _loadRemainingPagesInBackground - Total pages to load: $totalPages');
    }

    _fetchRemainingPages(totalPages).then((_) {
      if (kDebugMode) {
        print('GoodDashboardWarehouseBloc: Background loading completed. Total goods: ${_cachedGoods?.length ?? 0}');
      }
      _isBackgroundLoading = false;
    }).catchError((error) {
      if (kDebugMode) {
        print('GoodDashboardWarehouseBloc: Error in background loading: $error');
      }
      _isBackgroundLoading = false;
    });
  }

  Future<void> _fetchRemainingPages(int totalPages) async {
    try {
      List<GoodDashboardWarehouse> allGoods = List.from(_cachedGoods ?? []);
      int currentPage = 2;

      if (kDebugMode) {
        print('GoodDashboardWarehouseBloc: _fetchRemainingPages - Starting from page $currentPage to $totalPages');
      }

      while (currentPage <= totalPages) {
        try {
          if (kDebugMode) {
            print('GoodDashboardWarehouseBloc: Loading page $currentPage/$totalPages in background...');
          }

          final pageResponse = await apiService.getGoodDashboardWarehousePage(currentPage);

          if (kDebugMode) {
            print('GoodDashboardWarehouseBloc: Page $currentPage response - ${pageResponse.data.length} items');
          }

          if (pageResponse.data.isNotEmpty) {
            allGoods.addAll(pageResponse.data);

            // Update cache
            _cachedGoods = allGoods;

            // Update UI
            add(UpdateGoodsInBackground(allGoods));

            if (kDebugMode) {
              print('GoodDashboardWarehouseBloc: Background loaded page $currentPage, total goods now: ${allGoods.length}');
            }
          } else {
            if (kDebugMode) {
              print('GoodDashboardWarehouseBloc: Page $currentPage returned empty data, stopping');
            }
            break;
          }

          currentPage++;

          // Small delay between requests to avoid overwhelming the server
          await Future.delayed(const Duration(milliseconds: 100));

        } catch (e) {
          if (kDebugMode) {
            print('GoodDashboardWarehouseBloc: Error loading page $currentPage: $e');
          }
          // Continue to next page instead of breaking completely
          currentPage++;
          if (currentPage > totalPages) break;
        }
      }

      _lastLoadTime = DateTime.now();

      if (kDebugMode) {
        print('GoodDashboardWarehouseBloc: _fetchRemainingPages completed. Final total: ${allGoods.length} goods');
      }

    } catch (e) {
      if (kDebugMode) {
        print('GoodDashboardWarehouseBloc: Error in _fetchRemainingPages: $e');
      }
    }
  }

  Future<void> _updateGoodsInBackground(
      UpdateGoodsInBackground event,
      Emitter<GoodDashboardWarehouseState> emit,
      ) async {
    // Update state without showing loading
    emit(GoodDashboardWarehouseLoaded(event.goods));
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  List<GoodDashboardWarehouse>? getCachedGoods() {
    if (!_isCacheValid()) return null;
    return _cachedGoods;
  }
}