import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_wh.dart';
import 'package:crm_task_manager/models/page_2/pricing_model.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/models/user/user_model.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final _api = ApiService();
  late Future<List<PricingDocument>> _documents;
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Map<String, dynamic> _filters = {};
  bool _isSearching = false;
  bool _canCreate = false;

  @override
  void initState() {
    super.initState();
    _documents = _api.getPricingDocuments();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final canCreate = await _api.hasPermission('pricing.create') ||
        await _api.hasPermission('price_type.create');
    if (mounted) setState(() => _canCreate = canCreate);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _reload() => setState(() {
        _documents = _api.getPricingDocuments(
          search: _searchController.text,
          filters: _filters,
        );
      });

  void _onSearch(String _) => _reload();

  Future<void> _showPricingFilter() async {
    final filters = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => PricingDocumentFilterScreen(initialFilters: _filters),
      ),
    );
    if (filters != null) {
      setState(() => _filters = filters);
      _reload();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: colors.surfacePrimary,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _focusNode,
                autofocus: true,
                onChanged: _onSearch,
                decoration: const InputDecoration(
                  hintText: 'Поиск',
                  border: InputBorder.none,
                ),
              )
            : const Text('Цены'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Закрыть поиск' : 'Поиск',
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) {
                _searchController.clear();
                _reload();
              }
            },
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _filters.isNotEmpty,
              child: const Icon(Icons.filter_alt_outlined),
            ),
            tooltip: 'Фильтр',
            onPressed: _showPricingFilter,
          ),
        ],
      ),
      body: FutureBuilder<List<PricingDocument>>(
        future: _documents,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError)
            return _ErrorState(error: snapshot.error, retry: _reload);
          final documents = snapshot.data ?? const [];
          if (documents.isEmpty)
            return const Center(child: Text('Документы цен пока не созданы'));
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) => _PricingDocumentCard(
                document: documents[index],
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      PricingDetailsScreen(document: documents[index]),
                )),
              ),
            ),
          );
        },
      ),
      floatingActionButton: _canCreate
          ? FloatingActionButton(
              onPressed: () async {
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                      builder: (_) => const PricingCreateScreen()),
                );
                if (saved == true) {
                  _reload();
                  if (mounted) {
                    showCustomSnackBar(
                      context: context,
                      message: 'Успешно',
                    );
                  }
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _PricingDocumentCard extends StatelessWidget {
  const _PricingDocumentCard({required this.document, required this.onTap});
  final PricingDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = document.startDate;
    final formatted = date == null
        ? 'Дата не указана'
        : '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Card(
      color: context.appColors.surfaceElevated,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.appColors.borderSubtle),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.price_change_outlined)),
        title: Text('Цены № ${document.id}'),
        subtitle: Text(formatted),
        trailing: Text(document.authorName, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class PricingDetailsScreen extends StatelessWidget {
  const PricingDetailsScreen({super.key, required this.document});
  final PricingDocument document;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Цены № ${document.id}')),
        body: FutureBuilder<List<PricingDocumentItem>>(
          future: ApiService().getPricingDocumentItems(document.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(error: snapshot.error, retry: () {});
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty)
              return const Center(child: Text('В документе нет цен'));
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, index) => ListTile(
                title: Text(items[index].goodName),
                subtitle: Text(items[index].priceTypeName),
                trailing: Text(_number(items[index].price)),
              ),
            );
          },
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.retry});
  final Object? error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(error?.toString() ?? 'Не удалось загрузить данные',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: retry, child: const Text('Повторить')),
          ]),
        ),
      );
}

class PricingDocumentFilterScreen extends StatefulWidget {
  const PricingDocumentFilterScreen({super.key, required this.initialFilters});
  final Map<String, dynamic> initialFilters;

  @override
  State<PricingDocumentFilterScreen> createState() =>
      _PricingDocumentFilterScreenState();
}

