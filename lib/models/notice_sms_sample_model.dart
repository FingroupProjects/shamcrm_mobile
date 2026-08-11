import 'package:crm_task_manager/utils/safe_converters.dart';

class NoticeSmsSample {
  final int? id;
  final String name;
  final String text;
  final int paramsAmount;
  final bool isEmptyTemplate;

  const NoticeSmsSample({
    this.id,
    required this.name,
    required this.text,
    required this.paramsAmount,
    this.isEmptyTemplate = false,
  });

  factory NoticeSmsSample.fromJson(Map<String, dynamic> json) {
    return NoticeSmsSample(
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      text: SafeConverters.toSafeString(json['text']),
      paramsAmount: SafeConverters.toInt(json['params_amount']),
    );
  }

  factory NoticeSmsSample.empty() {
    return const NoticeSmsSample(
      id: null,
      name: 'Пустой шаблон',
      text: '',
      paramsAmount: 0,
      isEmptyTemplate: true,
    );
  }
}
