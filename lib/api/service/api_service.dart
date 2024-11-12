import 'dart:convert';
import 'dart:io';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/currency_model.dart';
import 'package:crm_task_manager/models/dashboard_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/history_model.dart';
import 'package:crm_task_manager/models/history_model_task.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/notes_model.dart';
import 'package:crm_task_manager/models/project_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/domain_check.dart';
import '../../models/login_model.dart';

class ApiService {
  // final String baseUrl = 'http://62.84.186.96/api';
  // final String baseUrl = 'http://192.168.1.61:8008/api';
  // final String baseUrl = 'https://shamcrm.com/api';
  final String baseUrl = 'https://fingroup-back.shamcrm.com/api';

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
    await _removeToken(); // Удаляем токен при логауте
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

    return response;
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

    return response;
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

    return response;
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

    return response;
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
 
  //_________________________________ START___API__DOMAIN_CHECK____________________________________________// 
 
  // Метод для проверки домена 
  Future<DomainCheck> checkDomain(String domain) async { 
    final response = await _postRequestDomain('/checkDomain', {'domain': domain}); 
 
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

  //_________________________________ END___API__DOMAIN_CHECK____________________________________________//

  //_________________________________ START___API__LOGIN____________________________________________//

  // Метод для проверки логина и пароля
  Future<LoginResponse> login(LoginModel loginModel) async {
    final response = await _postRequest('/login', loginModel.toJson());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final loginResponse = LoginResponse.fromJson(data);

      // Сохраняем токен после успешного логина
      await _saveToken(loginResponse.token);

      return loginResponse;
    } else {
      throw Exception('Не правильный Логин или Пароль: ${response.body}');
    }
  }
  //_________________________________ END___API__LOGIN____________________________________________//

  //_________________________________ START_____API__SCREEN__LEAD____________________________________________//

