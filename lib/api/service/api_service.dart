import 'dart:convert';
import 'dart:io';
// import 'package:crm_task_manager/models/chart_data.dart';
// import 'package:crm_task_manager/models/dashboard_charts_models/lead_conversion_model.dart';
import 'package:crm_task_manager/models/chatById_model.dart';
import 'package:crm_task_manager/models/chatGetId_model.dart';
import 'package:crm_task_manager/models/chatTaskProfile_model.dart';
import 'package:crm_task_manager/models/contact_person_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/deal_stats_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_conversion_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_chart_model.dart';
import 'package:crm_task_manager/models/deal_task_model.dart';
import 'package:crm_task_manager/models/lead_deal_model.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/lead_navigate_to_chat.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/notifications_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/project_chart_model.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/task_chart_model.dart';
import 'package:crm_task_manager/models/organization_model.dart';
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
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/notes_model.dart';
import 'package:crm_task_manager/models/pagination_dto.dart';
import 'package:crm_task_manager/models/project_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/models/role_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/taskbyId_model.dart';
import 'package:crm_task_manager/models/user_add_task_model.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/models/user_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/task/task_details/task_dropdown_bottom_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/domain_check.dart';
import '../../models/login_model.dart';

// final String baseUrl = 'https://fingroup-back.shamcrm.com/api';
// final String baseUrlSocket ='https://fingroup-back.shamcrm.com/broadcasting/auth';

class ApiService {
  late final String baseUrl;
  late final String baseUrlSocket;
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
    baseUrlSocket = await getSocketBaseUrl();
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
      '/login',
      (route) => false,
    );
  }

  Future<String> getDynamicBaseUrl() async {
    String? domain = await getEnteredDomain();
    if (domain != null && domain.isNotEmpty) {
      return 'https://$domain-back.shamcrm.com/api';
    } else {
      throw Exception('Домен не установлен в SharedPreferences');
    }
  }

  Future<String> getSocketBaseUrl() async {
    String? domain = await getEnteredDomain();
    if (domain != null && domain.isNotEmpty) {
      return 'https://$domain-back.shamcrm.com/broadcasting/auth';
    } else {
      throw Exception('Домен не установлен в SharedPreferences');
    }
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
    await _removeToken();
    await _removePermissions(); // Удаляем права доступа
    await _removeOrganizationId(); // Удаляем права доступа
  }

  Future<void> _removePermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs
        .remove('permissions'); // Удаляем права доступа из SharedPreferences
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
        if (token != null)
          'Authorization': 'Bearer $token', // Добавляем токен, если он есть
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
      print('Статус ответа: ${response.statusCode}');
    }
    if (kDebugMode) {
      print('getAll user: ${response.body}');
    }

    return dataUser;
  }

  // create new client
  Future<http.Response> createNewClient(String userID) async {
    final token = await getToken();
    final organizationId = await getSelectedOrganization();

    final response = await http.post(
      Uri.parse(
          '$baseUrl/chat/createChat/$userID${organizationId != null ? '?organization_id=$organizationId' : ''}'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null)
          'Authorization': 'Bearer $token', // Добавляем токен, если он есть
      },
    );

    if (kDebugMode) {
      print('Статус ответа: ${response.statusCode}');
    }
    if (kDebugMode) {
      print('data: ${response.body}');
    }

    return response;
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
      },
    );

    print('Статус ответа: ${response.statusCode}');
    print('Тело ответа: ${response.body}');

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
      },
      body: json.encode(body),
    );

    print('Статус ответа: ${response.statusCode}');
    print('Тело ответа: ${response.body}');

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
      },
      body: json.encode(body),
    );

    print('Статус ответа: ${response.statusCode}');
    print('Тело ответа: ${response.body}');

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
      },
    );

    print('Статус ответа: ${response.statusCode}');
    print('Тело ответа: ${response.body}');

    return _handleResponse(response);
  }

  // Метод для выполнения POST-запросов
  Future<http.Response> _postRequestDomain(
      String path, Map<String, dynamic> body) async {
    final String DomainUrl = 'https://shamcrm.com/api';
    final token = await getToken(); // Получаем токен перед запросом
    final response = await http.post(
      Uri.parse('$DomainUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',

        if (token != null)
          'Authorization': 'Bearer $token', // Добавляем токен, если он есть
      },
      body: json.encode(body),
    );

    print('Статус ответа: ${response.statusCode}');
    print('Тело ответа: ${response.body}');

    return response;
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
      },
      body: json.encode({
        'type': 'mobile', // Указываем тип устройства
        'token': deviceToken, // Передаем FCM-токен устройства
      }),
    );

    if (response.statusCode == 200) {
      print('FCM-токен успешно отправлен!');
    } else {
      print('Ошибка при отправке FCM-токена: ${response.statusCode}');
      throw Exception('Ошибка: ${response.body}');
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
      throw Exception('Ошибка получения чата: ${response.body}');
    }
  }

  //_________________________________ END___API__METHOD__POST__DEVICE__TOKEN_________________________________________________//

  //_________________________________ START___API__DOMAIN_CHECK____________________________________________//

  // Метод для проверки домена
  Future<DomainCheck> checkDomain(String domain) async {
    final organizationId = await getSelectedOrganization();
    final response = await _postRequestDomain(
        '/checkDomain${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {'domain': domain});

    if (response.statusCode == 200) {
      return DomainCheck.fromJson(json.decode(response.body));
    } else {
      throw Exception('Не удалось загрузить домен: ${response.body}');
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
  Future<void> saveDomain(String domain) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('enteredDomain', domain);
  }

// Метод для получения введенного домена
  Future<String?> getEnteredDomain() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs
        .getString('enteredDomain'); // Возвращаем введенный домен или null
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

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final loginResponse = LoginResponse.fromJson(data);

      await _saveToken(loginResponse.token);
      await _savePermissions(
          loginResponse.permissions); // Сохраняем права доступа

      return loginResponse;
    } else {
      throw Exception('Неправильный Логин или Пароль: ${response.body}');
    }
  }

