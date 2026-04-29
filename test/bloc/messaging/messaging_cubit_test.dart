import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/models/chat_messages_page.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RequestKey {
  const _RequestKey({
    required this.page,
    this.search,
  });

  final int page;
  final String? search;

  @override
  bool operator ==(Object other) {
    return other is _RequestKey && other.page == page && other.search == search;
  }

  @override
  int get hashCode => Object.hash(page, search);
}

class _FakeApiService extends ApiService {
  _FakeApiService(this.responses);

  final Map<_RequestKey, ChatMessagesPage> responses;

  @override
  Future<String> getDynamicBaseUrl() async => 'https://example.com/api';

  @override
  Future<void> initialize() async {}

  @override
  Future<ChatMessagesPage> getMessagesPage(
    int chatId, {
    int page = 1,
    String? search,
    String? chatType,
  }) async {
    final normalizedSearch =
        search?.trim().isEmpty ?? true ? null : search?.trim();
    final response =
        responses[_RequestKey(page: page, search: normalizedSearch)];
    if (response == null) {
      throw Exception('Missing stub for page=$page search=$normalizedSearch');
    }
    return response;
  }

  @override
  Future<void> editMessage(String messageId, String message) async {}

  @override
  Future<void> pinMessage(String messageId) async {}

  @override
  Future<void> unpinMessage(String messageId) async {}
}

Message _message(
  int id,
  String text, {
  bool isPinned = false,
  bool isMyMessage = false,
  String? createdAt,
}) {
  return Message(
    id: id,
    text: text,
    type: 'text',
    isMyMessage: isMyMessage,
    createMessateTime:
        createdAt ?? DateTime(2026, 1, id.abs().clamp(1, 28)).toIso8601String(),
    senderName: isMyMessage ? 'Me' : 'Other',
    isPinned: isPinned,
  );
}

ChatMessagesPage _page(
  List<Message> messages, {
  required int currentPage,
  required int totalPages,
}) {
  return ChatMessagesPage(
    data: messages,
    meta: ChatMessagesPagination(
      count: messages.length,
      total: messages.length * totalPages,
      perPage: messages.length,
      currentPage: currentPage,
      totalPages: totalPages,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'access_token': 'token',
      'userID': '42',
      'enteredMainDomain': 'example.com',
      'enteredDomain': 'demo',
      'is_domain_checked': true,
    });
  });

  test('loadInitialPage loads page 1 only and exposes pagination flags',
      () async {
    final cubit = MessagingCubit(
      _FakeApiService({
        const _RequestKey(page: 1): _page(
          [_message(3, 'third'), _message(2, 'second')],
          currentPage: 1,
          totalPages: 3,
        ),
      }),
    );

    await cubit.loadInitialPage(11, chatType: 'lead');

    final state = cubit.state as MessagesCollectionState;
    expect(state.messages.map((message) => message.id), [3, 2]);
    expect(state.loadedPages, {1});
    expect(state.hasReachedMax, isFalse);
    expect(state.isLoadingInitial, isFalse);
  });

  test('loadOlderPage appends older messages once without jumping order',
      () async {
    final cubit = MessagingCubit(
      _FakeApiService({
        const _RequestKey(page: 1): _page(
          [_message(3, 'third'), _message(2, 'second')],
          currentPage: 1,
          totalPages: 2,
        ),
        const _RequestKey(page: 2): _page(
          [_message(1, 'first')],
          currentPage: 2,
          totalPages: 2,
        ),
      }),
    );

    await cubit.loadInitialPage(11, chatType: 'lead');
    await cubit.loadOlderPage(11, chatType: 'lead');

    final state = cubit.state as MessagesCollectionState;
    expect(state.messages.map((message) => message.id), [3, 2, 1]);
    expect(state.loadedPages, {1, 2});
    expect(state.hasReachedMax, isTrue);
  });

  test('mergeIncomingMessage replaces local temp message with server one',
      () async {
    final cubit = MessagingCubit(
      _FakeApiService({
        const _RequestKey(page: 1): _page(
          [_message(2, 'server')],
          currentPage: 1,
          totalPages: 1,
        ),
      }),
    );

    cubit.showCachedMessages([
      _message(-1, 'hello',
          isMyMessage: true, createdAt: '2026-01-01T10:00:00.000'),
    ]);

    cubit.mergeIncomingMessage(
      _message(10, 'hello',
          isMyMessage: true, createdAt: '2026-01-01T10:00:01.000'),
    );

    final state = cubit.state as MessagesCollectionState;
    expect(state.messages, hasLength(1));
    expect(state.messages.first.id, 10);
    expect(state.messages.first.text, 'hello');
  });

  test(
      'mergeIncomingMessage replaces fresh local temp message when socket mislabels it',
      () async {
    final cubit = MessagingCubit(
      _FakeApiService({
        const _RequestKey(page: 1): _page(
          [_message(2, 'server')],
          currentPage: 1,
          totalPages: 1,
        ),
      }),
    );

    cubit.showCachedMessages([
      _message(-1, 'hello',
          isMyMessage: true, createdAt: '2026-01-01T10:00:00.000Z'),
    ]);

    cubit.mergeIncomingMessage(
      _message(10, 'hello',
          isMyMessage: false, createdAt: '2026-01-01T10:00:01.000Z'),
    );

    final state = cubit.state as MessagesCollectionState;
    expect(state.messages, hasLength(1));
    expect(state.messages.first.id, 10);
    expect(state.messages.first.isMyMessage, isTrue);
    expect(state.messages.first.senderName, 'Me');
  });

  test(
      'resetAndSearch resets to page 1 and clears previously loaded older pages',
      () async {
    final cubit = MessagingCubit(
      _FakeApiService({
        const _RequestKey(page: 1): _page(
          [_message(3, 'third'), _message(2, 'needle second')],
          currentPage: 1,
          totalPages: 2,
        ),
        const _RequestKey(page: 2): _page(
          [_message(1, 'first')],
          currentPage: 2,
          totalPages: 2,
        ),
        const _RequestKey(page: 1, search: 'needle'): _page(
          [_message(2, 'needle second')],
          currentPage: 1,
          totalPages: 1,
        ),
      }),
    );

    await cubit.loadInitialPage(11, chatType: 'lead');
    await cubit.loadOlderPage(11, chatType: 'lead');
    await cubit.resetAndSearch(11, search: 'needle', chatType: 'lead');

    final state = cubit.state as MessagesCollectionState;
    expect(state.messages.map((message) => message.id), [2]);
    expect(state.loadedPages, {1});
    expect(state.searchQuery, 'needle');
  });

  test('loadOlderPage dedupes by message id', () async {
    final cubit = MessagingCubit(
      _FakeApiService({
        const _RequestKey(page: 1): _page(
          [_message(3, 'third'), _message(2, 'second')],
          currentPage: 1,
          totalPages: 2,
        ),
        const _RequestKey(page: 2): _page(
          [_message(2, 'second updated'), _message(1, 'first')],
          currentPage: 2,
          totalPages: 2,
        ),
      }),
    );

    await cubit.loadInitialPage(11, chatType: 'lead');
    await cubit.loadOlderPage(11, chatType: 'lead');

    final state = cubit.state as MessagesCollectionState;
    expect(state.messages.map((message) => message.id), [3, 2, 1]);
    expect(
      state.messages.firstWhere((message) => message.id == 2).text,
      'second updated',
    );
  });
}
