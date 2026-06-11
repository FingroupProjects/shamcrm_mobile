import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/data/emoji_data.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

/// Полная панель выбора эмодзи (100+) с категориями и поиском
/// Открывается как bottom sheet
class FullEmojiPickerSheet extends StatefulWidget {
  final Function(String emoji) onEmojiSelected;
  final String? channelKey;

  const FullEmojiPickerSheet({
    Key? key,
    required this.onEmojiSelected,
    this.channelKey,
  }) : super(key: key);

  @override
  State<FullEmojiPickerSheet> createState() => _FullEmojiPickerSheetState();
}

class _FullEmojiPickerSheetState extends State<FullEmojiPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: EmojiData.reactionPickerCategories.length,
      vsync: this,
    );
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      final query = _searchController.text;
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _searchResults = EmojiData.searchReactionEmojis(
          query,
          channelKey: widget.channelKey,
        );
      }
    });
  }

  void _handleEmojiTap(String emoji) {
    widget.onEmojiSelected(emoji);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: context.appColors.surfacePrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle для свайпа
          _buildHandle(),
          // Быстрые реакции сверху
          _buildQuickReactions(),
          // Поле поиска
          _buildSearchBar(localizations),
          // Табы категорий или результаты поиска
          Expanded(
            child: _isSearching
                ? _buildSearchResults(localizations)
                : _buildCategoriesWithTabs(),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: context.appColors.borderSubtle,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildQuickReactions() {
    final quickReactions = EmojiData.reactionsForSource(
      'quick_panel',
      channelKey: widget.channelKey,
    );
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: quickReactions.map((emoji) {
            return GestureDetector(
              onTap: () => _handleEmojiTap(emoji),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.appColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.appColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: localizations.translate('search_emoji'),
          prefixIcon: Icon(Icons.search, color: context.appColors.iconSecondary),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: Icon(Icons.clear, color: context.appColors.iconSecondary),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(AppLocalizations localizations) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          localizations.translate('emoji_not_found'),
          style: TextStyle(color: context.appColors.textSecondary),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildEmojiCell(_searchResults[index]);
      },
    );
  }

  Widget _buildCategoriesWithTabs() {
    final fullReactions = EmojiData.reactionsForSource(
      'full_picker',
      channelKey: widget.channelKey,
    );

    return Column(
      children: [
        // Категории как иконки
        Container(
          height: 50,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicator: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                  color: context.appColors.buttonPrimaryBg,
                  width: 2,
                ),
              ),
            ),
            labelColor: context.appColors.buttonPrimaryBg,
            unselectedLabelColor: context.appColors.textSecondary,
            tabs: [
              Tab(
                child: Text(
                  fullReactions.isNotEmpty ? fullReactions.first : '🙂',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ],
          ),
        ),
        // Grid с эмодзи
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [fullReactions].map((emojis) {
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) {
                  return _buildEmojiCell(emojis[index]);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiCell(String emoji) {
    return GestureDetector(
      onTap: () => _handleEmojiTap(emoji),
      child: Container(
        decoration: BoxDecoration(
          color: context.appColors.overlay.withValues(alpha: 0.0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
        ),
      ),
    );
  }
}

/// Показать полную панель выбора эмодзи
Future<void> showFullEmojiPicker({
  required BuildContext context,
  required Function(String emoji) onEmojiSelected,
  String? channelKey,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appColors.overlay.withValues(alpha: 0.0),
    builder: (context) {
      return FullEmojiPickerSheet(
        onEmojiSelected: onEmojiSelected,
        channelKey: channelKey,
      );
    },
  );
}
