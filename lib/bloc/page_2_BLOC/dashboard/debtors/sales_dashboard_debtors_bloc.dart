import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:equatable/equatable.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/debtors_model.dart';

part 'sales_dashboard_debtors_event.dart';
part 'sales_dashboard_debtors_state.dart';

class SalesDashboardDebtorsBloc
    extends Bloc<SalesDashboardDebtorsEvent, SalesDashboardDebtorsState> {
  final apiService = ApiService();
  Map<String, dynamic>? _currentFilter;
  String? _currentSearch;

  SalesDashboardDebtorsBloc() : super(SalesDashboardDebtorsInitial()) {
    on<LoadDebtorsReport>((event, emit) async {
      try {
        final filter = event.filter ?? _currentFilter;
        final search = event.search ?? _currentSearch;

        if (event.page == 1) {
          emit(SalesDashboardDebtorsLoading());
          _currentFilter = filter;
          _currentSearch = search;
        }

        final response = await apiService.getDebtorsList(
          page: event.page,
          perPage: event.perPage,
          filters: filter,
          search: search,
        );

        final currentPage = response.result?.pagination?.currentPage ?? 1;
        final totalPages = response.result?.pagination?.totalPages ?? 1;
        final hasReachedMax = currentPage >= totalPages;

        if (event.page > 1 && state is SalesDashboardDebtorsLoaded) {
          final currentState = state as SalesDashboardDebtorsLoaded;
          final currentDebtors = currentState.result.result?.debtors ?? [];
          final newDebtors = response.result?.debtors ?? [];

          final mergedResponse = DebtorsResponse(
            errors: response.errors,
            result: response.result == null
                ? currentState.result.result
                : DebtorsResult(
                    totalDebt: response.result!.totalDebt,
                    debtors: [...currentDebtors, ...newDebtors],
                    period: response.result!.period,
                    percentageChange: response.result!.percentageChange,
                    isPositiveChange: response.result!.isPositiveChange,
                    pagination: response.result!.pagination,
                  ),
          );

          emit(SalesDashboardDebtorsLoaded(
            result: mergedResponse,
            currentPage: currentPage,
            totalPages: totalPages,
            hasReachedMax: hasReachedMax,
          ));
          return;
        }

        emit(SalesDashboardDebtorsLoaded(
          result: response,
          currentPage: currentPage,
          totalPages: totalPages,
          hasReachedMax: hasReachedMax,
        ));
      } catch (e) {
        emit(SalesDashboardDebtorsError(
          message: friendlyError(e).replaceAll('Exception: ', ''),
        ));
      }
    });
  }
}
