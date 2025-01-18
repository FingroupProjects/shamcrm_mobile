import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserTaskCompletionCacheHandler {
  static Future<void> saveUserTaskCompletionData(List<double> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user_task_completion_data_manager', json.encode(data));
  }

  static Future<List<double>?> getUserTaskCompletionData() async {
  final prefs = await SharedPreferences.getInstance();
  final String? dataString = prefs.getString('user_task_completion_data_manager');
  if (dataString != null) {
    final List<dynamic> jsonData = json.decode(dataString);
    return jsonData.map((e) => (e as num).toDouble()).toList();  
  }
  return null;
}

}
