import 'dart:convert';
import 'dart:io';
// import 'package:crm_task_manager/models/chart_data.dart';
// import 'package:crm_task_manager/models/dashboard_charts_models/lead_conversion_model.dart';
import 'package:crm_task_manager/firebase_options.dart';
import 'package:crm_task_manager/models/author_data_response.dart';
import 'package:crm_task_manager/models/calendar_model.dart';
import 'package:crm_task_manager/models/chatById_model.dart';
import 'package:crm_task_manager/models/chatGetId_model.dart';
import 'package:crm_task_manager/models/chatTaskProfile_model.dart';
import 'package:crm_task_manager/models/contact_person_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/deal_stats_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_conversion_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_chart_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/process_speed%20_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/user_task%20_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/deal_stats_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/lead_chart_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/lead_conversion_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/process_speed%20_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/task_chart_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/user_task_model.dart';
import 'package:crm_task_manager/models/deal_name_list.dart';
import 'package:crm_task_manager/models/deal_task_model.dart';
import 'package:crm_task_manager/models/department.dart';
import 'package:crm_task_manager/models/event_by_Id_model.dart';
import 'package:crm_task_manager/models/event_model.dart';
import 'package:crm_task_manager/models/history_model_my-task.dart';
import 'package:crm_task_manager/models/lead_deal_model.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/lead_multi_model.dart';
import 'package:crm_task_manager/models/lead_navigate_to_chat.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/my-task_Status_Name_model.dart';
import 'package:crm_task_manager/models/my-task_model.dart';
import 'package:crm_task_manager/models/my-taskbyId_model.dart';
import 'package:crm_task_manager/models/notice_history_model.dart';
import 'package:crm_task_manager/models/notice_subject_model.dart';
import 'package:crm_task_manager/models/notifications_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/project_chart_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/task_chart_model.dart';
import 'package:crm_task_manager/models/organization_model.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/models/page_2/character_list_model.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/lead_order_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryById.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/models/source_list_model.dart';
import 'package:crm_task_manager/models/source_model.dart';
import 'package:crm_task_manager/models/task_Status_Name_model.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/stats_model.dart';
import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/models/deal_history_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/lead_history_model.dart';
import 'package:crm_task_manager/models/history_model_task.dart';
import 'package:crm_task_manager/models/leadById_model.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/notes_model.dart';
import 'package:crm_task_manager/models/pagination_dto.dart';
import 'package:crm_task_manager/models/project_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/models/role_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/taskbyId_model.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/models/user_model.dart';
import 'package:crm_task_manager/page_2/order/order_details/lead_order_list.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/task_dropdown_bottom_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/domain_check.dart';
import '../../models/login_model.dart';

// final String baseUrl = 'https://fingroup-back.shamcrm.com/api';
// final String baseUrl = 'https://ede8-95-142-94-22.ngrok-free.app';

// final String baseUrlSocket ='https://fingroup-back.shamcrm.com/broadcasting/auth';

class ApiService {
  String? baseUrl;
  String? baseUrlSocket;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  ApiService() {
    _initializeIfDomainExists();
  }

  Future<void> _initializeIfDomainExists() async {
    bool isDomainSet = await isDomainChecked();
    if (isDomainSet) {
      await initialize();
    }
  }

  Future<void> initialize() async {
    baseUrl = await getDynamicBaseUrl();
  }

  // Инициализация API с доменом из QR-кода
  Future<void> initializeWithDomain(String domain, String mainDomain) async {
    baseUrl = 'https://$domain-back.$mainDomain/api';
    baseUrlSocket = 'https://$domain-back.$mainDomain/broadcasting/auth';
    print('API инициализировано с поДоменом: $domain и Доменом $mainDomain');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('domain', domain);
    await prefs.setString('mainDomain', mainDomain);
  }

  Future<String> getDynamicBaseUrl() async {
    Map<String, String?> domains = await getEnteredDomain();
    String? mainDomain =
        domains['enteredMainDomain']; // Извлекаем значение по ключу
    String? domain = domains['enteredDomain']; // Извлекаем значение по ключу

    if (domain != null && domain.isNotEmpty) {
      return 'https://$domain-back.$mainDomain/api';
    } else {
      throw Exception('Домен не установлен в SharedPreferences');
    }
  }

  Future<String> getSocketBaseUrl() async {
    Map<String, String?> domains = await getEnteredDomain();
    String? mainDomain =
        domains['enteredMainDomain']; // Извлекаем значение по ключу
    String? domain = domains['enteredDomain']; // Извлекаем значение по ключу
    if (domain != null && domain.isNotEmpty) {
      return 'https://$domain-back.$mainDomain/broadcasting/auth';
    } else {
      throw Exception('Домен не установлен в SharedPreferences');
    }
  }

  // Общая обработка ответа от сервера 401
  Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      await logout();
      _redirectToLogin();
      throw Exception('Неавторизованный доступ!');
    }
    return response;
  }

  // Метод для перенаправления на окно входа
  void _redirectToLogin() {
    final navigatorKey = GlobalKey<NavigatorState>();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/local_auth',
      (route) => false,
    );
  }

  Future<void> reset() async {
    // Сброс значений при выходе
    baseUrl = null;
    baseUrlSocket = null;
    print('API сброшено');
  }

  // Метод для получения токена из SharedPreferences
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Получаем токен из SharedPreferences
  }

  // Метод для сохранения токена в SharedPreferences
  Future<void> _saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token); // Сохраняем токен
  }

  // Метод для удаления токена (используется при логауте)
  Future<void> _removeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Удаляем токен
  }

  // Метод для логаута — очистка токена
  Future<void> logout() async {
    // Сохраняем текущие значения domainChecked и enteredDomain
    // bool? domainChecked = prefs.getBool('domainChecked');
    // String? enteredDomain = prefs.getString('enteredDomain');
    // String? enteredMainDomain = prefs.getString('enteredMainDomain');

    // Удаляем токен, права доступа и организацию
    await _removeToken();
    await _removePermissions();
    await _removeOrganizationId();

    // Очищаем все данные, кроме domainChecked и enteredDomain
    // bool isCleared = await prefs.clear();

    // // Восстанавливаем значения domainChecked и enteredDomain
    // if (domainChecked != null) {
    //   await prefs.setBool('domainChecked', domainChecked);
    // }
    // if (enteredDomain != null) {
    //   await prefs.setString('enteredDomain', enteredDomain);
    // }
    // if (enteredMainDomain != null) {
    //   await prefs.setString('enteredMainDomain', enteredMainDomain);
    // }

    // // Проверяем успешность очистки
    // if (isCleared) {
    //   print('Все данные успешно очищены, кроме $domainChecked и $enteredDomain и $enteredMainDomain');
    // } else {
    //   print('Ошибка при очистке данных.');
    // }
  }

  Future<void> _removePermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Выводим в консоль текущие права доступа до удаления
    print('Перед удалением: ${prefs.getStringList('permissions')}');

    // Удаляем права доступа
    await prefs.remove('permissions');

    // Проверяем, что ключ действительно удалён
    print('После удаления: ${prefs.getStringList('permissions')}');
  }

  //_________________________________ START___API__METHOD__GET__POST__PATCH__DELETE____________________________________________//

// Метод для выполнения GET-запросов
  Future<http.Response> _getRequest(String path) async {
    final token = await getToken(); // Получаем токен перед запросом
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Device': 'mobile'
      },
    );

    // print('Статус ответа! ${response.statusCode}');
    // print('Тело ответа!${response.body}');

    return _handleResponse(response);
  }

  // Метод для выполнения POST-запросов
  Future<http.Response> _postRequest(
      String path, Map<String, dynamic> body) async {
    final token = await getToken(); // Получаем токен перед запросом

    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null)
          'Authorization': 'Bearer $token', // Добавляем токен, если он есть
        'Device': 'mobile'
      },
      body: json.encode(body),
    );

    print('Статус ответа! ${response.statusCode}');
    print('Тело ответа!${response.body}');

    return _handleResponse(response);
  }

// Метод для выполнения PATCH-запросов
  Future<http.Response> _patchRequest(
      String path, Map<String, dynamic> body) async {
    final token = await getToken(); // Получаем токен перед запросом

    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null)
          'Authorization': 'Bearer $token', // Добавляем токен, если он есть
        'Device': 'mobile'
      },
      body: json.encode(body),
    );

    print('Статус ответа! ${response.statusCode}');
    print('Тело ответа!${response.body}');

    return _handleResponse(response);
  }

  // Метод для выполнения DELETE-запросов
  Future<http.Response> _deleteRequest(String path) async {
    final token = await getToken(); // Получаем токен перед запросом

    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Device': 'mobile'
      },
    );

    print('Статус ответа! ${response.statusCode}');
    print('Тело ответа!${response.body}');

    return _handleResponse(response);
  }

  //_________________________________ END___API__METHOD__GET__POST__PATCH__DELETE____________________________________________//

  //        if (!await hasPermission('deal.read')) {
  //   throw Exception('У вас нет прав для просмотра сделки'); // Сообщение об отсутствии прав доступа
  // }

  //_________________________________ START___API__METHOD__POST__DEVICE__TOKEN_________________________________________________//

  // Добавление метода для отправки токена устройства
  Future<void> sendDeviceToken(String deviceToken) async {
    final token =
        await getToken(); // Получаем токен пользователя (если он есть)
    final organizationId = await getSelectedOrganization();

    final response = await http.post(
      Uri.parse(
          '$baseUrl/add-fcm-token${organizationId != null ? '?organization_id=$organizationId' : ''}'), // Используем правильный путь
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        'Device': 'mobile'
      },
      body: json.encode({
        'type': 'mobile', // Указываем тип устройства
        'token': deviceToken, // Передаем FCM-токен устройства
      }),
    );

    if (response.statusCode == 200) {
      print('FCM-токен успешно отправлен!');
    } else {
      print('Ошибка при отправке FCM-токена!');
      throw Exception('Ошибка!');
    }
  }

  // Метод для получения чата по ID
  Future<ChatsGetId> getChatById(int chatId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
        '/chat/$chatId${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      return ChatsGetId.fromJson(json.decode(response.body));
    } else {
      throw Exception('Ошибка получения чата!');
    }
  }

  //_________________________________ END___API__METHOD__POST__DEVICE__TOKEN_________________________________________________//

  // Метод для сохранения данных из QR-кода
  Future<void> saveQrData(String mainDomain, String domain, String login,
      String token, String userId, String organizationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Сохраняем данные из QR-кода
    await prefs.setString('domain', domain ?? '');
    print(prefs.getString('domain'));
    await prefs.setString('mainDomain', mainDomain ?? '');
    print(prefs.getString('mainDomain'));
    await prefs.setString('userLogin', login ?? '');
    print(prefs.getString('userLogin'));
    await prefs.setString('token', token);
    print(prefs.getString('token'));
    await prefs.setString('userID', userId ?? '');
    print(prefs.getString('userID'));
    await prefs.setString('selectedOrganization', organizationId ?? '');
    print(prefs.getString('selectedOrganization'));

    // После сохранения обновляем информацию
    await saveDomainChecked(true);
    await saveDomain(mainDomain, domain);
  }

  // Метод для получения данных из QR-кода
  Future<Map<String, String?>> getQrData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? domain = prefs.getString('domain') ?? '';
    String? mainDomain = prefs.getString('mainDomain') ?? '';

    String? login = prefs.getString('userLogin') ?? '';
    String? token = prefs.getString('token') ?? '';
    String userId = prefs.getString('userID') ?? '';
    String? organizationId = prefs.getString('selectedOrganization') ?? '';
    return {
      'domain': domain,
      'mainDomain': mainDomain,
      'login': login,
      'token': token,
      'userID': userId,
      'selectedOrganization': organizationId
    };
  }

  //_________________________________ START___API__DOMAIN_CHECK____________________________________________//

  // Метод для выполнения POST-запросов
// Метод для выполнения POST-запросов
  Future<http.Response> _postRequestDomain(
      String path, Map<String, dynamic> body) async {
    final enteredDomainMap = await ApiService().getEnteredDomain();
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];

    final String DomainUrl = 'https://$enteredMainDomain/api';

    // Выводим URL домена перед отправкой запроса
    print(
        "-=-=--=-=-=-==-=-=-=-=--=-==DOAMIN URL--==--=-=-==---=-=-=-=-=-=-=-=-=-=--=-=-=-");
    print(DomainUrl);

    final token = await getToken(); // Получаем токен перед запросом

    // Выводим статус и тело запроса перед отправкой
    print('Отправка запроса на проверку домена...');

    final response = await http.post(
      Uri.parse('$DomainUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null)
          'Authorization': 'Bearer $token', // Добавляем токен, если он есть
        'Device': 'mobile'
      },
      body: json.encode(body),
    );

    // Выводим статус и тело ответа после получения ответа
    print('Статус ответа: ${response.statusCode}');
    print('Тело ответа: ${response.body}');

    return response;
  }

  // Метод для проверки домена
  Future<DomainCheck> checkDomain(String domain) async {
    print(
        '-=--=-=-=-=-=-=-==-=-=-=CHECK-DOMAIN-=--==-=-=--=-==--==-=-=-=-=-=-=-');
    print(domain);
    final organizationId = await getSelectedOrganization();
    final response = await _postRequestDomain(
        '/checkDomain${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {'domain': domain});

    if (response.statusCode == 200) {
      return DomainCheck.fromJson(json.decode(response.body));
    } else {
      throw Exception('Не удалось загрузить поддомен!');
    }
  }

  // Метод для сохранения домена
  Future<void> saveDomainChecked(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'domainChecked', value); // Сохраняем статус проверки домена
  }

  // Метод для проверки домена из SharedPreferences
  Future<bool> isDomainChecked() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('domainChecked') ??
        false; // Проверяем статус или возвращаем false
  }

  // Метод для сохранения введенного домена
  Future<void> saveDomain(String domain, String mainDomain) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('enteredMainDomain', mainDomain);
    await prefs.setString('enteredDomain', domain);
    print('Ввведеный Doмен:----------------------');
    print('ДОМЕН: ${prefs.getString('enteredMainDomain')}');
    print('Ввведеный Poddomen---=----:----------------------');
    print('ПОДДОМЕН: ${prefs.getString('enteredDomain')}');
  }

// Метод для получения введенного домена
  Future<Map<String, String?>> getEnteredDomain() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mainDomain = prefs.getString('enteredMainDomain');
    String? domain = prefs.getString('enteredDomain');

    return {
      'enteredMainDomain': mainDomain,
      'enteredDomain': domain,
    };
  }
  //_________________________________ END___API__DOMAIN_CHECK____________________________________________//

  //_________________________________ START___API__LOGIN____________________________________________//

  // Метод для проверки логина и пароля
  Future<LoginResponse> login(LoginModel loginModel) async {
    final organizationId = await getSelectedOrganization();
    print("------------------------ $organizationId");
    final response = await _postRequest(
        '/login${organizationId != null ? '?organization_id=$organizationId' : ''}',
        loginModel.toJson());

    // Выводим ответ от сервера в консоль
    print("Response from server: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final loginResponse = LoginResponse.fromJson(data);

      await _saveToken(loginResponse.token);
      // await _savePermissions(loginResponse.permissions); // Сохраняем права доступа

      return loginResponse;
    } else {
      throw Exception('Неправильный Логин или Пароль!');
    }
  }

// // Метод для сохранения прав доступа в SharedPreferences
//   Future<void> _savePermissions(List<String> permissions) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setStringList('permissions', permissions); // Сохраняем список прав
//   }

// // Метод для получения списка прав доступа
//   Future<List<String>> getPermissions() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getStringList('permissions') ?? []; // Возвращаем список прав доступа или пустой список
//   }

// // Метод для проверки, есть ли у пользователя определенное право
//   Future<bool> hasPermission(String permission) async {
//     final permissions = await getPermissions();
//     return permissions.contains(permission); // Проверяем наличие права
//   }

  Future<List<String>> fetchPermissionsByRoleId() async {
    final organizationId = await getSelectedOrganization();

    try {
      final response = await _getRequest(
          '/get-all-permissions?organization_id=$organizationId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['permissions'] != null) {
          // Преобразование списка разрешений в List<String>
          return (data['permissions'] as List<dynamic>)
              .map((permission) => permission as String)
              .toList();
        } else {
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка при получении прав доступа!!');
      }
    } catch (e) {
      print('Ошибка при выполнении запроса fetchPermissionsByRoleId: $e');
      rethrow;
    }
  }

// Сохранение прав доступа в SharedPreferences
  Future<void> savePermissions(List<String> permissions) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('permissions', permissions);
    // print('Сохранённые права доступа: ${prefs.getStringList('permissions')}');
  }

// Получение списка прав доступа из SharedPreferences
  Future<List<String>> getPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final permissions = prefs.getStringList('permissions') ?? [];
    // print('Извлечённые права доступа: $permissions');
    return permissions;
  }

// Проверка наличия определенного права
  Future<bool> hasPermission(String permission) async {
    final permissions = await getPermissions();
    return permissions.contains(permission);
  }
// // Сохранение прав доступа в SharedPreferences
// Future<void> savePermissionsPinCode(List<String> permissions) async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   await prefs.setStringList('permissions', permissions);
// }

// // Получение списка прав доступа из SharedPreferences
// Future<List<String>> getPermissionsPinCode() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getStringList('permissions') ?? [];
// }

// // Проверка наличия определенного права
// Future<bool> hasPermissionPinCode(String permission) async {
//   final permissions = await getPermissions();
//   return permissions.contains(permission);
// }

  //_________________________________ END___API__LOGIN____________________________________________//

  Future<String> forgotPin(LoginModel loginModel) async {
    try {
      // Получение ID организации (если необходимо)
      final organizationId = await getSelectedOrganization();

      // Формирование URL с учетом ID организации
      final url =
          '/forgotPin${organizationId != null ? '?organization_id=$organizationId' : ''}';

      // Запрос к API
      final response = await _postRequest(
        url,
        {
          'login': loginModel.login,
          'password': loginModel.password,
        },
      );

      // Обработка успешного ответа
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);

        if (decodedJson['result'] != null) {
          return decodedJson['result'].toString();
        } else {
          throw Exception('Не удалось получить временный PIN.');
        }
      }
      // Обработка ошибок сервера
      else if (response.statusCode == 400) {
        throw Exception('Некорректные данные запроса.');
      } else {
        print('Ошибка API forgotPin!');
        throw Exception('Ошибка сервера!');
      }
    } catch (e) {
      print('Ошибка в forgotPin!');
      throw Exception('Ошибка в запросе!');
    }
  }

  //_________________________________ START_____API__SCREEN__LEAD____________________________________________//

