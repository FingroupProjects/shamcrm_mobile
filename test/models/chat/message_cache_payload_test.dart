import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('text stays text even if an old cache stored a voice duration', () {
    final message = Message.fromJson({
      'id': 1,
      'text': 'обычное сообщение',
      'type': 'text',
      'voice_duration': 20,
      'created_at': '2026-01-02T00:00:00',
      'is_my_message': false,
      'sender': {'name': 'Анна'},
    });

    expect(message.type, 'text');
    expect(message.text, 'обычное сообщение');
  });

  test('a file with a real voice duration opens as voice', () {
    final message = Message.fromJson({
      'id': 2,
      'text': 'voice.ogg',
      'type': 'file',
      'file_path': 'https://cdn.example/voice.ogg',
      'voice_duration': 4,
      'created_at': '2026-01-02T00:00:00',
      'is_my_message': true,
      'sender': {'name': 'Я'},
    });

    expect(message.type, 'voice');
    expect(message.duration.inSeconds, 4);
  });

  test('cache snapshot round-trips the bubble the server sent', () {
    final original = Message(
      id: 7,
      text: 'привет',
      type: 'text',
      isMyMessage: true,
      createMessateTime: '2026-01-02T10:00:00',
      senderName: 'Я',
    );

    final json = original.toCacheJson(chatType: 'lead');
    expect(isDisplaySafeCachePayload(json), isTrue);
    expect(isDisplaySafeCachePayload({'id': 7, 'type': 'text'}), isFalse);

    final restored = Message.fromJson(json, chatType: 'lead');
    expect(restored.type, 'text');
    expect(restored.text, 'привет');
    expect(restored.isMyMessage, isTrue);
    expect(restored.senderName, 'Я');
  });
}