class _PricingDocumentFilterScreenState
    extends State<PricingDocumentFilterScreen> {
  final _api = ApiService();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  DateTime? _from;
  DateTime? _to;
  int? _authorId;
  List<UserTask> _authors = const [];
  bool _authorsLoading = true;

  @override
  void initState() {
    super.initState();
    _from =
        DateTime.tryParse(widget.initialFilters['date_from']?.toString() ?? '');
    _to = DateTime.tryParse(widget.initialFilters['date_to']?.toString() ?? '');
    _authorId =
        int.tryParse(widget.initialFilters['author_id']?.toString() ?? '');
    _syncDateControllers();
    _loadAuthors();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthors() async {
    try {
      final authors = await _api.getUserTask();
      if (mounted) setState(() => _authors = authors);
    } finally {
      if (mounted) setState(() => _authorsLoading = false);
    }
  }

  void _syncDateControllers() {
    String format(DateTime? value) => value == null
        ? ''
        : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    _fromController.text = format(_from);
    _toController.text = format(_to);
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String _serverDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  void _clear() {
    setState(() {
      _from = null;
      _to = null;
      _authorId = null;
      _syncDateControllers();
    });
  }

  void _apply() {
    _from = _parseDate(_fromController.text);
    _to = _parseDate(_toController.text);
    Navigator.pop(context, {
      if (_from != null) 'date_from': _serverDate(_from!),
      if (_to != null) 'date_to': _serverDate(_to!),
      if (_authorId != null) 'author_id': _authorId.toString(),
    });
  }

  Widget _section({required String title, required Widget child}) => Card(
        color: context.appColors.surfacePrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: context.appTextStyles.bodyLg
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            child,
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.backgroundSecondary,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text('Фильтр'),
        actions: [
          TextButton(onPressed: _clear, child: const Text('Очистить')),
          TextButton(onPressed: _apply, child: const Text('Применить')),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            title: 'Диапазон дат',
            child: Column(children: [
              DateFieldWithFromTo(
                controller: _fromController,
                label: 'От',
                isFrom: true,
                onDateSelected: (value) => _from = _parseDate(value),
              ),
              const SizedBox(height: 12),
              DateFieldWithFromTo(
                controller: _toController,
                label: 'До',
                isFrom: false,
                onDateSelected: (value) => _to = _parseDate(value),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Автор',
            child: _authorsLoading
                ? const SizedBox(
                    height: 50,
                    child: Center(child: CircularProgressIndicator()))
                : CustomDropdown<UserTask>.search(
                    items: _authors,
                    searchHintText: 'Поиск',
                    overlayHeight: 300,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: context.appColors.fieldBg,
                      expandedFillColor: context.appColors.surfacePrimary,
                      closedBorder:
                          Border.all(color: context.appColors.fieldBg),
                      expandedBorder:
                          Border.all(color: context.appColors.fieldBg),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorderRadius: BorderRadius.circular(12),
                    ),
                    initialItem: _authors.cast<UserTask?>().firstWhere(
                          (author) => author?.id == _authorId,
                          orElse: () => null,
                        ),
                    hintBuilder: (_, __, ___) => const Text('Выберите автора'),
                    headerBuilder: (_, author, __) =>
                        Text('${author.name} ${author.lastname}'.trim()),
                    listItemBuilder: (_, author, __, ___) =>
                        Text('${author.name} ${author.lastname}'.trim()),
                    onChanged: (author) => setState(() {
                      _authorId = author?.id;
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}

class PricingCreateScreen extends StatefulWidget {
  const PricingCreateScreen({super.key});
  @override
  State<PricingCreateScreen> createState() => _PricingCreateScreenState();
}

class _PricingCreateScreenState extends State<PricingCreateScreen> {
  final _api = ApiService();
  final _horizontal = ScrollController();
  // Вертикальный скролл таблицы — по нему грузим следующие страницы.
  final _vertical = ScrollController();
  final _priceFrom = TextEditingController();
  final _priceTo = TextEditingController();
  int? _categoryId;
  List<PricingGood> _goods = const [];
  List<Map<String, dynamic>> _rules = const [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasReachedMax = false;
  int _currentPage = 1;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _vertical.addListener(_onVerticalScroll);
    _loadGoods();
  }

  void _onVerticalScroll() {
    if (!_vertical.hasClients) return;
    if (_vertical.position.pixels <
        _vertical.position.maxScrollExtent - 200) {
      return;
    }
    _loadGoods(reset: false);
  }

  // Если первая страница короткая, сразу догружаем следующую.
  void _maybeLoadMoreIfListIsShort() {
    if (!mounted || _hasReachedMax || _loading || _loadingMore) return;
    if (_goods.isEmpty ||
        !_vertical.hasClients ||
        _vertical.position.maxScrollExtent <= 0) {
      _loadGoods(reset: false);
    }
  }

  Future<void> _loadGoods({bool reset = true}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _loadingMore = false;
        _error = null;
        _currentPage = 1;
        _hasReachedMax = false;
      });
    } else {
      if (_loading || _loadingMore || _hasReachedMax) return;
      setState(() => _loadingMore = true);
    }

    final pageToLoad = reset ? 1 : _currentPage + 1;
    try {
      final page = await _api.getPricingGoods(
        page: pageToLoad,
        priceFrom: _priceFrom.text.trim(),
        priceTo: _priceTo.text.trim(),
        categoryId: _categoryId,
        rules: _rules,
      );
      if (!mounted) return;
      final filteredGoods = _applyPriceFilter(page.items);
      if (_rules.isNotEmpty) {
        _applyRuleToAllPrices(filteredGoods, _rules.first);
      }
      final existingIds = reset
          ? <int>{}
          : _goods.map((good) => good.variantId).toSet();
      final uniqueGoods = filteredGoods
          .where((good) => !existingIds.contains(good.variantId))
          .toList();
      final nextGoods = reset ? uniqueGoods : [..._goods, ...uniqueGoods];
      final reachedLastPage =
          page.totalPages > 0 && page.currentPage >= page.totalPages;
      final reachedTotal = page.total > 0 && nextGoods.length >= page.total;
      setState(() {
        _goods = nextGoods;
        if (reset && _vertical.hasClients) {
          _vertical.jumpTo(0);
        }
        _currentPage = page.currentPage;
        _hasReachedMax = page.items.isEmpty ||
            (!reset && uniqueGoods.isEmpty) ||
            reachedLastPage ||
            reachedTotal;
        _loading = false;
        _loadingMore = false;
      });
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _maybeLoadMoreIfListIsShort());
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
          _loadingMore = false;
        });
    }
  }

  List<PricingGood> _applyPriceFilter(List<PricingGood> goods) {
    final from = double.tryParse(_priceFrom.text.trim().replaceAll(',', '.'));
    final to = double.tryParse(_priceTo.text.trim().replaceAll(',', '.'));
    if (from == null && to == null) return goods;
    return goods.where((good) {
      return good.prices.any((price) {
        final value = price.currentPrice;
        return (from == null || value >= from) && (to == null || value <= to);
      });
    }).toList();
  }

  void _applyRuleToAllPrices(
    List<PricingGood> goods,
    Map<String, dynamic> rule,
  ) {
    final percent = double.tryParse(
      (rule['change_percent']?.toString() ?? '').replaceAll(',', '.'),
    );
    final sum = double.tryParse(
      (rule['change_sum']?.toString() ?? '').replaceAll(',', '.'),
    );
    final isIncrease = rule['change_type'] != 'decrease';
    final decimals =
        (int.tryParse(rule['decimals']?.toString() ?? '') ?? 0).clamp(0, 10);
    final roundDigits = int.tryParse(rule['round_digits']?.toString() ?? '');
    final roundUp = rule['round_digits_change_type'] != 'decrease';
    final steps = [1, 10, 100, 1000, 10000, 100000];
    final step = roundDigits == null ? null : steps[roundDigits.clamp(0, 5)];

    for (final good in goods) {
      for (final price in good.prices) {
        var next = price.currentPrice;
        if (percent != null && percent > 0) {
          next *= isIncrease ? 1 + percent / 100 : 1 - percent / 100;
        }
        if (sum != null && sum > 0) {
          next += isIncrease ? sum : -sum;
        }
        next = double.parse(next.toStringAsFixed(decimals));
        if (step != null && step > 1) {
          next = (roundUp ? (next / step).ceil() : (next / step).floor()) *
              step.toDouble();
        }
        price.newPrice = next < 0 ? 0 : next;
        price.isEntered = price.newPrice != price.currentPrice;
      }
    }
  }

  @override
  void dispose() {
    _vertical.removeListener(_onVerticalScroll);
    _vertical.dispose();
    _horizontal.dispose();
    _priceFrom.dispose();
    _priceTo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final hasEnteredPrices =
        _goods.any((good) => good.prices.any((price) => price.isEntered));
    if (!hasEnteredPrices) {
      showCustomSnackBar(
        context: context,
        message: 'Введите хотя бы одну цену',
        isSuccess: false,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.createPricingDocument(
          goods: _goods, startDate: DateTime.now());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted)
        showCustomSnackBar(
          context: context,
          message: e.toString(),
          isSuccess: false,
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showFilter() async {
    List<CategoryData> categories;
    try {
      categories = await _api.getCategory();
    } catch (_) {
      categories = const [];
    }
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PricingFilterSheet(
        from: _priceFrom,
        to: _priceTo,
        categories: categories,
        selectedCategoryId: _categoryId,
        onCategoryChanged: (value) => _categoryId = value,
      ),
    );
    if (applied == true) _loadGoods();
  }

  Future<void> _showRules() async {
    final rule = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PricingRulesDialog(
        initialRule: _rules.isEmpty ? null : _rules.first,
      ),
    );
    if (rule != null) {
      setState(() => _rules = [rule]);
      _loadGoods();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: colors.surfacePrimary,
        title: const Text('Добавить цены'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _showFilter,
            tooltip: 'Фильтр',
            icon: const Icon(Icons.filter_alt_outlined),
          ),
          IconButton(
            onPressed: _saving ? null : _showRules,
            tooltip: 'Правила',
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      // Кнопки в Column, не в bottomNavigationBar — иначе последняя
      // строка таблицы заезжает под «Отмена / Сохранить».
      body: Column(children: [
        if (_rules.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                    label: const Text('Правило применено'),
                    onDeleted: () {
                      setState(() => _rules = const []);
                      _loadGoods();
                    })),
          ),
        Expanded(child: _body()),
        AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: colors.surfacePrimary,
                border: Border(top: BorderSide(color: colors.borderSubtle)),
              ),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving || _goods.isEmpty ? null : _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: colors.buttonPrimaryBg,
                      foregroundColor: colors.buttonPrimaryFg,
                    ),
                    child: _saving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.buttonPrimaryFg,
                            ),
                          )
                        : const Text('Сохранить'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorState(error: _error, retry: _loadGoods);
    if (_goods.isEmpty)
      return const Center(
          child: Text('По заданным условиям товары не найдены'));
    final priceTypes = _goods.first.prices;
    final showMoreLoader = !_hasReachedMax;
    return Scrollbar(
      controller: _horizontal,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontal,
        scrollDirection: Axis.horizontal,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: SizedBox(
          width: 190 + priceTypes.length * 170.0,
          child: ListView.builder(
            controller: _vertical,
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: _goods.length + 1 + (showMoreLoader ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) return _TableHeader(priceTypes: priceTypes);
              final goodIndex = index - 1;
              if (goodIndex >= _goods.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return _PricingGoodRow(good: _goods[goodIndex]);
            },
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.priceTypes});
  final List<PricingValue> priceTypes;
  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(children: [
          const SizedBox(
              width: 190,
              child:
                  Padding(padding: EdgeInsets.all(16), child: Text('Товар'))),
          ...priceTypes.map((price) => SizedBox(
              width: 170,
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(price.priceTypeName,
                      overflow: TextOverflow.ellipsis)))),
        ]),
      );
}

class _PricingGoodRow extends StatelessWidget {
  const _PricingGoodRow({required this.good});
  final PricingGood good;
  @override
  Widget build(BuildContext context) => Container(
        height: 78,
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor))),
        child: Row(children: [
          SizedBox(
              width: 190,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(good.name,
                      maxLines: 2, overflow: TextOverflow.ellipsis))),
          ...good.prices.map((price) => SizedBox(
              width: 170,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: _PricingValueInput(
                  key: ValueKey('${good.variantId}-${price.priceTypeId}'),
                  price: price,
                ),
              ))),
        ]),
      );
}