//Метод для получения Лида через его ID
  Future<LeadById> getLeadById(int leadId) async {
    try {
      final organizationId = await getSelectedOrganization();

      final response = await _getRequest(
          '/lead/$leadId${organizationId != null ? '?organization_id=$organizationId' : ''}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic> jsonLead = decodedJson['result'];
        return LeadById.fromJson(jsonLead, jsonLead['leadStatus']['id']);
      } else {
        throw Exception('Ошибка загрузки лида ID!');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки лида ID!');
    }
  }

  // Метод для получения списка Лидов с пагинацией
  Future<List<Lead>> getLeads(
    int? leadStatusId, {
    int page = 1,
    int perPage = 20,
    String? search,
    List<int>? managers,
    List<int>? regions,
    List<int>? sources,
    int? statuses,
    DateTime? fromDate,
    DateTime? toDate,
    bool? hasSuccessDeals,
    bool? hasInProgressDeals,
    bool? hasFailureDeals,
    bool? hasNotices,
    bool? hasContact,
    bool? hasChat,
    bool? hasDeal,
    int? daysWithoutActivity,
    bool? hasNoReplies, // Новый параметр
    bool? hasUnreadMessages, // Новый параметр
  }) async {
    final organizationId = await getSelectedOrganization();
    String path = '/lead?page=$page&per_page=$perPage';
    path += '&organization_id=$organizationId';

    bool hasFilters = (search != null && search.isNotEmpty) ||
        (managers != null && managers.isNotEmpty) ||
        (regions != null && regions.isNotEmpty) ||
        (sources != null && sources.isNotEmpty) ||
        (fromDate != null) ||
        (toDate != null) ||
        (hasSuccessDeals == true) ||
        (hasInProgressDeals == true) ||
        (hasFailureDeals == true) ||
        (hasNotices == true) ||
        (hasContact == true) ||
        (hasChat == true) ||
        (hasDeal == true) ||
        (hasNoReplies == true) || // Новый параметр
        (hasUnreadMessages == true) || // Новый параметр
        (daysWithoutActivity != null) ||
        (statuses != null);

    if (leadStatusId != null && !hasFilters) {
      path += '&lead_status_id=$leadStatusId';
    }

    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    if (managers != null && managers.isNotEmpty) {
      for (int i = 0; i < managers.length; i++) {
        path += '&managers[$i]=${managers[i]}';
      }
    }
    if (regions != null && regions.isNotEmpty) {
      for (int i = 0; i < regions.length; i++) {
        path += '&regions[$i]=${regions[i]}';
      }
    }
    if (sources != null && sources.isNotEmpty) {
      for (int i = 0; i < sources.length; i++) {
        path += '&sources[$i]=${sources[i]}';
      }
    }
    if (hasNoReplies == true) {
      // Новый параметр
      path += '&hasNoReplies=1';
    }

    if (hasUnreadMessages == true) {
      // Новый параметр
      path += '&hasUnreadMessages=1';
    }
    if (statuses != null) {
      path += '&lead_status_id=$statuses';
    }

    if (fromDate != null && toDate != null) {
      final formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
      final formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);
      path += '&from=$formattedFromDate&to=$formattedToDate';
    }
    if (hasSuccessDeals == true) {
      path += '&hasSuccessDeals=1';
    }
    if (hasInProgressDeals == true) {
      path += '&hasInProgressDeals=1';
    }
    if (hasFailureDeals == true) {
      path += '&hasFailureDeals=1';
    }
    if (hasNotices == true) {
      path += '&hasNotices=1';
    }
    if (hasContact == true) {
      path += '&hasContact=1';
    }
    if (hasChat == true) {
      path += '&hasChat=1';
    }
    if (hasDeal == true) {
      path += '&withoutDeal=1';
    }
    if (daysWithoutActivity != null) {
      path += '&lastUpdate=$daysWithoutActivity';
    }

    final response = await _getRequest(path);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((json) => Lead.fromJson(json, leadStatusId ?? -1))
            .toList();
      } else {
        throw Exception('Данные лидов отсутствуют в ответе');
      }
    } else {
      throw Exception('Ошибка загрузки лидов!');
    }
  }

  // Метод для получения статусов лидов
  Future<List<LeadStatus>> getLeadStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();

    try {
      // Отправляем запрос на сервер
      final response = await _getRequest(
          '/lead/statuses${organizationId != null ? '?organization_id=$organizationId' : ''}');

      // print(
      //     '=--=-=-=-=--==-=-=--=-==-RESPONSE GET-STATUS LEADS=-=--==-=-=-=-=-=-=-=-=-=--==-=-');
      // print('Отправка запроса на API с путём: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          final statuses = (data['result'] as List)
              .map((status) => LeadStatus.fromJson(status))
              .toList();

          // Принт старых кэшированных данных (если они есть)
          final cachedStatuses =
              prefs.getString('cachedLeadStatuses_$organizationId');
          if (cachedStatuses != null) {
            final decodedData = json.decode(cachedStatuses);
            // print(
            //     '------------------------------ Старые данные в кэше ------------------------------');
            // print(decodedData); // Старые данные
          }

          // Обновляем кэш новыми данными
          await prefs.setString('cachedLeadStatuses_$organizationId',
              json.encode(data['result']));
          // print(
          //     '------------------------------------ Новые данные, которые сохраняются в кэш ---------------------------------');
          // print(data['result']); // Новые данные, которые будут сохранены в кэш

          return statuses;
        } else {
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка при получении данных!');
      }
    } catch (e) {
      print('Ошибка загрузки статусов лидов. Используем кэшированные данные.');
      // Если запрос не удался, пытаемся загрузить данные из кэша
      final cachedStatuses =
          prefs.getString('cachedLeadStatuses_$organizationId');
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        final cachedList = (decodedData as List)
            .map((status) => LeadStatus.fromJson(status))
            .toList();
        return cachedList;
      } else {
        throw Exception(
            'Ошибка загрузки статусов лидов и отсутствуют кэшированные данные!');
      }
    }
  }

  Future<bool> checkIfStatusHasLeads(int leadStatusId) async {
    try {
      // Получаем список лидов для указанного статуса, берем только первую страницу
      final List<Lead> leads =
          await getLeads(leadStatusId, page: 1, perPage: 1);

      // Если список лидов не пуст, значит статус содержит элементы
      return leads.isNotEmpty;
    } catch (e) {
      print('Error while checking if status has leads!');
      return false;
    }
  }

  // Метод для создания Cтатуса Лида
  Future<Map<String, dynamic>> createLeadStatus(
      String title, String color, bool? isFailure, bool? isSuccess) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
        '/lead-status${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'title': title,
          'color': color,
          "is_success": isSuccess == true ? 1 : 0,
          "is_failure": isFailure == true ? 1 : 0,
        });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'Статус лида создан успешно'};
    } else {
      return {'success': false, 'message': 'Ошибка создания статуса лида!'};
    }
  }

//Обновление статуса карточки Лида  в колонке
  Future<void> updateLeadStatus(int leadId, int position, int statusId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
      '/lead/changeStatus/$leadId${organizationId != null ? '?organization_id=$organizationId' : ''}',
      {
        'position': position,
        'status_id': statusId,
      },
    );

    if (response.statusCode == 200) {
      print('Статус задачи успешно обновлен');
    } else if (response.statusCode == 422) {
      final responseData = jsonDecode(response.body);
      final errorMessage = responseData['message'];

      throw LeadStatusUpdateException(422, errorMessage);
    } else {
      throw Exception('Ошибка обновления задач лида!');
    }
  }

// Метод для получения Истории Лида
  Future<List<LeadHistory>> getLeadHistory(int leadId) async {
    try {
      final organizationId = await getSelectedOrganization();

      // Используем метод _getRequest вместо прямого выполнения запроса
      final response = await _getRequest(
          '/lead/history/$leadId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => LeadHistory.fromJson(json)).toList();
      } else {
        print('Failed to load lead history!');
        throw Exception('Ошибка загрузки истории лида!');
      }
    } catch (e) {
      print('Error occurred!');
      throw Exception('Ошибка загрузки истории лида!');
    }
  }

  Future<List<NoticeHistory>> getNoticeHistory(int leadId) async {
    try {
      final organizationId = await getSelectedOrganization();
      final response = await _getRequest(
          '/notices/history-by-lead-id/$leadId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result'];
        return jsonList.map((json) => NoticeHistory.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка загрузки истории заметок!');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки истории заметок!');
    }
  }

  Future<List<DealHistoryLead>> getDealHistoryLead(int leadId) async {
    try {
      final organizationId = await getSelectedOrganization();
      final response = await _getRequest(
          '/deal/history-by-lead-id/$leadId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result'];
        return jsonList.map((json) => DealHistoryLead.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка загрузки истории сделок!');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки истории сделок!');
    }
  }

  Future<List<Notes>> getLeadNotes(int leadId,
      {int page = 1, int perPage = 20}) async {
    final organizationId =
        await getSelectedOrganization(); // Получаем ID организации
    final path =
        '/notices/$leadId?page=$page&per_page=$perPage&organization_id=$organizationId';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result']['data'] as List)
          .map((note) => Notes.fromJson(note))
          .toList();
    } else {
      throw Exception('Ошибка загрузки заметок');
    }
  }

  // Метод для Создания Заметки Лида
  Future<Map<String, dynamic>> createNotes({
    required String title,
    required String body,
    required int leadId,
    DateTime? date,
    required List<int> users,
  }) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
        '/notices${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'title': title,
          'body': body,
          'lead_id': leadId,
          'date': date?.toIso8601String(),
          'users': users,
        });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'note_created_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('title')) {
        return {'success': false, 'message': 'error_field_is_not_empty'};
      } else if (response.body.contains('body')) {
        return {'success': false, 'message': 'error_field_is_not_empty'};
      } else if (response.body.contains('date')) {
        return {'success': false, 'message': 'error_valid_date'};
      } else {
        return {'success': false, 'message': 'unknown_error'};
      }
    } else {
      return {'success': false, 'message': 'error_create_note'};
    }
  }

  // Метод для Редактирование Заметки Лида
  Future<Map<String, dynamic>> updateNotes({
    required int noteId,
    required int leadId,
    required String title,
    required String body,
    DateTime? date,
  }) async {
    date ??= DateTime.now();
    final organizationId = await getSelectedOrganization();

    final response = await _patchRequest(
        '/notices/$noteId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'title': title,
          'body': body,
          'lead_id': leadId,
          'date': date.toIso8601String(),
        });

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Заметка успешно обновлена'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('title')) {
        return {'success': false, 'message': 'error_field_is_not_empty'};
      } else if (response.body.contains('body')) {
        return {'success': false, 'message': 'error_field_is_not_empty'};
      } else if (response.body.contains('date')) {
        return {'success': false, 'message': 'error_valid_date'};
      } else {
        return {'success': false, 'message': 'unknown_error'};
      }
    } else {
      return {'success': false, 'message': 'error_update_note'};
    }
  }

// Метод для Удаления Заметки Лида
  Future<Map<String, dynamic>> deleteNotes(int noteId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _deleteRequest(
        '/notices/$noteId${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete note!');
    }
  }

// Метод для Получения Сделки в Окно Лида
  Future<List<LeadDeal>> getLeadDeals(int leadId,
      {int page = 1, int perPage = 20}) async {
    final organizationId = await getSelectedOrganization();
    final path =
        '/deal/get-by-lead-id/$leadId?page=$page&per_page=$perPage&organization_id=$organizationId';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result']['data'] as List)
          .map((deal) => LeadDeal.fromJson(deal))
          .toList();
    } else {
      throw Exception('Ошибка загрузки заметок');
    }
  }

// Обновленный метод createLead
  Future<Map<String, dynamic>> createLead({
    required String name,
    required int leadStatusId,
    required String phone,
    int? regionId,
    int? managerId,
    int? sourceId,
    String? instaLogin,
    String? facebookLogin,
    String? tgNick,
    DateTime? birthday,
    String? email,
    String? description,
    String? waPhone,
    List<Map<String, String>>? customFields,
    String? manager, // Добавляем параметр для "system"
  }) async {
    final organizationId = await getSelectedOrganization();

    final Map<String, dynamic> requestData = {
      'name': name,
      'lead_status_id': leadStatusId,
      'phone': phone,
      'position': 1,
      if (regionId != null) 'region_id': regionId,
      if (managerId != null) 'manager_id': managerId,
      if (manager != null)
        'manager': manager, // Добавляем "manager" если он есть
      if (sourceId != null) 'source_id': sourceId,
      if (instaLogin != null) 'insta_login': instaLogin,
      if (facebookLogin != null) 'facebook_login': facebookLogin,
      if (tgNick != null) 'tg_nick': tgNick,
      if (birthday != null) 'birthday': birthday.toIso8601String(),
      if (email != null) 'email': email,
      if (description != null) 'description': description,
      if (waPhone != null) 'wa_phone': waPhone,
      'lead_custom_fields': customFields?.map((field) {
            return {
              'key': field.keys.first,
              'value': field.values.first,
            };
          }).toList() ??
          [],
    };

    final response = await _postRequest(
      '/lead${organizationId != null ? '?organization_id=$organizationId' : ''}',
      requestData,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'lead_created_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      }
      if (response.body
          .contains('The email field must be a valid email address.')) {
        return {'success': false, 'message': 'error_enter_email'};
      }
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'invalid_name_length'};
      } else if (response.body.contains('insta_login')) {
        return {'success': false, 'message': 'instagram_login_exists'};
      } else if (response.body.contains('facebook_login')) {
        return {'success': false, 'message': 'facebook_login_exists'};
      } else if (response.body.contains('tg_nick')) {
        return {'success': false, 'message': 'telegram_nick_exists'};
      } else if (response.body.contains('birthday')) {
        return {'success': false, 'message': 'invalid_birthday'};
      } else if (response.body.contains('wa_phone')) {
        return {'success': false, 'message': 'whatsapp_number_exists'};
      } else {
        return {'success': false, 'message': 'unknown_error'};
      }
    } else if (response.statusCode == 500) {
      return {'success': false, 'message': 'error_server_text'};
    } else {
      return {'success': false, 'message': 'lead_creation_error'};
    }
  }

// Новый метод для работы с динамическими данными
  Future<Map<String, dynamic>> createLeadWithData(
      Map<String, dynamic> data) async {
    final organizationId = await getSelectedOrganization();
    if (organizationId != null) {
      data['organization_id'] = organizationId;
    }

    final response = await _postRequest(
      '/lead${organizationId != null ? '?organization_id=$organizationId' : ''}',
      data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'lead_created_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      }
      if (response.body
          .contains('The email field must be a valid email address.')) {
        return {'success': false, 'message': 'error_enter_email'};
      }
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'invalid_name_length'};
      } else if (response.body.contains('insta_login')) {
        return {'success': false, 'message': 'instagram_login_exists'};
      } else if (response.body.contains('facebook_login')) {
        return {'success': false, 'message': 'facebook_login_exists'};
      } else if (response.body.contains('tg_nick')) {
        return {'success': false, 'message': 'telegram_nick_exists'};
      } else if (response.body.contains('birthday')) {
        return {'success': false, 'message': 'invalid_birthday'};
      } else if (response.body.contains('wa_phone')) {
        return {'success': false, 'message': 'whatsapp_number_exists'};
      } else {
        return {'success': false, 'message': 'unknown_error'};
      }
    } else if (response.statusCode == 500) {
      return {'success': false, 'message': 'error_server_text'};
    } else {
      return {'success': false, 'message': 'lead_creation_error'};
    }
  }

  // Метод для Обновления Лида
  Future<Map<String, dynamic>> updateLead({
    required int leadId,
    required String name,
    required int leadStatusId,
    required String phone,
    int? regionId,
    int? sourceId,
    int? managerId,
    String? instaLogin,
    String? facebookLogin,
    String? tgNick,
    DateTime? birthday,
    String? email,
    String? description,
    String? waPhone,
    List<Map<String, String>>? customFields,
  }) async {
    final organizationId = await getSelectedOrganization();

    final Map<String, dynamic> requestData = {
      'name': name,
      'lead_status_id': leadStatusId,
      'phone': phone,
      if (regionId != null) 'region_id': regionId,
      if (sourceId != null) 'source_id': sourceId,
      if (managerId != null) 'manager_id': managerId,
      if (instaLogin != null) 'insta_login': instaLogin,
      if (facebookLogin != null) 'facebook_login': facebookLogin,
      if (tgNick != null) 'tg_nick': tgNick,
      if (birthday != null) 'birthday': birthday.toIso8601String(),
      if (email != null) 'email': email,
      if (description != null) 'description': description,
      if (waPhone != null) 'wa_phone': waPhone,
      'lead_custom_fields': customFields
              ?.map((field) => {
                    'key': field.keys.first,
                    'value': field.values.first,
                  })
              .toList() ??
          [],
    };

    final response = await _patchRequest(
      '/lead/$leadId${organizationId != null ? '?organization_id=$organizationId' : ''}',
      requestData,
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'lead_updated_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      return {'success': false, 'message': 'unknown_error'};
    } else {
      return {'success': false, 'message': 'error_update_lead'};
    }
  }

  Future<Map<String, dynamic>> updateLeadWithData({
    required int leadId,
    required Map<String, dynamic> data,
  }) async {
    final organizationId = await getSelectedOrganization();
    if (organizationId != null) {
      data['organization_id'] = organizationId;
    }

    final response = await _patchRequest(
      '/lead/$leadId${organizationId != null ? '?organization_id=$organizationId' : ''}',
      data,
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'lead_updated_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      return {'success': false, 'message': 'unknown_error'};
    } else {
      return {'success': false, 'message': 'error_update_lead'};
    }
  }

// Api Service
  Future<DealNameDataResponse> getAllDealNames() async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
        '/service${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DealNameDataResponse.fromJson(data);
    } else {
      throw ('Failed to load deal names');
    }
  }

  //Метод для получения региона
  Future<RegionsDataResponse> getAllRegion() async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
        '/region${organizationId != null ? '?organization_id=$organizationId' : ''}');

    late RegionsDataResponse dataRegion;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataRegion = RegionsDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }

    if (kDebugMode) {
      // print('getAll region!');
    }

    return dataRegion;
  }

  //Метод для получения региона
// In your ApiService
  Future<List<SourceData>> getAllSource() async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
        '/source${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null) {
        List<SourceData> dataSource = List<SourceData>.from(
            data.map((source) => SourceData.fromJson(source)));
        return dataSource;
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }
  }

  //Метод для получения Менеджера
  Future<ManagersDataResponse> getAllManager() async {
    final organizationId = await getSelectedOrganization();

    // Используем общий метод для выполнения GET-запроса
    final response = await _getRequest(
        '/manager${organizationId != null ? '?organization_id=$organizationId' : ''}');

    late ManagersDataResponse dataManager;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataManager = ManagersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }

    if (kDebugMode) {}

    return dataManager;
  }

//Метод для получения Менеджера
  Future<LeadsMultiDataResponse> getAllLeadMulti() async {
    final organizationId = await getSelectedOrganization();

    // Используем общий метод для выполнения GET-запроса
    final response = await _getRequest(
        '/lead${organizationId != null ? '?organization_id=$organizationId' : ''}');

    late LeadsMultiDataResponse dataLead;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataLead = LeadsMultiDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }

    if (kDebugMode) {}

    return dataLead;
  }

  //Метод для получения лида
  Future<LeadsDataResponse> getAllLead() async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
        '/lead${organizationId != null ? '?organization_id=$organizationId' : ''}');

    late LeadsDataResponse dataLead;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        dataLead = LeadsDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }

    if (kDebugMode) {}

    return dataLead;
  }

  // Метод для Удаления Статуса Лида
  Future<Map<String, dynamic>> deleteLeadStatuses(int leadStatusId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _deleteRequest(
        '/lead-status/$leadStatusId${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete leadStatus!');
    }
  }

// Метод для изменения статуса лида в ApiService
  Future<Map<String, dynamic>> updateLeadStatusEdit(
      int leadStatusId, String title, bool isSuccess, bool isFailure) async {
    final organizationId = await getSelectedOrganization();

    final payload = {
      "title": title,
      "is_success": isSuccess ? 1 : 0,
      "is_failure": isFailure ? 1 : 0,
      "organization_id": organizationId,
    };

    final response = await _patchRequest(
      '/lead-status/$leadStatusId${organizationId != null ? '?organization_id=$organizationId' : ''}',
      payload, // Исправлено: Передача `payload` как второго аргумента
    );

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to update leadStatus!');
    }
  }

// Метод для Удаления Лида
  Future<Map<String, dynamic>> deleteLead(int leadId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _deleteRequest(
        '/lead/$leadId${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete lead!');
    }
  }

  // Метод для Получения Сделки в Окно Лида
  Future<List<ContactPerson>> getContactPerson(int leadId) async {
    final organizationId = await getSelectedOrganization();
    final path = '/contactPerson/$leadId?organization_id=$organizationId';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result'] as List)
          .map((contactPerson) => ContactPerson.fromJson(contactPerson))
          .toList();
    } else {
      throw Exception('Ошибка загрузки Контактное Лицо ');
    }
  }

  // Метод для Создания Контактного Лица
  Future<Map<String, dynamic>> createContactPerson({
    required int leadId,
    required String name,
    required String phone,
    required String position,
  }) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
        '/contactPerson${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'lead_id': leadId,
          'name': name,
          'phone': phone,
          'position': position,
        });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'contact_create_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      } else if (response.body.contains('position')) {
        return {'success': false, 'message': 'field_is_not_empty'};
      } else {
        return {'success': false, 'message': 'unknown_error'};
      }
    } else {
      return {'success': false, 'message': 'error_contact_create'};
    }
  }

  // Метод для Создания Контактного Лица
  Future<Map<String, dynamic>> updateContactPerson({
    required int leadId,
    required int contactpersonId,
    required String name,
    required String phone,
    required String position,
  }) async {
    final organizationId = await getSelectedOrganization();

    final response = await _patchRequest(
        '/contactPerson/$contactpersonId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'lead_id': leadId,
          'name': name,
          'phone': phone,
          'position': position,
        });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'contact_update_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      if (response.body.contains('The phone has already been taken.')) {
        return {'success': false, 'message': 'phone_already_exists'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      } else if (response.body.contains('position')) {
        return {'success': false, 'message': 'field_is_not_empty'};
      } else {
        return {'success': false, 'message': 'unknown_error'};
      }
    } else {
      return {'success': false, 'message': 'error_contact_update_successfully'};
    }
  }

