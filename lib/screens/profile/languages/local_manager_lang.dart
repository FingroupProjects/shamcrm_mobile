import 'package:crm_task_manager/api/service/widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageManager {
  static const String _languageKey = 'selected_language';

  static Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    
    // Sync language to iOS widget via App Groups
    await WidgetService.syncLanguageToWidget(languageCode);
  }

  static Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }
  
  /// Sync current language to widget (call on app start)
  static Future<void> syncCurrentLanguageToWidget() async {
    final languageCode = await getLanguage() ?? 'ru';
    await WidgetService.syncLanguageToWidget(languageCode);
  }
}