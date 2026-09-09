import 'package:crm_task_manager/models/chat/edited_message_socket_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses nested message payload from chat.messageEdited', () {
    final parsed = EditedMessageSocketPayload.tryParse({
      'message': {
        'id': 42,
        'text': 'updated html',
        'is_changed': true,
        'chat_id': 7,
      },
    });

    expect(parsed, isNotNull);
    expect(parsed!.messageId, 42);
    expect(parsed.text, 'updated html');
    expect(parsed.chatId, 7);
    expect(parsed.isChanged, isTrue);
  });

  test('parses flat payload and string ids', () {
    final parsed = EditedMessageSocketPayload.tryParse({
      'id': '15',
      'message': '<p>hello</p>',
      'is_changed': 1,
      'chatId': '9',
    });

    expect(parsed, isNotNull);
    expect(parsed!.messageId, 15);
    expect(parsed.text, '<p>hello</p>');
    expect(parsed.chatId, 9);
    expect(parsed.isChanged, isTrue);
  });

  test('returns null without message id', () {
    expect(
      EditedMessageSocketPayload.tryParse({'text': 'no id'}),
      isNull,
    );
  });
}