// Метод для Удаления конатного Лица
  Future<Map<String, dynamic>> deleteContactPerson(int contactpersonId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _deleteRequest(
        '/contactPerson/$contactpersonId${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete contactPerson!');
    }
  }

  // Метод для Получения Чата в Окно Лида
  Future<List<LeadNavigateChat>> getLeadToChat(int leadId) async {
    final organizationId = await getSelectedOrganization();
    final path = '/lead/$leadId/chats?organization_id=$organizationId';

    final response = await _getRequest(path);
    print('Request path: $path');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result'] as List)
          .map((leadtochat) => LeadNavigateChat.fromJson(leadtochat))
          .toList();
    } else {
      throw Exception('Ошибка загрузки чата в Лид');
    }
  }

// Метод для получения Источников
  Future<List<SourceLead>> getSourceLead() async {
    final organizationId = await getSelectedOrganization();
    final path = '/source?organization_id=$organizationId';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Полученные данные: $data');
      return (data as List)
          .map((sourceLead) => SourceLead.fromJson(sourceLead))
          .toList();
    } else {
      throw Exception('Ошибка загрузки источников');
    }
  }

  /// Метод для отправки на 1С
  Future<void> postLeadToC(int leadId) async {
    try {
      final organizationId = await getSelectedOrganization();
      final path =
          '/lead/sendToOneC/$leadId${organizationId != null ? '?organization_id=$organizationId' : ''}';

      final response = await _postRequest(path, {});

      if (response.statusCode == 200) {
        print('Успешно отправлено в 1С');
      } else {
        print('Ошибка отправки в 1С Лид!');
        throw Exception('Ошибка отправки в 1С!');
      }
    } catch (e) {
      print('Произошла ошибка!');
      throw Exception('Ошибка отправки в 1С!');
    }
  }
  // Future postLeadToC(int leadId) async {
  //   try {
  //     final organizationId = await getSelectedOrganization();

  //     // Формируем URL с параметрами запроса
  //     final path =
  //         '/lead/sendToOneC/$leadId${organizationId != null ? '?organization_id=$organizationId' : ''}';

  //     // Выполняем POST-запрос (без тела)
  //     final response = await _postRequest(path, {});

  //     if (response.statusCode == 200) {
  //       // final data = jsonDecode(response.body);
  //       print("------------------------------------------------------------------------------------");
  //       print('LEAD TO 1C');
  //       // print(data);

  //       // return data;
  //     } else {
  //       print('Ошибка отправки в  1С Лид!');
  //       throw Exception('Ошибка отправки в  Лид 1С!');
  //     }
  //   } catch (e) {
  //     print('Произошла ошибка!');
  //     throw Exception('Ошибка отправки 1С Лид!');
  //   }
  // }

// Метод для Обновления Данных 1С
  Future getData1C() async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
        '/get-all-data${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return (data['result'] as List).toList();
      } else {
        // throw Exception('Результат отсутствует в ответе');
      }
    } else if (response.statusCode == 500) {
      throw Exception('Ошибка сервера (500): Внутреняя ошибка сервера');
    } else if (response.statusCode == 422) {
      throw Exception('Ошибка валидации (422): Некорректные данные');
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

//Метод для получение кастомных полей Задачи
  Future<Map<String, dynamic>> getCustomFieldslead() async {
    final organizationId = await getSelectedOrganization();

    // Выполняем запрос
    final response = await _getRequest(
      '/lead/get/custom-fields${organizationId != null ? '?organization_id=$organizationId' : ''}',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return data; // Возвращаем данные, если они есть
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

  Future<LeadStatus> getLeadStatus(int leadStatusId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
      '/lead-status/$leadStatusId${organizationId != null ? '?organization_id=$organizationId' : ''}',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != null) {
        return LeadStatus.fromJson(data['result']);
      }
      throw Exception('Invalid response format');
    } else {
      throw Exception('Failed to fetch deal status!');
    }
  }

  Future<Map<String, dynamic>> addLeadsFromContacts(
      int statusId, List<Map<String, dynamic>> contacts) async {
    final organizationId = await getSelectedOrganization();
    final response = await _postRequest(
      '/lead/insert/${organizationId != null ? '?organization_id=$organizationId' : ''}',
      {
        'leads': contacts,
      },
    );

    // Parse the response body
    final responseData = json.decode(response.body);

    // If status code is not 200, throw an exception with the response data
    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    // Return the response data even for 200 status code
    // since it may contain partial errors
    return responseData;
  }
  //_________________________________ END_____API__SCREEN__LEAD____________________________________________//

  //_________________________________ START___API__SCREEN__DEAL____________________________________________//

//Метод для получения Сделки через его ID
  Future<DealById> getDealById(int dealId) async {
    try {
      final organizationId = await getSelectedOrganization();

      final response = await _getRequest(
          '/deal/$dealId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic>? jsonDeal = decodedJson['result'];

        if (jsonDeal == null || jsonDeal['deal_status'] == null) {
          throw Exception('Некорректные данные от API');
        }

        return DealById.fromJson(jsonDeal, jsonDeal['deal_status']['id'] ?? 0);
      } else {
        throw Exception('Ошибка загрузки deal ID!');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки deal ID!');
    }
  }

  Future<List<Deal>> getDeals(
    int? dealStatusId, {
    int page = 1,
    int perPage = 20,
    String? search,
    List<int>? managers,
    List<int>? leads,
    int? statuses,
    DateTime? fromDate,
    DateTime? toDate,
    int? daysWithoutActivity,
    bool? hasTasks,
  }) async {
    final organizationId = await getSelectedOrganization();
    String path = '/deal?page=$page&per_page=$perPage';
    path += '&organization_id=$organizationId';

    bool hasFilters = (search != null && search.isNotEmpty) ||
        (managers != null && managers.isNotEmpty) ||
        (leads != null && leads.isNotEmpty) ||
        (fromDate != null) ||
        (toDate != null) ||
        (daysWithoutActivity != null) ||
        (hasTasks == true) ||
        (statuses != null);

    if (dealStatusId != null && !hasFilters) {
      path += '&deal_status_id=$dealStatusId';
    }

    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    if (managers != null && managers.isNotEmpty) {
      for (int i = 0; i < managers.length; i++) {
        path += '&managers[$i]=${managers[i]}';
      }
    }
    if (leads != null && leads.isNotEmpty) {
      for (int i = 0; i < leads.length; i++) {
        path += '&clients[$i]=${leads[i]}';
      }
    }
    if (daysWithoutActivity != null) {
      path += '&lastUpdate=$daysWithoutActivity';
    }
    if (hasTasks == true) {
      path += '&withTasks=1';
    }
    if (statuses != null) {
      path += '&deal_status_id=$statuses';
    }

    if (fromDate != null && toDate != null) {
      final formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
      final formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);
      path += '&created_from=$formattedFromDate&created_to=$formattedToDate';
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((json) => Deal.fromJson(json, dealStatusId ?? -1))
            .toList();
      } else {
        throw Exception('Нет данных о сделках в ответе');
      }
    } else {
      throw Exception('Ошибка загрузки сделок!');
    }
  }

// Метод для получения статусов Сделок
  Future<List<DealStatus>> getDealStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();

    try {
      // Отправляем запрос на сервер
      final response = await _getRequest(
          '/deal/statuses${organizationId != null ? '?organization_id=$organizationId' : ''}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          // Принт старых кэшированных данных (если они есть)
          final cachedStatuses =
              prefs.getString('cachedDealStatuses_$organizationId');
          if (cachedStatuses != null) {
            final decodedData = json.decode(cachedStatuses);
          }

          // Обновляем кэш новыми данными
          await prefs.setString('cachedDealStatuses_$organizationId',
              json.encode(data['result']));
          // print(
          //     '------------------------------------ Новые данные, которые сохраняются в кэш ---------------------------------');
          // print(data['result']); // Новые данные, которые будут сохранены в кэш

          // print(
          //     '----p---------------¿-----UPDATE CACHE DEALSTATUS----------------------------');
          // print('Статусы сделок обновлены в кэше');

          return (data['result'] as List)
              .map((status) => DealStatus.fromJson(status))
              .toList();
        } else {
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка ${response.statusCode}!');
      }
    } catch (e) {
      print('Ошибка загрузки статусов сделок. Используем кэшированные данные.');
      // Если запрос не удался, пытаемся загрузить данные из кэша
      final cachedStatuses =
          prefs.getString('cachedDealStatuses_$organizationId');
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        final cachedList = (decodedData as List)
            .map((status) => DealStatus.fromJson(status))
            .toList();
        return cachedList;
      } else {
        throw Exception(
            'Ошибка загрузки статусов сделок и отсутствуют кэшированные данные!');
      }
    }
  }

  Future<bool> checkIfStatusHasDeals(int dealStatusId) async {
    try {
      // Получаем список лидов для указанного статуса, берем только первую страницу
      final List<Deal> deals =
          await getDeals(dealStatusId, page: 1, perPage: 1);

      // Если список лидов не пуст, значит статус содержит элементы
      return deals.isNotEmpty;
    } catch (e) {
      print('Error while checking if status has deals!');
      return false;
    }
  }

// Метод для создания Cтатуса Сделки
  Future<Map<String, dynamic>> createDealStatus(
      String title, String color, int? day) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
        '/deal/statuses${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'title': title,
          'day': day,
          'color': color,
        });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'Статус сделки успешно создан'};
    } else {
      return {'success': false, 'message': 'Ошибка создания статуса сделки!'};
    }
  }

  // Метод для получения Истории Лида
  Future<List<DealHistory>> getDealHistory(int dealId) async {
    try {
      final organizationId = await getSelectedOrganization();

      // Используем метод _getRequest вместо прямого выполнения запроса
      final response = await _getRequest(
          '/deal/history/$dealId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => DealHistory.fromJson(json)).toList();
      } else {
        print('Failed to load deal history!');
        throw Exception('Ошибка загрузки истории сделки!');
      }
    } catch (e) {
      print('Error occurred!');
      throw Exception('Ошибка загрузки истории сделки!');
    }
  }

  //Обновление статуса карточки Сделки  в колонке
  Future<void> updateDealStatus(int dealId, int position, int statusId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
      '/deal/changeStatus/$dealId${organizationId != null ? '?organization_id=$organizationId' : ''}',
      {
        'position': 1,
        'status_id': statusId,
      },
    );

    if (response.statusCode == 200) {
      print('Статус задачи успешно обновлен.');
    } else if (response.statusCode == 422) {
      throw DealStatusUpdateException(
        422,
        'Вы не можете переместить задачу на этот статус',
      );
    } else {
      throw Exception('Ошибка обновления задач сделки!');
    }
  }

  // Метод для Получения Сделки в Окно Лида
  Future<List<DealTask>> getDealTasks(int dealId) async {
    final organizationId = await getSelectedOrganization();
    final path = '/task/getByDeal/$dealId?organization_id=$organizationId';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result'] as List)
          .map((task) => DealTask.fromJson(task))
          .toList();
    } else {
      throw Exception('Ошибка загрузки сделки задачи');
    }
  }

// Метод для создания Сделки
  Future<Map<String, dynamic>> createDeal({
    required String name,
    required int dealStatusId,
    required int? managerId,
    required DateTime? startDate,
    required DateTime? endDate,
    required String sum,
    String? description,
    int? dealtypeId,
    required int? leadId,
    List<Map<String, String>>? customFields,
  }) async {
    final requestBody = {
      'name': name,
      'deal_status_id': dealStatusId,
      'position': 1,
      if (managerId != null) 'manager_id': managerId,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      'sum': sum,
      if (description != null) 'description': description,
      if (dealtypeId != null) 'deal_type_id': dealtypeId,
      if (leadId != null) 'lead_id': leadId,
      // Здесь добавляем deal_custom_fields
      'deal_custom_fields': customFields?.map((field) {
            // Изменяем структуру для соответствия новому формату
            return {
              'key': field.keys.first,
              'value': field.values.first,
            };
          }).toList() ??
          [],
    };
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
        '/deal${organizationId != null ? '?organization_id=$organizationId' : ''}',
        requestBody);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'deal_create_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      // Другие проверки на ошибки...
      return {'success': false, 'message': 'unknown_error'};
    } else if (response.statusCode == 500) {
      return {'success': false, 'message': 'error_server_text'};
    } else {
      return {'success': false, 'message': 'error_deal_create_successfully'};
    }
  }

  // Метод для обновления сделки
  Future<Map<String, dynamic>> updateDeal({
    required int dealId,
    required String name,
    required int dealStatusId,
    required int? managerId,
    required DateTime? startDate,
    required DateTime? endDate,
    required String sum,
    String? description,
    int? dealtypeId,
    required int? leadId,
    List<Map<String, String>>? customFields,
  }) async {
    final organizationId = await getSelectedOrganization();

    final response = await _patchRequest(
        '/deal/$dealId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'name': name,
          'deal_status_id': dealStatusId,
          if (managerId != null) 'manager_id': managerId,
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
          'sum': sum,
          if (description != null) 'description': description,
          if (dealtypeId != null) 'deal_type_id': dealtypeId,
          if (leadId != null) 'lead_id': leadId,
          'deal_custom_fields': customFields?.map((field) {
                return {
                  'key': field.keys.first,
                  'value': field.values.first,
                };
              }).toList() ??
              [],
        });

    // Обработка ответа
    if (response.statusCode == 200) {
      return {'success': true, 'message': 'deal_update_successfully'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('"name"')) {
        return {'success': false, 'message': 'invalid_name_length'};
      }
      // Дополнительные проверки на другие поля могут быть добавлены здесь...
      return {'success': false, 'message': 'unknown_error'};
    } else if (response.statusCode == 500) {
      return {'success': false, 'message': 'error_server_text'};
    } else {
      return {'success': false, 'message': 'error_deal_update_successfully'};
    }
  }

  // Метод для Удаления Статуса Лида
  Future<Map<String, dynamic>> deleteDealStatuses(int dealStatusId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _deleteRequest(
        '/deal/statuses/$dealStatusId${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete dealStatus!');
    }
  }

  // Метод для Удаления Сделки
  Future<Map<String, dynamic>> deleteDeal(int dealId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _deleteRequest(
        '/deal/$dealId${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete deal!');
    }
  }

  //Метод для получение кастомных полей Задачи
  Future<Map<String, dynamic>> getCustomFieldsdeal() async {
    final organizationId = await getSelectedOrganization();

    // Выполняем запрос
    final response = await _getRequest(
      '/deal/get/custom-fields${organizationId != null ? '?organization_id=$organizationId' : ''}',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return data; // Возвращаем данные, если они есть
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

// Метод для изменения статуса deal в ApiService
  Future<Map<String, dynamic>> updateDealStatusEdit(int dealStatusId,
      String title, int day, bool isSuccess, bool isFailure) async {
    final organizationId = await getSelectedOrganization();

    final payload = {
      "title": title,
      "day": day,
      "color": "#000",
      "is_success": isSuccess ? 1 : 0,
      "is_failure": isFailure ? 1 : 0,
      "organization_id": organizationId,
    };

    final response = await _patchRequest(
      '/deal/statuses/$dealStatusId${organizationId != null ? '?organization_id=$organizationId' : ''}',
      payload, // Исправлено: Передача `payload` как второго аргумента
    );

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to update leadStatus!');
    }
  }

  Future<DealStatus> getDealStatus(int dealStatusId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
      '/deal/statuses/$dealStatusId${organizationId != null ? '?organization_id=$organizationId' : ''}',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != null) {
        return DealStatus.fromJson(data['result']);
      }
      throw Exception('Invalid response format');
    } else {
      throw Exception('Failed to fetch deal status!');
    }
  }

  //_________________________________ END_____API_SCREEN__DEAL____________________________________________//
  //_________________________________ START___API__SCREEN__TASK____________________________________________//

  //Метод для получения Задачи через его ID
  Future<TaskById> getTaskById(int taskId) async {
    try {
      final organizationId = await getSelectedOrganization();

      final response = await _getRequest(
          '/task/$taskId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic>? jsonTask = decodedJson['result'];

        if (jsonTask == null || jsonTask['taskStatus'] == null) {
          throw Exception('Некорректные данные от API');
        }

        // Используем правильное имя ключа 'taskStatus' для получения статуса задачи
        return TaskById.fromJson(jsonTask, jsonTask['taskStatus']['id'] ?? 0);
      } else if (response.statusCode == 404) {
        throw Exception('Ресурс с задачи $taskId не найден');
      } else if (response.statusCode == 500) {
        throw Exception('Ошибка сервера. Попробуйте позже');
      } else {
        throw Exception('Ошибка загрузки task ID!');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки task ID');
    }
  }

  // API Service
  Future<List<Task>> getTasks(int? taskStatusId,
      {int page = 1,
      int perPage = 20,
      String? search,
      List<int>? users,
      int? statuses,
      DateTime? fromDate,
      DateTime? toDate,
      bool? overdue,
      bool? hasFile,
      bool? hasDeal,
      bool? urgent,
      DateTime? deadlinefromDate,
      DateTime? deadlinetoDate,
      String? project,
      final List<String>? authors,
      String? department}) async {
    final organizationId = await getSelectedOrganization();
    String path = '/task?page=$page&per_page=$perPage';
    path += '&organization_id=$organizationId';
    bool hasFilters = (search != null && search.isNotEmpty) ||
        (users != null && users.isNotEmpty) ||
        (fromDate != null) ||
        (toDate != null) ||
        (statuses != null) ||
        overdue == true ||
        hasFile == true ||
        hasDeal == true ||
        urgent == true ||
        (deadlinefromDate != null) ||
        (deadlinetoDate != null) ||
        (project != null && project.isNotEmpty) ||
        (authors != null && authors.isNotEmpty) ||
        (department != null && department.isNotEmpty);
    if (taskStatusId != null && !hasFilters) {
      path += '&task_status_id=$taskStatusId';
    }
    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }
    if (users != null && users.isNotEmpty) {
      for (int i = 0; i < users.length; i++) {
        path += '&users[$i]=${users[i]}';
      }
    }
    if (statuses != null) {
      path += '&task_status_id=$statuses';
    }
    if (fromDate != null && toDate != null) {
      final formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
      final formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);
      path += '&from=$formattedFromDate&to=$formattedToDate';
    }
    if (overdue == true) {
      path += '&overdue=1';
    }
    if (hasFile == true) {
      path += '&hasFile=1';
    }
    if (hasDeal == true) {
      path += '&hasDeal=1';
    }
    if (urgent == true) {
      path += '&urgent=1';
    }
    if (deadlinefromDate != null && deadlinetoDate != null) {
      final formattedFromDate =
          DateFormat('yyyy-MM-dd').format(deadlinefromDate);
      final formattedToDate = DateFormat('yyyy-MM-dd').format(deadlinetoDate);
      path += '&deadline_from=$formattedFromDate&deadline_to=$formattedToDate';
    }
    if (project != null && project.isNotEmpty) {
      path += '&project=$project';
    }
    if (authors != null && authors.isNotEmpty) {
      for (int i = 0; i < authors.length; i++) {
        path += '&authors[$i]=${authors[i]}';
      }
    }
    if (department != null && department.isNotEmpty) {
      path += '&department_id=$department';
    }

    final response = await _getRequest(path);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((json) => Task.fromJson(json, taskStatusId ?? -1))
            .toList();
      } else {
        throw Exception('Нет данных о задачах в ответе');
      }
    } else {
      print('Error response! - ${response.body}');
      throw Exception('Ошибка загрузки задач!');
    }
  }