// Метод для сохранения прав доступа в SharedPreferences
  Future<void> _savePermissions(List<String> permissions) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'permissions', permissions); // Сохраняем список прав
  }

// Метод для получения списка прав доступа
  Future<List<String>> getPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('permissions') ??
        []; // Возвращаем список прав доступа или пустой список
  }

// Метод для проверки, есть ли у пользователя определенное право
  Future<bool> hasPermission(String permission) async {
    final permissions = await getPermissions();
    return permissions.contains(permission); // Проверяем наличие права
  }

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
        print('Ошибка API forgotPin: ${response.statusCode}');
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка в forgotPin: $e');
      throw Exception('Ошибка в запросе: $e');
    }
  }

  //_________________________________ END___API__LOGIN____________________________________________//

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
        print('Failed to load lead ID: ${response.statusCode}');
        throw Exception('Ошибка загрузки лида ID: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
      throw Exception('Ошибка загрузки лида ID: $e');
    }
  }

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
        print('Ошибка загрузки профиля чата: ${response.statusCode}');
        throw Exception('${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка в getChatProfile: $e');
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

      print(
          'Response status code: ${response.statusCode}'); // Логируем статус ответа
      print('Response body: ${response.body}'); // Логируем тело ответа

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
        print('Ошибка загрузки задачи: ${response.statusCode}');
        throw Exception('Ошибка загрузки задачи: ${response.statusCode}');
      }
    } catch (e) {
      print('Полная ошибка в getTaskProfile: $e');
      print('Трассировка стека: ${StackTrace.current}');
      throw Exception('Ошибка загрузки задачи: $e');
    }
  }

