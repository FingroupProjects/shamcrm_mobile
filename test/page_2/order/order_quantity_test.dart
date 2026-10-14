import 'package:crm_task_manager/page_2/order/order_details/order_quantity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderQuantity', () {
    test('keeps whole numbers whole and fractions short', () {
      expect(OrderQuantity.format(1), '1');
      expect(OrderQuantity.format(1.0), '1');
      expect(OrderQuantity.format(0.5), '0.5');
      expect(OrderQuantity.format(1.4), '1.4');
      expect(OrderQuantity.format(1.40), '1.4');
    });

    test('parses a finished decimal and ignores an unfinished one', () {
      expect(OrderQuantity.tryParse('0.5'), 0.5);
      expect(OrderQuantity.tryParse('1.4'), 1.4);
      expect(OrderQuantity.tryParse('1,4'), 1.4);
      expect(OrderQuantity.tryParse('0.'), isNull);
      expect(OrderQuantity.tryParse('0'), isNull);
      expect(OrderQuantity.tryParse('1.'), isNull);
      expect(OrderQuantity.isTyping('0.'), isTrue);
      expect(OrderQuantity.isTyping('1.'), isTrue);
      expect(OrderQuantity.isTyping('0.5'), isFalse);
    });

    test('compact sends 1 as int and 0.5 as double', () {
      expect(OrderQuantity.compact(1), 1);
      expect(OrderQuantity.compact(1.0), isA<int>());
      expect(OrderQuantity.compact(0.5), 0.5);
      expect(OrderQuantity.compact(1.4), 1.4);
    });

    test('does not replace the field while the same fraction is typed', () {
      expect(OrderQuantity.shouldKeepText('0.50', '0.5'), isTrue);
      expect(OrderQuantity.shouldKeepText('1.', '1'), isTrue);
      expect(OrderQuantity.shouldKeepText('2', '1'), isFalse);
    });
  });
}