// Метод для получения статусов задач
  Future<List<TaskStatus>> getTaskStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();

    try {
      // Отправляем запрос на сервер
      final response = await _getRequest(
          '/task-status${organizationId != null ? '?organization_id=$organizationId' : ''}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          // Принт старых кэшированных данных (если они есть)
          final cachedStatuses =
              prefs.getString('cachedTaskStatuses_$organizationId');
          if (cachedStatuses != null) {
            final decodedData = json.decode(cachedStatuses);
            // print(
            //     '------------------------------ Старые данные в кэше ------------------------------');
            // print(decodedData); // Старые данные
          }

          // Обновляем кэш новыми данными
          await prefs.setString('cachedTaskStatuses_$organizationId',
              json.encode(data['result']));
          // print(
          //     '------------------------------------ Новые данные, которые сохраняются в кэш ---------------------------------');
          // print(data['result']); // Новые данные, которые будут сохранены в кэш

          return (data['result'] as List)
              .map((status) => TaskStatus.fromJson(status))
              .toList();
        } else {
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка ${response.statusCode}!');
      }
    } catch (e) {
      print('Ошибка загрузки статусов задач. Используем кэшированные данные.');
      // Если запрос не удался, пытаемся загрузить данные из кэша
      final cachedStatuses =
          prefs.getString('cachedTaskStatuses_$organizationId');
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        final cachedList = (decodedData as List)
            .map((status) => TaskStatus.fromJson(status))
            .toList();
        return cachedList;
      } else {
        throw Exception(
            'Ошибка загрузки статусов задач и отсутствуют кэшированные данные!');
      }
    }
  }

  Future<bool> checkIfStatusHasTasks(int taskStatusId) async {
    try {
      // Получаем список лидов для указанного статуса, берем только первую страницу
      final List<Task> tasks =
          await getTasks(taskStatusId, page: 1, perPage: 1);

      // Если список лидов не пуст, значит статус содержит элементы
      return tasks.isNotEmpty;
    } catch (e) {
      print('Error while checking if status has deals!');
      return false;
    }
  }

//Обновление статуса карточки Задачи  в колонке

  Future<void> updateTaskStatus(int taskId, int position, int statusId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
        '/task/changeStatus/$taskId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'position': 1,
          'status_id': statusId,
        });

    if (response.statusCode == 200) {
      print('Статус задачи успешно обновлен');
    } else if (response.statusCode == 422) {
      throw TaskStatusUpdateException(
          422, 'Вы не можете переместить задачу на этот статус');
    } else {
      throw Exception('Ошибка обновления задач сделки!');
    }
  }

  Map<String, dynamic> _handleTaskResponse(
      http.Response response, String operation) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);

      // Проверяем наличие ошибок в ответе
      if (data['errors'] != null) {
        return {
          'success': false,
          'message': 'Ошибка ${operation} задачи: ${data['errors']}',
        };
      }

      return {
        'success': true,
        'message':
            'Задача ${operation == 'создания' ? 'создана' : 'обновлена'} успешно.',
        'data': data['result'],
      };
    }

    if (response.statusCode == 422) {
      final data = json.decode(response.body);
      final validationErrors = {
        'name': 'Название задачи должно содержать минимум 3 символа.',
        'from': 'Неверный формат даты начала.',
        'to': 'Неверный формат даты окончания.',
        'project_id': 'Указанный проект не существует.',
        'user_id': 'Указанный пользователь не существует.',
        // Убрана валидация файла
      };

      // Игнорируем ошибки валидации файла
      if (data['errors']?['file'] != null) {
        data['errors'].remove('file');
      }

      // Проверяем каждое поле на наличие ошибки, кроме файла
      for (var entry in validationErrors.entries) {
        if (data['errors']?[entry.key] != null) {
          return {'success': false, 'message': entry.value};
        }
      }

      // Если остались только ошибки файла, считаем что валидация прошла успешно
      if (data['errors']?.isEmpty ?? true) {
        return {
          'success': true,
          'message':
              'Задача ${operation == 'создания' ? 'создана' : 'обновлена'} успешно.',
        };
      }

      return {
        'success': false,
        'message': 'Ошибка валидации: ${data['errors'] ?? response.body}',
      };
    }

    return {
      'success': false,
      'message': 'Ошибка ${operation} задачи!',
    };
  }

  // Общий метод обработки ошибок
  Exception _handleErrorResponse(http.Response response, String operation) {
    try {
      final data = json.decode(response.body);
      final errorMessage = data['errors'] ?? data['message'] ?? response.body;
      return Exception('Ошибка ${operation}! - $errorMessage');
    } catch (e) {
      return Exception('Ошибка ${operation}! - ${response.body}');
    }
  }

  /// Создает новый статус задачи
  Future<Map<String, dynamic>> CreateTaskStatusAdd({
    required int taskStatusNameId,
    required int projectId,
    required bool needsPermission,
    List<int>? roleIds,
    bool? finalStep,
  }) async {
    try {
      // Формируем данные для запроса
      final Map<String, dynamic> data = {
        'task_status_name_id': taskStatusNameId,
        'project_id': projectId,
        'needs_permission': needsPermission ? 1 : 0,
      };

      // Добавляем final_step, если оно не null
      if (finalStep != null) {
        data['final_step'] = finalStep;
      }

      // Обрабатываем список ролей, если он существует
      if (roleIds != null && roleIds.isNotEmpty) {
        data['roles'] = roleIds.map((roleId) => {'role_id': roleId}).toList();
      }

      // Получаем идентификатор организации
      final organizationIdProfile = await getSelectedOrganization();

      // Выполняем запрос
      final response = await _postRequest(
        '/task-status${organizationIdProfile != null ? '?organization_id=$organizationIdProfile' : ''}',
        data,
      );

      // Проверяем статус ответа
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Статус задачи успешно создан',
          'data': responseData,
        };
      }

      // Обрабатываем различные коды ошибок
      String errorMessage;
      switch (response.statusCode) {
        case 400:
          errorMessage = 'Неверные данные запроса';
          break;
        case 401:
          errorMessage = 'Необходима авторизация';
          break;
        case 403:
          errorMessage = 'Недостаточно прав для создания статуса';
          break;
        case 404:
          errorMessage = 'Ресурс не найден';
          break;
        case 409:
          errorMessage = 'Конфликт при создании статуса';
          break;
        case 500:
          errorMessage = 'Внутренняя ошибка сервера';
          break;
        default:
          errorMessage = 'Произошла ошибка при создании статуса';
      }

      return {
        'success': false,
        'message': '$errorMessage!',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка при выполнении запроса!',
        'error': e.toString(),
      };
    }
  }

// Метод для создание задачи из сделки
  Future<Map<String, dynamic>> createTaskFromDeal({
    required int dealId,
    required String name,
    required int? statusId,
    required int? taskStatusId,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? projectId,
    List<int>? userId,
    String? description,
    List<Map<String, String>>? customFields,
    List<String>? filePaths, // Список путей к файлам
    int position = 1,
  }) async {
    try {
      final token = await getToken();
      final organizationId = await getSelectedOrganization();
      var uri = Uri.parse(
          '${baseUrl}/task/createFromDeal/$dealId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      request.fields['name'] = name;
      request.fields['task_status_id'] = taskStatusId.toString();
      request.fields['position'] = position.toString();

      if (priority != null) {
        request.fields['priority_level'] = priority.toString();
      }
      if (startDate != null) {
        request.fields['from'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        request.fields['to'] = endDate.toIso8601String();
      }
      if (projectId != null) {
        request.fields['project_id'] = projectId.toString();
      }
      if (description != null) {
        request.fields['description'] = description;
      }

      if (userId != null && userId.isNotEmpty) {
        for (int i = 0; i < userId.length; i++) {
          request.fields['users[$i][user_id]'] = userId[i].toString();
        }
      }

      if (customFields != null && customFields.isNotEmpty) {
        for (int i = 0; i < customFields.length; i++) {
          var field = customFields[i];
          request.fields['task_custom_fields[$i][key]'] = field.keys.first;
          request.fields['task_custom_fields[$i][value]'] = field.values.first;
        }
      }

      // Добавляем файлы, если они есть
      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath(
              'files[]', filePath); // Используем 'files[]'
          request.files.add(file);
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'task_deal_create_successfully',
        };
      } else if (response.statusCode == 422) {
        if (response.body.contains('name')) {
          return {
            'success': false,
            'message': 'invalid_name_length',
          };
        }
        if (response.statusCode == 500) {
          return {'success': false, 'message': 'error_server_text'};
        }
        if (response.body.contains('from')) {
          return {
            'success': false,
            'message': 'error_start_date_task',
          };
        }
        if (response.body.contains('to')) {
          return {
            'success': false,
            'message': 'error_end_date_task',
          };
        }
        if (response.body.contains('priority_level')) {
          return {
            'success': false,
            'message': 'error_priority_level',
          };
        }
        return {
          'success': false,
          'message': 'unknown_error',
        };
      } else {
        return {
          'success': false,
          'message': 'error_create_task',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'error_create_task',
      };
    }
  }

/*
// Метод для создание задачи
  Future<Map<String, dynamic>> createTask({
    required String name,
    required int? statusId,
    required int? taskStatusId,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? projectId,
    List<int>? userId,
    String? description,
    List<Map<String, String>>? customFields,
    String? filePath,
    int position = 1,
  }) async {
    try {
      final token = await getToken(); // Получаем токен
      final organizationId = await getSelectedOrganization();
      var uri = Uri.parse(
          '${baseUrl}/task${organizationId != null ? '?organization_id=$organizationId' : ''}');

      // Создаем multipart request
      var request = http.MultipartRequest('POST', uri);

      // Добавляем заголовки с токеном
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      // Добавляем все поля в формате form-data
      request.fields['name'] = name;
      request.fields['status_id'] = statusId.toString();
      request.fields['task_status_id'] = taskStatusId.toString();
      request.fields['position'] = position.toString();

      if (priority != null) {
        request.fields['priority_level'] = priority.toString();
      }
      if (startDate != null) {
        request.fields['from'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        request.fields['to'] = endDate.toIso8601String();
      }
      if (projectId != null) {
        request.fields['project_id'] = projectId.toString();
      }
      if (description != null) {
        request.fields['description'] = description;
      }

      // Добавляем пользователей
      if (userId != null && userId.isNotEmpty) {
        for (int i = 0; i < userId.length; i++) {
          request.fields['users[$i][user_id]'] = userId[i].toString();
        }
      }

      // Добавляем кастомные поля
      if (customFields != null && customFields.isNotEmpty) {
        for (int i = 0; i < customFields.length; i++) {
          var field = customFields[i];
          request.fields['task_custom_fields[$i][key]'] = field.keys.first;
          request.fields['task_custom_fields[$i][value]'] = field.values.first;
        }
      }

      // Добавляем файл, если он есть
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          final fileName = file.path.split('/').last;
          final fileStream = http.ByteStream(file.openRead());
          final length = await file.length();

          final multipartFile = http.MultipartFile(
            'file',
            fileStream,
            length,
            filename: fileName,
          );
          request.files.add(multipartFile);
        }
      }

      // Отправляем запрос
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'task_create_successfully',
        };
      } else if (response.statusCode == 422) {
        // Обработка ошибок валидации
        if (response.body.contains('name')) {
          return {
            'success': false,
            'message': 'invalid_name_length',
          };
        }
        if (response.body.contains('from')) {
          return {
            'success': false,
            'message': 'error_start_date_task',
          };
        }
        if (response.body.contains('to')) {
          return {
            'success': false,
            'message': 'error_end_date_task',
          };
        }
        if (response.body.contains('priority_level')) {
          return {
            'success': false,
            'message': 'error_priority_level',
          };
        }
        return {
          'success': false,
          'message': 'unknown_error',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'error_server_text',
        };
      } else {
        return {
          'success': false,
          'message': 'error_create_task',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'error_create_task',
      };
    }
  }*/
// Метод для создание задачи
  Future<Map<String, dynamic>> createTask({
    required String name,
    required int? statusId,
    required int? taskStatusId,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? projectId,
    List<int>? userId,
    String? description,
    List<Map<String, String>>? customFields,
    List<String>? filePaths, // Список путей к файлам
    int position = 1,
  }) async {
    try {
      final token = await getToken(); // Получаем токен
      final organizationId = await getSelectedOrganization();
      var uri = Uri.parse(
          '${baseUrl}/task${organizationId != null ? '?organization_id=$organizationId' : ''}');

      // Создаем multipart request
      var request = http.MultipartRequest('POST', uri);

      // Добавляем заголовки с токеном
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      // Добавляем все поля в формате form-data
      request.fields['name'] = name;
      request.fields['status_id'] = statusId.toString();
      request.fields['task_status_id'] = taskStatusId.toString();
      request.fields['position'] = position.toString();

      if (priority != null) {
        request.fields['priority_level'] = priority.toString();
      }
      if (startDate != null) {
        request.fields['from'] = startDate.toString().split(' ')[0];
      }
      if (endDate != null) {
        request.fields['to'] = endDate.toString().split(' ')[0];
      }

      if (projectId != null) {
        request.fields['project_id'] = projectId.toString();
      }
      if (description != null) {
        request.fields['description'] = description;
      }

      // Добавляем пользователей
      if (userId != null && userId.isNotEmpty) {
        for (int i = 0; i < userId.length; i++) {
          request.fields['users[$i][user_id]'] = userId[i].toString();
        }
      }

      // Добавляем кастомные поля
      if (customFields != null && customFields.isNotEmpty) {
        for (int i = 0; i < customFields.length; i++) {
          var field = customFields[i];
          request.fields['task_custom_fields[$i][key]'] = field.keys.first;
          request.fields['task_custom_fields[$i][value]'] = field.values.first;
        }
      }

      // Добавляем файлы, если они есть
      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath(
              'files[]', filePath); // Используем 'files[]'
          request.files.add(file);
        }
      }

      // Отправляем запрос
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'task_create_successfully',
        };
      } else if (response.statusCode == 422) {
        // Обработка ошибок валидации
        if (response.body.contains('name')) {
          return {
            'success': false,
            'message': 'invalid_name_length',
          };
        }
        if (response.body.contains('from')) {
          return {
            'success': false,
            'message': 'error_start_date_task',
          };
        }
        if (response.body.contains('to')) {
          return {
            'success': false,
            'message': 'error_end_date_task',
          };
        }
        if (response.body.contains('priority_level')) {
          return {
            'success': false,
            'message': 'error_priority_level',
          };
        }
        return {
          'success': false,
          'message': 'unknown_error',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'error_server_text',
        };
      } else {
        return {
          'success': false,
          'message': 'error_create_task',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'error_create_task',
      };
    }
  }

  //Метод для обновление задачи
  Future<Map<String, dynamic>> updateTask({
    required int taskId,
    required String name,
    required int taskStatusId,
    String? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? projectId,
    List<int>? userId,
    String? description,
    List<String>? filePaths, // Список путей к файлам
    List<Map<String, String>>? customFields,
    List<TaskFiles>?
        existingFiles, // Добавляем параметр для существующих файлов
  }) async {
    try {
      final token = await getToken();
      final organizationId = await getSelectedOrganization();
      var uri = Uri.parse(
          '${baseUrl}/task/$taskId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      // Создаем multipart request
      var request = http.MultipartRequest('POST', uri);

      // Добавляем заголовки с токеном
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      // Добавляем все поля в формате form-data
      request.fields['name'] = name;
      request.fields['task_status_id'] = taskStatusId.toString();
      request.fields['_method'] = 'POST'; // Для эмуляции PUT запроса

      if (priority != null) {
        request.fields['priority_level'] = priority;
      }
      if (startDate != null) {
        request.fields['from'] = startDate.toString().split(' ')[0];
      }
      if (endDate != null) {
        request.fields['to'] = endDate.toString().split(' ')[0];
      }

      if (projectId != null) {
        request.fields['project_id'] = projectId.toString();
      }
      if (description != null) {
        request.fields['description'] = description;
      }

      // Добавляем пользователей
      if (userId != null && userId.isNotEmpty) {
        for (int i = 0; i < userId.length; i++) {
          request.fields['users[$i][user_id]'] = userId[i].toString();
        }
      }

      // Добавляем кастомные поля
      if (customFields != null && customFields.isNotEmpty) {
        for (int i = 0; i < customFields.length; i++) {
          var field = customFields[i];
          request.fields['task_custom_fields[$i][key]'] = field.keys.first;
          request.fields['task_custom_fields[$i][value]'] = field.values.first;
        }
      }

      // Добавляем ID существующих файлов
      if (existingFiles != null && existingFiles.isNotEmpty) {
        for (int i = 0; i < existingFiles.length; i++) {
          request.fields['existing_files[$i]'] = existingFiles[i].id.toString();
        }
      }

      // Добавляем новые файлы
      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath('files[]', filePath);
          request.files.add(file);
        }
      }
      // Отправляем запрос
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'task_update_successfully',
        };
      } else if (response.statusCode == 422) {
        print('Server Response: ${response.body}'); // Добавим для отладки

        // Обработка ошибок валидации
        if (response.body.contains('name')) {
          return {
            'success': false,
            'message': 'invalid_name_length',
          };
        }
        if (response.body.contains('from')) {
          return {
            'success': false,
            'message': 'error_start_date_task',
          };
        }
        if (response.body.contains('to')) {
          return {
            'success': false,
            'message': 'error_end_date_task',
          };
        }
        if (response.body.contains('priority_level')) {
          return {
            'success': false,
            'message': 'error_priority_level',
          };
        }
        return {
          'success': false,
          'message': 'unknown_error',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'error_server_text',
        };
      } else {
        print('Server Response: ${response.body}'); // Добавим для отладки

        return {
          'success': false,
          'message': 'error_task_update_successfully',
        };
      }
    } catch (e) {
      print('Update Task Error: $e'); // Добавим для отладки

      return {
        'success': false,
        'message': 'error_task_update_successfully',
      };
    }
  }

// Метод для получения Истории Задачи
  Future<List<TaskHistory>> getTaskHistory(int taskId) async {
    try {
      final organizationId = await getSelectedOrganization();

      // Используем метод _getRequest вместо прямого выполнения запроса
      final response = await _getRequest(
          '/task/history/$taskId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => TaskHistory.fromJson(json)).toList();
      } else {
        print('Failed to load task history!');
        throw Exception('Ошибка загрузки истории задач!');
      }
    } catch (e) {
      print('Error occurred!');
      throw Exception('Ошибка загрузки истории задач!');
    }
  }

// Метод для получения Проекта
  Future<ProjectsDataResponse> getAllProject() async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
        '/project${organizationId != null ? '?organization_id=$organizationId' : ''}');

    late ProjectsDataResponse dataProject;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataProject = ProjectsDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных!');
    }

    if (kDebugMode) {
    }

    return dataProject;
  }

// Метод для получения Проекта
  Future<ProjectTaskDataResponse> getTaskProject() async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
        '/task/get/projects${organizationId != null ? '?organization_id=$organizationId' : ''}');

    late ProjectTaskDataResponse dataProject;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataProject = ProjectTaskDataResponse.fromJson(data);
      } else {
        throw ('Результат отсутствует в ответе');
      }
    } else if (response.statusCode == 404) {
      throw ('Ресурс не найден');
    } else if (response.statusCode == 500) {
      throw ('Внутренняя ошибка сервера');
    } else {
      throw ('Ошибка при получении данных!');
    }

    if (kDebugMode) {
      // print('getAll project!');
    }

    return dataProject;
  }

  // Метод для получение Пользователя
  Future<List<UserTask>> getUserTask() async {
    try {
      final organizationId = await getSelectedOrganization();

      print('Отправка запроса на /user');
      final response = await _getRequest(
          '/user${organizationId != null ? '?organization_id=$organizationId' : ''}');
      // print('Статус ответа!');
      // print('Тело ответа!');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Убедитесь, что данные соответствуют ожидаемой структуре
        if (data['result'] != null && data['result'] is List) {
          final usersList = (data['result'] as List)
              .map((user) => UserTask.fromJson(user))
              .toList();

          return usersList;
        } else {
          throw Exception('Неверная структура данных пользователей');
        }
      } else {
        throw Exception('Ошибка сервера!');
      }
    } catch (e) {
      rethrow;
    }
  }
  // Future<List<UserTaskAdd>> getUsers() async {
  // final response = await _getRequest('/user');

  // if (response.statusCode == 200) {
  //   final data = json.decode(response.body);
  //   print('Ответ пользователей: $data'); // Для отладки

  //   if (data['users'] != null) {
  //     return (data['users'] as List)
  //         .map((user) => UserTaskAdd.fromJson(user))
  //         .toList();
  //   } else {
  //     throw Exception('Пользователи не найдены');
  //   }
  // } else {
  //   throw Exception('Ошибка ${response.statusCode}!');
  // }}

  // Метод для получение Роли
  Future<List<Role>> getRoles() async {
    final organizationId = await getSelectedOrganization();
    final response = await _getRequest(
        '/role${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return (data['result'] as List)
            .map((role) => Role.fromJson(role))
            .toList();
      } else {
        throw Exception('Роли не найдены');
      }
    } else {
      throw Exception('Ошибка при получении ролей!');
    }
  }