class _PricingValueInput extends StatefulWidget {
  const _PricingValueInput({super.key, required this.price});
  final PricingValue price;

  @override
  State<_PricingValueInput> createState() => _PricingValueInputState();
}

class _PricingValueInputState extends State<_PricingValueInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _number(widget.price.newPrice));
  }

  @override
  void didUpdateWidget(covariant _PricingValueInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!FocusScope.of(context).hasFocus &&
        oldWidget.price.newPrice != widget.price.newPrice) {
      _controller.text = _number(widget.price.newPrice);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearInitialZero() {
    if (!widget.price.isEntered && _controller.text == '0') {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
        ],
        decoration: InputDecoration(
            isDense: true,
            labelText: 'Было ${_number(widget.price.currentPrice)}'),
        onTap: _clearInitialZero,
        onChanged: (value) {
          final normalized = value.trim().replaceAll(',', '.');
          widget.price.newPrice = double.tryParse(normalized) ?? 0;
          widget.price.isEntered = normalized.isNotEmpty;
        },
      );
}

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

class _PricingFilterSheet extends StatelessWidget {
  const _PricingFilterSheet({
    required this.from,
    required this.to,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
  });
  final TextEditingController from;
  final TextEditingController to;
  final List<CategoryData> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategoryChanged;
  @override
  Widget build(BuildContext context) {
    var visibleCategoryId = selectedCategoryId;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Фильтр',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 20),
                      const Text('Цена'),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                            child: TextField(
                                controller: from,
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(labelText: 'От'))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: TextField(
                                controller: to,
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(labelText: 'До'))),
                      ]),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int?>(
                        value: visibleCategoryId,
                        decoration:
                            const InputDecoration(labelText: 'Категория'),
                        items: [
                          const DropdownMenuItem<int?>(
                              value: null, child: Text('Все категории')),
                          ...categories.map((category) =>
                              DropdownMenuItem<int?>(
                                  value: category.id,
                                  child: Text(category.name))),
                        ],
                        onChanged: (value) {
                          onCategoryChanged(value);
                          setSheetState(() => visibleCategoryId = value);
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(
                            onPressed: () {
                              from.clear();
                              to.clear();
                              onCategoryChanged(null);
                              Navigator.pop(context, true);
                            },
                            child: const Text('Очистить')),
                        const SizedBox(width: 8),
                        ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Применить')),
                      ]),
                    ])),
      ),
    );
  }
}

