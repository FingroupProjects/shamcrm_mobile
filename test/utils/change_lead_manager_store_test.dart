import 'package:crm_task_manager/utils/change_lead_manager_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChangeLeadManagerStore.allowsChange', () {
    test('opens the field when the permission is in the list', () {
      final body = {
        'permissions': ['lead.update', 'change_lead_manager'],
        'has_ai_integration': true,
      };

      expect(ChangeLeadManagerStore.allowsChange(body), isTrue);
    });

    test('locks the field when the permission is missing', () {
      final body = {
        'permissions': ['lead.update', 'change_deal_manager'],
        'has_ai_integration': true,
      };

      expect(ChangeLeadManagerStore.allowsChange(body), isFalse);
    });

    test('locks the field when permissions are absent', () {
      expect(
        ChangeLeadManagerStore.allowsChange({'has_ai_integration': true}),
        isFalse,
      );
    });

    test('ignores a boolean field and looks only at the permissions list', () {
      expect(
        ChangeLeadManagerStore.allowsChange({'change_lead_manager': true}),
        isFalse,
      );
      expect(
        ChangeLeadManagerStore.allowsChangeFromList(
          ['lead.update', 'change_lead_manager'],
        ),
        isTrue,
      );
      expect(
        ChangeLeadManagerStore.allowsChangeFromList(['lead.update']),
        isFalse,
      );
    });

    test('unwraps result before looking at permissions', () {
      final body = {
        'result': {
          'permissions': ['change_lead_manager'],
        },
      };

      expect(ChangeLeadManagerStore.allowsChange(body), isTrue);
    });
  });
}