// Метод для получения Cтатуса задачи
  Future<List<StatusName>> getStatusName() async {
    final organizationId = await getSelectedOrganization();

    print('Начало запроса статусов задач'); // Отладочный вывод
    final response = await _getRequest(
        '/taskStatusName${organizationId != null ? '?organization_id=$organizationId' : ''}');
    print('Статус код ответа!'); // Отладочный вывод

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Полученные данные: $data'); // Отладочный вывод

      if (data['result'] != null) {
        final statusList = (data['result'] as List)
            .map((name) => StatusName.fromJson(name))
            .toList();
        print(
            'Преобразованный список статусов: $statusList'); // Отладочный вывод
        return statusList;
      } else {
        throw Exception('Статусы задач не найдены');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

  // Метод для Удаления Задачи
  Future<Map<String, dynamic>> deleteTask(int taskId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _deleteRequest(
        '/task/$taskId${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete task!');
    }
  }

  // Метод для Удаления Статуса Задачи

  Future<Map<String, dynamic>> deleteTaskStatuses(int taskStatusId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _deleteRequest(
        '/task-status/$taskStatusId${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete taskStatus!');
    }
  }

  // Метод для завершения задачи


Future<Map<String, dynamic>> finishTask(int taskId) async {
  final organizationId = await getSelectedOrganization();

  final response = await _postRequest(
      '/task/finish${organizationId != null ? '?organization_id=$organizationId' : ''}',
      {
        'task_id': taskId,
      });

  if (response.statusCode == 200 || response.statusCode == 201) {
    return {'success': true, 'message': 'Задача успешно завершена'};
  } else if (response.statusCode == 422) {
    try {
      final responseData = jsonDecode(response.body);
      final errorMessage = responseData['message'] ?? 'Неизвестная ошибка при завершении задачи';
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка обработки ответа сервера',
      };
    }
  } else {
    return {'success': false, 'message': 'Ошибка завершения задачи!'};
  }
}

  //Метод для получение кастомных полей Задачи
  Future<Map<String, dynamic>> getCustomFields() async {
    final organizationId = await getSelectedOrganization();

    // Выполняем запрос
    final response = await _getRequest(
      '/task/get/custom-fields${organizationId != null ? '?organization_id=$organizationId' : ''}',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return data; // Возвращаем данные, если они есть
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

  Future<TaskStatus> getTaskStatus(int taskStatusId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
      '/task-status/$taskStatusId${organizationId != null ? '?organization_id=$organizationId' : ''}',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != null) {
        return TaskStatus.fromJson(data['result']);
      }
      throw Exception('Invalid response format');
    } else {
      throw Exception('Failed to fetch deal status!');
    }
  }

// Метод для изменения статуса лида в ApiService
  Future<Map<String, dynamic>> updateTaskStatusEdit({
    required int taskStatusId,
    required String name,
    required bool needsPermission,
    required bool finalStep,
    required bool checkingStep,
    required List<int> roleIds,
  }) async {
    final organizationId = await getSelectedOrganization();

    final roles = roleIds.map((roleId) => {"role_id": roleId}).toList();

    final payload = {
      "task_status_name_id": taskStatusId,
      "needs_permission": needsPermission ? 1 : 0,
      "final_step": finalStep ? 1 : 0,
      "checking_step": checkingStep ? 1 : 0,
      "roles": roles,
      "organization_id": organizationId,
    };

    final response = await _patchRequest(
      '/task-status/$taskStatusId${organizationId != null ? '?organization_id=$organizationId' : ''}',
      payload,
    );

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to update task status!');
    }
  }

  Future<Map<String, dynamic>> deleteTaskFile(int fileId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _deleteRequest(
        '/task/deleteFile/$fileId${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete task file!');
    }
  }

  Future<List<Department>> getDepartments() async {
    final organizationId = await getSelectedOrganization();
    final path = '/department?organization_id=$organizationId';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['result']; // Извлекаем массив из ключа "result"
      print('Полученные данные отделов: $result');
      return (result as List)
          .map((department) => Department.fromJson(department))
          .toList();
    } else {
      throw Exception('Ошибка загрузки отделов');
    }
  }
  //_________________________________ END_____API_SCREEN__TASK____________________________________________//

  //_________________________________ START_____API_SCREEN__DASHBOARD____________________________________________//

  /// Получение данных графика для дашборда
  Future<List<ChartData>> getLeadChart() async {
    final organizationId = await getSelectedOrganization();

    String path =
        '/dashboard/lead-chart${organizationId != null ? '?organization_id=$organizationId' : ''}';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        return data.map((json) => ChartData.fromJson(json)).toList();
      } else {
        throw ('Нет данных графика в ответе "Клиенты"');
      }
    } else {
      throw ('Ошибка загрузки данных график клиента!');
    }
  }

  Future<LeadConversion> getLeadConversionData() async {
    final organizationId = await getSelectedOrganization();

    String path =
        '/dashboard/leadConversion-chart${organizationId != null ? '?organization_id=$organizationId' : ''}';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        final conversion = LeadConversion.fromJson(data);
        return conversion;
      } else {
        throw ('Нет данных графика в ответе "Конверсия лидов');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('');
    }
  }

// Метод для получения графика Сделки
  Future<DealStatsResponse> getDealStatsData() async {
    final organizationId = await getSelectedOrganization();

    String path =
        '/dashboard/dealStats${organizationId != null ? '?organization_id=$organizationId' : ''}';
    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DealStatsResponse.fromJson(jsonData);
      } else if (response.statusCode == 500) {
        throw Exception('Ошибка сервера!');
      } else {
        throw Exception('Ошибка загрузки данных!');
      }
    } catch (e) {
      print('Ошибка запроса!');
      throw ('');
    }
  }

// Метод для получения графика Задачи
  Future<TaskChart> getTaskChartData() async {
    final organizationId = await getSelectedOrganization();

    String path =
        '/dashboard/task-chart${organizationId != null ? '?organization_id=$organizationId' : ''}';
    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        if (jsonMap['result'] != null && jsonMap['result']['data'] != null) {
          final taskChart = TaskChart.fromJson(jsonMap);
          return taskChart;
        } else {
          throw ('Нет данных графика в ответе "Задачи');
        }
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера!');
      } else {
        throw ('Ошибка загрузки данных графика!');
      }
    } catch (e) {
      throw ('Ошибка получения данных!');
    }
  }

  // Метод для получения графика Скорость обработки

  Future<ProcessSpeed> getProcessSpeedData() async {
    final organizationId = await getSelectedOrganization();
    final enteredDomainMap = await ApiService().getEnteredDomain();
    // Извлекаем значения из Map
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    String? enteredDomain = enteredDomainMap['enteredDomain'];

    String path =
        '/dashboard/lead-process-speed${organizationId != null ? '?organization_id=$organizationId' : ''}';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        final speed = ProcessSpeed.fromJson(data);
        return speed;
      } else {
        throw ('Нет данных графика в ответе "Скорость обработки"');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('Ошибка загрузки данных графика Скорость обработки');
    }
  }

  Future<List<UserTaskCompletion>> getUsersChartData() async {
    final organizationId = await getSelectedOrganization();
    String path =
        '/dashboard/users-chart${organizationId != null ? '?organization_id=$organizationId' : ''}';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['result'] != null) {
        final List<dynamic> resultList = data['result'];
        return resultList
            .map((item) => UserTaskCompletion.fromJson(item))
            .toList();
      } else {
        throw ('Нет данных графика в ответе "Выполнение целей"');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('Ошибка загрузки данных графика Выролнение целей!');
    }
  }

  //_________________________________ END_____API_SCREEN__DASHBOARD____________________________________________//

  //_________________________________ START_____API_SCREEN__DASHBOARD_Manager____________________________________________//

// Метод для получения графика Сделки
  Future<DealStatsResponseManager> getDealStatsManagerData() async {
    final organizationId = await getSelectedOrganization();

    String path =
        '/dashboard/dealStats/for-manager${organizationId != null ? '?organization_id=$organizationId' : ''}';
    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DealStatsResponseManager.fromJson(jsonData);
      } else if (response.statusCode == 500) {
        throw Exception('Ошибка сервера!');
      } else {
        throw Exception('Ошибка загрузки данных!');
      }
    } catch (e) {
      print('Ошибка запроса!');
      throw ('');
    }
  }

  /// Получение данных графика для дашборда
  Future<List<ChartDataManager>> getLeadChartManager() async {
    final organizationId = await getSelectedOrganization();

    String path =
        '/dashboard/lead-chart/for-manager${organizationId != null ? '?organization_id=$organizationId' : ''}';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        return data.map((json) => ChartDataManager.fromJson(json)).toList();
      } else {
        throw ('Нет данных графика в ответе "Клиенты"');
      }
    } else {
      throw ('Ошибка загрузки данных график клиента!');
    }
  }

  Future<LeadConversionManager> getLeadConversionDataManager() async {
    final organizationId = await getSelectedOrganization();

    String path =
        '/dashboard/leadConversion-chart/for-manager${organizationId != null ? '?organization_id=$organizationId' : ''}';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        final conversion = LeadConversionManager.fromJson(data);
        return conversion;
      } else {
        throw ('Нет данных графика в ответе "Конверсия лидов');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('');
    }
  }

  Future<ProcessSpeedManager> getProcessSpeedDataManager() async {
    final organizationId = await getSelectedOrganization();

    String path =
        '/dashboard/lead-process-speed/for/manager${organizationId != null ? '?organization_id=$organizationId' : ''}';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        final speed = ProcessSpeedManager.fromJson(data);
        return speed;
      } else {
        throw ('Нет данных графика в ответе "Скорость обработки"');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('Ошибка загрузки данных графика Скорость обработки');
    }
  }

  // Метод для получения графика Задачи
  Future<TaskChartManager> getTaskChartDataManager() async {
    final organizationId = await getSelectedOrganization();

    String path =
        '/dashboard/task-chart/for-manager${organizationId != null ? '?organization_id=$organizationId' : ''}';
    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        if (jsonMap['result'] != null && jsonMap['result']['data'] != null) {
          final taskChart = TaskChartManager.fromJson(jsonMap);
          return taskChart;
        } else {
          throw ('Нет данных графика в ответе "Задачи');
        }
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера!');
      } else {
        throw ('Ошибка загрузки данных графика!');
      }
    } catch (e) {
      throw ('Ошибка получения данных!');
    }
  }

// API Service
  Future<UserTaskCompletionManager> getUserStatsManager() async {
    final organizationId = await getSelectedOrganization();

    String path =
        '/dashboard/completed-task-chart${organizationId != null ? '?organization_id=$organizationId' : ''}';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['result'] != null) {
        return UserTaskCompletionManager.fromJson(data);
      } else {
        throw ('Нет данных графика в ответе');
      }
    } else if (response.statusCode == 500) {
      throw ('Ошибка сервера: 500');
    } else {
      throw ('Неизвестная ошибка');
    }
  }

  //_________________________________ END_____API_SCREEN__DASHBOARD__Manager__________________________________________//

  //_________________________________ START_____API_SCREEN__CHATS____________________________________________//

  Future<PaginationDTO<Chats>> getAllChats(String endPoint,
      [int page = 1, String? search]) async {
    final token = await getToken();
    final organizationId = await getSelectedOrganization();

    String url =
        '$baseUrl/chat/getMyChats/$endPoint?page=$page&organization_id=$organizationId';

    if (search != null && search.isNotEmpty) {
      url += '&search=$search'; // Добавляем параметр поиска
    }

    print('Request URL: $url'); // Печать URL запроса

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        // print('Parsed data: ${data['result']}'); // Печать результата парсинга
        return PaginationDTO<Chats>.fromJson(data['result'], (e) {
          return Chats.fromJson(e);
        });
      } else {
        print('No result found in the response');
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      print('Error: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }
  }

  Future<String> sendMessages(List<int> messageIds) async {
    final token = await getToken();
    final organizationId = await getSelectedOrganization();

    // Construct the URL
    final url = Uri.parse('$baseUrl/chat/read?organization_id=$organizationId');

    // Prepare the body
    final body = json.encode({'message_ids': messageIds});

    // Make the POST request
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['message'] ?? 'Success';
    } else {
      throw Exception('Error ${response.statusCode}!');
    }
  }

// Метод для получения сообщений по chatId
  Future<List<Message>> getMessages(
    int chatId, {
    String? search,
  }) async {
    final token = await getToken();
    final organizationId = await getSelectedOrganization();

    String url =
        '$baseUrl/chat/getMessages/$chatId?organization_id=$organizationId';

    if (search != null && search.isNotEmpty) {
      url += '&search=$search';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return (data['result'] as List)
            .map((msg) => Message.fromJson(msg))
            .toList();
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

  Future<void> closeChatSocket(int chatId) async {
    final organizationId = await getSelectedOrganization();
    final response = await _postRequest(
        '/chat/clearCache/$chatId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {});

    if (response.statusCode != 200) {
      throw Exception('close sokcet!');
    }
  }

// Метод для отправки текстового сообщения
  Future<void> sendMessage(int chatId, String message,
      {String? replyMessageId}) async {
    final organizationId = await getSelectedOrganization();
    final response = await _postRequest(
        '/chat/sendMessage/$chatId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'message': message,
          if (replyMessageId != null) 'forwarded_message_id': replyMessageId,
        });

    if (response.statusCode != 200) {
      throw Exception('Ошибка отправки сообщения!');
    }
  }

  Future<void> pinMessage(String messageId) async {
    final organizationId = await getSelectedOrganization();
    final response = await _postRequest(
        '/chat/pinMessage/$messageId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {});

    if (response.statusCode != 200) {
      throw Exception('Ошибка закрепления сообщения!');
    }
  }

  Future<void> unpinMessage(String messageId) async {
    final organizationId = await getSelectedOrganization();
    final response = await _postRequest(
        '/chat/pinMessage/$messageId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {});

    if (response.statusCode != 200) {
      throw Exception('Ошибка закрепления сообщения!');
    }
  }

  Future<void> editMessage(String messageId, String message) async {
    final organizationId = await getSelectedOrganization();
    final response = await _postRequest(
        '/chat/editMessage/$messageId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'message': message,
        });

    if (response.statusCode != 200) {
      throw Exception('Ошибка изменения сообщения!');
    }
  }

  // Метод для отправки audio file
  Future<void> sendChatAudioFile(int chatId, File audio) async {
    final token = await getToken(); // Получаем токен
    final organizationId = await getSelectedOrganization();

    String requestUrl =
        '$baseUrl/chat/sendVoice/$chatId${organizationId != null ? '?organization_id=$organizationId' : ''}';

    Dio dio = Dio();
    try {
      final voice = await MultipartFile.fromFile(audio.path,
          contentType: MediaType('audio', 'm4a')
          // "/Users/diyorjonnasriddinov/Downloads/2024-10-30\ 17.35.27.ogg",
          );
      FormData formData = FormData.fromMap({'voice': voice});

      var response = await dio.post(requestUrl,
          data: formData,
          options: Options(
            headers: {
              "Authorization": "Bearer $token",
              // "Accept": "application/json",
              // 'Content-Type': 'multipart/form-data'
            },
            // contentType: 'multipart/form-data',
          ));
      if (kDebugMode) {
        print('response.statusCode!');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Audio message sent successfully!');
        }
      } else {
        if (kDebugMode) {
          print('Error sending audio message: ${response.data}');
        }
        throw Exception('Error sending audio message: ${response.data}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Exception caught!');
      }
      if (kDebugMode) {
        print(e.response?.data);
      }
      throw Exception('Failed to send audio message due to an exception!');
    }
  }

// Метод для отправки audio file
  Future<void> sendChatFile(int chatId, String pathFile) async {
    final token = await getToken(); // Получаем токен
    final organizationId = await getSelectedOrganization();

    String requestUrl =
        '$baseUrl/chat/sendFile/$chatId${organizationId != null ? '?organization_id=$organizationId' : ''}';

    Dio dio = Dio();
    try {
      FormData formData =
          FormData.fromMap({'file': await MultipartFile.fromFile(pathFile)});

      var response = await dio.post(requestUrl,
          data: formData,
          options: Options(
            headers: {
              "Authorization": "Bearer $token",
              "Accept": "application/json",
              'Device': 'mobile'
            },
            contentType: 'multipart/form-data',
          ));
      if (kDebugMode) {
        print('response.statusCode!');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Audio message sent successfully!');
        }
      } else {
        if (kDebugMode) {
          print('Error sending audio message: ${response.data}');
        }
        throw Exception('Error sending audio message: ${response.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception caught!');
      }
      throw Exception('Failed to send audio message due to an exception!');
    }
  }

  // Метод для отправки файла
  Future<void> sendFile(int chatId, String filePath) async {
    // Если вы используете MultipartRequest для отправки файлов, создайте метод
    // Для упрощения мы будем использовать _postRequest как пример
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
        '/chat/sendFile/$chatId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'file_path':
              filePath, // Убедитесь, что вы используете правильные параметры
        });

    if (response.statusCode != 200) {
      throw Exception('Ошибка отправки файла!');
    }
  }

  // Метод для отправки голосового сообщения
  Future<void> sendVoice(int chatId, String voicePath) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
        '/chat/sendVoice/$chatId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'voice_path':
              voicePath, // Убедитесь, что вы используете правильные параметры
        });

    if (response.statusCode != 200) {
      throw Exception('Ошибка отправки голосового сообщения!');
    }
  }

// //Метод для передачи всех iD-сообщениях чата в сервер
//   Future<void> readChatMessages(int chatId, List<int> messageIds) async {
//     final token = await getToken();
//     final organizationId = await getSelectedOrganization();

//     final url = Uri.parse('$baseUrl/chat/read');

//     try {
//       final response = await http.post(
//         url,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: json.encode({
//           'chat_id': chatId,
//           'organization_id': organizationId,
//           'messages': messageIds,
//         }),
//       );