//Метод для получения список Лидов с пагинацией
  Future<List<Lead>> getLeads(int? leadStatusId,
      {int page = 1, int perPage = 20, String? search}) async {
    final organizationId = await getSelectedOrganization();
    String path = '/lead?page=$page&per_page=$perPage';

    // Добавляем параметр organization_id
    path += '&organization_id=$organizationId';

    if (leadStatusId != null) {
      path += '&lead_status_id=$leadStatusId';
    }

    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    // Логируем конечный URL запроса
    print('Sending request to API with path: $path');
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((json) => Lead.fromJson(json, leadStatusId ?? -1))
            .toList();
      } else {
        throw Exception('Нет данных о лидах в ответе');
      }
    } else {
      throw Exception('Ошибка загрузки лидов: ${response.body}');
    }
  }

  // Метод для получения статусов лидов
  Future<List<LeadStatus>> getLeadStatuses() async {
    final organizationId = await getSelectedOrganization();
    final response = await _getRequest(
        '/lead/statuses${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return (data['result'] as List)
            .map((status) => LeadStatus.fromJson(status))
            .toList();
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }
  }

  // Метод для создания Cтатуса Лида
  Future<Map<String, dynamic>> createLeadStatus(
      String title, String color) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
        '/lead-status${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'title': title,
          'color': color,
        });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'Статус лида создан успешно'};
    } else {
      return {
        'success': false,
        'message': 'Ошибка создания статуса лида: ${response.body}'
      };
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
      print('Статус задачи обновлен успешно.');
    } else if (response.statusCode == 422) {
      throw LeadStatusUpdateException(
        422,
        'Вы не можете переместить задачу на этот статус',
      );
    } else {
      throw Exception('Ошибка обновления задач лида: ${response.body}');
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
        print('Failed to load lead history: ${response.statusCode}');
        throw Exception('Ошибка загрузки истории лида: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
      throw Exception('Ошибка загрузки истории лида: $e');
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
  }) async {
    date ??= DateTime.now();
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
        '/notices${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'title': title,
          'body': body,
          'lead_id': leadId,
          'date': date.toIso8601String(),
        });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'Заметка создана успешно.'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('title')) {
        return {
          'success': false,
          'message': 'Ошибка! Поля не может быть пустым.'
        };
      } else if (response.body.contains('body')) {
        return {
          'success': false,
          'message': 'Ошибка! Поля не может быть пустым.'
        };
      } else if (response.body.contains('date')) {
        return {'success': false, 'message': 'Не правильная дата.'};
      } else {
        return {
          'success': false,
          'message': 'Неизвестная ошибка: ${response.body}'
        };
      }
    } else {
      return {
        'success': false,
        'message': 'Ошибка создания Заметки: ${response.body}'
      };
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
      return {'success': true, 'message': 'Заметка обновлена успешно.'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('title')) {
        return {
          'success': false,
          'message': 'Ошибка! Поля не может быть пустым.'
        };
      } else if (response.body.contains('body')) {
        return {
          'success': false,
          'message': 'Ошибка! Поля не может быть пустым.'
        };
      } else if (response.body.contains('date')) {
        return {'success': false, 'message': 'Не правильная дата.'};
      } else {
        return {
          'success': false,
          'message': 'Неизвестная ошибка: ${response.body}'
        };
      }
    } else {
      return {
        'success': false,
        'message': 'Ошибка создания Заметки: ${response.body}'
      };
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
      throw Exception('Failed to delete note: ${response.body}');
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

  // Метод для Создания Лида
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
  }) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
        '/lead${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'name': name,
          'lead_status_id': leadStatusId,
          'phone': phone,
          if (regionId != null) 'region_id': regionId,
          if (managerId != null) 'manager_id': managerId,
          if (sourceId != null) 'source_id': sourceId,
          if (instaLogin != null) 'insta_login': instaLogin,
          if (facebookLogin != null) 'facebook_login': facebookLogin,
          if (tgNick != null) 'tg_nick': tgNick,
          if (birthday != null)
            'birthday': birthday.toIso8601String(), // Конвертация в строку
          if (email != null) 'email': email,
          if (description != null) 'description': description,
          if (waPhone != null) 'wa_phone': waPhone,
          // Здесь добавляем deal_custom_fields
          'lead_custom_fields': customFields?.map((field) {
                // Изменяем структуру для соответствия новому формату
                return {
                  'key': field.keys.first,
                  'value': field.values.first,
                };
              }).toList() ??
              [],
        });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'Лид создан успешно.'};
    } else if (response.statusCode == 422) {
      // Обработка ошибки дублирования номера телефона
      if (response.body.contains('The phone has already been taken.')) {
        return {
          'success': false,
          'message': 'Этот номер телефона уже существует.'
        };
      }
      if (response.body.contains('validation.phone')) {
        return {
          'success': false,
          'message':
              'Неправильный номер телефона. Проверьте формат и количество цифр.'
        };
      }
      if (response.body
          .contains('The email field must be a valid email address.')) {
        return {
          'success': false,
          'message': 'Неправильный e-mail!! Введите корректный e-mail.'
        };
      }
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'Введите хотябы 3-х символов!.'};
      }
      // Обработка ошибки дублирования логина Instagram
      else if (response.body.contains('insta_login')) {
        return {
          'success': false,
          'message': 'Этот логин Instagram уже используется.'
        };
      } else if (response.body.contains('facebook_login')) {
        return {
          'success': false,
          'message': 'Этот логин facebook уже используется.'
        };
      } else if (response.body.contains('tg_nick')) {
        return {
          'success': false,
          'message': 'Этот логин Telegram уже используется.'
        };
      } else if (response.body.contains('birthday')) {
        return {'success': false, 'message': 'Не правильная дата рождения.'};
      } else if (response.body.contains('wa_phone')) {
        return {
          'success': false,
          'message': 'Этот номер Whatsapp уже существует.'
        };
      } else {
        return {
          'success': false,
          'message': 'Неизвестная ошибка: ${response.body}'
        };
      }
    } else if (response.statusCode == 500) {
      return {
        'success': false,
        'message': 'Ошибка на сервере. Попробуйте позже.'
      };
    } else {
      return {
        'success': false,
        'message': 'Ошибка создания лида: ${response.body}'
      };
    }
  }

  // Метод для Обновления Лида
  Future<Map<String, dynamic>> updateLead({
    required int leadId,
    required String name,
    required int leadStatusId,
    required String phone,
    int? regionId,
    int? managerId,
    String? instaLogin,
    String? facebookLogin,
    String? tgNick,
    DateTime? birthday,
    String? email,
    String? description,
    int? organizationId,
    String? waPhone,
    List<Map<String, String>>? customFields,
  }) async {
    final organizationId = await getSelectedOrganization();

    final response = await _patchRequest(
        '/lead/$leadId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'name': name,
          'lead_status_id': leadStatusId,
          'phone': phone,
          if (regionId != null) 'region_id': regionId,
          if (managerId != null) 'manager_id': managerId,
          if (instaLogin != null) 'insta_login': instaLogin,
          if (facebookLogin != null) 'facebook_login': facebookLogin,
          if (tgNick != null) 'tg_nick': tgNick,
          if (birthday != null) 'birthday': birthday.toIso8601String(),
          if (email != null) 'email': email,
          if (description != null) 'description': description,
          if (organizationId != null) 'organization_id': organizationId,
          if (waPhone != null) 'wa_phone': waPhone,
        });

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Лид обновлен успешно.'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('phone')) {
        return {
          'success': false,
          'message':
              'Неправильный номер телефона. Проверьте формат и количество цифр.'
        };
      }
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'Введите хотя бы 3-х символов!.'};
      }
      if (response.body.contains('birthday')) {
        return {'success': false, 'message': 'Не правильная дата рождения.'};
      }
      if (response.body
          .contains('The email field must be a valid email address.')) {
        return {
          'success': false,
          'message': 'Неправильный e-mail!! Введите корректный e-mail.'
        };
      }
      // Другие проверки на ошибки...
      return {
        'success': false,
        'message': 'Неизвестная ошибка: ${response.body}'
      };
    } else if (response.statusCode == 500) {
      return {
        'success': false,
        'message': 'Ошибка на сервере. Попробуйте позже.'
      };
    } else {
      return {
        'success': false,
        'message': 'Ошибка обновления лида: ${response.body}'
      };
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
      throw Exception('Ошибка при получении данных: ${response.statusCode}');
    }

    if (kDebugMode) {
      print('getAll region: ${response.body}');
    }

    return dataRegion;
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
      throw Exception('Ошибка при получении данных: ${response.statusCode}');
    }

    if (kDebugMode) {
      print('getAll manager: ${response.body}');
    }

    return dataManager;
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
      throw Exception('Ошибка при получении данных: ${response.statusCode}');
    }

    if (kDebugMode) {
      print('getAll lead: ${response.body}');
    }

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
      throw Exception('Failed to delete leadStatus: ${response.body}');
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
      throw Exception('Failed to delete lead: ${response.body}');
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
      return {'success': true, 'message': 'Заметка создана успешно.'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'Введите хотя бы 3-х символов!.'};
      }
      if (response.body.contains('The phone has already been taken.')) {
        return {
          'success': false,
          'message': 'Этот номер телефона уже существует.'
        };
      }
      if (response.body.contains('validation.phone')) {
        return {
          'success': false,
          'message':
              'Неправильный номер телефона. Проверьте формат и количество цифр.'
        };
      } else if (response.body.contains('position')) {
        return {'success': false, 'message': 'Поля не может быть пустым.'};
      } else {
        return {
          'success': false,
          'message': 'Неизвестная ошибка: ${response.body}'
        };
      }
    } else {
      return {
        'success': false,
        'message': 'Ошибка создания Контактного лица: ${response.body}'
      };
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
      return {'success': true, 'message': 'Заметка создана успешно.'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'Введите хотя бы 3-х символов!.'};
      }
      if (response.body.contains('The phone has already been taken.')) {
        return {
          'success': false,
          'message': 'Этот номер телефона уже существует.'
        };
      }
      if (response.body.contains('validation.phone')) {
        return {
          'success': false,
          'message':
              'Неправильный номер телефона. Проверьте формат и количество цифр.'
        };
      } else if (response.body.contains('position')) {
        return {'success': false, 'message': 'Поля не может быть пустым.'};
      } else {
        return {
          'success': false,
          'message': 'Неизвестная ошибка: ${response.body}'
        };
      }
    } else {
      return {
        'success': false,
        'message': 'Ошибка создания Контактного лица: ${response.body}'
      };
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
      throw Exception('Failed to delete contactPerson: ${response.body}');
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
        print('Ошибка отправки в 1С Лид: ${response.statusCode}');
        throw Exception('Ошибка отправки в 1С: ${response.statusCode}');
      }
    } catch (e) {
      print('Произошла ошибка: $e');
      throw Exception('Ошибка отправки в 1С: $e');
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
  //       print('Ошибка отправки в  1С Лид: ${response.statusCode}');
  //       throw Exception('Ошибка отправки в  Лид 1С: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Произошла ошибка: $e');
  //     throw Exception('Ошибка отправки 1С Лид: $e');
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
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }
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
        throw Exception('Ошибка загрузки deal ID: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки deal ID: $e');
    }
  }

  Future<List<Deal>> getDeals(int? dealStatusId,
      {int page = 1, int perPage = 20, String? search}) async {
    final organizationId =
        await getSelectedOrganization(); // Получаем ID организации
    String path = '/deal?page=$page&per_page=$perPage';

    // Добавляем параметр organization_id
    path += '&organization_id=$organizationId';

    // Добавляем параметр deal_status_id, если он передан
    if (dealStatusId != null) {
      path += '&deal_status_id=$dealStatusId';
    }

    // Добавляем параметр поиска, если он передан
    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    // Логируем конечный URL запроса
    print('Sending request to API with path: $path');
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
      // Логирование ошибки с ответом сервера
      print('Error response: ${response.statusCode} - ${response.body}');
      throw Exception('Ошибка загрузки сделок: ${response.body}');
    }
  }

  // Метод для получения статусов Сделок
  Future<List<DealStatus>> getDealStatuses() async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
        '/deal/statuses${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return (data['result'] as List)
            .map((status) => DealStatus.fromJson(status))
            .toList();
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }
  }

