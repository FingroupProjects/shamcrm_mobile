import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/reconciliation_act/sales_dashboard_reconciliation_act_bloc.dart';
import 'package:crm_task_manager/models/page_2/dashboard/act_of_reconciliation_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  test('emits empty state when filter lacks lead_id and supplier_id', () async {
    final bloc = SalesDashboardReconciliationActBloc(
      fetchReconciliationAct: ({filters, page, perPage, search}) async {
        return ActOfReconciliationResponse(result: const []);
      },
    );

    bloc.add(const LoadReconciliationActReport(filter: {}));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<SalesDashboardReconciliationActLoaded>((state) =>
            (state.data.result?.isEmpty ?? false) && state.hasReachedMax),
      ]),
    );

    await bloc.close();
  });

  test('loads page 1 and then loads and merges page 2', () async {
    final page1 = ActOfReconciliationResponse(
      result: [
        ReconciliationItem(id: 1, sum: '100'),
        ReconciliationItem(id: 2, sum: '200'),
      ],
      pagination: const ReconciliationPagination(
        currentPage: 1,
        totalPages: 2,
        total: 4,
        perPage: 2,
      ),
    );

    final page2 = ActOfReconciliationResponse(
      result: [
        ReconciliationItem(id: 3, sum: '300'),
        ReconciliationItem(id: 4, sum: '400'),
      ],
      pagination: const ReconciliationPagination(
        currentPage: 2,
        totalPages: 2,
        total: 4,
        perPage: 2,
      ),
    );

    final pagedData = {
      1: page1,
      2: page2,
    };

    final bloc = SalesDashboardReconciliationActBloc(
      fetchReconciliationAct: ({filters, page, perPage, search}) async {
        return pagedData[page ?? 1] ??
            ActOfReconciliationResponse(result: const []);
      },
    );

    bloc.add(const LoadReconciliationActReport(
      page: 1,
      perPage: 2,
      filter: {'lead_id': 10},
    ));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<SalesDashboardReconciliationActLoading>(),
        predicate<SalesDashboardReconciliationActLoaded>((state) {
          return state.data.result?.length == 2 &&
              state.currentPage == 1 &&
              state.totalPages == 2 &&
              !state.hasReachedMax;
        }),
      ]),
    );

    bloc.add(const LoadReconciliationActReport(page: 2, perPage: 2));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<SalesDashboardReconciliationActLoaded>((state) {
          final items = state.data.result ?? [];
          return items.length == 4 &&
              items.map((i) => i.id).toList().toString() == '[1, 2, 3, 4]' &&
              state.currentPage == 2 &&
              state.totalPages == 2 &&
              state.hasReachedMax;
        }),
      ]),
    );

    await bloc.close();
  });
}
