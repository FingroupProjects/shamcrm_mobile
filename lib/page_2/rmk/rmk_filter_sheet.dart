import 'package:crm_task_manager/offline/db/app_database.dart';
import 'package:flutter/material.dart';

Future<int?> showRmkFilterSheet({
  required BuildContext context,
  required List<RmkCategory> categories,
  required int? selectedCategoryId,
}) {
  return showModalBottomSheet<int?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return _RmkFilterContent(
        categories: categories,
        selectedCategoryId: selectedCategoryId,
      );
    },
  );
}

class _RmkFilterContent extends StatelessWidget {
  const _RmkFilterContent({
    required this.categories,
    required this.selectedCategoryId,
  });

  final List<RmkCategory> categories;
  final int? selectedCategoryId;

  List<_CategoryNode> _flattenCategories() {
    final roots = categories.where((item) => item.parentId == null).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final result = <_CategoryNode>[];
    for (final root in roots) {
      _appendCategory(result, root, 0);
    }
    return result;
  }

  void _appendCategory(
    List<_CategoryNode> result,
    RmkCategory category,
    int level,
  ) {
    result.add(_CategoryNode(category: category, level: level));

    final children = categories
        .where((item) => item.parentId == category.id)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    for (final child in children) {
      _appendCategory(result, child, level + 1);
    }
  }

  bool _hasChildren(int categoryId) {
    return categories.any((item) => item.parentId == categoryId);
  }

  void _handleCategoryTap(BuildContext context, RmkCategory category) {
    Navigator.pop(context, category.id);
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _flattenCategories();

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _FilterHeader(onClose: () => Navigator.pop(context)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: nodes.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _FilterCategoryCard(
                      title: 'Все товары',
                      level: 0,
                      icon: Icons.category,
                      isSelected: selectedCategoryId == null,
                      onTap: () => Navigator.pop(context),
                    );
                  }

                  final node = nodes[index - 1];
                  final category = node.category;
                  final hasChildren = _hasChildren(category.id);

                  return _FilterCategoryCard(
                    title: category.name,
                    level: node.level,
                    icon: node.level > 0
                        ? Icons.subdirectory_arrow_right
                        : Icons.category,
                    isSelected: selectedCategoryId == category.id,
                    showArrow: !hasChildren,
                    onTap: () => _handleCategoryTap(context, category),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Фильтр',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xff99A4BA)),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _CategoryNode {
  const _CategoryNode({
    required this.category,
    required this.level,
  });

  final RmkCategory category;
  final int level;
}

class _FilterCategoryCard extends StatelessWidget {
  const _FilterCategoryCard({
    required this.title,
    required this.level,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.showArrow = false,
  });

  final String title;
  final int level;
  final IconData icon;
  final bool isSelected;
  final bool showArrow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final leftPadding = 16.0 + (level * 24.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: level > 0 ? leftPadding - 16 : 0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4F7FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: level > 0
                ? const Color(0xFFE5E7EB).withValues(alpha: 0.7)
                : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (level > 0) ...[
                Container(
                  width: 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xff4759FF).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                width: level > 0 ? 40 : 50,
                height: level > 0 ? 40 : 50,
                decoration: BoxDecoration(
                  color: const Color(0xffF4F7FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xff4759FF),
                  size: level > 0 ? 20 : 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: level > 0 ? 14 : 16,
                    fontFamily: 'Gilroy',
                    fontWeight: level > 0 ? FontWeight.w500 : FontWeight.w600,
                    color: const Color(0xff1E2E52),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_rounded,
                  color: Color(0xff4759FF),
                  size: 22,
                )
              else if (showArrow)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xff99A4BA),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