// Метод для создания Cтатуса Сделки
  Future<Map<String, dynamic>> createDealStatus(
      String title, String color, int day) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
        '/deal/statuses${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'title': title,
          'day': day,
          'color': color,
        });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'Статус сделки создан успешно'};
    } else {
      return {
        'success': false,
        'message': 'Ошибка создания статуса сделки: ${response.body}'
      };
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
        print('Failed to load deal history: ${response.statusCode}');
        throw Exception(
            'Ошибка загрузки истории сделки: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
      throw Exception('Ошибка загрузки истории сделки: $e');
    }
  }

  //Обновление статуса карточки Сделки  в колонке
  Future<void> updateDealStatus(int dealId, int position, int statusId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
      '/deal/changeStatus/$dealId${organizationId != null ? '?organization_id=$organizationId' : ''}',
      {
        'position': position,
        'status_id': statusId,
      },
    );

    if (response.statusCode == 200) {
      print('Статус задачи обновлен успешно.');
    } else if (response.statusCode == 422) {
      throw DealStatusUpdateException(
        422,
        'Вы не можете переместить задачу на этот статус',
      );
    } else {
      throw Exception('Ошибка обновления задач сделки: ${response.body}');
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
      return {'success': true, 'message': 'Сделка создана успешно.'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'Введите хотя бы 3-х символов!.'};
      }
      // Другие проверки на ошибки...
      return {
        'success': false,
        'message': 'Неизвестная ошибка: ${response.body}'
      };
    } else if (response.statusCode == 500) {
      return {
        'success': false,
        'message': 'Ошибка на сервере. Попробуйте позже.'
      };
    } else {
      return {
        'success': false,
        'message': 'Ошибка обновления лида: ${response.body}'
      };
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
      return {'success': true, 'message': 'Сделка обновлена успешно.'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('"name"')) {
        return {
          'success': false,
          'message': 'Название должно содержать не менее 3 символов.'
        };
      }
      // Дополнительные проверки на другие поля могут быть добавлены здесь...
      return {
        'success': false,
        'message': 'Неизвестная ошибка: ${response.body}'
      };
    } else if (response.statusCode == 500) {
      return {
        'success': false,
        'message': 'Ошибка на сервере. Попробуйте позже.'
      };
    } else {
      return {
        'success': false,
        'message': 'Ошибка обновления лида: ${response.body}'
      };
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
      throw Exception('Failed to delete dealStatus: ${response.body}');
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
      throw Exception('Failed to delete deal: ${response.body}');
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
      } else {
        throw Exception('Ошибка загрузки task ID: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки task ID: $e');
    }
  }

  Future<List<Task>> getTasks(int? taskStatusId,
      {int page = 1, int perPage = 20, String? search}) async {
    final organizationId =
        await getSelectedOrganization(); // Получаем ID организации
    String path = '/task?page=$page&per_page=$perPage';

    // Добавляем параметр organization_id
    path += '&organization_id=$organizationId';

    // Добавление параметра task_status_id, если он передан
    if (taskStatusId != null) {
      path += '&task_status_id=$taskStatusId';
    }

    // Добавление параметра поиска, если он передан
    if (search != null && search.isNotEmpty) {
      path += '&search=$search';
    }

    // Логируем конечный URL запроса
    print('Sending request to API with path: $path');
    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result']['data'] != null) {
        // Логирование задач
        final tasks = (data['result']['data'] as List).map((json) {
          return Task.fromJson(json, taskStatusId ?? -1);
        }).toList();

        return tasks;
      } else {
        throw Exception('Нет данных о задачах в ответе');
      }
    } else {
      throw Exception('Ошибка загрузки задач: ${response.body}');
    }
  }

  // Метод для получения статусов Задач
  Future<List<TaskStatus>> getTaskStatuses() async {
    final organizationId = await getSelectedOrganization();

    final response = await _getRequest(
        '/task-status${organizationId != null ? '?organization_id=$organizationId' : ''}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return (data['result'] as List)
            .map((status) => TaskStatus.fromJson(status))
            .toList();
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }
  }

