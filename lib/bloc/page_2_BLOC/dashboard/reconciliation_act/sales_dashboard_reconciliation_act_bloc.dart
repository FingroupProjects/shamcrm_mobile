import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/act_of_reconciliation_model.dart';

part 'sales_dashboard_reconciliation_act_event.dart';
part 'sales_dashboard_reconciliation_act_state.dart';

class SalesDashboardReconciliationActBloc extends Bloc<
    SalesDashboardReconciliationActEvent,
    SalesDashboardReconciliationActState> {
  final ApiService _apiService;
  final Future<ActOfReconciliationResponse> Function({
    int? page,
    int? perPage,
    String? search,
    Map<String, dynamic>? filters,
  })? _fetchReconciliationAct;
  Map<String, dynamic>? _currentFilter;
  String? _currentSearch;

  SalesDashboardReconciliationActBloc({
    ApiService? apiService,
    Future<ActOfReconciliationResponse> Function({
      int? page,
      int? perPage,
      String? search,
      Map<String, dynamic>? filters,
    })? fetchReconciliationAct,
  })  : _apiService = apiService ?? ApiService(),
        _fetchReconciliationAct = fetchReconciliationAct,
        super(SalesDashboardReconciliationActInitial()) {
    on<LoadReconciliationActReport>((event, emit) async {
      try {
        final filter = event.filter ?? _currentFilter;
        final search = event.search ?? _currentSearch;

        if (event.page == 1) {
          _currentFilter = filter;
          _currentSearch = search;
        }

        debugPrint("Event Filter: $filter, page: ${event.page}");
        if (filter == null ||
            (filter['lead_id'] == null && filter['supplier_id'] == null)) {
          emit(SalesDashboardReconciliationActLoaded(
            data: ActOfReconciliationResponse(result: const []),
            currentPage: 1,
            totalPages: 1,
            hasReachedMax: true,
          ));
          return;
        }

        if (event.page == 1) {
          emit(SalesDashboardReconciliationActLoading());
        }

        final fetcher = _fetchReconciliationAct;
        final response = await (fetcher != null
            ? fetcher(
                page: event.page,
                perPage: event.perPage,
                search: search,
                filters: filter,
              )
            : _apiService.getReconciliationAct(
                page: event.page,
                perPage: event.perPage,
                search: search,
                filters: filter,
              ));

        final newItems = response.result ?? [];
        final pagination = response.pagination;
        final currentPage = pagination?.currentPage ?? event.page;
        final totalPages = pagination?.totalPages ??
            (newItems.length < event.perPage ? currentPage : currentPage + 1);
        final hasReachedMax = pagination != null
            ? currentPage >= totalPages
            : newItems.length < event.perPage;

        if (event.page > 1 && state is SalesDashboardReconciliationActLoaded) {
          final currentState = state as SalesDashboardReconciliationActLoaded;
          final currentItems = currentState.data.result ?? [];

          final mergedResponse = ActOfReconciliationResponse(
            errors: response.errors,
            result: [...currentItems, ...newItems],
            pagination: response.pagination,
          );

          emit(SalesDashboardReconciliationActLoaded(
            data: mergedResponse,
            currentPage: currentPage,
            totalPages: totalPages,
            hasReachedMax: hasReachedMax,
          ));
          return;
        }

        emit(SalesDashboardReconciliationActLoaded(
          data: response,
          currentPage: currentPage,
          totalPages: totalPages,
          hasReachedMax: hasReachedMax,
        ));
      } catch (e) {
        if (event.page > 1 && state is SalesDashboardReconciliationActLoaded) {
          final current = state as SalesDashboardReconciliationActLoaded;
          emit(SalesDashboardReconciliationActLoaded(
            data: current.data,
            currentPage: current.currentPage,
            totalPages: current.totalPages,
            hasReachedMax: current.hasReachedMax,
          ));
        } else {
          emit(SalesDashboardReconciliationActError(
            message: friendlyError(e).replaceAll('Exception: ', ''),
          ));
        }
      }
    });
  }
}
