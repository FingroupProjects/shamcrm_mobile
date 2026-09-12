import 'package:crm_task_manager/models/page_2/call_center_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the outgoing destination separate from the caller line', () {
    final call = CallLogEntry.fromJson({
      'id': 1,
      'caller': '992488886363',
      'destination_number': '+992929664041',
      'trunk': '992488886363',
      'incoming': false,
      'missed': false,
      'call_started_at': '2026-08-05T08:00:00.000Z',
      'lead': {
        'id': 10,
        'name': 'сафаров абдулгафор',
        'phone': '+992200059356',
      },
    });

    expect(call.callType, CallType.outgoing);
    expect(call.phoneNumber, '+992200059356');
    expect(call.displayTitle, 'сафаров абдулгафор');
    expect(call.displaySubtitle, '+992200059356');
    expect(call.destinationNumber, '+992929664041');
    expect(call.trunk, '992488886363');
    expect(call.outboundCallerNumber, '992488886363');
  });

  test('hides duplicate lead phone when it matches the name', () {
    final call = CallLogEntry.fromJson({
      'id': 2,
      'caller': '992488882002',
      'destination_number': '929664041',
      'trunk': '992488882002',
      'incoming': false,
      'missed': false,
      'call_started_at': '2026-09-12T09:56:33.000000Z',
      'lead': {
        'id': 6699,
        'name': '+992929664041',
        'phone': '+992929664041',
      },
    });

    expect(call.displayTitle, '+992929664041');
    expect(call.displaySubtitle, isNull);
    expect(call.callDate.isUtc, isFalse);
    expect(call.callDate.hour, DateTime.parse('2026-09-12T09:56:33.000000Z').toLocal().hour);
  });
}