//Обновление статуса карточки Задачи  в колонке

  Future<void> updateTaskStatus(int taskId, int position, int statusId) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
        '/task/changeStatus/$taskId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'position': position,
          'status_id': statusId,
        });

    if (response.statusCode == 200) {
      print('Статус задачи обновлен успешно.');
    } else if (response.statusCode == 422) {
      throw TaskStatusUpdateException(
          422, 'Вы не можете переместить задачу на этот статус');
    } else {
      throw Exception('Ошибка обновления задач сделки: ${response.body}');
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
      'message': 'Ошибка ${operation} задачи: ${response.body}',
    };
  }

  // Общий метод обработки ошибок
  Exception _handleErrorResponse(http.Response response, String operation) {
    try {
      final data = json.decode(response.body);
      final errorMessage = data['errors'] ?? data['message'] ?? response.body;
      return Exception(
          'Ошибка ${operation}: ${response.statusCode} - $errorMessage');
    } catch (e) {
      return Exception(
          'Ошибка ${operation}: ${response.statusCode} - ${response.body}');
    }
  }

  /// Создает новый статус задачи
  Future<Map<String, dynamic>> CreateTaskStatusAdd({
    required int taskStatusNameId,
    required int projectId,
    required int organizationId,
    required bool needsPermission,
    List<int>? roleIds,
    bool? finalStep,
  }) async {
    try {
      // Формируем данные для запроса
      final Map<String, dynamic> data = {
        'task_status_name_id': taskStatusNameId,
        'project_id': projectId,
        'organization_id': organizationId,
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
        'message': '$errorMessage: ${response.body}',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка при выполнении запроса: $e',
        'error': e.toString(),
      };
    }
  }

  // Метод для создания задачи
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
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'name': name,
        'status_id': statusId,
        'task_status_id': taskStatusId,
        'priority_level': priority, // Используем строковое значение приоритета
        if (startDate != null) 'from': startDate.toIso8601String(),
        if (endDate != null) 'to': endDate.toIso8601String(),
        if (projectId != null) 'project_id': projectId,
        if (userId != null)
          'users': userId
              .map((id) => {'user_id': id})
              .toList(), // Передаем список как массив
        if (description != null) 'description': description,
        // Здесь добавляем deal_custom_fields
        'task_custom_fields': customFields?.map((field) {
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
        '/task${organizationId != null ? '?organization_id=$organizationId' : ''}',
        requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Задача успешно создана.',
        };
      } else if (response.statusCode == 422) {
        // Обработка ошибок валидации
        if (response.body.contains('name')) {
          return {
            'success': false,
            'message': 'Название задачи должно быть не менее 3 символов.',
          };
        }
        if (response.body.contains('from')) {
          return {
            'success': false,
            'message': 'Дата начала задачи указана некорректно.',
          };
        }
        if (response.body.contains('to')) {
          return {
            'success': false,
            'message': 'Дата завершения задачи указана некорректно.',
          };
        }
        if (response.body.contains('priority_level')) {
          return {
            'success': false,
            'message': 'Указан некорректный уровень приоритета.',
          };
        }
        return {
          'success': false,
          'message': 'Неизвестная ошибка: ${response.body}',
        };
      } else if (response.statusCode == 500) {
        // Обработка ошибки сервера
        return {
          'success': false,
          'message': 'Ошибка на сервере. Попробуйте позже.',
        };
      } else {
        return {
          'success': false,
          'message': 'Ошибка создания задачи: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка при создании задачи: $e',
      };
    }
  }