class _PricingRulesDialog extends StatefulWidget {
  const _PricingRulesDialog({this.initialRule});
  final Map<String, dynamic>? initialRule;
  @override
  State<_PricingRulesDialog> createState() => _PricingRulesDialogState();
}

class _PricingRulesDialogState extends State<_PricingRulesDialog> {
  late final TextEditingController _percent;
  late final TextEditingController _sum;
  late final TextEditingController _decimals;
  bool _increase = true;
  int? _roundDigits;
  bool _roundIncrease = true;

  @override
  void initState() {
    super.initState();
    final rule = widget.initialRule;
    _percent = TextEditingController(
      text: rule?['change_percent']?.toString() ?? '',
    );
    _sum = TextEditingController(
      text: rule?['change_sum']?.toString() ?? '',
    );
    _decimals = TextEditingController(
      text: rule?['decimals']?.toString() ?? '0',
    );
    _increase = rule?['change_type'] != 'decrease';
    _roundIncrease = rule?['round_digits_change_type'] != 'decrease';
    _roundDigits = int.tryParse(rule?['round_digits']?.toString() ?? '');
  }

  @override
  void dispose() {
    _percent.dispose();
    _sum.dispose();
    _decimals.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height - 72,
          ),
          child: Column(children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Expanded(
                            child: Text('Правила',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700))),
                        IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close)),
                      ]),
                      const SizedBox(height: 16),
                      _RuleNumberField(
                        controller: _percent,
                        label: 'Изменить на X %',
                        hint: 'Введите процент',
                        autofocus: true,
                      ),
                      const SizedBox(height: 12),
                      _RuleNumberField(
                        controller: _sum,
                        label: 'Изменить на X сумму',
                        hint: 'Введите сумму',
                      ),
                      const SizedBox(height: 12),
                      _RuleDirection(
                          value: _increase,
                          onChanged: (value) =>
                              setState(() => _increase = value)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _decimals,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                            labelText: 'Округление (знаков после запятой)'),
                      ),
                      const SizedBox(height: 16),
                      const Text('Округление (разряды до запятой)'),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.42,
                        children: List.generate(
                            6,
                            (digit) => _RoundDigitsCard(
                                  digit: digit,
                                  selected: _roundDigits == digit,
                                  onTap: () => setState(() => _roundDigits =
                                      _roundDigits == digit ? null : digit),
                                )),
                      ),
                      const SizedBox(height: 12),
                      _RuleDirection(
                          value: _roundIncrease,
                          onChanged: (value) =>
                              setState(() => _roundIncrease = value)),
                      const SizedBox(height: 12),
                    ]),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogTheme.backgroundColor,
                border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final percent =
                        double.tryParse(_percent.text.replaceAll(',', '.'));
                    final sum = double.tryParse(_sum.text.replaceAll(',', '.'));
                    if ((percent == null || percent <= 0) &&
                        (sum == null || sum <= 0)) {
                      showCustomSnackBar(
                        context: context,
                        message: 'Введите процент или сумму больше нуля',
                        isSuccess: false,
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'change_type': _increase ? 'increase' : 'decrease',
                      'change_percent': _percent.text.trim(),
                      'change_sum': _sum.text.trim(),
                      'decimals': _decimals.text.trim(),
                      if (_roundDigits != null) 'round_digits': _roundDigits,
                      'round_digits_change_type':
                          _roundIncrease ? 'increase' : 'decrease',
                    });
                  },
                  child: const Text('Применить'),
                ),
              ]),
            ),
          ]),
        ),
      );
}

