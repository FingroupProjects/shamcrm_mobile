import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/storage/secure_storage_service.dart';
import 'package:crm_task_manager/services/app_logout_service.dart';
import 'package:crm_task_manager/utils/user_friendly_error.dart';

class SessionValidationResult {
  final bool isValid;
  final String? errorMessage;

  SessionValidationResult({required this.isValid, this.errorMessage});
}

Future<SessionValidationResult> validateApplicationSession(
    ApiService apiService) async {
  try {
    final token = await apiService.getToken();
    if (token == null || token.isEmpty) {
      return SessionValidationResult(isValid: false, errorMessage: 'No token');
    }

    String? domain = await apiService.getVerifiedDomain();
    if (domain == null || domain.isEmpty) {
      Map<String, String?> qrData = await apiService.getQrData();
      String? qrDomain = qrData['domain'];
      String? qrMainDomain = qrData['mainDomain'];

      if (qrDomain == null ||
          qrDomain.isEmpty ||
          qrMainDomain == null ||
          qrMainDomain.isEmpty) {
        Map<String, String?> domains = await apiService.getEnteredDomain();
        String? enteredDomain = domains['enteredDomain'];
        String? enteredMainDomain = domains['enteredMainDomain'];

        if (enteredDomain == null ||
            enteredDomain.isEmpty ||
            enteredMainDomain == null ||
            enteredMainDomain.isEmpty) {
          return SessionValidationResult(
              isValid: false, errorMessage: 'No domain');
        }
      }
    }

    final organizationId = await apiService.getSelectedOrganization();
    if (organizationId == null || organizationId.isEmpty) {
      // No organization selected
    }

    return SessionValidationResult(isValid: true);
  } catch (e) {
    return SessionValidationResult(
        isValid: false, errorMessage: friendlyError(e));
  }
}

Future<void> clearAllApplicationData(
    ApiService apiService, AuthService authService) async {
  await AppLogoutService.logoutAndReset(
    restartApp: false,
    navigateToAuth: false,
    notifyServer: false,
  );
}
