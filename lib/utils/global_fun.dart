import 'dart:io';

import 'package:dio/dio.dart';
// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<File?> urlToFile(String imageUrl) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));
    final documentDirectory = await getTemporaryDirectory();
    
    // Создаем уникальное имя файла на основе URL или timestamp
    final uniqueFileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${documentDirectory.path}/$uniqueFileName');
    
    await file.writeAsBytes(response.bodyBytes);
    return file;
  } catch (e) {
    //print('Error converting URL to file: $e');
    return null;
  }
}

Future<void> cleanTempFiles() async {
  try {
    final directory = await getTemporaryDirectory();
    final files = directory.listSync();
    
    final cutoffTime = DateTime.now().subtract(Duration(hours: 1));
    for (var file in files) {
      if (file is File && 
          file.path.endsWith('.jpg') && 
          file.lastModifiedSync().isBefore(cutoffTime)) {
        await file.delete();
      }
    }
  } catch (e) {
    //print('Error cleaning temp files: $e');
  }
}

Future<File?> convertAudioFile(String inputPath, String outputPath) async {
  // await FFmpegKit.execute('-i $inputPath $outputPath').then((session) async {
  //   final returnCode = await session.getReturnCode();
  //   if (returnCode!.isValueSuccess()) {
  //     //print('Konvertatsiya muvaffaqiyatli yakunlandi!');
  //     return File(outputPath);
  //   } else {
  //     //print('Konvertatsiya muvaffaqiyatsiz yakunlandi: $returnCode');
  //     return null;
  //   }
  // });
  // return null;
}

Future<void> uploadFile(File file, String uploadUrl) async {
  Dio dio = Dio();

  FormData formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(file.path, filename: 'audio.ogg'), // fayl nomini kerakli formatga mos ravishda o'zgartiring
  });

  try {
    Response response = await dio.post(uploadUrl, data: formData);
    //print('Fayl yuklandi: ${response.statusCode}');
  } catch (e) {
    //print('Fayl yuklashda xatolik!');
  }
}

String time(String dateAndTime) {
  // //print('------- time 1');
  // //print(DateTime.now().timeZoneOffset.inMinutes);
  // //print('------- time 2');
  if(DateTime.now().timeZoneOffset.inMinutes > 0) {
    if(dateAndTime.isEmpty) dateAndTime = DateTime.now().subtract(Duration(minutes: DateTime.now().timeZoneOffset.inMinutes)).toString();
  } else {
    // if(dateAndTime.isEmpty) dateAndTime = DateTime.now().subtract(Duration(minutes: DateTime.now().timeZoneOffset.inMinutes)).toString();
  }
  String str = '';
  if (dateAndTime.endsWith('Z')) {
    dateAndTime = dateAndTime.substring(0, dateAndTime.length - 1);
  }
  try {
    DateTime dateTime = DateTime.parse(dateAndTime);

    str = DateFormat('HH:mm').format(
        (DateTime.now().timeZoneOffset.inMinutes > 0)  ? dateTime.add(Duration(minutes: DateTime.now().timeZoneOffset.inMinutes),) :  dateTime.add(Duration(minutes: DateTime.now().timeZoneOffset.inMinutes),),
    );

    // //print(time); // Natija: 11:22:22
  } catch (e) {
    str = dateAndTime;
  }
  return str;
}

String date(String dateAndTime) {
  String str = '';

  try {
    str = dateAndTime.split('T')[0].toString();

  } catch (e) {
    str = dateAndTime;
  }
  return str;
}

class AppStyles {
  static const TextStyle chatNameStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: 'Gilroy',
    color: Color(0xFF1E2E52),
  );

  static const TextStyle chatMessageStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff99A4BA),
  );

  static const TextStyle chatTimeStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff99A4BA),
  );

  static const TextStyle chatTimeStyleWhite = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Colors.white,
  );
}

/// used on money income/outcome cards to compare backend and frontend dates
bool areDatesEqual(String backendDateStr, String frontendDateStr) {
  try {
    debugPrint("Comparing dates: backend='$backendDateStr', frontend='$frontendDateStr'");

    final backendDate = DateTime.parse(backendDateStr);
    final frontendDate = DateTime.parse(frontendDateStr);

    return backendDate.year == frontendDate.year &&
        backendDate.month == frontendDate.month &&
        backendDate.day == frontendDate.day &&
        backendDate.hour == frontendDate.hour &&
        backendDate.minute == frontendDate.minute;
  } catch (e) {
    debugPrint('Error comparing dates: $e');
    return false;
  }
}

/// Parses double, num, or string values to String
/// Removes trailing zeros: 1.00 -> "1", 2.50 -> "2.5", 2.55 -> "2.55"
/// Handles both comma and dot as decimal separator: "1,00" -> "1", "2,5" -> "2.5"
String parseNumberToString(dynamic value, {String nullValue = ''}) {
  if (value == null) return nullValue;
  
  try {
    String stringValue = value.toString();
    
    // Replace comma with dot for parsing
    stringValue = stringValue.replaceAll(',', '.');
    
    // Parse to double
    double numValue = double.parse(stringValue);
    
    // Check if the number is an integer (no decimal part)
    if (numValue == numValue.toInt()) {
      return numValue.toInt().toString();
    }
    
    // Remove trailing zeros from decimal part
    String result = numValue.toString();
    if (result.contains('.')) {
      result = result.replaceAll(RegExp(r'0*$'), '');
      result = result.replaceAll(RegExp(r'\.$'), '');
    }
    
    return result;
  } catch (e) {
    debugPrint('Error parsing number to string: $e');
    return value.toString();
  }
}

/// used on money income/outcome forms to format money input
class MoneyInputFormatter extends TextInputFormatter {
  final int decimalRange;

  MoneyInputFormatter({this.decimalRange = 2}) : assert(decimalRange >= 0);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String value = newValue.text;

    // Allow empty
    if (value.isEmpty) return newValue;

    // Reject if contains anything except digits and dot
    final regEx = RegExp(r'^\d*\.?\d*$');
    if (!regEx.hasMatch(value)) {
      return oldValue;
    }

    // Must not start with dot
    if (value.startsWith('.')) {
      return oldValue;
    }

    // Must not start with 0 unless it's "0." (like 0.25)
    if (value.startsWith('0') && value.length > 1 && !value.startsWith('0.')) {
      return oldValue;
    }

    // Only one dot allowed
    if (value.indexOf('.') != value.lastIndexOf('.')) {
      return oldValue;
    }

    // Limit decimal places
    if (value.contains('.')) {
      final parts = value.split('.');
      if (parts.length > 1 && parts[1].length > decimalRange) {
        return oldValue;
      }
    }

    return newValue;
  }
}