class _RuleNumberField extends StatelessWidget {
  const _RuleNumberField({
    required this.controller,
    required this.label,
    required this.hint,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool autofocus;
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
        ],
        decoration: InputDecoration(labelText: label, hintText: hint),
      );
}

class _RoundDigitsCard extends StatelessWidget {
  const _RoundDigitsCard({
    required this.digit,
    required this.selected,
    required this.onTap,
  });
  final int digit;
  final bool selected;
  final VoidCallback onTap;
  static const _titles = [
    'Единицы',
    'Десятки',
    'Сотни',
    'Тысячи',
    'Десятки тысяч',
    'Сто тысяч'
  ];
  static const _examples = [
    '1848 → 1850',
    '1848 → 1900',
    '1848 → 2000',
    '12847 → 13000',
    '102847 → 110000',
    '102847 → 200000'
  ];
  static const _steps = ['целых', '10', '100', '1000', '10000', '100000'];
  @override
  Widget build(BuildContext context) => Material(
        color: selected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.22)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                  width: selected ? 2 : 1),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_titles[digit],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('Округление до ${_steps[digit]}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(_examples[digit],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall),
                ]),
          ),
        ),
      );
}

class _RuleDirection extends StatelessWidget {
  const _RuleDirection({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Radio<bool>(
                value: true,
                groupValue: value,
                onChanged: (next) => onChanged(next!)),
            const Text('На повышение'),
            Radio<bool>(
                value: false,
                groupValue: value,
                onChanged: (next) => onChanged(next!)),
            const Text('На уменьшение'),
          ]);
}
