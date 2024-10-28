import 'dart:convert';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/models/history_model.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:dio/dio.dart';
import 'package:crm_task_manager/models/notes_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Импортируем SharedPreferences
import '../../models/domain_check.dart';
import '../../models/login_model.dart';
import '../../utils/global_fun.dart';


class ApiService {

  // final String baseUrl = 'http://62.84.186.96/api';
  // final String baseUrl = 'http://192.168.1.61:8008/api';
  final String baseUrl = 'https://shamcrm.com/api';

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

  // Метод для проверки домена
  Future<DomainCheck> checkDomain(String domain) async {
    final response = await _postRequest('/checkDomain', {'domain': domain});

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

  // Метод для проверки логина и пароля
  Future<LoginResponse> login(LoginModel loginModel) async {
    final response = await _postRequest('/login', loginModel.toJson());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final loginResponse = LoginResponse.fromJson(data);

      // Сохраняем токен после успешного логина
      await _saveToken(loginResponse.token!);

      return loginResponse;
    } else {
      throw Exception('Не правильный Логин или Пароль: ${response.body}');
    }
  }

  // Метод для получения лидов
  Future<List<Lead>> getLeads(int leadStatusId,
      {int page = 1, int perPage = 20}) async {
    final response = await _getRequest(
        '/lead?lead_status_id=$leadStatusId&page=$page&per_page=$perPage');

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

// Метод для получения Заметки Лида
  Future<List<Notes>> getLeadNotes(int leadId) async {
    final response = await _getRequest('/notices/$leadId');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['result']['data'] as List)
          .map((note) => Notes.fromJson(note))
          .toList();
    } else {
      throw Exception('Failed to load notes');
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

//Обновление статуса карточки в колонке
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


// -------------------------------

// Метод для отправки audio file
  Future<void> sendChatAudioFile(int chatId, String pathAudio) async {
    final token = await getToken(); // Получаем токен
    String requestUrl = '$baseUrl/chat/sendVoice/$chatId';

    Dio dio = Dio();
    try {
      FormData formData = FormData.fromMap({
        'voice': await MultipartFile.fromFile(pathAudio)
      });

      var response = await dio.post(
          requestUrl,
          data: formData,
          options: Options(
            headers: {
              "Authorization": "Bearer $token",
              "Accept": "application/json",
            },
            contentType: 'multipart/form-data',
          )
      );
      print('response.statusCode: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Audio message sent successfully!');
      } else {
        print('Error sending audio message: ${response.data}');
        throw Exception('Error sending audio message: ${response.data}');
      }
    } catch (e) {
      print('Exception caught: $e');
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
