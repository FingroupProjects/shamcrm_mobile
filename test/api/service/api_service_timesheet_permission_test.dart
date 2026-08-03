import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('timesheet access is enabled by timesheet.read permission', () async {
    SharedPreferences.setMockInitialValues({
      'permissions': <String>['lead.read', ApiService.workdayReadPermission],
    });

    expect(await ApiService().canReadTimesheet(), isTrue);
  });

  test('timesheet access is disabled without timesheet.read permission',
      () async {
    SharedPreferences.setMockInitialValues({
      'permissions': <String>['lead.read', 'task.read'],
    });

    expect(await ApiService().canReadTimesheet(), isFalse);
  });
}
