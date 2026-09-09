import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/pricing_model.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/warehouse_document_filter_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  void _onFilterSelected(Map<String, dynamic> filters) {
    setState(() => _filters = Map<String, dynamic>.from(filters));
    _reload();
  }

  void _resetFilters() {
    setState(() => _filters = {});
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: colors.surfacePrimary,
        title: CustomAppBarPage2(
          title: 'Цены',
          showSearchIcon: true,
          showFilterIcon: false,
          showFilterOrderIcon: false,
          showFilterIncomeIcon: false,
          showFilterIncomingIcon: true,
          warehouseFilterType: WarehouseDocumentFilterType.clientSale,
          onFilterIncomingSelected: _onFilterSelected,
          onIncomingResetFilters: _resetFilters,
          onChangedSearchInput: _onSearch,
          textEditingController: _searchController,
          focusNode: _focusNode,
          clearButtonClick: (isSearching) {
            if (!isSearching) {
              _searchController.clear();
              _reload();
            }
          },
          onClickProfileAvatar: () {},
          clearButtonClickFiltr: (_) {},
          currentFilters: _filters,
        ),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Цены успешно созданы')),
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

class PricingCreateScreen extends StatefulWidget {
  const PricingCreateScreen({super.key});
  @override
  State<PricingCreateScreen> createState() => _PricingCreateScreenState();
}

class _PricingCreateScreenState extends State<PricingCreateScreen> {
  final _api = ApiService();
  final _horizontal = ScrollController();
  final _priceFrom = TextEditingController();
  final _priceTo = TextEditingController();
  int? _categoryId;
  List<PricingGood> _goods = const [];
  List<Map<String, dynamic>> _rules = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGoods();
  }

  Future<void> _loadGoods() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _api.getPricingGoods(
        priceFrom: _priceFrom.text.trim(),
        priceTo: _priceTo.text.trim(),
        categoryId: _categoryId,
        rules: _rules,
      );
      if (mounted)
        setState(() {
          if (_rules.isNotEmpty) {
            for (final good in page.items) {
              for (final price in good.prices) {
                price.isEntered = price.newPrice != 0;
              }
            }
          }
          _goods = page.items;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _priceFrom.dispose();
    _priceTo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final hasEnteredPrices =
        _goods.any((good) => good.prices.any((price) => price.isEntered));
    if (!hasEnteredPrices) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите хотя бы одну цену')),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
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
        context: context, builder: (_) => const _PricingRulesDialog());
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
          TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Отмена')),
          TextButton(
              onPressed: _saving || _goods.isEmpty ? null : _save,
              child: Text(_saving ? 'Сохранение...' : 'Сохранить')),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Expanded(
                child: Text('Товаров: ${_goods.length}',
                    style: Theme.of(context).textTheme.titleMedium)),
            IconButton.outlined(
              onPressed: _showFilter,
              tooltip: 'Фильтр',
              icon: const Icon(Icons.filter_alt_outlined),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: _showRules,
              tooltip: 'Правила',
              icon: const Icon(Icons.tune),
            ),
          ]),
        ),
        if (_rules.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
    return Scrollbar(
      controller: _horizontal,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontal,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 190 + priceTypes.length * 170.0,
          child: ListView.builder(
            itemCount: _goods.length + 1,
            itemBuilder: (context, index) => index == 0
                ? _TableHeader(priceTypes: priceTypes)
                : _PricingGoodRow(good: _goods[index - 1]),
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
                child: TextFormField(
                  initialValue: _number(price.newPrice),
                  selectAllOnFocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                  ],
                  decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Было ${_number(price.currentPrice)}'),
                  onChanged: (value) {
                    final normalized = value.trim().replaceAll(',', '.');
                    price.newPrice = double.tryParse(normalized) ?? 0;
                    price.isEntered = normalized.isNotEmpty;
                  },
                ),
              ))),
        ]),
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
  const _PricingRulesDialog();
  @override
  State<_PricingRulesDialog> createState() => _PricingRulesDialogState();
}

class _PricingRulesDialogState extends State<_PricingRulesDialog> {
  final _percent = TextEditingController();
  final _sum = TextEditingController();
  final _decimals = TextEditingController(text: '0');
  bool _increase = true;
  int _roundDigits = 0;
  bool _roundIncrease = true;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Expanded(
                      child: Text('Правила',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w700))),
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
                    onChanged: (value) => setState(() => _increase = value)),
                const SizedBox(height: 16),
                TextField(
                  controller: _decimals,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                            onTap: () => setState(() => _roundDigits = digit),
                          )),
                ),
                const SizedBox(height: 12),
                _RuleDirection(
                    value: _roundIncrease,
                    onChanged: (value) =>
                        setState(() => _roundIncrease = value)),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final percent =
                          double.tryParse(_percent.text.replaceAll(',', '.'));
                      final sum =
                          double.tryParse(_sum.text.replaceAll(',', '.'));
                      if ((percent == null || percent <= 0) &&
                          (sum == null || sum <= 0)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Введите процент или сумму больше нуля')));
                        return;
                      }
                      Navigator.pop(context, {
                        'change_type': _increase ? 'increase' : 'decrease',
                        'change_percent': _percent.text.trim(),
                        'change_sum': _sum.text.trim(),
                        'decimals': _decimals.text.trim(),
                        'round_digits': _roundDigits,
                        'round_digits_change_type':
                            _roundIncrease ? 'increase' : 'decrease',
                      });
                    },
                    child: const Text('Применить'),
                  ),
                ]),
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