//       if (response.statusCode == 200) {
//         print('Messages marked as read');
//       } else {
//         print('Error marking messages as read!');
//       }
//     } catch (e) {
//       print('Exception when marking messages as read!');
//     }
//   }

  Future<Map<String, dynamic>> deleteChat(int chatId) async {
    final organizationId = await getSelectedOrganization();

    try {
      final response = await _deleteRequest(
          '/chat/$chatId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return {
          'result': responseBody['result'],
          'errors': responseBody['errors'],
        };
      } else if (response.statusCode == 400) {
        // Ошибка запроса
        throw Exception('Ошибка запроса: Неверные данные');
      } else if (response.statusCode == 401) {
        // Ошибка авторизации
        throw Exception('Ошибка авторизации: Некорректные учетные данные');
      } else if (response.statusCode == 403) {
        // Ошибка доступа
        throw Exception('Ошибка доступа: Недостаточно прав');
      } else if (response.statusCode == 404) {
        // Чат не найден
        throw Exception('Ошибка: Чат не найден');
      } else if (response.statusCode >= 500 && response.statusCode < 600) {
        // Ошибка сервера
        throw Exception('Ошибка сервера: Попробуйте позже');
      } else {
        // Обработка других ошибок
        throw Exception('Неизвестная ошибка!');
      }
    } catch (e) {
      // Обработка ошибок сети или других непредвиденных исключений
      throw Exception('Не удалось выполнить запрос!');
    }
  }

  // get all users
  Future<UsersDataResponse> getAllUser() async {
    final token = await getToken(); // Получаем токен перед запросом
    final organizationId = await getSelectedOrganization();

    final response = await http.get(
      Uri.parse(
          '$baseUrl/user${organizationId != null ? '?organization_id=$organizationId' : ''}'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    late UsersDataResponse dataUser;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataUser = UsersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    }

    if (kDebugMode) {
      // print('Статус ответа!');
    }
    if (kDebugMode) {
      // print('getAll user!');
    }

    return dataUser;
  }

  Future<UsersDataResponse> getAnotherUsers() async {
    final token = await getToken(); // Получаем токен перед запросом
    final organizationId = await getSelectedOrganization();

    final response = await http.get(
      Uri.parse(
          '$baseUrl/user/getAnotherUsers/${organizationId != null ? '?organization_id=$organizationId' : ''}'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    late UsersDataResponse dataUser;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataUser = UsersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    }

    if (kDebugMode) {
      // print('Статус ответа!');
    }
    if (kDebugMode) {
      // print('getAll user!');
    }

    return dataUser;
  }

  // addUserToGroup
  Future<UsersDataResponse> getUsersNotInChat(String chatId) async {
    final token = await getToken();
    final organizationId = await getSelectedOrganization();

    final response = await http.get(
      Uri.parse('$baseUrl/user/users-not-in-chat/$chatId' +
          (organizationId != null ? '?organization_id=$organizationId' : '')),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    late UsersDataResponse dataUser;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataUser = UsersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    }

    if (kDebugMode) {
      // print('Статус ответа!');
    }
    if (kDebugMode) {
      // print('getUsersNotInChat!');
    }

    return dataUser;
  }

//Список юзеров Корпорт чата  для созд с польз
  Future<UsersDataResponse> getUsersWihtoutCorporateChat() async {
    final token = await getToken(); // Получаем токен перед запросом
    final organizationId = await getSelectedOrganization();

    final response = await http.get(
      Uri.parse(
          '$baseUrl/chat/users/without-corporate-chat/${organizationId != null ? '?organization_id=$organizationId' : ''}'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    print(
        '----------------------------------------------------------------------');
    print(
        '-------------------------------getUsersWihtoutCorporateChat---------------------------------------');
    print(response);

    late UsersDataResponse dataUser;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataUser = UsersDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    }

    if (kDebugMode) {
      // print('Статус ответа!');
    }
    if (kDebugMode) {
      // print('getAll user!');
    }

    return dataUser;
  }

  // create new client
  Future<Map<String, dynamic>> createNewClient(String userID) async {
    final token = await getToken();
    final organizationId = await getSelectedOrganization();

    final response = await http.post(
      Uri.parse(
          '$baseUrl/chat/createChat/$userID${organizationId != null ? '?organization_id=$organizationId' : ''}'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (kDebugMode) {
      // print('Статус ответа!');
      // print('data!');
    }

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      var chatId = jsonResponse['result']['id']; // Извлекаем chatId
      return {'chatId': chatId}; // Возвращаем chatId
    } else {
      throw Exception('Failed to create chat');
    }
  }

  // Метод для создания Групповго чата
  Future<Map<String, dynamic>> createGroupChat({
    required String name,
    List<int>? userId,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'name': name,
        'users': userId?.map((id) => {'id': id}).toList() ?? [],
      };

      final organizationId = await getSelectedOrganization();

      final response = await _postRequest(
        '/chat/createGroup${organizationId != null ? '?organization_id=$organizationId' : ''}',
        requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'group_chat_created_successfully',
        };
      } else if (response.statusCode == 422) {
        if (response.body.contains('name')) {
          return {
            'success': false,
            'message': 'invalid_name_length',
          };
        }
        return {
          'success': false,
          'message': 'error_validation',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'error_server_text',
        };
      } else {
        return {
          'success': false,
          'message': 'error_create_group_chat',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'error_create_group_chat',
      };
    }
  }

// Метод для создания Групповго чата
  Future<Map<String, dynamic>> addUserToGroup({
    required int chatId,
    int? userId,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'chatId': chatId,
        'userId': userId,
      };

      final organizationId = await getSelectedOrganization();

      final response = await _postRequest(
        '/chat/addUserToGroup/$chatId/$userId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Участник успешно добавлен.',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'Ошибка на сервере. Попробуйте позже.',
        };
      } else {
        return {
          'success': false,
          'message': 'Ошибка добавления участника!',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка при добавление участника !',
      };
    }
  }

// Метод для создания Групповго чата
  Future<Map<String, dynamic>> deleteUserFromGroup({
    required int chatId,
    int? userId,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'chatId': chatId,
        'userId': userId,
      };

      final organizationId = await getSelectedOrganization();

      final response = await _postRequest(
        '/chat/removeUserFromGroup/$chatId/$userId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Участник успешно добавлен.',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'Ошибка на сервере. Попробуйте позже.',
        };
      } else {
        return {
          'success': false,
          'message': 'Ошибка добавления участника!',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка при добавление участника !',
      };
    }
  }

// Метод для удаления сообщение
  Future<void> DeleteMessage({int? messageId}) async {
    if (messageId == null) {
      throw Exception('MessageId не может быть null');
    }

    final organizationId = await getSelectedOrganization();

    String path =
        '/chat/delete-message/$messageId?organization_id=$organizationId';

    print('Sending DELETE request to API with path: $path');

    // Используем _deleteRequest для отправки DELETE-запроса
    final response = await _deleteRequest(path);

    if (response.statusCode != 200) {
      throw Exception('Ошибка удаления уведомлений!');
    }

    final data = json.decode(response.body);
    if (data['result'] == 'deleted') {
      return;
    } else {
      throw Exception('Ошибка удаления уведомления');
    }
  }

  //_________________________________ END_____API_SCREEN__CHATS____________________________________________//

  //_________________________________ START_____API_SCREEN__PROFILE_CHAT____________________________________________//

  Future<ChatProfile> getChatProfile(int chatId) async {
    try {
      final organizationId = await getSelectedOrganization();

      final response = await _getRequest(
        '/lead/getByChat/$chatId${organizationId != null ? '?organization_id=$organizationId' : ''}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        if (decodedJson['result'] != null) {
          return ChatProfile.fromJson(decodedJson['result']);
        } else {
          throw Exception('Данные профиля не найдены');
        }
      } else if (response.statusCode == 404) {
        throw ('Такого Лида не существует');
      } else {
        print('Ошибка загрузки профиля чата!');
        throw Exception('${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка в getChatProfile!');
      throw ('$e');
    }
  }

  Future<TaskProfile> getTaskProfile(int chatId) async {
    try {
      final organizationId = await getSelectedOrganization();
      print('Organization ID: $organizationId'); // Добавим логирование

      final response = await _getRequest(
        '/task/getByChat/$chatId${organizationId != null ? '?organization_id=$organizationId' : ''}',
      );

      print('Response status code!'); // Логируем статус ответа
      print('Response body!'); // Логируем тело ответа

      if (response.statusCode == 200) {
        try {
          final dynamic decodedJson = json.decode(response.body);
          print(
              'Decoded JSON type: ${decodedJson.runtimeType}'); // Логируем тип декодированного JSON
          print('Decoded JSON: $decodedJson'); // Отладочный вывод

          if (decodedJson is Map<String, dynamic>) {
            if (decodedJson['result'] != null) {
              print(
                  'Result type: ${decodedJson['result'].runtimeType}'); // Логируем тип результата
              return TaskProfile.fromJson(decodedJson['result']);
            } else {
              print('Result is null');
              throw Exception('Данные задачи не найдены');
            }
          } else {
            print('Decoded JSON is not a Map: ${decodedJson.runtimeType}');
            throw Exception('Неверный формат ответа');
          }
        } catch (parseError) {
          print('Ошибка парсинга JSON: $parseError');
          throw Exception('Ошибка парсинга ответа: $parseError');
        }
      } else {
        print('Ошибка загрузки задачи!');
        throw Exception('Ошибка загрузки задачи!');
      }
    } catch (e) {
      print('Полная ошибка в getTaskProfile!');
      print('Трассировка стека: ${StackTrace.current}');
      throw Exception('Ошибка загрузки задачи!');
    }
  }

  //_________________________________ END_____API_SCREEN__PROFILE_CHAT____________________________________________//

  //_________________________________ START_____API_SCREEN__PROFILE____________________________________________//

  // Метод для получения Организации
  Future<List<Organization>> getOrganization() async {
    final response = await _getRequest('/organization');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Тело ответа: $data'); // Для отладки

      if (data['result'] != null && data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((organization) => Organization.fromJson(organization))
            .toList();
      } else {
        throw Exception('Организация не найдено');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

  // Сохранение выбранной организации
  Future<void> saveSelectedOrganization(String organizationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedOrganization', organizationId);
  }

  // Получение выбранной организации
  Future<String?> getSelectedOrganization() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedOrganization');
  }

  // Метод для удаления токена (используется при логауте)
  Future<void> _removeOrganizationId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedOrganization'); // Удаляем токен
  }

  Future<void> logoutAccount() async {
    final organizationId = await getSelectedOrganization();
    final response = await _postRequest(
        '/logout${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {});

    if (response.statusCode != 200) {
      throw Exception('Ошибка logout аккаунта!');
    }
  }

  //_________________________________ END_____API_SCREEN__PROFILE____________________________________________//

  //_________________________________ START_____API_SCREEN__NOTIFICATIONS____________________________________________//

  // Метод для получения список Уведомления
  Future<List<Notifications>> getAllNotifications(
      {int page = 1, int perPage = 20}) async {
    final organizationId = await getSelectedOrganization();
    String path = '/notification/unread?page=$page&per_page=$perPage';

    path += '&organization_id=$organizationId';

    // print('Sending request to API with path: $path');
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((json) => Notifications.fromJson(json))
            .toList();
      } else {
        throw Exception('Нет данных о уведомлениях в ответе');
      }
    } else {
      throw Exception('Ошибка загрузки уведомлений!');
    }
  }

  // Метод для прочтения всех  Уведомлении
  Future<void> DeleteAllNotifications() async {
    final organizationId = await getSelectedOrganization();
    String path = '/notification/readAll?organization_id=$organizationId';

    print('Sending POST request to API with path: $path');

    final response = await _postRequest(path, {});

    if (response.statusCode != 200) {
      throw Exception('Ошибка удаления уведомлений!');
    }
  }

// Метод для удаления Уведомлений
  Future<void> DeleteNotifications({int? notificationId}) async {
    final organizationId = await getSelectedOrganization();

    String path = '/notification/read/$notificationId';

    Map<String, dynamic> body = {
      'notificationId': notificationId,
      'organization_id': organizationId,
    };

    print('Sending POST request to API with path: $path');

    final response = await _postRequest(path, body);

    if (response.statusCode != 200) {
      throw Exception('Ошибка удаления уведомлений!');
    }
    final data = json.decode(response.body);
    if (data['result'] == 'Success') {
      return;
    } else {
      throw Exception('Ошибка удаления уведомления');
    }
  }

  //_________________________________ END_____API_SCREEN__NOTIFICATIONS____________________________________________//

  //_________________________________ START_____API_PROFILE_SCREEN____________________________________________//
//Метод для получения Пользователя через его ID
  Future<UserByIdProfile> getUserById(int userId) async {
    try {
      final organizationId = await getSelectedOrganization();

      final response = await _getRequest(
          '/user/$userId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic>? jsonUser = decodedJson['result'];

        if (jsonUser == null) {
          throw Exception('Некорректные данные от API');
        }

        return UserByIdProfile.fromJson(jsonUser);
      } else {
        throw Exception('Ошибка загрузки User ID!');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки User ID!');
    }
  }

  // Метод для Редактирование профиля
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String name,
    required String sname,
    required String phone,
    String? email,
    String? filePath,
  }) async {
    try {
      final token = await getToken(); // Получаем токен
      final organizationId = await getSelectedOrganization();

      // Создаем URL для обновления профиля
      var uri = Uri.parse(
          '${baseUrl}/profile/$userId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      // Создаем multipart запрос
      var request = http.MultipartRequest('POST', uri);

      // Добавляем заголовки с токеном
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      // Добавляем поля
      request.fields['name'] = name;
      request.fields['lastname'] = sname;
      request.fields['phone'] = phone;

      if (email != null) {
        request.fields['email'] = email;
      }

      // Добавляем файл, если указан путь
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          final fileName = file.path.split('/').last;
          final fileStream = http.ByteStream(file.openRead());
          final length = await file.length();

          final multipartFile = http.MultipartFile(
            'image', // Название поля в API, куда передается файл
            fileStream,
            length,
            filename: fileName,
          );
          request.files.add(multipartFile);
        }
      }

      // Отправляем запрос
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'profile_updated_successfully'};
      } else if (response.statusCode == 422) {
        return {'success': false, 'message': 'error_validation_data'};
      }
      if (response.body.contains('validation.phone')) {
        return {'success': false, 'message': 'invalid_phone_format'};
      } else if (response.statusCode == 500) {
        return {'success': false, 'message': 'error_server_text'};
      } else {
        return {'success': false, 'message': 'error_update_profile'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'error_update_profile',
      };
    }
  }

  //_________________________________ END_____API_PROFILE_SCREEN____________________________________________//

  //_________________________________ START___API__SCREEN__MY-TASK____________________________________________//

  Future<MyTaskById> getMyTaskById(int taskId) async {
    try {
      final organizationId = await getSelectedOrganization();
      final response = await _getRequest(
        '/my-task/$taskId${organizationId != null ? '?organization_id=$organizationId' : ''}',
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic>? result = decodedJson['result'];

        if (result == null) {
          throw ('Некорректные данные от API: result is null');
        }

        return MyTaskById.fromJson(result, 0);
      } else {
        throw ('HTTP Error');
      }
    } catch (e) {
      print('Error in getMyTaskById: $e');
      throw ('Ошибка загрузки task ID');
    }
  }

  Future<bool> checkOverdueTasks() async {
    try {
      final organizationId = await getSelectedOrganization();
      final response = await _getRequest(
        '/my-task/check/overdue${organizationId != null ? '?organization_id=$organizationId' : ''}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        return decodedJson['res'] ?? false;
      } else {
        throw Exception('Failed to check overdue tasks');
      }
    } catch (e) {
      throw Exception('Error checking overdue tasks: $e');
    }
  }

  Future<List<MyTask>> getMyTasks(
    int? taskStatusId, {
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final organizationId = await getSelectedOrganization();
    String path = '/my-task?page=$page&per_page=$perPage';

    path += '&organization_id=$organizationId';

    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    } else if (taskStatusId != null) {
      // Условие: если нет userId
      path += '&task_status_id=$taskStatusId';
    }
    // Логируем конечный URL запроса
    // print('Sending request to API with path: $path');
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((json) => MyTask.fromJson(json, taskStatusId ?? -1))
            .toList();
      } else {
        throw Exception('Нет данных о задачах в ответе');
      }
    } else {
      // Логирование ошибки с ответом сервера
      print('Error response! - ${response.body}');
      throw Exception('Ошибка загрузки задач!');
    }
  }

// Метод для получения статусов задач
  Future<List<MyTaskStatus>> getMyTaskStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();

    try {
      // Отправляем запрос на сервер
      final response = await _getRequest(
          '/my-task-status${organizationId != null ? '?organization_id=$organizationId' : ''}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          // Принт старых кэшированных данных (если они есть)
          final cachedStatuses =
              prefs.getString('cachedMyTaskStatuses_$organizationId');
          if (cachedStatuses != null) {
            final decodedData = json.decode(cachedStatuses);
          }

          // Обновляем кэш новыми данными
          await prefs.setString('cachedMyTaskStatuses_$organizationId',
              json.encode(data['result']));
          // print(
          //     '------------------------------------ Новые данные, которые сохраняются в кэш ---------------------------------');
          // print(data['result']); // Новые данные, которые будут сохранены в кэш

          return (data['result'] as List)
              .map((status) => MyTaskStatus.fromJson(status))
              .toList();
        } else {
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка ${response.statusCode}!');
      }
    } catch (e) {
      print('Ошибка загрузки статусов задач. Используем кэшированные данные.');
      // Если запрос не удался, пытаемся загрузить данные из кэша
      final cachedStatuses =
          prefs.getString('cachedMyTaskStatuses_$organizationId');
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        final cachedList = (decodedData as List)
            .map((status) => MyTaskStatus.fromJson(status))
            .toList();
        return cachedList;
      } else {
        throw Exception(
            'Ошибка загрузки статусов задач и отсутствуют кэшированные данные!');
      }
    }
  }

  Future<bool> checkIfStatusHasMyTasks(int taskStatusId) async {
    try {
      // Получаем список лидов для указанного статуса, берем только первую страницу
      final List<MyTask> tasks =
          await getMyTasks(taskStatusId, page: 1, perPage: 1);

      // Если список лидов не пуст, значит статус содержит элементы
      return tasks.isNotEmpty;
    } catch (e) {
      print('Error while checking if status has deals!');
      return false;
    }
  }

//Обновление статуса карточки Задачи  в колонке

  Future<void> updateMyTaskStatus(
      int taskId, int position, int statusId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
        '/my-task/change-status/$taskId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'position': 1,
          'status_id': statusId,
        });

    if (response.statusCode == 200) {
      print('Статус задачи успешно обновлен');
    } else if (response.statusCode == 422) {
      throw MyTaskStatusUpdateException(
          422, 'Вы не можете переместить задачу на этот статус');
    } else {
      throw Exception('Ошибка обновления задач сделки!');
    }
  }

  Map<String, dynamic> _handleMyTaskResponse(
      http.Response response, String operation) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);

      // Проверяем наличие ошибок в ответе
      if (data['errors'] != null) {
        return {
          'success': false,
          'message': 'Ошибка ${operation} задачи: ${data['errors']}',
        };
      }

      return {
        'success': true,
        'message':
            'Задача ${operation == 'создания' ? 'создана' : 'обновлена'} успешно.',
        'data': data['result'],
      };
    }

    if (response.statusCode == 422) {
      final data = json.decode(response.body);
      final validationErrors = {
        'name': 'Название задачи должно содержать минимум 3 символа.',
        'from': 'Неверный формат даты начала.',
        'to': 'Неверный формат даты окончания.',
        'project_id': 'Указанный проект не существует.',
        'user_id': 'Указанный пользователь не существует.',
        // Убрана валидация файла
      };

      // Игнорируем ошибки валидации файла
      if (data['errors']?['file'] != null) {
        data['errors'].remove('file');
      }

      // Проверяем каждое поле на наличие ошибки, кроме файла
      for (var entry in validationErrors.entries) {
        if (data['errors']?[entry.key] != null) {
          return {'success': false, 'message': entry.value};
        }
      }

      // Если остались только ошибки файла, считаем что валидация прошла успешно
      if (data['errors']?.isEmpty ?? true) {
        return {
          'success': true,
          'message':
              'Задача ${operation == 'создания' ? 'создана' : 'обновлена'} успешно.',
        };
      }

      return {
        'success': false,
        'message': 'Ошибка валидации: ${data['errors'] ?? response.body}',
      };
    }

    return {
      'success': false,
      'message': 'Ошибка ${operation} задачи!',
    };
  }

  // // Общий метод обработки ошибок
  // Exception _handleErrorResponse(http.Response response, String operation) {
  //   try {
  //     final data = json.decode(response.body);
  //     final errorMessage = data['errors'] ?? data['message'] ?? response.body;
  //     return Exception(
  //         'Ошибка ${operation}! - $errorMessage');
  //   } catch (e) {
  //     return Exception(
  //         'Ошибка ${operation}! - ${response.body}');
  //   }
  // }
  /// Создает новый статус задачи
  Future<Map<String, dynamic>> CreateMyTaskStatusAdd({
    required String statusName,
    bool? finalStep,
  }) async {
    try {
      // Формируем данные для запроса
      final Map<String, dynamic> data = {
        'title': statusName,
        'color': "#000",
      };
      if (finalStep != null) {
        data['final_step'] = finalStep;
      }

      // Получаем идентификатор организации
      final organizationIdProfile = await getSelectedOrganization();

      // Формируем URL с учетом organization_id
      final String url =
          '/my-task-status${organizationIdProfile != null ? '?organization_id=$organizationIdProfile' : ''}';

      // Выполняем запрос
      final response = await _postRequest(url, data);

      // Проверяем успешность запроса
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Статус задачи успешно создан',
          'data': responseData,
        };
      }

      // Получаем текст ошибки в зависимости от кода ответа
      final errorMessage = _getErrorMessage(response.statusCode);

      return {
        'success': false,
        'message': errorMessage,
        'statusCode': response.statusCode,
        'details': response.body,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка при создании статуса',
        'error': e.toString(),
      };
    }
  }

  /// Возвращает сообщение об ошибке по коду статуса
  String _getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Неверные данные для создания статуса';
      case 401:
        return 'Необходима авторизация';
      case 403:
        return 'Недостаточно прав для создания статуса';
      case 404:
        return 'Ресурс не найден';
      case 409:
        return 'Статус с таким названием уже существует';
      case 500:
        return 'Внутренняя ошибка сервера';
      default:
        return 'Произошла ошибка при создании статуса (код: $statusCode)';
    }
  }

