import 'dart:convert';
import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Chats.fromJson correctly parses channel and maps to WhatsApp icon from socket payload', () {
    final payloadJson = json.decode('''
    {
      "id": 9949,
      "unique_id": "fingroupcrm-new-back-9949",
      "task": null,
      "channel": {
        "id": 14,
        "name": "green_api",
        "base_name": "whatsapp",
        "source_key": "whatsapp",
        "label": "WhatsApp",
        "connected": false,
        "unread_count": 0,
        "organization_id": null
      },
      "lastMessage": {
        "id": 81093,
        "text": "Ассалому алайкум.",
        "type": "text",
        "created_at": "2026-10-21T10:02:39.000000Z"
      },
      "chatUsers": [
        {
          "type": "lead",
          "participant": {
            "id": 3522,
            "name": "karomatulloa02",
            "wa_name": "karomatulloa02",
            "wa_phone": "+992550000864"
          }
        }
      ],
      "lead": {
        "id": 3522,
        "name": "karomatulloa02"
      },
      "user": {
        "id": 3522,
        "name": "karomatulloa02"
      },
      "can_send_message": true,
      "type": "lead",
      "integration": {
        "id": 153,
        "name": "9255636363",
        "username": "9255636363"
      }
    }
    ''');

    final chat = Chats.fromJson(payloadJson);
    expect(chat.channel, equals('green_api'));
    expect(chat.channelObj?.baseName, equals('whatsapp'));

    final chatItem = chat.toChatItem();
    expect(chatItem.icon, equals('assets/icons/leads/whatsapp.png'));
    expect(chatItem.icon.contains('default'), isFalse);
  });

  test('Chats.fromJson fallbacks to lead data (wa_phone) when channel object is empty', () {
    final payloadJson = json.decode('''
    {
      "id": 9950,
      "unique_id": "fingroupcrm-new-back-9950",
      "channel": null,
      "lastMessage": {
        "id": 81094,
        "text": "Hello",
        "type": "text"
      },
      "lead": {
        "id": 3523,
        "name": "test_lead",
        "wa_phone": "+992920000000"
      },
      "type": "lead"
    }
    ''');

    final chat = Chats.fromJson(payloadJson);
    expect(chat.channel, equals('whatsapp'));

    final chatItem = chat.toChatItem();
    expect(chatItem.icon, equals('assets/icons/leads/whatsapp.png'));
  });
}