  // Метод для получения лидов
Future<List<Lead>> getLeads(int? leadStatusId, {int page = 1, int perPage = 20, String? search}) async {
  String path = '/lead?page=$page&per_page=$perPage';
  
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




  // Future<List<Lead>> getLeads(int? leadStatusId,
  //     {int page = 1, int perPage = 20, String search = ''}) async {
  //   String path = '/lead';
  //   if (leadStatusId != null) {
  //     path += '?lead_status_id=$leadStatusId&page=$page&per_page=$perPage&search=$search';
  //   } else {
  //     path += '?page=$page&per_page=$perPage';
  //   }

  //   final response = await _getRequest(path);

  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     if (data['result']['data'] != null) {
  //       return (data['result']['data'] as List)
  //           .map((json) => Lead.fromJson(json, leadStatusId ?? -1))
  //           .toList();
  //     } else {
  //       throw Exception('Нет данных о лидах в ответе');
  //     }
  //   } else {
  //     throw Exception('Ошибка загрузки лидов: ${response.body}');
  //   }
  // }

  // Метод для получения статусов лидов
  Future<List<LeadStatus>> getLeadStatuses() async {
    final response = await _getRequest('/lead/statuses');

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
    final response = await _postRequest('/lead-status', {
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
    final response = await _postRequest('/lead/changeStatus/$leadId', {
      'position': position,
      'status_id': statusId,
    });

    if (response.statusCode == 200) {
      print('Статус лида обновлен успешно.');
    } else {
      throw Exception('Ошибка обновления статуса лида: ${response.body}');
    }
  }

// Метод для получения Истории Лида
  Future<List<LeadHistory>> getLeadHistory(int leadId) async {
    try {
      final token = await getToken(); // Получаем токен
      final response = await http.get(
        Uri.parse('$baseUrl/lead/history/$leadId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}'); // Логирование ответа

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => LeadHistory.fromJson(json)).toList();
      } else {
        print(
            'Failed to load lead history: ${response.statusCode}'); // Логирование ошибки
        throw Exception('Ошибка загрузки истории лида: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e'); // Логирование исключений
      throw Exception('Ошибка загрузки истории лида: $e');
    }
  }

// Метод для получения Заметок с Пагинацией
  Future<List<Notes>> getLeadNotes(int leadId,
      {int page = 1, int perPage = 20}) async {
    final response =
        await _getRequest('/notices/$leadId?page=$page&per_page=$perPage');
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
    required String body,
    required int leadId,
    DateTime? date,
    bool sendNotification = false,
  }) async {
    date ??= DateTime.now();

    final response = await _postRequest('/notices', {
      'body': body,
      'lead_id': leadId,
      'date': date.toIso8601String(),
      'send_notification': sendNotification ? 1 : 0,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'Заметка создана успешно.'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('body.')) {
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
    required String body,
    DateTime? date,
    bool sendNotification = false,
  }) async {
    date ??= DateTime.now();

    final response = await _patchRequest('/notices/$noteId', {
      'body': body,
      'lead_id': leadId,
      'date': date.toIso8601String(),
      'send_notification': sendNotification ? 1 : 0,
    });

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Заметка обновлена успешно.'};
    } else if (response.statusCode == 422) {
      if (response.body.contains('body.')) {
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
        'message': 'Ошибка обновления Заметки: ${response.body}'
      };
    }
  }

// Метод для Удаления Заметки Лида
  Future<Map<String, dynamic>> deleteNotes(int noteId) async {
    final response = await _deleteRequest('/notices/$noteId');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete note: ${response.body}');
    }
  }

  // Метод для Создания Лида
  Future<Map<String, dynamic>> createLead({
    required String name,
    required int leadStatusId,
    required String phone,
    int? regionId,
    int? managerId,
    String? instaLogin,
    String? facebookLogin,
    String? tgNick,
    DateTime? birthday,
    String? description,
    int? organizationId,
    String? waPhone,
  }) async {
    final response = await _postRequest('/lead', {
      'name': name,
      'lead_status_id': leadStatusId,
      'phone': phone,
      if (regionId != null) 'region_id': regionId,
      if (managerId != null) 'manager_id': managerId,
      if (instaLogin != null) 'insta_login': instaLogin,
      if (facebookLogin != null) 'facebook_login': facebookLogin,
      if (tgNick != null) 'tg_nick': tgNick,
      if (birthday != null)
        'birthday': birthday.toIso8601String(), // Конвертация в строку
      if (description != null) 'description': description,
      if (organizationId != null) 'organization_id': organizationId,
      if (waPhone != null) 'wa_phone': waPhone,
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
      }
      // Другие проверки...
      else {
        return {
          'success': false,
          'message': 'Неизвестная ошибка: ${response.body}'
        };
      }
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
    String? description,
    int? organizationId,
    String? waPhone,
  }) async {
    final response = await _patchRequest('/lead/$leadId', {
      'name': name,
      'lead_status_id': leadStatusId,
      'phone': phone,
      if (regionId != null) 'region_id': regionId,
      if (managerId != null) 'manager_id': managerId,
      if (instaLogin != null) 'insta_login': instaLogin,
      if (facebookLogin != null) 'facebook_login': facebookLogin,
      if (tgNick != null) 'tg_nick': tgNick,
      if (birthday != null) 'birthday': birthday.toIso8601String(),
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
      // Другие проверки на ошибки...
      return {
        'success': false,
        'message': 'Неизвестная ошибка: ${response.body}'
      };
    } else {
      return {
        'success': false,
        'message': 'Ошибка обновления лида: ${response.body}'
      };
    }
  }

  // Метод для получения региона
  Future<List<Region>> getRegion() async {
    final response = await _getRequest('/region');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return (data['result'] as List)
            .map((region) => Region.fromJson(region))
            .toList();
      } else {
        throw Exception('Регионов не найдено');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }
  }

  // Метод для получения Менеджера
  Future<List<Manager>> getManager() async {
    final response = await _getRequest('/manager');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Тело ответа: $data'); // Для отладки

      if (data['result'] != null && data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((manager) => Manager.fromJson(manager))
            .toList();
      } else {
        throw Exception('Менеджеров не найдено');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }
  }
  // Метод для Удаления Статуса Лида 
  Future<Map<String, dynamic>> deleteLeadStatuses(int leadStatusId) async { 
    final response = await _deleteRequest('/lead-status/$leadStatusId'); 
 
    if (response.statusCode == 200) { 
      return {'result': 'Success'}; 
    } else { 
      throw Exception('Failed to delete leadStatus: ${response.body}'); 
    } 
  }
// Метод для Удаления Лида 
  Future<Map<String, dynamic>> deleteLead(int leadId) async { 
    final response = await _deleteRequest('/lead/$leadId'); 
 
    if (response.statusCode == 200) { 
      return {'result': 'Success'}; 
    } else { 
      throw Exception('Failed to delete lead: ${response.body}'); 
    } 
  } 

  //_________________________________ END_____API__SCREEN__LEAD____________________________________________//

  //_________________________________ START___API__SCREEN__DEAL____________________________________________//

  // Метод для получения Сделок
  Future<List<Deal>> getDeals(int dealStatusId,
      {int page = 1, int perPage = 20}) async {
    final response = await _getRequest(
        '/deal?deal_status_id=$dealStatusId&page=$page&per_page=$perPage');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((json) => Deal.fromJson(json, dealStatusId))
            .toList();
      } else {
        throw Exception('Нет данных о сделках в ответе');
      }
    } else {
      throw Exception('Ошибка загрузки сделок: ${response.body}');
    }
  }

