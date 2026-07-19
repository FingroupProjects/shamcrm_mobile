import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:equatable/equatable.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/dashboard/creditors_model.dart';

part 'sales_dashboard_creditors_event.dart';
part 'sales_dashboard_creditors_state.dart';

class SalesDashboardCreditorsBloc
    extends Bloc<SalesDashboardCreditorsEvent, SalesDashboardCreditorsState> {
  final apiService = ApiService();
  Map<String, dynamic>? _currentFilter;
  String? _currentSearch;

  SalesDashboardCreditorsBloc() : super(SalesDashboardCreditorsInitial()) {
    on<LoadCreditorsReport>((event, emit) async {
      try {
        final filter = event.filter ?? _currentFilter;
        final search = event.search ?? _currentSearch;

        if (event.page == 1) {
          emit(SalesDashboardCreditorsLoading());
          _currentFilter = filter;
          _currentSearch = search;
        }

        final response = await apiService.getCreditorsList(
          page: event.page,
          perPage: event.perPage,
          filters: filter,
          search: search,
        );

        final currentPage = response.result?.pagination?.currentPage ?? 1;
        final totalPages = response.result?.pagination?.totalPages ?? 1;
        final hasReachedMax = currentPage >= totalPages;

        if (event.page > 1 && state is SalesDashboardCreditorsLoaded) {
          final currentState = state as SalesDashboardCreditorsLoaded;
          final currentCreditors = currentState.result.result?.creditors ?? [];
          final newCreditors = response.result?.creditors ?? [];

          final mergedResponse = CreditorsResponse(
            errors: response.errors,
            result: response.result == null
                ? currentState.result.result
                : CreditorsResult(
                    totalDebt: response.result!.totalDebt,
                    creditors: [...currentCreditors, ...newCreditors],
                    period: response.result!.period,
                    percentageChange: response.result!.percentageChange,
                    isPositiveChange: response.result!.isPositiveChange,
                    pagination: response.result!.pagination,
                  ),
          );

          emit(SalesDashboardCreditorsLoaded(
            result: mergedResponse,
            currentPage: currentPage,
            totalPages: totalPages,
            hasReachedMax: hasReachedMax,
          ));
          return;
        }

        emit(SalesDashboardCreditorsLoaded(
          result: response,
          currentPage: currentPage,
          totalPages: totalPages,
          hasReachedMax: hasReachedMax,
        ));
      } catch (e) {
        emit(SalesDashboardCreditorsError(
          message: friendlyError(e).replaceAll('Exception: ', ''),
        ));
      }
    });
  }
}
