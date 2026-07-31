import 'package:crm_task_manager/models/page_2/call_center_by_id_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a call when optional user fields are null', () {
    final call = CallById.fromJson({
      'id': 4487,
      'linked_id': '1785390059.1298360',
      'caller': '992488886363',
      'destination_number': '556664444',
      'trunk': '992488886363',
      'organization_id': 1,
      'lead': {
        'id': 6108,
        'name': 'Imron',
        'phone': '+992556664444',
        'sent_to_1c': false,
        'last_update': 0,
        'messageStatus': 'hasReply',
        'bonus': '0.00',
      },
      'call_record_url': 'https://example.com/record',
      'user': {
        'id': 2,
        'name': 'Амирчон Расулов',
        'lastname': null,
        'login': 'A_Rasulov',
        'email': 'amirfingrou1p@gmail.com',
        'phone': '+992927880829',
        'image': '<svg />',
        'last_seen': '2026-07-30T06:30:05.839544Z',
        'deleted_at': null,
        'telegram_user_id': '7058235708',
        'job_title': 'Менеджер по развитию',
        'online': true,
        'full_name': 'Амирчон Расулов',
        'is_first_login': 1,
        'unique_id': 'fingroupcrm-back-2',
      },
      'call_duration': null,
      'call_ringing_duration': null,
      'incoming': false,
      'missed': true,
      'answered': false,
      'call_status': 'NOANSWER',
      'call_started_at': '2026-07-30T00:41:00.000000Z',
      'call_ended_at': '2026-07-30T00:41:19.000000Z',
      'additional_data': {
        'roistat': '0',
        'user_id': '096475',
        'treeName': 'Исходящая',
        'treeNumber': '000-2411196',
      },
      'rating': null,
      'report': null,
      'created_at': '2026-07-30 10:41',
      'updated_at': '2026-07-30 10:42',
    });

    expect(call.user?.lastname, isEmpty);
    expect(call.callDuration, isNull);
    expect(call.missed, isTrue);
  });
}