  // Метод для получения статусов Сделок
  Future<List<DealStatus>> getDealStatuses() async {
    final response = await _getRequest('/deal/statuses');

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
      String title, String color) async {
    final response = await _postRequest('/deal/statuses', {
      'title': title,
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

  //Обновление статуса карточки Сделки  в колонке
  Future<void> updateDealStatus(int dealId, int position, int statusId) async {
    final response = await _postRequest('/deal/changeStatus/$dealId', {
      'position': position,
      'status_id': statusId,
    });

    if (response.statusCode == 200) {
      print('Статус сделки обновлен успешно.');
    } else {
      throw Exception('Ошибка обновления статуса сделки: ${response.body}');
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
    int? organizationId,
    int? dealtypeId,
    required int? leadId,
    required int? currencyId,
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
      if (organizationId != null) 'organization_id': organizationId,
      if (dealtypeId != null) 'deal_type_id': dealtypeId,
      if (leadId != null) 'lead_id': leadId,
      if (currencyId != null) 'currency_id': currencyId,
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

    final response = await _postRequest('/deal', requestBody);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'Сделка создана успешно.'};
    } else if (response.statusCode == 422) {
      // Обработка ошибки дублирования номера телефона
      if (response.body.contains('name')) {
        return {'success': false, 'message': 'Введите хотя бы 3 символа!.'};
      } else {
        return {
          'success': false,
          'message': 'Неизвестная ошибка: ${response.body}'
        };
      }
    } else {
      return {
        'success': false,
        'message': 'Ошибка создания лида: ${response.body}'
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
    int? organizationId,
    int? dealtypeId,
    required int? leadId,
    required int? currencyId,
    List<Map<String, String>>? customFields,
  }) async {
    final response = await _patchRequest('/deal/$dealId', {
      'name': name,
      'deal_status_id': dealStatusId,
      if (managerId != null) 'manager_id': managerId,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      'sum': sum,
      if (description != null) 'description': description,
      if (organizationId != null) 'organization_id': organizationId,
      if (dealtypeId != null) 'deal_type_id': dealtypeId,
      if (leadId != null) 'lead_id': leadId,
      if (currencyId != null) 'currency_id': currencyId,
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
        'message': 'Ошибка валидации данных: ${response.body}'
      };
    } else {
      return {
        'success': false,
        'message': 'Ошибка обновления сделки: ${response.body}'
      };
    }
  }

  // Метод для получения Валюта
  Future<List<Currency>> getCurrency() async {
    final response = await _getRequest('/currency');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Тело ответа: $data');

      if (data['result'] != null && data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((currency) => Currency.fromJson(currency))
            .toList();
      } else {
        throw Exception('Валюты не найдено');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }
  }
  
  // Метод для Удаления Сделки 
  Future<Map<String, dynamic>> deleteDeal(int dealId) async { 
    final response = await _deleteRequest('/deal/$dealId'); 
 
    if (response.statusCode == 200) { 
      return {'result': 'Success'}; 
    } else { 
      throw Exception('Failed to delete deal: ${response.body}'); 
    } 
  }
 
  //_________________________________ END_____API_SCREEN__DEAL____________________________________________//
  //_________________________________ START___API__SCREEN__TASK____________________________________________//

  Future<List<Task>> getTasks(int? taskStatusId,
      {int page = 1, int perPage = 20}) async {
    String path = '/task';
    if (taskStatusId != null) {
      path += '?task_status_id=$taskStatusId&page=$page&per_page=$perPage';
    } else {
      path += '?page=$page&per_page=$perPage';
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
      throw Exception('Ошибка загрузки задач: ${response.body}');
    }
  }

  // Метод для получения статусов Задач
  Future<List<TaskStatus>> getTaskStatuses() async {
    final response = await _getRequest('/task-status');

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

//Обновление статуса карточки Сделки  в колонке
  Future<void> updateTaskStatus(int taskId, int position, int statusId) async {
    final response = await _postRequest('/task/changeStatus/$taskId', {
      'position': position,
      'status_id': statusId,
    });

    if (response.statusCode == 200) {
      print('Статус задачи обновлен успешно.');
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
 // Метод для создания Cтатуса Лида
  Future<Map<String, dynamic>> createTaskStatus(
      String name, String color) async {
    final response = await _postRequest('/task-status', {
      'name': name,
      'color': color,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': 'Статус задачи создан успешно'};
    } else {
      return {
        'success': false,
        'message': 'Ошибка создания статуса задач: ${response.body}'
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
    int? userId,
    String? description,
    // Map<String, dynamic>? file,
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
        if (userId != null) 'user_id': userId,
        // if (file != null) "file": file,
        if (description != null) 'description': description,
        
      };

      final response = await _postRequest('/task', requestBody);
      return _handleTaskResponse(response, 'создания');
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
    int? userId,
    String? description,
    Map<String, dynamic>? file,
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
        if (userId != null) 'user_id': userId,
        if (file != null) 'file': file,
        if (description != null) 'description': description,
      };

      final response = await _postRequest('/task/$taskId', requestBody);
      return _handleTaskResponse(response, 'обновления');
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
      final token = await getToken(); // Получаем токен
      final response = await http.get(
        Uri.parse('$baseUrl/task/history/$taskId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}'); // Логирование ответа

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        final List<dynamic> jsonList = decodedJson['result']['history'];
        return jsonList.map((json) => TaskHistory.fromJson(json)).toList();
      } else {
        print(
            'Failed to load task history: ${response.statusCode}'); // Логирование ошибки
        throw Exception(
            'Ошибка загрузки истории задач: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e'); // Логирование исключений
      throw Exception('Ошибка загрузки истории задач: $e');
    }
  }

// Метод для получения Проекта
  Future<List<Project>> getProject() async {
    final response = await _getRequest('/project');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Тело ответа: $data'); // Для отладки

      if (data['result'] != null && data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((project) => Project.fromJson(project))
            .toList();
      } else {
        throw Exception('Проектов не найдено');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }
  }

  // Метод для получение Пользователя
  Future<List<UserTask>> getUserTask() async {
    try {
      print('Отправка запроса на /user');
      final response = await _getRequest('/user');
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

    /// Получение статистики для дашборда
  Future<DashboardStats> getDashboardStats() async {
    String path = '/dashboard/getTopStats?organization_id=1';
    
    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null) {
          return DashboardStats.fromJson(data);
        } else {
          throw Exception('Нет данных о статистике в ответе');
        }
      } else {
        throw Exception('Ошибка загрузки статистики: ${response.body}');
      }
    } catch (e) {
      throw Exception('Ошибка при получении статистики: $e');
    }
  }

 /// Получение данных графика для дашборда
  Future<List<ChartData>> getLeadChart() async {
    String path = '/dashboard/lead-chart';
    
    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return data.map((json) => ChartData.fromJson(json)).toList();
        } else {
          throw Exception('Нет данных графика в ответе');
        }
      } else {
        throw Exception('Ошибка загрузки данных графика: ${response.body}');
      }
    } catch (e) {
      throw Exception('Ошибка при получении данных графика: $e');
    }
  }

  
  //_________________________________ END_____API_SCREEN__TASK____________________________________________//

  // Метод для получения список чатов
  Future<List<Chats>> getAllChats() async {
    final token = await getToken(); // Получаем токен
    final response = await http.get(
      Uri.parse('$baseUrl/chat/getMyChats'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null) {
        return (data['result'] as List)
            .map((chat) => Chats.fromJson(chat))
            .toList();
      } else {
        throw Exception('Результат отсутствует в ответе');
      }
    } else {
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }
  }

// Метод для получения сообщений по chatId
  Future<List<Message>> getMessages(int chatId) async {
    final token = await getToken(); // Получаем токен
    final response = await http.get(
      Uri.parse(
          '$baseUrl/chat/getMessages/$chatId'), // Обновите путь согласно вашему API
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
    final response = await _postRequest('/chat/sendMessage/$chatId', {
      'message': message,
    });

    print(
        'Response from sendMessage: ${response.body}'); // Добавлено для отладки

    if (response.statusCode != 200) {
      print('Ошибка отправки сообщения: ${response.body}'); // Отладка ошибок
      throw Exception('Ошибка отправки сообщения: ${response.body}');
    }
  }

  // Метод для отправки файла
  Future<void> sendFile(int chatId, String filePath) async {
    // Если вы используете MultipartRequest для отправки файлов, создайте метод
    // Для упрощения мы будем использовать _postRequest как пример
    final response = await _postRequest('/chat/sendFile/$chatId', {
      'file_path':
          filePath, // Убедитесь, что вы используете правильные параметры
    });

    if (response.statusCode != 200) {
      throw Exception('Ошибка отправки файла: ${response.body}');
    }
  }

  // Метод для отправки голосового сообщения
  Future<void> sendVoice(int chatId, String voicePath) async {
    final response = await _postRequest('/chat/sendVoice/$chatId', {
      'voice_path':
          voicePath, // Убедитесь, что вы используете правильные параметры
    });

    if (response.statusCode != 200) {
      throw Exception('Ошибка отправки голосового сообщения: ${response.body}');
    }
  }
}
