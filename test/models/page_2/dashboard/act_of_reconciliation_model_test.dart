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
    expect(response.result!.last.movementType, 'PKO: Оплата клиента');
  });
}
