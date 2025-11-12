// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// /// Сервис для мгновенного запуска приложения
// /// Загружает только критически важные данные из кэша
// class FastStartupService {
//   static Future<SessionData> getQuickSessionData() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
      
//       return SessionData(
//         hasToken: prefs.getString('authToken')?.isNotEmpty ?? false,
//         hasPin: prefs.getString('user_pin')?.isNotEmpty ?? false,
//         isDomainChecked: prefs.getBool('isDomainChecked') ?? false,
//         userName: prefs.getString('userName') ?? 'Пользователь',
//         userImage: prefs.getString('userImage') ?? '',
//       );
//     } catch (e) {
//       return SessionData.empty();
//     }
//   }
  
//   /// Проверка валидности сессии БЕЗ сетевых запросов
//   static Future<bool> isSessionValid() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
      
//       final hasToken = prefs.getString('authToken')?.isNotEmpty ?? false;
//       final hasDomain = prefs.getString('verifiedDomain')?.isNotEmpty ?? false;
      
//       return hasToken && hasDomain;
//     } catch (e) {
//       return false;
//     }
//   }
// }

// class SessionData {
//   final bool hasToken;
//   final bool hasPin;
//   final bool isDomainChecked;
//   final String userName;
//   final String userImage;
  
//   SessionData({
//     required this.hasToken,
//     required this.hasPin,
//     required this.isDomainChecked,
//     required this.userName,
//     required this.userImage,
//   });
  
//   factory SessionData.empty() => SessionData(
//     hasToken: false,
//     hasPin: false,
//     isDomainChecked: false,
//     userName: '',
//     userImage: '',
//   );
// }