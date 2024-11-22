// LeadConversion модель
  class LeadConversion {
    final List<double> data;

    LeadConversion({
      required this.data,
    });

    factory LeadConversion.fromJson(Map<String, dynamic> json) {
      // Получаем данные из поля 'result' и проверяем, что 'data' не null
      final result = json['result'] as Map<String, dynamic>? ?? {};
      final data = result['data'] as List<dynamic>? ?? [];

      // Преобразуем список в список чисел с типом double
      return LeadConversion(
        data: data.map((x) => (x as num).toDouble()).toList(),
      );
    }
  }