// Обновленный метод обновления задачи
  Future<Map<String, dynamic>> updateTask({
    required int taskId,
    required String name,
    required int statusId,
    required int taskStatusId,
    String? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? projectId,
    List<int>? userId,
    String? description,
    Map<String, dynamic>? file,
        List<Map<String, String>>? customFields,

  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'name': name,
        'status_id': statusId,
        'task_status_id': taskStatusId,
        'priority_level': priority, // Используем строковое значение приоритета
        if (startDate != null) 'from': startDate.toIso8601String(),
        if (endDate != null) 'to': endDate.toIso8601String(),
        if (projectId != null) 'project_id': projectId,
        if (userId != null)
          'users': userId.map((id) => {'user_id': id}).toList(),
        if (file != null) 'file': file,
        if (description != null) 'description': description,
      };

      final organizationId = await getSelectedOrganization();

      final response = await _postRequest(
        '/task/$taskId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Задача успешно обновлена.',
        };
      } else if (response.statusCode == 422) {
        // Обработка ошибок валидации
        if (response.body.contains('name')) {
          return {
            'success': false,
            'message': 'Название задачи должно быть не менее 3 символов.',
          };
        }
        if (response.body.contains('from')) {
          return {
            'success': false,
            'message': 'Дата начала задачи указана некорректно.',
          };
        }
        if (response.body.contains('to')) {
          return {
            'success': false,
            'message': 'Дата завершения задачи указана некорректно.',
          };
        }
        if (response.body.contains('priority_level')) {
          return {
            'success': false,
            'message': 'Указан некорректный уровень приоритета.',
          };
        }
        return {
          'success': false,
          'message': 'Неизвестная ошибка: ${response.body}',
        };
      } else if (response.statusCode == 500) {
        // Обработка ошибки сервера
        return {
          'success': false,
          'message': 'Ошибка на сервере. Попробуйте позже.',
        };
      } else {
        return {
          'success': false,
          'message': 'Ошибка обновления задачи: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка при обновлении задачи: $e',
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
        print('Failed to load task history: ${response.statusCode}');
        throw Exception(
            'Ошибка загрузки истории задач: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
      throw Exception('Ошибка загрузки истории задач: $e');
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
      throw Exception('Ошибка при получении данных: ${response.statusCode}');
    }

    if (kDebugMode) {
      print('getAll project: ${response.body}');
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
      print('Статус ответа: ${response.statusCode}');
      print('Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Убедитесь, что данные соответствуют ожидаемой структуре
        if (data['result'] != null && data['result'] is List) {
          final usersList = (data['result'] as List)
              .map((user) => UserTask.fromJson(user))
              .toList();

          print('Получено пользователей: ${usersList.length}');
          return usersList;
        } else {
          print('Структура данных неверна: $data');
          throw Exception('Неверная структура данных пользователей');
        }
      } else {
        print('Ошибка HTTP: ${response.statusCode}');
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при получении пользователей: $e');
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
  //   throw Exception('Ошибка ${response.statusCode}: ${response.body}');
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
      throw Exception('Ошибка при получении ролей: ${response.statusCode}');
    }
  }

// Метод для получения Cтатуса задачи
  Future<List<StatusName>> getStatusName() async {
    final organizationId = await getSelectedOrganization();

    print('Начало запроса статусов задач'); // Отладочный вывод
    final response = await _getRequest(
        '/taskStatusName${organizationId != null ? '?organization_id=$organizationId' : ''}');
    print('Статус код ответа: ${response.statusCode}'); // Отладочный вывод

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
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
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
      throw Exception('Failed to delete task: ${response.body}');
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
      throw Exception('Failed to delete taskStatus: ${response.body}');
    }
  }
  //_________________________________ END_____API_SCREEN__TASK____________________________________________//

  //_________________________________ START_____API_SCREEN__DASHBOARD____________________________________________//

  /// Получение статистики для дашборда

  Future<DashboardStats> getDashboardStats() async {
    final organizationId = await getSelectedOrganization();

    String path =
        '/dashboard/getTopStats${organizationId != null ? '?organization_id=$organizationId' : ''}';

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          return DashboardStats.fromJson(data);
        } else {
          throw ('Нет данных о статистике в ответе');
        }
      } else {
        throw ('Ошибка загрузки статистики: ${response.body}');
      }
    } catch (e) {
      throw ('Ошибка при получении статистики: $e');
    }
  }

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
      throw ('Ошибка загрузки данных графика: ${response.body}');
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
      throw ('Ошибка загрузки данных графика: ${response.body}');
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
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return DealStatsResponse.fromJson(jsonData);
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера!');
      } else {
        throw ('Ошибка загрузки данных!');
      }
    } catch (e) {
      print('Ошибка запроса!');
      throw ('Ошибка получения данных');
    }
  }

