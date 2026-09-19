import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/dashboard/dashboard_goods_report.dart';
import 'package:crm_task_manager/models/page_2/dashboard/goods_expiration_report.dart';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:equatable/equatable.dart';

part 'sales_dashboard_goods_expiration_event.dart';
part 'sales_dashboard_goods_expiration_state.dart';

/// Отчёт по сроку годности. Только для adminbiovecotj.
class SalesDashboardGoodsExpirationBloc extends Bloc<
    SalesDashboardGoodsExpirationEvent, SalesDashboardGoodsExpirationState> {
  final apiService = ApiService();

  SalesDashboardGoodsExpirationBloc()
      : super(SalesDashboardGoodsExpirationInitial()) {
    on<LoadGoodsExpirationReport>(_onLoad);
  }

  Future<void> _onLoad(
    LoadGoodsExpirationReport event,
    Emitter<SalesDashboardGoodsExpirationState> emit,
  ) async {
    try {
      if (event.page == 1) {
        emit(SalesDashboardGoodsExpirationLoading());
        final response = await apiService.getGoodsReportByExpirationDate(
          page: event.page,
          perPage: event.perPage,
          filters: event.filter,
          search: event.search,
        );
        emit(SalesDashboardGoodsExpirationLoaded(
          items: response.data,
          pagination: response.pagination,
          hasReachedMax: response.pagination.current_page >=
              response.pagination.total_pages,
          filter: event.filter,
          search: event.search,
        ));
        return;
      }

      final currentState = state;
      if (currentState is! SalesDashboardGoodsExpirationLoaded) return;

      final filter = event.filter ?? currentState.filter;
      final search = event.search ?? currentState.search;
      final response = await apiService.getGoodsReportByExpirationDate(
        page: event.page,
        perPage: event.perPage,
        filters: filter,
        search: search,
      );
      emit(SalesDashboardGoodsExpirationLoaded(
        items: [...currentState.items, ...response.data],
        pagination: response.pagination,
        hasReachedMax:
            response.pagination.current_page >= response.pagination.total_pages,
        filter: filter,
        search: search,
      ));
    } catch (e) {
      final currentState = state;
      if (event.page > 1 && currentState is SalesDashboardGoodsExpirationLoaded) {
        emit(SalesDashboardGoodsExpirationPaginationError(
          message: friendlyError(e).replaceAll('Exception: ', ''),
        ));
        emit(currentState);
        return;
      }
      emit(SalesDashboardGoodsExpirationError(
        message: friendlyError(e).replaceAll('Exception: ', ''),
      ));
    }
  }
}
