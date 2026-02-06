import 'package:flutter/material.dart';
import 'package:crm_task_manager/data/emoji_data.dart';

/// Полная панель выбора эмодзи (100+) с категориями и поиском
/// Открывается как bottom sheet
class FullEmojiPickerSheet extends StatefulWidget {
  final Function(String emoji) onEmojiSelected;

  const FullEmojiPickerSheet({
    Key? key,
    required this.onEmojiSelected,
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
      length: EmojiData.categories.length,
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
        _searchResults = EmojiData.searchEmojis(query);
      }
    });
  }

  void _handleEmojiTap(String emoji) {
    widget.onEmojiSelected(emoji);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle для свайпа
          _buildHandle(),
          // Быстрые реакции сверху
          _buildQuickReactions(),
          // Поле поиска
          _buildSearchBar(),
          // Табы категорий или результаты поиска
          Expanded(
            child: _isSearching
                ? _buildSearchResults()
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
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildQuickReactions() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: EmojiData.quickReactions.map((emoji) {
            return GestureDetector(
              onTap: () => _handleEmojiTap(emoji),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Поиск эмодзи...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
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

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'Эмодзи не найдены',
          style: TextStyle(color: Colors.grey),
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
                  color: Colors.blue,
                  width: 2,
                ),
              ),
            ),
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: EmojiData.categories.keys.map((category) {
              // Берем первый эмодзи категории как иконку
              final iconEmoji = EmojiData.categories[category]!.first;
              return Tab(
                child: Text(
                  iconEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              );
            }).toList(),
          ),
        ),
        // Grid с эмодзи
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: EmojiData.categories.values.map((emojis) {
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
          color: Colors.transparent,
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
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return FullEmojiPickerSheet(
        onEmojiSelected: onEmojiSelected,
      );
    },
  );
}
