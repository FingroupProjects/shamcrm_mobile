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
      id: json['id'] as int?,
      name: (json['name'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      paramsAmount: json['params_amount'] is int
          ? json['params_amount'] as int
          : int.tryParse('${json['params_amount']}') ?? 0,
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
