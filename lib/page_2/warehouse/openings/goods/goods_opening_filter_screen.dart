import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/author/get_all_author_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_wh.dart';
import 'package:crm_task_manager/custom_widget/dropdown_loading_state.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/models/page_2/openings/goods_opening_filter.dart';
import 'package:crm_task_manager/models/user/author_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Пункт мультивыбора. Сравнение по id, чтобы галочки не сбрасывались.
class _Option {
  final int id;
  final String name;

  const _Option(this.id, this.name);

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) => other is _Option && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Фильтр товаров в первоначальном остатке.
/// Тот же карточный экран, что у прихода: сброс, применить, мигание загрузки.
class GoodsOpeningFilterScreen extends StatefulWidget {
  final GoodsOpeningFilter initial;

  const GoodsOpeningFilterScreen({
    super.key,
    this.initial = GoodsOpeningFilter.empty,
  });

  @override
  State<GoodsOpeningFilterScreen> createState() =>
      _GoodsOpeningFilterScreenState();
}

class _GoodsOpeningFilterScreenState extends State<GoodsOpeningFilterScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  List<_Option> _goods = [];
  List<_Option> _categories = [];
  List<_Option> _storages = [];
  List<_Option> _authors = [];
  bool _authorsRestored = false;

  List<_Option> _selectedGoods = [];
  List<_Option> _selectedCategories = [];
  List<_Option> _selectedStorages = [];
  List<_Option> _selectedAuthors = [];

  bool _goodsLoading = true;
  bool _categoriesLoading = true;
  bool _storagesLoading = true;
  String? _goodsError;
  String? _categoriesError;
  String? _storagesError;

  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initial.dateFrom;
    _toDate = widget.initial.dateTo;
    if (_fromDate != null) {
      _fromController.text = DateFormat('dd/MM/yyyy').format(_fromDate!);
    }
    if (_toDate != null) {
      _toController.text = DateFormat('dd/MM/yyyy').format(_toDate!);
    }
    _loadGoods();
    _loadCategories();
    _loadStorages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<GetAllAuthorBloc>();
      final state = bloc.state;
      if (state is GetAllAuthorSuccess) {
        setState(() {
          _applyAuthors(state.dataAuthor.result ?? <AuthorData>[]);
        });
        return;
      }
      bloc.add(GetAllAuthorEv());
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  List<_Option> _restore(List<_Option> all, List<int> ids) {
    return all.where((item) => ids.contains(item.id)).toList();
  }

  Future<void> _loadGoods() async {
    setState(() {
      _goodsLoading = true;
      _goodsError = null;
    });
    try {
      final loaded = <_Option>[];
      var page = 1;
      // Несколько страниц, чтобы в списке были не только первые 20 товаров.
      while (page <= 8) {
        final response = await _api.getGoodVariantsForDropdown(
          page: page,
          perPage: 50,
        );
        final data = response.result?.data ?? [];
        for (final item in data) {
          final id = item.id;
          if (id == null) continue;
          final name = (item.fullName ?? '').trim();
          loaded.add(_Option(id, name.isEmpty ? '$id' : name));
        }
        final pages = response.result?.pagination?.totalPages ?? page;
        if (data.isEmpty || page >= pages) break;
        page++;
      }
      if (!mounted) return;
      setState(() {
        _goods = loaded;
        _selectedGoods = _restore(loaded, widget.initial.goodIds);
        _goodsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _goodsLoading = false;
        _goodsError = e.toString();
      });
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });
    try {
      final tree = await _api.getCategory();
      final flat = _flattenCategories(tree);
      if (!mounted) return;
      setState(() {
        _categories = flat;
        _selectedCategories = _restore(flat, widget.initial.categoryIds);
        _categoriesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoriesLoading = false;
        _categoriesError = e.toString();
      });
    }
  }

  List<_Option> _flattenCategories(List<CategoryData> categories, [int level = 0]) {
    final result = <_Option>[];
    for (final category in categories) {
      final prefix = level == 0 ? '' : '  ' * level;
      result.add(_Option(category.id, '$prefix${category.name}'));
      if (category.subcategories.isEmpty) continue;
      final children = category.subcategories
          .map((sub) => CategoryData(
                id: sub.id,
                name: sub.name,
                image: sub.image,
                subcategories: sub.subcategories,
              ))
          .toList();
      result.addAll(_flattenCategories(children, level + 1));
    }
    return result;
  }

  Future<void> _loadStorages() async {
    setState(() {
      _storagesLoading = true;
      _storagesError = null;
    });
    try {
      final storages = await _api.getWareHouses();
      final loaded = storages.map((item) => _Option(item.id, item.name)).toList();
      if (!mounted) return;
      setState(() {
        _storages = loaded;
        _selectedStorages = _restore(loaded, widget.initial.storageIds);
        _storagesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _storagesLoading = false;
        _storagesError = e.toString();
      });
    }
  }

  DateTime? _readDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  GoodsOpeningFilter _buildFilter() {
    return GoodsOpeningFilter(
      goodIds: _selectedGoods.map((item) => item.id).toList(),
      categoryIds: _selectedCategories.map((item) => item.id).toList(),
      storageIds: _selectedStorages.map((item) => item.id).toList(),
      authorIds: _selectedAuthors.map((item) => item.id).toList(),
      dateFrom: _fromDate,
      dateTo: _toDate,
    );
  }

  void _applyAuthors(List<AuthorData> authors) {
    final loaded = authors
        .map((author) {
          final name = '${author.name} ${author.lastname}'.trim();
          return _Option(author.id, name.isEmpty ? author.name : name);
        })
        .toList();
    _authors = loaded;
    // Один раз подставляем сохранённый выбор. Дальше список ведёт пользователь.
    if (!_authorsRestored) {
      _selectedAuthors = _restore(loaded, widget.initial.authorIds);
      _authorsRestored = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Scaffold(
      backgroundColor: colors.backgroundSecondary,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          localizations.translate('filter'),
          style: textStyles.titleLg.copyWith(color: colors.textPrimary),
        ),
        backgroundColor: colors.surfacePrimary,
        forceMaterialTransparency: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, GoodsOpeningFilter.empty),
            style: _actionStyle(colors),
            child: Text(
              localizations.translate('reset'),
              style: textStyles.labelLg.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => Navigator.pop(context, _buildFilter()),
            style: _actionStyle(colors),
            child: Text(
              localizations.translate('apply'),
              style: textStyles.labelLg.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _multiCard(
            title: localizations.translate('goods'),
            hint: localizations.translate('select_goods'),
            loading: _goodsLoading,
            error: _goodsError,
            onRetry: _loadGoods,
            items: _goods,
            selected: _selectedGoods,
            onChanged: (values) => setState(() => _selectedGoods = values),
          ),
          const SizedBox(height: 8),
          _multiCard(
            title: localizations.translate('category'),
            hint: localizations.translate('select_category'),
            loading: _categoriesLoading,
            error: _categoriesError,
            onRetry: _loadCategories,
            items: _categories,
            selected: _selectedCategories,
            onChanged: (values) => setState(() => _selectedCategories = values),
          ),
          const SizedBox(height: 8),
          _multiCard(
            title: localizations.translate('warehouse'),
            hint: localizations.translate('select_warehouse'),
            loading: _storagesLoading,
            error: _storagesError,
            onRetry: _loadStorages,
            items: _storages,
            selected: _selectedStorages,
            onChanged: (values) => setState(() => _selectedStorages = values),
          ),
          const SizedBox(height: 8),
          _card(
            child: DateFieldWithFromTo(
              isFrom: true,
              controller: _fromController,
              label: localizations.translate('date'),
              withTime: false,
              onDateSelected: (date) {
                setState(() => _fromDate = _readDate(date));
              },
            ),
          ),
          const SizedBox(height: 8),
          _card(
            child: DateFieldWithFromTo(
              isFrom: false,
              controller: _toController,
              label: localizations.translate('date'),
              withTime: false,
              onDateSelected: (date) {
                setState(() => _toDate = _readDate(date));
              },
            ),
          ),
          const SizedBox(height: 8),
          _authorCard(localizations),
        ],
      ),
    );
  }

  Widget _authorCard(AppLocalizations localizations) {
    return BlocConsumer<GetAllAuthorBloc, GetAllAuthorState>(
      listener: (context, state) {
        if (state is GetAllAuthorSuccess) {
          setState(() {
            _applyAuthors(state.dataAuthor.result ?? <AuthorData>[]);
          });
        }
      },
      builder: (context, state) {
        final loading = state is GetAllAuthorInitial ||
            state is GetAllAuthorLoading ||
            (state is GetAllAuthorSuccess && !_authorsRestored);
        return _multiCard(
          title: localizations.translate('author'),
          hint: localizations.translate('select_author'),
          loading: loading,
          error: state is GetAllAuthorError ? state.message : null,
          onRetry: () => context.read<GetAllAuthorBloc>().add(GetAllAuthorEv()),
          items: _authors,
          selected: _selectedAuthors,
          // Поле внизу экрана: список открываем вверх, чтобы поиск не пропадал.
          openUpward: true,
          canCloseOutsideBounds: false,
          onChanged: (values) => setState(() => _selectedAuthors = values),
        );
      },
    );
  }

  Widget _multiCard({
    required String title,
    required String hint,
    required bool loading,
    required String? error,
    required VoidCallback onRetry,
    required List<_Option> items,
    required List<_Option> selected,
    required ValueChanged<List<_Option>> onChanged,
    bool openUpward = false,
    bool canCloseOutsideBounds = true,
  }) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textStyles.bodyLg.copyWith(
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          if (loading)
            const DropdownLoadingState()
          else if (error != null)
            TextButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.translate('retry_dialog')),
            )
          else
            CustomDropdown<_Option>.multiSelectSearch(
              key: ValueKey('$title-${items.length}'),
              items: items,
              initialItems: selected,
              searchHintText: AppLocalizations.of(context)!.translate('search'),
              overlayHeight: 320,
              openUpward: openUpward,
              // Иначе тап по поиску внизу экрана закрывает список.
              canCloseOutsideBounds: canCloseOutsideBounds,
              decoration: CustomDropdownDecoration(
                closedFillColor: colors.fieldBg,
                expandedFillColor: colors.surfacePrimary,
                closedBorder: Border.all(color: colors.borderSubtle, width: 1),
                closedBorderRadius: BorderRadius.circular(12),
                expandedBorder: Border.all(color: colors.borderSubtle, width: 1),
                expandedBorderRadius: BorderRadius.circular(12),
                hintStyle: textStyles.bodyMd.copyWith(
                  color: colors.textSecondary,
                ),
                headerStyle: textStyles.bodyMd.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                listItemStyle: textStyles.bodyMd.copyWith(
                  color: colors.textPrimary,
                ),
                // Без этого поиск и выбранная строка остаются белыми.
                listItemDecoration: ListItemDecoration(
                  selectedColor: colors.buttonPrimaryBg.withValues(alpha: 0.18),
                  highlightColor: colors.buttonPrimaryBg.withValues(alpha: 0.1),
                  splashColor: Colors.transparent,
                ),
                searchFieldDecoration: SearchFieldDecoration(
                  fillColor: colors.fieldBg,
                  textStyle: textStyles.bodyMd.copyWith(
                    color: colors.textPrimary,
                  ),
                  hintStyle: textStyles.bodyMd.copyWith(
                    color: colors.textSecondary,
                  ),
                  prefixIcon: Icon(Icons.search, color: colors.iconSecondary),
                  suffixIcon: (onClear) => IconButton(
                    onPressed: onClear,
                    icon: Icon(Icons.close_rounded, color: colors.iconSecondary),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.fieldBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.buttonPrimaryBg),
                  ),
                ),
              ),
              listItemBuilder: (context, item, isSelected, onItemSelect) {
                return Text(
                  item.name,
                  style: textStyles.bodyMd.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
              headerListBuilder: (context, hintText, enabled) {
                final label = selected.isEmpty
                    ? hint
                    : selected.map((item) => item.name.trim()).join(', ');
                return Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.bodyMd.copyWith(
                    color: selected.isEmpty
                        ? colors.textSecondary
                        : colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
              hintBuilder: (context, hintText, enabled) {
                return Text(
                  hint,
                  style: textStyles.bodyMd.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
              onListChanged: onChanged,
            ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    final colors = context.appColors;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colors.surfacePrimary,
      shadowColor: colors.shadowColor,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: child,
      ),
    );
  }

  ButtonStyle _actionStyle(AppThemeColors colors) {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      backgroundColor: colors.buttonSecondaryBg.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: colors.buttonPrimaryBg, width: 0.5),
    );
  }
}
