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

    test('does not invent 20 seconds when voice_duration is missing', () {
      final message = Message.fromJson({
        'id': 48002,
        'type': 'voice',
        'text': null,
        'file_path':
            'https://file-api.shamcrm.com/tenants/x/chat/files/voice.ogg',
        'voice_duration': null,
        'created_at': '2026-07-07T15:52:16.000000Z',
        'sender': {'id': 5748, 'name': 'Доктор', 'type': 'lead'},
      });

      expect(message.type, 'voice');
      expect(message.duration, Duration.zero);
      expect(parseVoiceDuration(null), Duration.zero);
      expect(parseVoiceDuration(8), const Duration(seconds: 8));
      expect(parseVoiceDuration('8.4'), const Duration(seconds: 8));
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