// Метод для создания задачи
  Future<Map<String, dynamic>> createMyTask({
    required String name,
    required int? statusId,
    required int? taskStatusId,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    List<String>? filePaths,
    int position = 1,
    required bool setPush,
  }) async {
    try {
      final token = await getToken();
      final organizationId = await getSelectedOrganization();
      var uri = Uri.parse(
          '${baseUrl}/my-task${organizationId != null ? '?organization_id=$organizationId' : ''}');

      // Создаем multipart request
      var request = http.MultipartRequest('POST', uri);

      // Добавляем заголовки с токеном
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      // Добавляем все поля в формате form-data
      request.fields['name'] = name;
      request.fields['status_id'] = statusId.toString();
      request.fields['task_status_id'] = taskStatusId.toString();
      request.fields['position'] = position.toString();
      request.fields['send_notification'] = setPush ? '1' : '0';

      if (startDate != null) {
        request.fields['from'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        request.fields['to'] = endDate.toIso8601String();
      }
      if (description != null) {
        request.fields['description'] = description;
      }

      // Добавляем файлы, если они есть
      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath(
              'files[]', filePath); // Используем 'files[]'
          request.files.add(file);
        }
      }

      // Отправляем запрос
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Задача успешно создана',
          'data': responseData,
        };
      } else {
        // Обрабатываем различные коды ошибок
        String errorMessage;
        switch (response.statusCode) {
          case 400:
            errorMessage = 'Неверные данные запроса';
            break;
          case 401:
            errorMessage = 'Необходима авторизация';
            break;
          case 403:
            errorMessage = 'Недостаточно прав для создания задачи';
            break;
          case 404:
            errorMessage = 'Ресурс не найден';
            break;
          case 409:
            errorMessage = 'Конфликт при создании задачи';
            break;
          case 500:
            errorMessage = 'Внутренняя ошибка сервера';
            break;
          default:
            errorMessage = 'Произошла ошибка при создании задачи';
        }
        return {
          'success': false,
          'message': '$errorMessage!',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('Detailed error: $e');
      return {
        'success': false,
        'message': 'Ошибка при выполнении запроса!',
        'error': e.toString(),
      };
    }
  }

/*// Метод для создания задачи
  // Метод для создания задачи с поддержкой нескольких файлов
Future<Map<String, dynamic>> createMyTask({
  required String name,
  required int? statusId,
  required int? taskStatusId,
  DateTime? startDate,
  DateTime? endDate,
  String? description,
  List<String>? filePaths, // Изменено на список путей к файлам
  int position = 1,
  required bool setPush,
}) async {
  try {
    // Формируем данные для запроса
    final Map<String, dynamic> data = {
      'name': name,
      'status_id': statusId,
      'task_status_id': taskStatusId,
      'position': position,
      'send_notification': setPush, // Передаем как true/false для boolean
      if (startDate != null) 'from': startDate.toIso8601String(),
      if (endDate != null) 'to': endDate.toIso8601String(),
      if (description != null) 'description': description,
    };

    // Получаем идентификатор организации
    final organizationIdProfile = await getSelectedOrganization();

    // Создаем multipart запрос для загрузки файлов
    final uri = Uri.parse(
        '/my-task${organizationIdProfile != null ? '?organization_id=$organizationIdProfile' : ''}');
    final request = http.MultipartRequest('POST', uri);

    // Добавляем поля данных
    request.fields.addAll(data.map((key, value) => MapEntry(key, value.toString())));

    // Добавляем файлы, если они есть
    if (filePaths != null && filePaths.isNotEmpty) {
      for (var filePath in filePaths) {
        final file = await http.MultipartFile.fromPath('files', filePath);
        request.files.add(file);
      }
    }

    // Выполняем запрос
    final response = await request.send();

    // Проверяем статус ответа
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = await response.stream.bytesToString();
      return {
        'success': true,
        'message': 'Задача успешно создана',
        'data': json.decode(responseData),
      };
    }

    // Обрабатываем различные коды ошибок
    String errorMessage;
    switch (response.statusCode) {
      case 400:
        errorMessage = 'Неверные данные запроса';
        break;
      case 401:
        errorMessage = 'Необходима авторизация';
        break;
      case 403:
        errorMessage = 'Недостаточно прав для создания задачи';
        break;
      case 404:
        errorMessage = 'Ресурс не найден';
        break;
      case 409:
        errorMessage = 'Конфликт при создании задачи';
        break;
      case 500:
        errorMessage = 'Внутренняя ошибка сервера';
        break;
      default:
        errorMessage = 'Произошла ошибка при создании задачи';
    }

    return {
      'success': false,
      'message': '$errorMessage!',
      'statusCode': response.statusCode,
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Ошибка при выполнении запроса!',
      'error': e.toString(),
    };
  }
}*/
  Future<Map<String, dynamic>> updateMyTask({
    required int taskId,
    required String name,
    required int? taskStatusId,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    List<String>? filePaths,
    required bool setPush,
    List<MyTaskFiles>? existingFiles,
  }) async {
    try {
      final token = await getToken();
      final organizationId = await getSelectedOrganization();
      var uri = Uri.parse(
          '${baseUrl}/my-task/$taskId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      // Создаем multipart request
      var request = http.MultipartRequest('POST', uri);

      // Добавляем заголовки с токеном
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      // Добавляем все поля в формате form-data
      request.fields['name'] = name;
      request.fields['task_status_id'] = taskStatusId.toString();
      request.fields['send_notification'] = setPush ? '1' : '0';

      if (endDate != null) {
        request.fields['to'] =
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      }
      if (description != null) {
        request.fields['description'] = description;
      }

      // Добавляем новые файлы, если они есть
      if (filePaths != null && filePaths.isNotEmpty) {
        for (var filePath in filePaths) {
          final file = await http.MultipartFile.fromPath('files[]', filePath);
          request.files.add(file);
        }
      }

      // Добавляем информацию о существующих файлах
      if (existingFiles != null && existingFiles.isNotEmpty) {
        List<Map<String, dynamic>> existingFilesList = existingFiles
            .map(
                (file) => {'id': file.id, 'name': file.name, 'path': file.path})
            .toList();

        request.fields['existing_files'] = json.encode(existingFilesList);
      }

      // Отправляем запрос
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Задача успешно обновлена',
          'data': responseData,
        };
      } else {
        String errorMessage;
        switch (response.statusCode) {
          case 400:
            errorMessage = 'Неверные данные запроса';
            break;
          case 401:
            errorMessage = 'Необходима авторизация';
            break;
          case 403:
            errorMessage = 'Недостаточно прав для обновления задачи';
            break;
          case 404:
            errorMessage = 'Ресурс не найден';
            break;
          case 409:
            errorMessage = 'Конфликт при обновлении задачи';
            break;
          case 500:
            errorMessage = 'Внутренняя ошибка сервера';
            break;
          default:
            errorMessage = 'Произошла ошибка при обновлении задачи';
        }
        return {
          'success': false,
          'message': '$errorMessage!',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('Detailed error: $e');
      return {
        'success': false,
        'message': 'Ошибка при выполнении запроса!',
        'error': e.toString(),
      };
    }
  }

// Метод для получения Истории Задачи
  Future<List<MyTaskHistory>> getMyTaskHistory(int taskId) async {
    try {
      final organizationId = await getSelectedOrganization();

      // Используем метод _getRequest вместо прямого выполнения запроса
      final response = await _getRequest(
          '/my-task/history/$taskId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => MyTaskHistory.fromJson(json)).toList();
      } else {
        print('Failed to load task history!');
        throw Exception('Ошибка загрузки истории задач!');
      }
    } catch (e) {
      print('Error occurred!');
      throw Exception('Ошибка загрузки истории задач!');
    }
  }

// Метод для получения Cтатуса задачи
  Future<List<MyStatusName>> getMyStatusName() async {
    final organizationId = await getSelectedOrganization();

    print('Начало запроса статусов задач'); // Отладочный вывод
    final response = await _getRequest(
        '/my-taskStatusName${organizationId != null ? '?organization_id=$organizationId' : ''}');
    print('Статус код ответа!'); // Отладочный вывод

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Полученные данные: $data'); // Отладочный вывод

      if (data['result'] != null) {
        final statusList = (data['result'] as List)
            .map((name) => MyStatusName.fromJson(name))
            .toList();
        print(
            'Преобразованный список статусов: $statusList'); // Отладочный вывод
        return statusList;
      } else {
        throw Exception('Статусы задач не найдены');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

  // Метод для Удаления Задачи
  Future<Map<String, dynamic>> deleteMyTask(int taskId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _deleteRequest(
        '/my-task/$taskId${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete task!');
    }
  }

  // Метод для Удаления Статуса Задачи

  Future<Map<String, dynamic>> deleteMyTaskStatuses(int taskStatusId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _deleteRequest(
        '/my-task-status/$taskStatusId${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete taskStatus!');
    }
  }

  // Метод для завершения задачи
  Future<Map<String, dynamic>> finishMyTask(int taskId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
        '/my-task/finish${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'task_id': taskId,
        });

  if (response.statusCode == 200 || response.statusCode == 201) {
    return {'success': true, 'message': 'Задача успешно завершена'};
  } else if (response.statusCode == 422) {
    try {
      final responseData = jsonDecode(response.body);
      final errorMessage = responseData['message'] ?? 'Неизвестная ошибка при завершении задачи';
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка обработки ответа сервера',
      };
    }
  } else {
    return {'success': false, 'message': 'Ошибка завершения задачи!'};
  }
}

  //Метод для получение кастомных полей Задачи
  Future<Map<String, dynamic>> getMyCustomFields() async {
    final organizationId = await getSelectedOrganization();

    // Выполняем запрос
    final response = await _getRequest(
      '/my-task/get/custom-fields${organizationId != null ? '?organization_id=$organizationId' : ''}',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return data; // Возвращаем данные, если они есть
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}!');
    }
  }

  Future<MyTaskStatus> getMyTaskStatus(int myTaskStatusId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
      '/my-task-status/$myTaskStatusId${organizationId != null ? '?organization_id=$organizationId' : ''}',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != null) {
        return MyTaskStatus.fromJson(data['result']);
      }
      throw Exception('Invalid response format');
    } else {
      throw Exception('Failed to fetch deal status!');
    }
  }

  Future<Map<String, dynamic>> updateMyTaskStatusEdit(int myTaskStatusId,
      String title, bool finalStep, AppLocalizations localizations) async {
    final organizationId = await getSelectedOrganization();
    final payload = {
      "title": title,
      "organization_id": organizationId,
      "color": "#000",
      "final_step": finalStep ? 1 : 0, // Конвертируем bool в 1/0
    };
    final response = await _patchRequest(
      '/my-task-status/$myTaskStatusId${organizationId != null ? '?organization_id=$organizationId' : ''}',
      payload,
    );
    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to update leadStatus!');
    }
  }

  //_________________________________ END_____API_SCREEN__MY-TASK____________________________________________//a

  //_________________________________ START_____API_SCREEN__EVENT____________________________________________//a

  Future<List<NoticeEvent>> getEvents({
    int page = 1,
    int perPage = 20,
    String? search,
    List<int>? managers,
    int? statuses,
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? noticefromDate,
    DateTime? noticetoDate,
  }) async {
    try {
      final organizationId = await getSelectedOrganization();
      String path = '/notices?page=$page&per_page=$perPage';
      path += '&organization_id=$organizationId'; // organization_id в URL

      if (search != null && search.isNotEmpty) {
        path += '&search=$search';
      }

      if (managers != null && managers.isNotEmpty) {
        for (int i = 0; i < managers.length; i++) {
          path += '&managers[$i]=${managers[i]}';
        }
      }

      if (statuses != null) {
        path += '&event_status_id=$statuses';
        bool isFinished = statuses == 2;
        path +=
            '&isFinished=${isFinished ? '1' : '0'}'; // Передаем 1 или 0 вместо true/false
      }

      if (fromDate != null && toDate != null) {
        final formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
        final formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);
        path += '&created_from=$formattedFromDate&created_to=$formattedToDate';
      }

      if (noticefromDate != null && noticetoDate != null) {
        final formattedFromDate =
            DateFormat('yyyy-MM-dd').format(noticefromDate);
        final formattedToDate = DateFormat('yyyy-MM-dd').format(noticetoDate);
        path += '&push_from=$formattedFromDate&push_to=$formattedToDate';
      }

      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null && data['result']['data'] != null) {
          return (data['result']['data'] as List)
              .map((json) => NoticeEvent.fromJson(json))
              .toList();
        } else {
          throw ('Нет данных о событиях в ответе');
        }
      } else {
        throw ('Ошибка загрузки событий!');
      }
    } catch (e) {
      throw ('Ошибка загрузки событий');
    }
  }

  Future<Notice> getNoticeById(int noticeId) async {
    try {
      final organizationId = await getSelectedOrganization();

      final response = await _getRequest(
          '/notices/show/$noticeId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final Map<String, dynamic>? jsonNotice = decodedJson['result'];

        if (jsonNotice == null) {
          throw ('Некорректные данные от API');
        }

        return Notice.fromJson(jsonNotice);
      } else {
        throw ('Ошибка загрузки notice ID!');
      }
    } catch (e) {
      throw ('Ошибка загрузки notice ID!');
    }
  }

  Future<Map<String, dynamic>> createNotice({
    String? title,
    required String body,
    required int leadId,
    DateTime? date,
    required int sendNotification,
    required List<int> users,
  }) async {
    final organizationId = await getSelectedOrganization();

    final requestBody = {
      'title': title ?? '', // Используем пустую строку, если title == null
      'body': body,
      'lead_id': leadId,
      'date': date != null ? DateFormat('yyyy-MM-dd HH:mm').format(date) : null,
      'send_notification': sendNotification,
      'users': users,
      'organization_id': organizationId ?? '2'
    };

    final response = await _postRequest(
        '/notices?organization_id=${organizationId ?? ""}', requestBody);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'notice_create_successfully'};
    } else if (response.statusCode == 422) {
      return {'success': false, 'message': 'validation_error'};
    } else if (response.statusCode == 500) {
      return {'success': false, 'message': 'error_server_text'};
    } else {
      return {'success': false, 'message': 'error_notice_create'};
    }
  }

  Future<Map<String, dynamic>> updateNotice({
    required int noticeId,
    String? title,
    required String body,
    required int leadId,
    DateTime? date,
    required int sendNotification,
    required List<int> users,
  }) async {
    final organizationId = await getSelectedOrganization();

    final requestBody = {
      'title': title,
      'body': body,
      'lead_id': leadId,
      'date': date != null ? DateFormat('yyyy-MM-dd HH:mm').format(date) : null,
      'send_notification': sendNotification,
      'users': users,
      'organization_id': organizationId ?? '2'
    };

    final response = await _patchRequest(
      '/notices/$noticeId?organization_id=${organizationId ?? "2"}',
      requestBody,
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': '111'};
    } else if (response.statusCode == 422) {
      return {'success': false, 'message': 'validation_error'};
    } else if (response.statusCode == 500) {
      return {'success': false, 'message': 'error_server_text'};
    } else {
      return {'success': false, 'message': 'error_notice_update'};
    }
  }

  Future<Map<String, dynamic>> deleteNotice(int noticeId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _deleteRequest(
        '/notices/$noticeId${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw ('Failed to delete notice!');
    }
  }

  Future<Map<String, dynamic>> finishNotice(
      int noticeId, String conclusion) async {
    final organizationId = await getSelectedOrganization();

    final response = await _patchRequest(
        '/notices/finish/$noticeId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {"conclusion": conclusion, "organization_id": organizationId});

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw ('Failed to finish notice!');
    }
  }

  Future<SubjectDataResponse> getAllSubjects() async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
        '/noteSubject${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return SubjectDataResponse.fromJson(data);
    } else {
      throw ('Failed to load subjects');
    }
  }

