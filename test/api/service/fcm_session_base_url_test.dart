import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('QR login replaces a previous email domain for add-fcm-token', () async {
    SharedPreferences.setMockInitialValues({
      'verifiedDomain': 'old-tenant-back.shamcrm.com',
      'verifiedLogin': 'old@mail.com',
      'enteredDomain': 'old-tenant',
      'enteredMainDomain': 'shamcrm.com',
    });

    final api = ApiService();
    // Конструктор без токена сразу выходит. Даём ему закончить до записи QR.
    await Future<void>.delayed(const Duration(milliseconds: 30));

    await api.saveQrData(
      'acme',
      'shamcrm.com',
      'qr-user',
      'qr-token',
      '7',
      '3',
    );

    expect(await api.getVerifiedDomain(), isNull);
    expect(await api.getToken(), 'qr-token');
    expect(
      await api.getDynamicBaseUrl(),
      'https://acme-back.shamcrm.com/api',
    );
    expect(api.baseUrl, 'https://acme-back.shamcrm.com/api');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('enteredDomain'), 'acme');
    expect(prefs.getString('enteredMainDomain'), 'shamcrm.com');
    expect(prefs.getString('selectedOrganization'), '3');
  });

  test('email login base url ignores a leftover QR domain', () async {
    SharedPreferences.setMockInitialValues({
      'domain': 'oldqr',
      'mainDomain': 'shamcrm.com',
      'enteredDomain': 'oldqr',
      'enteredMainDomain': 'shamcrm.com',
    });

    final api = ApiService();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    await api.saveEmailVerificationData(
      'new-tenant-back.shamcrm.com',
      'user@mail.com',
      organizationId: '2',
    );
    await api.clearQrDomainData();
    await api.alignEnteredDomainWithVerifiedEmail();

    expect(await api.getDynamicBaseUrl(), 'https://new-tenant-back.shamcrm.com/api');
    expect(await api.bindActiveSessionBaseUrl(), isTrue);
    expect(api.baseUrl, 'https://new-tenant-back.shamcrm.com/api');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('domain'), isNull);
    expect(prefs.getString('mainDomain'), isNull);
    expect(prefs.getString('enteredDomain'), 'new-tenant');
    expect(prefs.getString('enteredMainDomain'), 'shamcrm.com');
  });
}
