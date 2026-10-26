import 'package:crm_task_manager/models/page_2/dashboard/act_of_reconciliation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses counterparty and model when they arrive as strings', () {
    final response = ActOfReconciliationResponse.fromJson({
      'result': [
        {
          'id': '12',
          'movement_type': 'income',
          'sum': 10.5,
          'date': '2026-09-08',
          'counterparty': 'РМК',
          'model': 'not-a-map',
        },
        {
          'id': 13,
          'counterparty': {'id': '4', 'name': 'Клиент'},
        },
      ],
    });

    expect(response.result, hasLength(2));
    expect(response.result!.first.counterparty?.name, 'РМК');
    expect(response.result!.first.model, isNull);
    expect(response.result!.first.id, 12);
    expect(response.result!.last.counterparty?.id, 4);
    expect(response.result!.last.counterparty?.name, 'Клиент');
  });

  test('maps operation_type from nested act-of-reconciliation payload', () {
    final response = ActOfReconciliationResponse.fromJson({
      'result': {
        'data': [
          {
            'counterparty': 'Абду',
            'sum': 500,
            'operation_type': 'Документ: rmk',
            'date': '2026-09-08 12:07:34',
            'author': 'Admin',
          },
          {
            'counterparty': 'Абду',
            'sum': 300,
            'operation_type': 'PKO: Оплата клиента',
            'date': '2026-09-08 12:07:34',
            'author': 'Admin',
          },
        ],
      },
    });

    expect(response.result, hasLength(2));
    expect(response.result!.first.movementType, 'Документ: rmk');
    expect(response.result!.first.counterparty?.name, 'Абду');
    expect(response.result!.first.sum, '500');
    expect(response.result!.first.author, 'Admin');
    expect(response.result!.last.movementType, 'PKO: Оплата клиента');
    expect(response.result!.last.author, 'Admin');
  });

  test('parses author when arriving as map, string or author_name', () {
    final response = ActOfReconciliationResponse.fromJson({
      'result': [
        {
          'id': 1,
          'author': {'name': 'Иван Иванов'},
        },
        {
          'id': 2,
          'author': 'Петр Петров',
        },
        {
          'id': 3,
          'author_name': 'Сидор Сидоров',
        },
      ],
    });

    expect(response.result![0].author, 'Иван Иванов');
    expect(response.result![1].author, 'Петр Петров');
    expect(response.result![2].author, 'Сидор Сидоров');
  });

  test('parses pagination from top-level and nested result payloads', () {
    final responseWithTopPagination = ActOfReconciliationResponse.fromJson({
      'result': [
        {'id': 1, 'sum': 100},
      ],
      'pagination': {
        'current_page': 1,
        'total_pages': 3,
        'total': 50,
        'per_page': 20,
      },
    });

    expect(responseWithTopPagination.pagination, isNotNull);
    expect(responseWithTopPagination.pagination!.currentPage, 1);
    expect(responseWithTopPagination.pagination!.totalPages, 3);
    expect(responseWithTopPagination.pagination!.total, 50);
    expect(responseWithTopPagination.pagination!.perPage, 20);

    final responseWithNestedPagination = ActOfReconciliationResponse.fromJson({
      'result': {
        'data': [
          {'id': 2, 'sum': 200},
        ],
        'pagination': {
          'current_page': 2,
          'total_pages': 4,
          'total': 80,
          'per_page': 20,
        },
      },
    });

    expect(responseWithNestedPagination.pagination, isNotNull);
    expect(responseWithNestedPagination.pagination!.currentPage, 2);
    expect(responseWithNestedPagination.pagination!.totalPages, 4);
    expect(responseWithNestedPagination.pagination!.total, 80);
    expect(responseWithNestedPagination.pagination!.perPage, 20);
  });
}
