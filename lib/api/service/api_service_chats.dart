import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class ApiServiceDownload {
  
  // final String baseUrl = 'http://192.168.1.61:8008';

  // Метод для загрузки и открытия файла
  Future<void> downloadAndOpenFile(String filePath) async {
    try {

      final ApiService _apiService = ApiService();
    final enteredDomainMap = await ApiService().getEnteredDomain();
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];

      print('=-=-=--=-=-=-=-==-=-=--=-=-=-=-=---======-=-=-=-=-=-=--=-=-=-=--=-==--=-=-=-=');
      print('=-=-=--=-=-=-=-==-=-=--=-=-=-=-=---API-SERVICE-CHATS=START=====-=-=-=-=-=-=--=-=-=-=--=-==--=-=-=-=');
      print('Полученный базовый домен: $enteredMainDomain');
      print('=-=-=--=-=-=-=-==-=-=--=-=-=-=-=---API-SERVICE-CHATS=END=====-=-=-=-=-=-=--=-=-=-=--=-==--=-=-=-=');


      final String baseUrl = 'https://$enteredMainDomain';

      // Полный URL файла для загрузки
      final String fullUrl = '$baseUrl/storage/$filePath';

      // Получаем путь для сохранения файла
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${filePath.split('/').last}');

      // Проверяем, существует ли файл
      if (!file.existsSync()) {
        // Скачиваем файл, если он не существует
        final response = await http.get(Uri.parse(fullUrl));

        // Проверяем успешность ответа
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
        } else {
          print('Ошибка загрузки файла: ${response.statusCode}');
          return; // Выходим из функции, если произошла ошибка
        }
      }

      // Открываем файл
      await OpenFile.open(file.path);
    } catch (e) {
      print('Ошибка загрузки файла!');
    }
  }

}