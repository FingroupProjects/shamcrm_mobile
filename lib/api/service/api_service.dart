import 'dart:convert';
import 'dart:io';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/pagination_dto.dart';
import 'package:crm_task_manager/models/user.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Импортируем SharedPreferences
import '../../models/domain_check.dart';
import '../../models/login_model.dart';
import '../../utils/global_fun.dart';

// final String baseUrl = 'http://62.84.186.96/api';
final String baseUrl = 'https://fingroup-back.shamcrm.com/api';
final String baseUrlForCheckDomain = 'https://shamcrm.com/api';
final String baseUrlSocket = 'https://fingroup-back.shamcrm.com/broadcasting/auth';

class ApiService {
  // final String baseUrl = 'http://192.168.1.61:8008/api';

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

    // get all users
  Future<UsersDataResponse> getAllUser() async {
    final token = await getToken(); // Получаем токен перед запросом

    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null)
          'Authorization': 'Bearer $token', // Добавляем токен, если он есть
      },

    );
    late UsersDataResponse dataUser;

    if(response.statusCode == 200) {
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

    final response = await http.post(
      Uri.parse('$baseUrl/chat/createChat/$userID'),
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


  // Метод для выполнения POST-запросов
  Future<http.Response> _postRequest(
      String path, Map<String, dynamic> body) async {
    final token = await getToken(); // Получаем токен перед запросом

    String baseUrlInFun = '';
    if(path == '/checkDomain') {
      baseUrlInFun = baseUrlForCheckDomain;
    } else {
      baseUrlInFun = baseUrl;
    }

    String url = '$baseUrlInFun$path';
    if (kDebugMode) {
      print(url);
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null)
          'Authorization': 'Bearer $token', // Добавляем токен, если он есть
      },
      body: json.encode(body),
    );

    if (kDebugMode) {
      print('Статус ответа: ${response.statusCode}');
    }
    if (kDebugMode) {
      print('Тело ответа: ${response.body}');
    }

    return response;
  }

// Метод для выполнения GET-запросов
  Future<http.Response> _getRequest(String path) async {
    final token = await getToken(); // Получаем токен перед запросом

    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (kDebugMode) {
      print('Статус ответа: ${response.statusCode}');
    }
    if (kDebugMode) {
      print('Тело ответа: ${response.body}');
    }

    return response;
  }

  // Метод для проверки домена
  Future<DomainCheck> checkDomain(String domain) async {
    final response = await _postRequest('/checkDomain', {'domain': domain});

    if (response.statusCode == 200) {
      return DomainCheck.fromJson(json.decode(response.body));
    } else {
      throw Exception('Не удалось загрузить домен: ${response.body}');
    }
  }

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
  // Метод для Удаления Статуса Лида
  Future<Map<String, dynamic>> deleteDealStatuses(int dealStatusId) async {
    final response = await _deleteRequest('/deal-status/$dealStatusId');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete dealStatus: ${response.body}');
    }
  }
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

  // Метод для Удаления Сделки
  Future<Map<String, dynamic>> deleteDeal(int dealId) async {
    final response = await _deleteRequest('/deal/$dealId');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete deal: ${response.body}');
    }
  }
  Future<Map<String, dynamic>> deleteTaskStatuses(int taskStatusId) async {
    final response = await _deleteRequest('/task-status/$taskStatusId');

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete taskStatus: ${response.body}');
    }
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


  // Метод для получения лидов
  Future<List<Lead>> getLeads() async {
    final response = await _getRequest('/lead?lead_status_id');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result']['data'] != null) {
        return (data['result']['data'] as List)
            .map((json) => Lead.fromJson(json))
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

  // Метод для создания нового лида
  Future<void> createLead(String name, int leadStatusId, String phone) async {
    final response = await _postRequest('/lead', {
      'name': name,
      'lead_status_id': leadStatusId,
      'phone': phone,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (kDebugMode) {
        print('Лид создан успешно.');
      }
    } else {
      throw Exception('Ошибка создания лида: ${response.body}');
    }
  }

//Обновление статуса карточки в колонке
  Future<void> updateLeadStatus(int leadId, int position, int statusId) async {
    final response = await _postRequest('/lead/changeStatus/$leadId', {
      'position': position,
      'status_id': statusId,
    });

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('Статус лида обновлен успешно.');
      }
    } else {
      throw Exception('Ошибка обновления статуса лида: ${response.body}');
    }
  }

  // Метод для получения список чатов
  Future<PaginationDTO<Chats>> getAllChats(String endPoint,
      [int page = 1]) async {
    final token = await getToken(); // Получаем токен
    String url = '$baseUrl/chat/getMyChats/$endPoint?page=$page';
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

    if (kDebugMode) {
      print(
        'Response from sendMessage: ${response.body}');
    } // Добавлено для отладки

    if (response.statusCode != 200) {
      if (kDebugMode) {
        print('Ошибка отправки сообщения: ${response.body}');
      } // Отладка ошибок
      throw Exception('Ошибка отправки сообщения: ${response.body}');
    }
  }

// -------------------------------

// Метод для отправки audio file
  Future<void> sendChatAudioFile(int chatId, File audio) async {
    final token = await getToken(); // Получаем токен
    String requestUrl = '$baseUrl/chat/sendVoice/$chatId';

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
    String requestUrl = '$baseUrl/chat/sendFile/$chatId';

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
