import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

/// One row in the category picker. Subcategories stay indented.
class GoodsOpeningCategoryOption {
  final int id;
  final String name;
  final int level;

  const GoodsOpeningCategoryOption({
    required this.id,
    required this.name,
    required this.level,
  });

  const GoodsOpeningCategoryOption.clear()
      : id = 0,
        name = '',
        level = 0;

  bool get isClear => id == 0 && name.isEmpty;
}

/// Picks one category. Same /category list as orders and incoming.
class GoodsOpeningCategoryPicker {
  static Future<GoodsOpeningCategoryOption?> show(
    BuildContext context, {
    int? selectedId,
  }) {
    return showDialog<GoodsOpeningCategoryOption>(
      context: context,
      builder: (_) => _GoodsOpeningCategoryDialog(selectedId: selectedId),
    );
  }
}

class _GoodsOpeningCategoryDialog extends StatefulWidget {
  final int? selectedId;

  const _GoodsOpeningCategoryDialog({this.selectedId});

  @override
  State<_GoodsOpeningCategoryDialog> createState() =>
      _GoodsOpeningCategoryDialogState();
}

class _GoodsOpeningCategoryDialogState
    extends State<_GoodsOpeningCategoryDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<GoodsOpeningCategoryOption> _all = [];
  List<GoodsOpeningCategoryOption> _visible = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categories = await _apiService.getCategory();
      final flat = _flatten(categories);
      if (!mounted) return;
      setState(() {
        _all = flat;
        _visible = flat;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // Same flatten idea as VariantBottomSheetBloc.
  List<GoodsOpeningCategoryOption> _flatten(
    List<CategoryData> categories, [
    int level = 0,
  ]) {
    final result = <GoodsOpeningCategoryOption>[];
    for (final category in categories) {
      result.add(GoodsOpeningCategoryOption(
        id: category.id,
        name: category.name,
        level: level,
      ));
      if (category.subcategories.isEmpty) continue;
      final children = category.subcategories
          .map((sub) => CategoryData(
                id: sub.id,
                name: sub.name,
                image: sub.image,
                subcategories: sub.subcategories,
              ))
          .toList();
      result.addAll(_flatten(children, level + 1));
    }
    return result;
  }

  void _filter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _visible = _all;
        return;
      }
      _visible = _all
          .where((item) => item.name.toLowerCase().contains(q))
          .toList();
    });
  }

  String _t(String key, String fallback) {
    return AppLocalizations.of(context)?.translate(key) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 420,
        ),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
              decoration: const BoxDecoration(
                color: Color(0xff38BDF8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _t('select_category', 'Выберите категорию'),
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: _t('search', 'Поиск...'),
                  hintStyle: TextStyle(color: colors.textSecondary),
                  prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                  filled: true,
                  fillColor: colors.fieldBg,
                  isDense: true,
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
                    borderSide: BorderSide(color: colors.borderPrimary),
                  ),
                ),
              ),
            ),
            Flexible(child: _buildBody()),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: Text(_t('retry_dialog', 'Повторить'))),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      shrinkWrap: true,
      children: [
        // Clear filter: show every product again.
        _tile(
          title: _t('clear', 'Очистить'),
          selected: widget.selectedId == null,
          indent: 0,
          onTap: () => Navigator.pop(
            context,
            const GoodsOpeningCategoryOption.clear(),
          ),
        ),
        ..._visible.map((item) => _tile(
              title: item.name,
              selected: widget.selectedId == item.id,
              indent: item.level,
              onTap: () => Navigator.pop(context, item),
            )),
      ],
    );
  }

  Widget _tile({
    required String title,
    required bool selected,
    required int indent,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.fromLTRB(12 + indent * 16.0, 12, 12, 12),
        decoration: BoxDecoration(
          color: selected
              ? colors.buttonPrimaryBg.withValues(alpha: 0.12)
              : colors.surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colors.buttonPrimaryBg : colors.borderSubtle,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
