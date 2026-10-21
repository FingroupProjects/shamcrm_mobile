import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:crm_task_manager/offline/repositories/chat_offline_repository.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chats_items.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';

class ChatFolderSelectResult {
  final Set<int> selectedChatIds;
  final List<Chats> selectedChats;

  const ChatFolderSelectResult({
    required this.selectedChatIds,
    required this.selectedChats,
  });
}

class ChatFolderSelectChatsSheet extends StatefulWidget {
  final String endpoint;
  final int? currentSalesFunnelId;
  final Set<int> initialSelectedChatIds;
  final List<Chats>? initialAvailableChats;
  final Map<int, Chats>? preloadedChats;

  const ChatFolderSelectChatsSheet({
    super.key,
    required this.endpoint,
    this.currentSalesFunnelId,
    required this.initialSelectedChatIds,
    this.initialAvailableChats,
    this.preloadedChats,
  });

  static Future<ChatFolderSelectResult?> show(
    BuildContext context, {
    required String endpoint,
    int? currentSalesFunnelId,
    required Set<int> initialSelectedChatIds,
    List<Chats>? initialAvailableChats,
    Map<int, Chats>? preloadedChats,
  }) {
    return showModalBottomSheet<ChatFolderSelectResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatFolderSelectChatsSheet(
        endpoint: endpoint,
        currentSalesFunnelId: currentSalesFunnelId,
        initialSelectedChatIds: initialSelectedChatIds,
        initialAvailableChats: initialAvailableChats,
        preloadedChats: preloadedChats,
      ),
    );
  }

  @override
  State<ChatFolderSelectChatsSheet> createState() =>
      _ChatFolderSelectChatsSheetState();
}

