import 'package:crm_task_manager/screens/chats/chats_widgets/chat_file_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const baseUrl = 'https://fingroupcrm-back.shamcrm.com';

  test('keeps an absolute chat media URL unchanged', () {
    const fileUrl =
        'https://file-api.shamcrm.com/tenants/fingroupcrm-back/chat/files/photo.jpg';

    expect(resolveFileUrl(fileUrl, baseUrl), fileUrl);
  });

  test('removes an invalid storage prefix before an absolute URL', () {
    const fileUrl =
        'https://file-api.shamcrm.com/tenants/fingroupcrm-back/chat/files/photo.jpg';

    expect(resolveFileUrl('storage/$fileUrl', baseUrl), fileUrl);
  });

  test('resolves a relative chat media path through storage', () {
    expect(
      resolveFileUrl('chat/files/photo.jpg', baseUrl),
      '$baseUrl/storage/chat/files/photo.jpg',
    );
  });
}