// get all authors
  Future<AuthorsDataResponse> getAllAuthor() async {
    final token = await getToken(); // Получаем токен перед запросом
    final organizationId = await getSelectedOrganization();

    final response = await http.get(
      Uri.parse(
          '$baseUrl/user${organizationId != null ? '?organization_id=$organizationId' : ''}'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    late AuthorsDataResponse dataAuthor;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['result'] != null) {
        dataAuthor = AuthorsDataResponse.fromJson(data);
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    }

    if (kDebugMode) {
      // print('Статус ответа!');
    }
    if (kDebugMode) {
      // print('getAll author!');
    }

    return dataAuthor;
  }

  String getRecordingUrl(String recordPath) {
    if (recordPath.isEmpty) return '';

    // Если путь уже содержит полный URL, возвращаем его
    if (recordPath.startsWith('http://') || recordPath.startsWith('https://')) {
      return recordPath;
    }

    // Убираем '/api' из baseUrl и добавляем путь к записи
    String cleanBaseUrl = baseUrl?.replaceAll('/api', '') ?? '';
    return recordPath.startsWith('/call-recordings/')
        ? '$cleanBaseUrl$recordPath'
        : '$cleanBaseUrl/storage/$recordPath';
  }
  //_________________________________ END_____API_SCREEN__EVENT____________________________________________//a

  //_________________________________ START_____API_SCREEN__TUTORIAL____________________________________________//a

  Future<Map<String, dynamic>> getTutorialProgress() async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
      '/tutorials/getProgress${organizationId != null ? '?organization_id=$organizationId' : ''}',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception(
          'Failed to get tutorial progress: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getSettings(String? organizationId) async {
    final response = await _getRequest(
      '/setting${organizationId != null ? '?organization_id=$organizationId' : ''}',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to get settings: ${response.statusCode}');
    }
  }

  Future<void> markPageCompleted(String section, String pageType) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
      '/tutorials/markPageCompleted${organizationId != null ? '?organization_id=$organizationId' : ''}',
      {
        "section": section,
        "page_type": pageType,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark page completed: ${response.statusCode}');
    }
  }

  //_________________________________ END_____API_SCREEN__TUTORIAL____________________________________________//

  //_________________________________ START_____API_SCREEN__CATEGORY____________________________________________//

  Future<CharacteristicListDataResponse> getAllCharacteristics() async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
        '/attribute${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return CharacteristicListDataResponse.fromJson(data);
    } else {
      throw ('Ошибка загрузки списка характеритсикии');
    }
  }

  Future<List<CategoryData>> getCategory() async {
    final organizationId = await getSelectedOrganization();
    // final String path = '/category/organization_id=$organizationId';
    final String path = '/category';

    final response = await _getRequest(path); // Ваш метод запроса

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.containsKey('result') && data['result'] is List) {
        return (data['result'] as List)
            .map((category) =>
                CategoryData.fromJson(category as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      throw Exception('Ошибка загрузки категории: ${response.statusCode}');
    }
  }

  Future<SubCategoryResponseASD> getSubCategoryById(int categoryId) async {
    try {
      final organizationId = await getSelectedOrganization();
      final url =
          '/category/get-by-parent-id/$categoryId${organizationId != null ? '?organization_id=$organizationId' : ''}';

      final response = await _getRequest(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        print(decodedJson);
        return SubCategoryResponseASD.fromJson(decodedJson);
      } else {
        throw Exception(
            'Failed to load subcategories. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load subcategories: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createCategory({
    required String name,
    required int parentId,
    required List<Map<String, dynamic>> attributes, // Обновлено
    File? image,
    required String displayType,
    required bool hasPriceCharacteristics,
  }) async {
    try {
      final token = await getToken();
      final organizationId = await getSelectedOrganization();
      var uri = Uri.parse(
          '${baseUrl}/category${organizationId != null ? '?organization_id=$organizationId' : ''}');

      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      request.fields['name'] = name;
      if (parentId != 0) {
        request.fields['parent_id'] = parentId.toString();
      }
      request.fields['display_type'] = displayType;
      request.fields['has_price_characteristics'] =
          hasPriceCharacteristics ? '1' : '0';

      for (int i = 0; i < attributes.length; i++) {
        request.fields['attributes[$i][attribute]'] = attributes[i]['name'];
        request.fields['attributes[$i][is_individual]'] = attributes[i]
                ['is_individual']
            ? '1'
            : '0'; // Отправляем "1" или "0"
      }

      if (image != null) {
        final imageFile =
            await http.MultipartFile.fromPath('image', image.path);
        request.files.add(imageFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'category_created_successfully',
          'data': CategoryData.fromJson(responseBody),
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to create category',
          'error': responseBody,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateCategory({
    required int categoryId,
    required String name,
    File? image,
  }) async {
    try {
      final token = await getToken();
      final organizationId = await getSelectedOrganization();
      var uri = Uri.parse(
          '${baseUrl}/category/update/$categoryId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      request.fields['name'] = name;

      if (image != null) {
        final imageFile =
            await http.MultipartFile.fromPath('image', image.path);
        request.files.add(imageFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Категория успешно обновлена',
          'data': responseBody,
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to update category',
          'error': responseBody,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteCategory(int categoryId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _deleteRequest(
        '/category/$categoryId${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete category!');
    }
  }

  Future<Map<String, dynamic>> updateSubCategory({
    required int subCategoryId,
    required String name,
    File? image,
    required List<Map<String, dynamic>> attributes,
    required String displayType,
    required bool hasPriceCharacteristics,
  }) async {
    try {
      final token = await getToken();
      final organizationId = await getSelectedOrganization();
      var uri = Uri.parse(
          '${baseUrl}/category/update/$subCategoryId${organizationId != null ? '?organization_id=$organizationId' : ''}');

      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      request.fields['name'] = name;
      request.fields['display_type'] = displayType;
      request.fields['has_price_characteristics'] =
          hasPriceCharacteristics ? '1' : '0';

      for (int i = 0; i < attributes.length; i++) {
        request.fields['attributes[$i][attribute]'] = attributes[i]['name'];
        request.fields['attributes[$i][is_individual]'] =
            attributes[i]['is_individual'] ? '1' : '0';
      }

      if (image != null) {
        final imageFile =
            await http.MultipartFile.fromPath('image', image.path);
        request.files.add(imageFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'subcategory_updated_successfully',
          'data': responseBody,
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'failed_to_update_subcategory',
          'error': responseBody,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'error_occurred: $e',
      };
    }
  }
  //_________________________________ END_____API_SCREEN__CATEGORY____________________________________________//

  //_________________________________ START_____API_SCREEN__GOODS____________________________________________//

  Future<List<Goods>> getGoods({int page = 1, int perPage = 20}) async {
    final organizationId = await getSelectedOrganization();
    final String path =
        '/good?page=$page&per_page=$perPage&organization_id=$organizationId';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result') && data['result']['data'] is List) {
        return (data['result']['data'] as List)
            .map((item) => Goods.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      throw Exception('Ошибка загрузки товаров: ${response.statusCode}');
    }
  }

  Future<List<Goods>> getGoodsById(int goodsId) async {
    final organizationId = await getSelectedOrganization();
    final String path = '/good/$goodsId?organization_id=$organizationId';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result')) {
        return [Goods.fromJson(data['result'] as Map<String, dynamic>)];
      } else {
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      throw Exception(
          'Ошибка загрузки просмотра товаров: ${response.statusCode}');
    }
  }

  Future<List<SubCategoryAttributesData>> getSubCategoryAttributes() async {
    final organizationId = await getSelectedOrganization();
    final String path =
        '/category/get/subcategories?organization_id=$organizationId';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('data')) {
        return (data['data'] as List)
            .map((item) => SubCategoryAttributesData.fromJson(
                item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      throw Exception(
          'Ошибка загрузки просмотра товаров: ${response.statusCode}');
    }
  }

Future<Map<String, dynamic>> createGoods({
  required String name,
  required int parentId,
  required String description,
  required int quantity,
  required List<Map<String, dynamic>> attributes,
  required List<Map<String, dynamic>> variants,
  required List<File> images,
  required bool isActive,
  double? discountPrice,
  required int branch,
  double? price, // Добавляем параметр price
}) async {
  try {
    final token = await getToken();
    final organizationId = await getSelectedOrganization();
    var uri = Uri.parse(
        '$baseUrl/good${organizationId != null ? '?organization_id=$organizationId' : ''}');
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Device': 'mobile',
      'Content-Type': 'multipart/form-data; charset=utf-8',
    });

    print('Sending createGoods request:');
    print('name: $name, parentId: $parentId, description: $description');
    print('quantity: $quantity, isActive: $isActive, discountPrice: $discountPrice, branch: $branch, price: $price');
    print('attributes: $attributes');
    print('variants: $variants');
    print('images: ${images.map((file) => file.path).toList()}');

    request.fields['name'] = name;
    request.fields['category_id'] = parentId.toString();
    request.fields['description'] = description;
    request.fields['quantity'] = quantity.toString();
    request.fields['is_active'] = isActive ? '1' : '0';

    // Добавляем price в корень, если оно передано
    if (price != null) {
      request.fields['price'] = price.toString();
      print('ApiService: Added price: $price');
    }

    // Добавляем discount_price, если оно передано
    if (discountPrice != null) {
      request.fields['discount_price'] = discountPrice.toString();
      print('ApiService: Added discount_price: $discountPrice');
    }

    // Исправляем отправку branch в формате branches[0][branch_id]
    request.fields['branches[0][branch_id]'] = branch.toString();
    print('ApiService: Added branches[0][branch_id]: $branch');

    for (int i = 0; i < attributes.length; i++) {
      request.fields['attributes[$i][category_attribute_id]'] =
          attributes[i]['category_attribute_id'].toString();
      request.fields['attributes[$i][value]'] =
          attributes[i]['value'].toString();
      print('ApiService: Added attribute $i: ${request.fields['attributes[$i][category_attribute_id]']}, ${request.fields['attributes[$i][value]']}');
    }

    for (int i = 0; i < variants.length; i++) {
      // Добавляем is_active для каждого варианта
      request.fields['variants[$i][is_active]'] =
          variants[i]['is_active'] ? '1' : '0';
      print('ApiService: Added variant $i is_active: ${variants[i]['is_active']}');

      // Добавляем price для варианта
      final variantPrice = variants[i]['price'] ?? 0.0;
      request.fields['variants[$i][price]'] = variantPrice.toString();
      print('ApiService: Added variant price $i: $variantPrice');

      List<dynamic> variantAttributes =
          variants[i]['variant_attributes'] ?? [];
      for (int j = 0; j < variantAttributes.length; j++) {
        request.fields[
                'variants[$i][variant_attributes][$j][category_attribute_id]'] =
            variantAttributes[j]['category_attribute_id'].toString();
        request.fields['variants[$i][variant_attributes][$j][value]'] =
            variantAttributes[j]['value'].toString();
        print('ApiService: Added variant attribute $i-$j: ${variantAttributes[j]}');
      }

      List<File> variantFiles = variants[i]['files'] ?? [];
      for (int j = 0; j < variantFiles.length; j++) {
        File file = variantFiles[j];
        if (await file.exists()) {
          final imageFile = await http.MultipartFile.fromPath(
              'variants[$i][files][$j]', file.path);
          request.files.add(imageFile);
          print('ApiService: Added variant file $i-$j: ${file.path}');
        } else {
          print('ApiService: Variant file not found, skipping: ${file.path}');
        }
      }
    }

    for (int i = 0; i < images.length; i++) {
      File file = images[i];
      if (await file.exists()) {
        final imageFile =
            await http.MultipartFile.fromPath('files[$i]', file.path);
        request.files.add(imageFile);
        print('ApiService: Added general image $i: ${file.path}');
      } else {
        print('ApiService: General image not found, skipping: ${file.path}');
      }
    }

    print('ApiService: Full request fields: ${request.fields}');
    print('ApiService: Full request files: ${request.files.map((file) => file.field).toList()}');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final responseBody = json.decode(response.body);

    print('ApiService: Response status: ${response.statusCode}');
    print('ApiService: Response body: $responseBody');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'message': 'Товар успешно создан',
        'data': responseBody,
      };
    } else {
      return {
        'success': false,
        'message': responseBody['message'] ?? 'Не удалось создать товар',
        'error': responseBody,
      };
    }
  } catch (e, stackTrace) {
    print('ApiService: Error in createGoods: $e');
    print('ApiService: Stack trace: $stackTrace');
    return {
      'success': false,
      'message': 'Произошла ошибка: $e',
    };
  }
}
  // Метод для обновления товара
Future<Map<String, dynamic>> updateGoods({
  required int goodId,
  required String name,
  required int parentId,
  required String description,
  required int quantity,
  required List<Map<String, dynamic>> attributes,
  required List<Map<String, dynamic>> variants,
  required List<File> images,
  required bool isActive,
  double? discountPrice,
  required int branch,
}) async {
  try {
    final token = await getToken();
    final organizationId = await getSelectedOrganization();
    var uri = Uri.parse(
        '$baseUrl/good/$goodId${organizationId != null ? '?organization_id=$organizationId' : ''}');
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Device': 'mobile',
      'Content-Type': 'multipart/form-data; charset=utf-8',
    });

    print('ApiService: Sending updateGoods request:');
    print('ApiService: goodId: $goodId, name: $name, parentId: $parentId, description: $description');
    print('ApiService: quantity: $quantity, isActive: $isActive, discountPrice: $discountPrice, branch: $branch');
    print('ApiService: attributes: $attributes');
    print('ApiService: variants: $variants');
    print('ApiService: images: ${images.map((file) => file.path).toList()}');

    request.fields['name'] = name;
    request.fields['category_id'] = parentId.toString();
    request.fields['description'] = description;
    request.fields['quantity'] = quantity.toString();
    request.fields['is_active'] = isActive ? '1' : '0';
    
    // Исправляем отправку branch в формате branches[0][branch_id]
    request.fields['branches[0][branch_id]'] = branch.toString();
    print('ApiService: Added branches[0][branch_id]: $branch');

    if (discountPrice != null) {
      request.fields['discount_price'] = discountPrice.toString();
      print('ApiService: Added discount_price: $discountPrice');
    }

    for (int i = 0; i < attributes.length; i++) {
      request.fields['attributes[$i][category_attribute_id]'] =
          attributes[i]['category_attribute_id'].toString();
      request.fields['attributes[$i][value]'] = attributes[i]['value'].toString();
      print('ApiService: Added attribute $i: ${request.fields['attributes[$i][category_attribute_id]']}, ${request.fields['attributes[$i][value]']}');
    }

    for (int i = 0; i < variants.length; i++) {
      if (variants[i].containsKey('id')) {
        request.fields['variants[$i][id]'] = variants[i]['id'].toString();
        print('ApiService: Added variant ID $i: ${variants[i]['id']}');
      }
      // Добавляем is_active для каждого варианта
      request.fields['variants[$i][is_active]'] =
          variants[i]['is_active'] ? '1' : '0';
      print('ApiService: Added variant $i is_active: ${variants[i]['is_active']}');

      request.fields['variants[$i][price]'] = (variants[i]['price'] ?? 0.0).toString();
      print('ApiService: Added variant price $i: ${variants[i]['price']}');

      List<dynamic> variantAttributes = variants[i]['variant_attributes'] ?? [];
      for (int j = 0; j < variantAttributes.length; j++) {
        if (variantAttributes[j].containsKey('id')) {
          request.fields['variants[$i][variant_attributes][$j][id]'] =
              variantAttributes[j]['id'].toString();
          print('ApiService: Added variant attribute ID $i-$j: ${variantAttributes[j]['id']}');
        }
        request.fields['variants[$i][variant_attributes][$j][category_attribute_id]'] =
            variantAttributes[j]['category_attribute_id'].toString();
        request.fields['variants[$i][variant_attributes][$j][value]'] =
            variantAttributes[j]['value'].toString();
        print('ApiService: Added variant attribute $i-$j: ${variantAttributes[j]}');
      }

      List<File> variantFiles = variants[i]['files'] ?? [];
      for (int j = 0; j < variantFiles.length; j++) {
        File file = variantFiles[j];
        if (await file.exists()) {
          final imageFile =
              await http.MultipartFile.fromPath('variants[$i][files][$j]', file.path);
          request.files.add(imageFile);
          print('ApiService: Added variant file $i-$j: ${file.path}');
        } else {
          print('ApiService: Variant file not found, skipping: ${file.path}');
        }
      }
    }

    for (int i = 0; i < images.length; i++) {
      File file = images[i];
      if (await file.exists()) {
        final imageFile = await http.MultipartFile.fromPath('files[$i]', file.path);
        request.files.add(imageFile);
        print('ApiService: Added general image $i: ${file.path}');
      } else {
        print('ApiService: General image not found, skipping: ${file.path}');
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final responseBody = json.decode(response.body);

    print('ApiService: Response status: ${response.statusCode}');
    print('ApiService: Response body: $responseBody');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'message': 'goods_updated_successfully',
        'data': responseBody,
      };
    } else {
      return {
        'success': false,
        'message': responseBody['message'] ?? 'Failed to update goods',
        'error': responseBody,
      };
    }
  } catch (e, stackTrace) {
    print('ApiService: Error in updateGoods: $e');
    print('ApiService: Stack trace: $stackTrace');
    return {
      'success': false,
      'message': 'An error occurred: $e',
    };
  }
}
  Future<bool> deleteGoods(int goodId, {int? organizationId}) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final orgId = await getSelectedOrganization();
      final effectiveOrgId = organizationId ??
          orgId; // Используем переданный organizationId или из getSelectedOrganization
      var uri = Uri.parse(
        '$baseUrl/good/$goodId${effectiveOrgId != null ? '?organization_id=$effectiveOrgId' : ''}',
      );

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Device': 'mobile',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
            jsonResponse['message'] ?? 'Ошибка при удалении товара');
      }
    } catch (e) {
      print('Ошибка удаления товара: $e');
      return false;
    }
  }

  //_________________________________ END____API_SCREEN__GOODS____________________________________________//

  //_________________________________ START_____API_SCREEN__ORDER____________________________________________//
// Метод для получение статусов заказы
  Future<List<OrderStatus>> getOrderStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();

    try {
      final response = await _getRequest(
          '/order-status${organizationId != null ? '?organization_id=$organizationId' : ''}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          await prefs.setString('cachedOrderStatuses_$organizationId',
              json.encode(data['result']));
          return (data['result'] as List)
              .map((status) => OrderStatus.fromJson(status))
              .toList();
        } else {
          throw Exception('Результат отсутствует в ответе');
        }
      } else {
        throw Exception('Ошибка сервера');
      }
    } catch (e) {
      print(
          'Ошибка загрузки статусов заказов. Используем кэшированные данные.');
      final cachedStatuses =
          prefs.getString('cachedOrderStatuses_$organizationId');
      if (cachedStatuses != null) {
        final decodedData = json.decode(cachedStatuses);
        return (decodedData as List)
            .map((status) => OrderStatus.fromJson(status))
            .toList();
      } else {
        throw Exception(
            'Ошибка загрузки статусов заказов и нет кэшированных данных!');
      }
    }
  }

  // Метод для получение карточки
  Future<OrderResponse> getOrders({
    int page = 1,
    int perPage = 20,
    int? statusId,
  }) async {
    final organizationId = await getSelectedOrganization();

    try {
      String url =
          '/order${organizationId != null ? '?organization_id=$organizationId' : ''}';
      url += '&page=$page&per_page=$perPage';
      if (statusId != null) {
        url += '&order_status_id=$statusId';
      }

      final response = await _getRequest(url);
      print('Request URL: $url'); // Логи для отладки
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final rawData = json.decode(response.body);
        final data = rawData['result'];
        print('Response data: $data'); // Логи для отладки
        return OrderResponse.fromJson(data);
      } else {
        throw Exception('Ошибка сервера!');
      }
    } catch (e) {
      print('Ошибка загрузки заказов: $e');
      throw e;
    }
  }

  //Метод для получение просмотра заказов
  Future<Order> getOrderDetails(int orderId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final organizationId = await getSelectedOrganization();

    try {
      final response = await _getRequest(
        '/order/$orderId${organizationId != null ? '?organization_id=$organizationId' : ''}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['result'];
        final order = Order.fromJson(data);
        await prefs.setString('cachedOrder_$orderId', json.encode(data));
        return order;
      } else {
        throw Exception('Ошибка сервера!');
      }
    } catch (e) {
      print(
          'Ошибка загрузки деталей заказа: $e. Используем кэшированные данные.');
      final cachedOrder = prefs.getString('cachedOrder_$orderId');
      if (cachedOrder != null) {
        final decodedData = json.decode(cachedOrder);
        return Order.fromJson(decodedData);
      } else {
        throw Exception(
            'Ошибка загрузки деталей заказа и нет кэшированных данных!');
      }
    }
  }

Future<Map<String, dynamic>> createOrder({
  required String phone,
  required int leadId,
  required bool delivery,
  required String deliveryAddress,
  required List<Map<String, dynamic>> goods,
  required int organizationId,
  required int statusId,
  int? branchId,
  String? commentToCourier,
}) async {
  try {
    final token = await getToken();
    if (token == null) throw Exception('Токен не найден');

    final uri = Uri.parse('$baseUrl/order?organization_id=$organizationId');
    final body = {
      'phone': phone,
      'lead_id': leadId,
      'deliveryType': delivery ? 'delivery' : 'pickup',
      'goods': goods,
      'organization_id': organizationId.toString(),
      'status_id': statusId,
    };

    if (delivery) {
      body['delivery_address'] = deliveryAddress;
    } else {
      body['delivery_address_id'] = 0;
      body['branch_id'] = branchId!.toString();
      body['comment_to_courier'] = commentToCourier!;
    }

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Device': 'mobile',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      final returnedStatusId = jsonResponse['result']['status_id'] ?? statusId;
      return {
        'success': true,
        'statusId': returnedStatusId,
        'order': jsonResponse['result'],
      };
    } else {
      final jsonResponse = jsonDecode(response.body);
      throw Exception(jsonResponse['message'] ?? 'Ошибка при создании заказа');
    }
  } catch (e) {
    print('Ошибка создания заказа: $e');
    return {'success': false, 'error': e.toString()};
  }
}

  // Метод для редактирование заказа
Future<Map<String, dynamic>> updateOrder({
  required int orderId,
  required String phone,
  required int leadId,
  required bool delivery,
  required String deliveryAddress,
  required List<Map<String, dynamic>> goods,
  required int organizationId,
  int? branchId,
  String? commentToCourier,
}) async {
  try {
    final token = await getToken();
    if (token == null) throw Exception('Токен не найден');

    final uri = Uri.parse('$baseUrl/order/$orderId?organization_id=$organizationId');
    final body = {
      'phone': phone,
      'lead_id': leadId,
      'deliveryType': delivery ? 'delivery' : 'pickup',
      'goods': goods,
      'organization_id': organizationId.toString(),
    };

    if (delivery) {
      body['delivery_address'] = deliveryAddress;
    } else {
      body['delivery_address_id'] = 0;
      body['branch_id'] = branchId!.toString();
      body['comment_to_courier'] = commentToCourier!;
    }

    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Device': 'mobile',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return {
        'success': true,
        'order': jsonResponse['result'],
      };
    } else {
      final jsonResponse = jsonDecode(response.body);
      throw Exception(jsonResponse['message'] ?? 'Ошибка при обновлении заказа');
    }
  } catch (e) {
    print('Ошибка обновления заказа: $e');
    return {'success': false, 'error': e.toString()};
  }
}

  Future<bool> deleteOrder({
    required int orderId,
    required int? organizationId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final uri =
          Uri.parse('$baseUrl/order/$orderId?organization_id=$organizationId');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
            jsonResponse['message'] ?? 'Ошибка при удалении заказа');
      }
    } catch (e) {
      print('Ошибка удаления заказа: $e');
      return false;
    }
  }

// api_service.dart
  Future<bool> changeOrderStatus({
    required int orderId,
    required int statusId,
    required int? organizationId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      final uri = Uri.parse(
          '$baseUrl/order/changeStatus/$orderId${organizationId != null ? '?organization_id=$organizationId' : ''}');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Device': 'mobile',
        },
        body: jsonEncode({
          'status_id': statusId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
            jsonResponse['message'] ?? 'Ошибка при смене статуса заказа');
      }
    } catch (e) {
      print('Ошибка смены статуса заказа: $e');
      return false;
    }
  }

  Future<List<Branch>> getBranches() async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
        '/branch${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        List<Branch> branches = List<Branch>.from(
            data['result'].map((branch) => Branch.fromJson(branch)));
        return branches;
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка при получении данных: ${response.statusCode}');
    }
  }

  Future<List<LeadOrderData>> getLeadOrders() async {
    final organizationId = await getSelectedOrganization();
    String path = '/lead?organization_id=$organizationId';

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result') && data['result']['data'] is List) {
        return (data['result']['data'] as List<dynamic>)
            .map((e) => LeadOrderData.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      throw Exception('Ошибка загрузки LeadOrder: ${response.statusCode}');
    }
  }



Future<List<CalendarEvent>> getCalendarEventsByMonth(
    int month, {
    String? search,
    List<String>? types,
    List<String>? userIds, // Added parameter for user IDs
}) async {
  final organizationId = await getSelectedOrganization();

  String url = '/calendar/getByMonth?month=$month';

  if (search != null && search.isNotEmpty) {
    url += '&search=$search';
  }

  if (organizationId != null) {
    url += '&organization_id=$organizationId';
  }

  if (types != null && types.isNotEmpty) {
    url += types.map((type) => '&type[]=$type').join();
  }

  if (userIds != null && userIds.isNotEmpty) {
    url += userIds.map((userId) => '&user_id[]=$userId').join(); // Append user IDs
  }

  final response = await _getRequest(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['result'] != null && data['result'] is List) {
      return (data['result'] as List).map((item) => CalendarEvent.fromJson(item)).toList();
    }
    throw ('Ошибка формата загрузки календаря!');
  } else {
    throw ('Ошибка загрузки календаря!');
  }
}
  

  //_________________________________ END_____API_SCREEN__ORDER____________________________________________//
}