class _ChatFolderSelectChatsSheetState
    extends State<ChatFolderSelectChatsSheet> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Set<int> _selectedChatIds = {};
  final Map<int, Chats> _chatsMap = {};

  List<Chats> _chats = [];
  bool _isLoadingChats = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _selectedChatIds.addAll(widget.initialSelectedChatIds);

    if (widget.preloadedChats != null) {
      _chatsMap.addAll(widget.preloadedChats!);
    }

    if (widget.initialAvailableChats != null &&
        widget.initialAvailableChats!.isNotEmpty) {
      _chats = List.from(widget.initialAvailableChats!);
      for (final c in _chats) {
        _chatsMap[c.id] = c;
      }
      _isLoadingChats = false;
      _loadChats(page: 1, isSilent: true);
    } else {
      _isLoadingChats = true;
      _loadCachedChats();
      _loadChats(page: 1, isSilent: false);
    }

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      if (!_isLoadingMore && !_isLoadingChats && _hasMore) {
        _loadMoreChats();
      }
    }
  }

  Future<void> _loadCachedChats() async {
    try {
      final offlineRepo = ChatOfflineRepository.fromRuntime(_apiService);
      final cached = await offlineRepo.readCachedChats(
        endPoint: widget.endpoint,
        page: 1,
        tabId: null,
      );
      if (cached != null && cached.data.isNotEmpty && mounted) {
        if (_chats.isEmpty) {
          setState(() {
            _chats = cached.data;
            for (final c in cached.data) {
              _chatsMap[c.id] = c;
            }
            _isLoadingChats = false;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadChats({int page = 1, bool isSilent = false}) async {
    if (!isSilent && _chats.isEmpty) {
      setState(() => _isLoadingChats = true);
    }

    try {
      final pagination = await _apiService.getAllChats(
        widget.endpoint,
        page,
        _searchQuery.isNotEmpty ? _searchQuery : null,
        widget.endpoint == 'lead' ? widget.currentSalesFunnelId : null,
      );

      if (mounted) {
        setState(() {
          _currentPage = pagination.currentPage;
          _hasMore = _currentPage < pagination.totalPage;
          _chats = pagination.data;
          for (final c in pagination.data) {
            _chatsMap[c.id] = c;
          }
          _isLoadingChats = false;
        });
      }
    } catch (e, stack) {
      debugPrint('ChatFolderSelectChatsSheet._loadChats error: $e\n$stack');
      if (mounted) {
        setState(() => _isLoadingChats = false);
      }
    }
  }

  Future<void> _loadMoreChats() async {
    if (_isLoadingMore || _isLoadingChats || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final pagination = await _apiService.getAllChats(
        widget.endpoint,
        nextPage,
        _searchQuery.isNotEmpty ? _searchQuery : null,
        widget.endpoint == 'lead' ? widget.currentSalesFunnelId : null,
      );

      if (mounted) {
        setState(() {
          _currentPage = pagination.currentPage;
          _hasMore = _currentPage < pagination.totalPage;

          final existingIds = _chats.map((c) => c.id).toSet();
          final newItems = pagination.data
              .where((c) => !existingIds.contains(c.id))
              .toList();
          _chats.addAll(newItems);
          for (final c in pagination.data) {
            _chatsMap[c.id] = c;
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query.trim();
        _currentPage = 1;
        _hasMore = true;
      });
      _loadChats(page: 1, isSilent: false);
    });
  }

  String _cleanMessagePreview(String raw) {
    if (raw.isEmpty) return '';
    String cleaned = raw
        .replaceAll(RegExp(r'</p>\s*<p>|<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .replaceAll('&nbsp;', ' ');
    if (cleaned.contains('<') && cleaned.contains('>')) {
      cleaned = stripHtmlTags(cleaned);
    }
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  ChatItem _toCleanChatItem(Chats chat) {
    final baseItem = chat.toChatItem();
    final cleanMsg = _cleanMessagePreview(chat.lastMessage);
    return ChatItem(
      baseItem.name,
      cleanMsg,
      baseItem.time,
      baseItem.avatar,
      baseItem.icon,
      baseItem.unreadCount,
      isGroup: baseItem.isGroup,
      chatId: chat.id,
      labels: baseItem.labels,
    );
  }

  void _toggleChatSelection(int chatId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedChatIds.contains(chatId)) {
        _selectedChatIds.remove(chatId);
      } else {
        _selectedChatIds.add(chatId);
      }
    });
  }

  void _done() {
    HapticFeedback.lightImpact();
    final selectedChats = _selectedChatIds
        .map((id) => _chatsMap[id])
        .whereType<Chats>()
        .toList();

    Navigator.of(context).pop(
      ChatFolderSelectResult(
        selectedChatIds: Set<int>.from(_selectedChatIds),
        selectedChats: selectedChats,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final localizations = AppLocalizations.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Container(
              width: 36,
              height: 3.5,
              decoration: BoxDecoration(
                color: colors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localizations?.translate('folder_add_chats') ??
                        'Добавить чаты',
                    style: textStyles.titleMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontSize: 16.5,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _done,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _selectedChatIds.isNotEmpty
                        ? '${localizations?.translate('done') ?? 'Готово'} (${_selectedChatIds.length})'
                        : (localizations?.translate('done') ?? 'Готово'),
                    style: textStyles.bodyMd.copyWith(
                      color: colors.buttonPrimaryBg,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: textStyles.bodySm.copyWith(
                color: colors.textPrimary,
                fontSize: 13.5,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: localizations?.translate('search_chats') ??
                    'Поиск чатов...',
                hintStyle: textStyles.bodySm.copyWith(
                  color: colors.textSecondary,
                  fontSize: 13.5,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colors.textSecondary,
                  size: 18,
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: colors.backgroundSecondary.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: colors.buttonPrimaryBg, width: 1.5),
                ),
              ),
            ),
          ),

          const Divider(height: 6),

          // Chat list
          Expanded(
            child: _buildChatList(colors, textStyles, localizations),
          ),

          // Bottom Action Button
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              border: Border(
                top: BorderSide(
                    color: colors.borderSubtle.withValues(alpha: 0.6)),
              ),
            ),
            child: CustomButton(
              buttonText: _selectedChatIds.isNotEmpty
                  ? '${localizations?.translate('folder_add_chats') ?? 'Добавить чаты'} (${_selectedChatIds.length})'
                  : (localizations?.translate('done') ?? 'Готово'),
              buttonColor: colors.buttonPrimaryBg,
              textColor: colors.buttonPrimaryFg,
              onPressed: _done,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(
    dynamic colors,
    dynamic textStyles,
    AppLocalizations? localizations,
  ) {
    if (_isLoadingChats && _chats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: CircularProgressIndicator(
            color: colors.buttonPrimaryBg,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_chats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _searchQuery.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.chat_bubble_outline_rounded,
                size: 40,
                color: colors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? (localizations?.translate('nothing_found') ??
                        'Чаты не найдены')
                    : (localizations?.translate('empty_chats_title') ??
                        'Нет доступных чатов'),
                style: textStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Попробуйте изменить поисковый запрос',
                  style: textStyles.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      itemCount: _chats.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _chats.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.buttonPrimaryBg,
                ),
              ),
            ),
          );
        }

        final chat = _chats[index];
        final isChecked = _selectedChatIds.contains(chat.id);

        return InkWell(
          key: ValueKey(chat.uniqueId ?? chat.id.toString()),
          onTap: () => _toggleChatSelection(chat.id),
          splashColor: colors.buttonPrimaryBg.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: ChatListItem(
            chatItem: _toCleanChatItem(chat),
            endPointInTab: widget.endpoint,
            isSelectionMode: true,
            isSelected: isChecked,
            isCompact: true,
            onSelectionToggle: () => _toggleChatSelection(chat.id),
          ),
        );
      },
    );
  }
}
