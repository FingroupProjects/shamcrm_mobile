import 'package:crm_task_manager/services/chat_voice_player_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('voice playback helpers', () {
    test('cycles through exclusive speeds', () {
      expect(nextVoicePlaybackSpeed(1.0), 1.5);
      expect(nextVoicePlaybackSpeed(1.5), 2.0);
      expect(nextVoicePlaybackSpeed(2.0), 1.0);
    });

    test('formats speed and clock labels', () {
      expect(formatVoiceSpeedLabel(1.0), '1x');
      expect(formatVoiceSpeedLabel(1.5), '1.5x');
      expect(formatVoiceClock(const Duration(seconds: 83)), '01:23');
    });

    test('hides the mini player only inside the same chat', () {
      expect(
        shouldShowChatVoiceMiniPlayer(
          isActive: true,
          trackChatId: 10,
          foregroundChatId: 10,
        ),
        isFalse,
      );
      expect(
        shouldShowChatVoiceMiniPlayer(
          isActive: true,
          trackChatId: 10,
          foregroundChatId: 3,
        ),
        isTrue,
      );
    });

    test('keeps one track identity per chat message', () {
      expect(
        chatVoiceTrackKey(chatId: 10, messageId: 3, filePath: 'a.ogg'),
        chatVoiceTrackKey(chatId: 10, messageId: 3, filePath: 'a.ogg'),
      );
      expect(
        chatVoiceTrackKey(chatId: 10, messageId: 3, filePath: 'a.ogg'),
        isNot(chatVoiceTrackKey(chatId: 10, messageId: 4, filePath: 'a.ogg')),
      );
    });

    test('formats sent time for today and older dates', () {
      final now = DateTime(2026, 9, 7, 12, 0);
      expect(formatChatVoiceSentAt('2026-09-07T12:00:00', now: now), isNotEmpty);
      expect(
        formatChatVoiceSentAt('2026-01-02T08:20:00', now: now),
        contains('.'),
      );
    });
  });
}
