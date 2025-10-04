import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/dashboard_goods_report.dart';

part 'sales_dashboard_goods_event.dart';
part 'sales_dashboard_goods_state.dart';

class SalesDashboardGoodsBloc extends Bloc<SalesDashboardGoodsEvent, SalesDashboardGoodsState> {
  final apiService = ApiService();

  SalesDashboardGoodsBloc() : super(SalesDashboardProductsInitial()) {
    on<LoadGoodsReport>((event, emit) async {
      try {
        // Initial load (page 1)
        if (event.page == 1) {
          emit(SalesDashboardGoodsLoading());
          final response = await apiService.getSalesDashboardGoodsReport(
            page: event.page,
            perPage: event.perPage,
            filters: event.filter,
            search: event.search,
          );
          emit(SalesDashboardGoodsLoaded(
            goods: response.data,
            pagination: response.pagination,
            hasReachedMax: response.pagination.current_page >= response.pagination.total_pages,
          ));
        } else {
          // Pagination load (page 2+)
          final currentState = state;
          if (currentState is SalesDashboardGoodsLoaded) {
            final response = await apiService.getSalesDashboardGoodsReport(
              page: event.page,
              perPage: event.perPage,
              filters: event.filter,
              search: event.search,
            );

            // Append new data to existing data
            final updatedGoods = List<DashboardGoods>.from(currentState.goods)
              ..addAll(response.data);

            emit(SalesDashboardGoodsLoaded(
              goods: updatedGoods,
              pagination: response.pagination,
              hasReachedMax: response.pagination.current_page >= response.pagination.total_pages,
            ));
          }
        }
      } catch (e) {
        final currentState = state;

        // If it's a pagination error (not initial load), emit pagination error
        if (event.page > 1 && currentState is SalesDashboardGoodsLoaded) {
          emit(SalesDashboardGoodsPaginationError(
            message: e.toString().replaceAll('Exception: ', ''),
            goods: currentState.goods,
            pagination: currentState.pagination,
            hasReachedMax: currentState.hasReachedMax,
          ));
          // Return to previous loaded state
          emit(currentState);
        } else {
          // Initial load error
          emit(SalesDashboardGoodsError(
            message: e.toString().replaceAll('Exception: ', ''),
          ));
        }
      }
    });
  }
}