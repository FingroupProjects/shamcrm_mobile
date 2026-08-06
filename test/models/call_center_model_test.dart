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
    });

    expect(call.callType, CallType.outgoing);
    expect(call.phoneNumber, '992488886363');
    expect(call.destinationNumber, '+992929664041');
    expect(call.trunk, '992488886363');
    expect(call.outboundCallerNumber, '992488886363');
  });
}