// Метод для получения графика Задачи
  Future<TaskChart> getTaskChartData() async {
    final organizationId = await getSelectedOrganization();

    String path =
        '/dashboard/task-chart${organizationId != null ? '?organization_id=$organizationId' : ''}';
    try {
      print('getTaskChartData: Начало запроса');
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

  // Метод для получения графика Проект
  Future<ProjectChartResponse> getProjectChartData() async {
    final organizationId = await getSelectedOrganization();
    String path =
        '/dashboard/projects-chart${organizationId != null ? '?organization_id=$organizationId' : ''}';
    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final result = ProjectChartResponse.fromJson(jsonData);
        return result;
      } else if (response.statusCode == 500) {
        throw ('Ошибка сервера!');
      } else {
        throw ('Ошибка загрузки данных проектов!');
      }
    } catch (e) {
      throw ('Ошибка получения данных проектов!');
    }
  }

  //_________________________________ END_____API_SCREEN__DASHBOARD____________________________________________//

  //_________________________________ START_____API_SCREEN__CHATS____________________________________________//

  // Метод для получения список чатов
  Future<PaginationDTO<Chats>> getAllChats(String endPoint,
      [int page = 1]) async {
    final token = await getToken(); // Получаем токен
    final organizationId =
        await getSelectedOrganization(); // Получаем ID организации

    // Формируем URL с параметром organization_id
    String url =
        '$baseUrl/chat/getMyChats/$endPoint?page=$page&organization_id=$organizationId';

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
        return PaginationDTO<Chats>.fromJson(data['result'], (e) {
          return Chats.fromJson(e);
        });
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
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
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

// Метод для получения сообщений по chatId
  Future<List<Message>> getMessages(int chatId) async {
    final token = await getToken(); // Получаем токен
    final organizationId =
        await getSelectedOrganization(); // Получаем ID организации

    // Формируем путь с параметром organization_id
    final url = Uri.parse(
        '$baseUrl/chat/getMessages/$chatId?organization_id=$organizationId');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return (data['result'] as List)
            .map(
                (msg) => Message.fromJson(msg)) // Создайте модель для сообщения
            .toList();
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }
  }

