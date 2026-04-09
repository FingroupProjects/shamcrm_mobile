part of 'messaging_cubit.dart';

const Object _messagesCollectionUndefined = Object();

sealed class MessagingState extends Equatable {
  const MessagingState();

  @override
  List<Object?> get props => [];
}

final class MessagingInitial extends MessagingState {}

final class MessagesLoadingState extends MessagingState {}

class MessagesCollection extends Equatable {
  const MessagesCollection({
    this.messages = const [],
    this.pinnedMessages = const [],
    this.isFromCache = false,
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.loadedPages = const {},
    this.searchQuery,
    this.lastLoadedPage = 0,
  });

  final List<Message> messages;
  final List<Message> pinnedMessages;
  final bool isFromCache;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final Set<int> loadedPages;
  final String? searchQuery;
  final int lastLoadedPage;

  MessagesCollection copyWith({
    List<Message>? messages,
    List<Message>? pinnedMessages,
    bool? isFromCache,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasReachedMax,
    Set<int>? loadedPages,
    Object? searchQuery = _messagesCollectionUndefined,
    int? lastLoadedPage,
  }) {
    return MessagesCollection(
      messages: List<Message>.unmodifiable(messages ?? this.messages),
      pinnedMessages:
          List<Message>.unmodifiable(pinnedMessages ?? this.pinnedMessages),
      isFromCache: isFromCache ?? this.isFromCache,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      loadedPages:
          Set<int>.unmodifiable(loadedPages ?? Set<int>.from(this.loadedPages)),
      searchQuery: identical(searchQuery, _messagesCollectionUndefined)
          ? this.searchQuery
          : searchQuery as String?,
      lastLoadedPage: lastLoadedPage ?? this.lastLoadedPage,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        pinnedMessages,
        isFromCache,
        isLoadingInitial,
        isLoadingMore,
        hasReachedMax,
        SplayTreeSet<int>.from(loadedPages).toList(growable: false),
        searchQuery,
        lastLoadedPage,
      ];
}

sealed class MessagesCollectionState extends MessagingState {
  const MessagesCollectionState({
    required this.collection,
  });

  final MessagesCollection collection;

  List<Message> get messages => collection.messages;
  List<Message> get pinnedMessages => collection.pinnedMessages;
  bool get isFromCache => collection.isFromCache;
  bool get isLoadingInitial => collection.isLoadingInitial;
  bool get isLoadingMore => collection.isLoadingMore;
  bool get hasReachedMax => collection.hasReachedMax;
  Set<int> get loadedPages => collection.loadedPages;
  String? get searchQuery => collection.searchQuery;
  int get lastLoadedPage => collection.lastLoadedPage;

  @override
  List<Object?> get props => [collection];
}

final class MessagesLoadedState extends MessagesCollectionState {
  const MessagesLoadedState({
    required super.collection,
  });
}

final class MessagesErrorState extends MessagingState {
  const MessagesErrorState({required this.error});

  final String error;

  @override
  List<Object?> get props => [error];
}

final class EditingMessageState extends MessagesCollectionState {
  const EditingMessageState({
    required this.editingMessage,
    required super.collection,
  });

  final Message editingMessage;

  @override
  List<Object?> get props => [editingMessage, collection];
}

final class ReplyingToMessageState extends MessagesCollectionState {
  const ReplyingToMessageState({
    required this.replyingMessage,
    required super.collection,
  });

  final Message replyingMessage;

  @override
  List<Object?> get props => [replyingMessage, collection];
}

final class PinnedMessagesState extends MessagesCollectionState {
  const PinnedMessagesState({
    required super.collection,
  });
}

final class MessagesPartialErrorState extends MessagingState {
  const MessagesPartialErrorState({
    required this.error,
    this.canRetry = true,
  });

  final String error;
  final bool canRetry;

  @override
  List<Object?> get props => [error, canRetry];
}
