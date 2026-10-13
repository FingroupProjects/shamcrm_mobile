import 'package:crm_task_manager/page_2/dashboard/widgets/charts/chart_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('суммы с пробелом и запятой читаются как число', () {
    expect(parseChartNumber('1 234,50'), 1234.5);
    expect(parseChartNumber('12,5%'), 12.5);
    expect(parseChartNumber(10), 10);
    expect(parseChartNumber(null), 0);
  });

  test('верх шкалы чуть выше максимума с сервера', () {
    final scale = ChartScale.fromValues([0, 125]);
    expect(scale.maxY, greaterThan(125));
    expect(scale.maxY, lessThanOrEqualTo(200));
    expect(scale.minY, 0);
    expect(scale.interval, greaterThan(0));
  });

  test('нули не рисуют ось 0-100', () {
    final scale = ChartScale.fromValues([0, 0, 0]);
    expect(scale.minY, 0);
    expect(scale.maxY, 1);
    expect(scale.interval, 1);
  });

  test('убыток оставляет отрицательную границу', () {
    final scale = ChartScale.fromValues([-40, 10], allowNegative: true);
    expect(scale.minY, lessThan(0));
    expect(scale.minY, lessThanOrEqualTo(-40));
    expect(scale.maxY, greaterThanOrEqualTo(10));
  });
}
