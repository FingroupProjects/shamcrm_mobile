import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Message.resolveIncomingType voice', () {
    test('keeps explicit voice type', () {
      expect(Message.resolveIncomingType('voice', ''), 'voice');
    });

    test('maps audio aliases to voice', () {
      expect(Message.resolveIncomingType('audio', ''), 'voice');
      expect(Message.resolveIncomingType('ptt', ''), 'voice');
      expect(Message.resolveIncomingType('voice_message', ''), 'voice');
    });

    test('maps file paths with audio extensions to voice', () {
      expect(
        Message.resolveIncomingType(
          'file',
          'audio.ogg',
          filePath: 'https://file-api.shamcrm.com/tenants/x/chat/files/a.ogg',
        ),
        'voice',
      );
      expect(
        Message.resolveIncomingType('document', '', filePath: 'notes.opus'),
        'voice',
      );
    });

    test('treats messages with voice_duration as voice', () {
      final message = Message.fromJson({
        'id': 1,
        'type': 'file',
        'text': 'voice',
        'file_path': 'chat/files/unknown',
        'voice_duration': 20,
        'created_at': '2026-09-08T09:53:00',
        'is_read': false,
        'sender': {'name': 'Ahmadshoh'},
      });
      expect(message.type, 'voice');
    });

    test('does not treat photos as voice', () {
      expect(
        Message.resolveIncomingType('file', 'photo.jpg', filePath: 'p.jpg'),
        'image',
      );
    });
  });
}
