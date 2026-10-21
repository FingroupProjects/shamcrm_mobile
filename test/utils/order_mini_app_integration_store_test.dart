import 'package:crm_task_manager/models/page_2/order_internet_store_model.dart';
import 'package:crm_task_manager/utils/order_mini_app_integration_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderMiniAppIntegrationStore.pick', () {
    test('keeps a bot with an empty name', () {
      final store = OrderInternetStore.fromJson({
        'id': 306,
        'type': 'mini_app_telegram_bot',
        'category': 'mini_app',
        'name': '',
        'username': '',
        'is_active': true,
      });

      expect(store.id, 306);
      expect(store.label, 'Mini App #306');
      expect(OrderMiniAppIntegrationStore.pick([store])?.id, 306);
    });

    test('prefers the active integration', () {
      final inactive = OrderInternetStore(
        id: 1,
        type: 'mini_app_telegram_bot',
        category: 'mini_app',
        name: '',
        username: '',
        isActive: false,
      );
      final active = OrderInternetStore(
        id: 306,
        type: 'mini_app_telegram_bot',
        category: 'mini_app',
        name: '',
        username: '',
        isActive: true,
      );

      expect(
        OrderMiniAppIntegrationStore.pick([inactive, active])?.id,
        306,
      );
    });

    test('ignores a row without id', () {
      final empty = OrderInternetStore(
        id: 0,
        type: 'mini_app_telegram_bot',
        category: 'mini_app',
        name: 'Shop',
        username: '',
        isActive: true,
      );

      expect(OrderMiniAppIntegrationStore.pick([empty]), isNull);
    });
  });

  group('OrderMiniAppIntegrationSnapshot', () {
    test('round-trips the id with organization and funnel', () {
      const snapshot = OrderMiniAppIntegrationSnapshot(
        id: 306,
        organizationId: '1',
        salesFunnelId: '1',
        name: '',
        username: '',
        type: 'mini_app_telegram_bot',
        isActive: true,
      );

      final restored =
          OrderMiniAppIntegrationSnapshot.fromJson(snapshot.toJson());

      expect(restored.id, 306);
      expect(restored.organizationId, '1');
      expect(restored.salesFunnelId, '1');
      expect(restored.isActive, isTrue);
    });
  });
}