// Метод для отправки текстового сообщения
  Future<void> sendMessage(int chatId, String message) async {
    final organizationId = await getSelectedOrganization();

    final response = await _postRequest(
        '/chat/sendMessage/$chatId${organizationId != null ? '?organization_id=$organizationId' : ''}',
        {
          'message': message,
        });

    if (kDebugMode) {
      print('Response from sendMessage: ${response.body}');
    } // Добавлено для отладки

    if (response.statusCode != 200) {
      if (kDebugMode) {
        print('Ошибка отправки сообщения: ${response.body}');
      } // Отладка ошибок
      throw Exception('Ошибка отправки сообщения: ${response.body}');
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
        print('response.statusCode: ${response.statusCode}');
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
        print('Exception caught: $e');
      }
      if (kDebugMode) {
        print(e.response?.data);
      }
      throw Exception('Failed to send audio message due to an exception: $e');
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
            },
            contentType: 'multipart/form-data',
          ));
      if (kDebugMode) {
        print('response.statusCode: ${response.statusCode}');
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
        print('Exception caught: $e');
      }
      throw Exception('Failed to send audio message due to an exception: $e');
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
      throw Exception('Ошибка отправки файла: ${response.body}');
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
      throw Exception('Ошибка отправки голосового сообщения: ${response.body}');
    }
  }

  //_________________________________ END_____API_SCREEN__CHATS____________________________________________//

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
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
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

  //_________________________________ END_____API_SCREEN__PROFILE____________________________________________//

  //_________________________________ START_____API_SCREEN__NOTIFICATIONS____________________________________________//

  // Метод для получения список Уведомления
  Future<List<Notifications>> getAllNotifications(
      {int page = 1, int perPage = 20}) async {
    final organizationId = await getSelectedOrganization();
    String path = '/notification/unread?page=$page&per_page=$perPage';

    path += '&organization_id=$organizationId';

    print('Sending request to API with path: $path');
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
      throw Exception('Ошибка загрузки уведомлений: ${response.body}');
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
      throw Exception('Ошибка удаления уведомлений: ${response.body}');
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
        throw Exception('Ошибка загрузки User ID: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки User ID: $e');
    }
  }

  // Метод для Редактирование профиля
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String name,
    required String phone,
    String? email,
    String? login,
    String? image,
  }) async {
    final response = await _postRequest(
      '/profile/$userId',
      {
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
        // if (login != null) 'login': login,
        if (image != null) 'image': image,
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Профиль обновлен успешно.'};
    } else if (response.statusCode == 422) {
      return {
        'success': false,
        'message': 'Ошибка валидации данных. Проверьте введенные данные.'
      };
    } else if (response.statusCode == 500) {
      return {
        'success': false,
        'message': 'Ошибка на сервере. Попробуйте позже.'
      };
    } else {
      return {
        'success': false,
        'message': 'Ошибка обновления профиля: ${response.body}'
      };
    }
  }
  //_________________________________ END_____API_PROFILE_SCREEN____________________________________________//
}
