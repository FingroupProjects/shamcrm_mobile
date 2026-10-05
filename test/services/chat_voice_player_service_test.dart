import 'package:crm_task_manager/services/chat_voice_catalog.dart';
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

    test('ignores a fake completion while switching tracks', () {
      expect(shouldIgnoreVoiceCompletion(switchingTrack: true), isTrue);
      expect(shouldIgnoreVoiceCompletion(switchingTrack: false), isFalse);
    });

    test('plays the next newer voice in the same chat', () {
      final older = _track(1);
      final current = _track(2);
      final newer = _track(3);
      expect(nextVoiceInChat([older, current, newer], current)?.messageId, 3);
      expect(nextVoiceInChat([older, current], current), isNull);
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

ChatVoiceTrack _track(int messageId) {
  return ChatVoiceTrack(
    messageId: messageId,
    chatId: 10,
    filePath: 'voice.ogg',
    localPath: 'voice.ogg',
    senderName: 'Анна',
    sentAtLabel: '12:00',
    duration: const Duration(seconds: 3),
    endPointInTab: 'lead',
  );
}
