import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class ApiServiceDownload {
  
  // Метод для загрузки и открытия файла
  Future<void> downloadAndOpenFile(String filePath) async {
    try {
      String fullUrl;

      // Если сервер уже вернул полный URL — используем как есть
      if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
        fullUrl = filePath;
      } else {
        final enteredDomainMap = await ApiService().getEnteredDomain();
        String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
        final String baseUrl = 'https://$enteredMainDomain';
        fullUrl = '$baseUrl/$filePath';
      }

      // Получаем путь для сохранения файла
      final directory = await getApplicationDocumentsDirectory();
      final fileName = fullUrl.split('/').last;
      final file = File('${directory.path}/$fileName');

      // Проверяем, существует ли файл
      if (!file.existsSync()) {
        // Скачиваем файл, если он не существует
        final response = await http.get(Uri.parse(fullUrl));

        // Проверяем успешность ответа
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
        } else {
          return; // Выходим из функции, если произошла ошибка
        }
      }

      // Открываем файл
      await OpenFile.open(file.path);
    } catch (e) {
      //print('Ошибка загрузки файла!');
    }
  }

}
