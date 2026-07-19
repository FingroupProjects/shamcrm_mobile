import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/category/category_screen.dart';
import 'package:crm_task_manager/page_2/goods/goods_screen.dart';
import 'package:crm_task_manager/page_2/money/money_references/cash_desk/cash_desk_screen.dart';
import 'package:crm_task_manager/page_2/money/money_references/expense/expense_screen.dart';
import 'package:crm_task_manager/page_2/money/money_references/income/income_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/measure_units/measue_units_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/openings/openings_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/price_type/pricetype_creen.dart';
import 'package:crm_task_manager/page_2/warehouse/ware_house/ware_house_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier/supplier_creen.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/lead/lead_screen.dart';
import 'package:reorderables/reorderables.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReferencesScreen extends StatefulWidget {
  const ReferencesScreen({super.key});

  @override
  State<ReferencesScreen> createState() => _ReferencesScreenState();
}

class _ReferencesScreenState extends State<ReferencesScreen> {
  static const String _referenceOrderPrefsKey = 'warehouse_reference_order';
  final ApiService _apiService = ApiService();
  bool isClickAvatarIcon = false;
  bool _isLoading = true;

  List<ReferenceItem> _references = [];

  // Флаги прав доступа для каждого справочника
  bool _hasStorage = false;
  bool _hasUnit = false;
  bool _hasSupplier = false;
  bool _hasProduct = false;
  bool _hasPriceType = false;
  bool _hasCashRegister = false;
  bool _hasRkoArticle = false;
  bool _hasPkoArticle = false;
  bool _hasCategory = false; // Новое право для категорий
  bool _hasLead = false; // TODO, проверка права для лидов
  bool _hasOpenings = false; // TODO, проверка права для первоначальных остатков

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoading) {
      _initializeReferences();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Проверяем права для каждого справочника отдельно
      _hasStorage = await _apiService.hasPermission('storage.read');
      _hasUnit = await _apiService.hasPermission('unit.read');
      _hasSupplier = await _apiService.hasPermission('supplier.read');
      _hasProduct = await _apiService.hasPermission('product.read');
      _hasPriceType = await _apiService.hasPermission('price_type.read');
      _hasCashRegister = await _apiService.hasPermission('cash_register.read');
      _hasRkoArticle = await _apiService.hasPermission('rko_article.read');
      _hasPkoArticle = await _apiService.hasPermission('pko_article.read');
      _hasCategory = await _apiService
          .hasPermission('category.read'); // Проверка права для категорий
      _hasLead = await _apiService.hasPermission('lead.read');
      _hasOpenings = await _apiService.hasPermission(
          'initial_balance.read'); // TODO: Проверить правильное имя права
    } catch (e) {
      debugPrint('Ошибка при проверке прав доступа: $e');
      _hasStorage = false;
      _hasUnit = false;
      _hasSupplier = false;
      _hasProduct = false;
      _hasPriceType = false;
      _hasCashRegister = false;
      _hasRkoArticle = false;
      _hasPkoArticle = false;
      _hasCategory = false;
      _hasLead = false;
      _hasOpenings = false;
    } finally {
      setState(() {
        _isLoading = false;
      });
      _initializeReferences();
    }
  }

  void _initializeReferences() {
    final colors = context.appColors;
    final Color refColor = colors.buttonPrimaryBg;
    List<ReferenceItem> allReferences = [];

    // Добавляем справочники только если есть соответствующее право
    if (_hasStorage) {
      allReferences.add(
        ReferenceItem(
          keyName: 'warehouse',
          title:
              AppLocalizations.of(context)!.translate('warehouse') ?? 'Склад',
          icon: Icons.warehouse_outlined,
          color: refColor,
        ),
      );
    }

    if (_hasUnit) {
      allReferences.add(
        ReferenceItem(
          keyName: 'unit',
          title:
              AppLocalizations.of(context)!.translate('units_of_measurement') ??
                  'Единицы измерения',
          icon: Icons.straighten_outlined,
          color: refColor,
        ),
      );
    }

    if (_hasSupplier) {
      allReferences.add(
        ReferenceItem(
          keyName: 'supplier',
          title: AppLocalizations.of(context)!.translate('supplier') ??
              'Поставщик',
          icon: Icons.business_outlined,
          color: refColor,
        ),
      );
    }

    if (_hasProduct) {
      allReferences.add(
        ReferenceItem(
          keyName: 'product',
          title: AppLocalizations.of(context)!.translate('product') ?? 'Товар',
          icon: Icons.inventory_2_outlined,
          color: refColor,
        ),
      );
    }

    if (_hasCategory) {
      allReferences.add(
        ReferenceItem(
          keyName: 'category',
          title: AppLocalizations.of(context)!.translate('appbar_categories') ??
              'Категории',
          icon: Icons.category_outlined,
          color: refColor,
        ),
      );
    }

    if (_hasPriceType) {
      allReferences.add(
        ReferenceItem(
          keyName: 'price_type',
          title: AppLocalizations.of(context)!.translate('price_type') ??
              'Тип цены',
          icon: Icons.price_change_outlined,
          color: refColor,
        ),
      );
    }

    if (_hasCashRegister) {
      allReferences.add(
        ReferenceItem(
          keyName: 'cash_register',
          title:
              AppLocalizations.of(context)!.translate('cash_desk') ?? 'Касса',
          icon: Icons.account_balance_wallet,
          color: refColor,
        ),
      );
    }

    if (_hasRkoArticle) {
      allReferences.add(
        ReferenceItem(
          keyName: 'rko_article',
          title: AppLocalizations.of(context)!.translate('expense_articles') ??
              'Статьи расходов',
          icon: Icons.trending_down,
          color: refColor,
        ),
      );
    }

    if (_hasPkoArticle) {
      allReferences.add(
        ReferenceItem(
          keyName: 'pko_article',
          title: AppLocalizations.of(context)!.translate('income_articles') ??
              'Статьи доходов',
          icon: Icons.trending_up,
          color: refColor,
        ),
      );
    }

    if (_hasLead) {
      allReferences.add(
        ReferenceItem(
          keyName: 'clients',
          title:
              AppLocalizations.of(context)!.translate('clients') ?? 'Клиенты',
          icon: Icons.person_outline,
          color: refColor,
        ),
      );
    }

    if (_hasOpenings) {
      allReferences.add(
        ReferenceItem(
          keyName: 'openings',
          title: AppLocalizations.of(context)!.translate('openings') ??
              'Первоначальный остаток',
          icon: Icons.account_balance_outlined,
          color: refColor,
        ),
      );
    }

    setState(() {
      _references = allReferences;
    });
    _applySavedReferenceOrder(allReferences);
  }

  Future<void> _applySavedReferenceOrder(List<ReferenceItem> references) async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrder = prefs.getStringList(_referenceOrderPrefsKey) ?? const [];
    final byKey = {
      for (final reference in references) reference.keyName: reference
    };
    final ordered = <ReferenceItem>[
      for (final key in savedOrder)
        if (byKey.containsKey(key)) byKey.remove(key)!,
      ...references.where((reference) => byKey.containsKey(reference.keyName)),
    ];

    if (!mounted) return;
    setState(() {
      _references = ordered;
    });
  }

  Future<void> _saveReferenceOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _referenceOrderPrefsKey,
      _references.map((reference) => reference.keyName).toList(),
    );
  }

  void _navigateToReference(ReferenceItem reference) {
    if (reference.keyName == 'supplier') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SupplierCreen()),
      );
    } else if (reference.keyName == 'warehouse') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WareHouseScreen()),
      );
    } else if (reference.keyName == 'unit') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MeasureUnitsScreen()),
      );
    } else if (reference.keyName == 'product') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GoodsScreen()),
      );
    } else if (reference.keyName == 'category') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CategoryScreen()),
      );
    } else if (reference.keyName == 'price_type') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PriceTypeScreen()),
      );
    } else if (reference.keyName == 'cash_register') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CashDeskScreen()),
      );
    } else if (reference.keyName == 'rko_article') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ExpenseScreen()),
      );
    } else if (reference.keyName == 'pko_article') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => IncomeScreen()),
      );
    } else if (reference.keyName == 'clients') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LeadScreen(
            isWarehouseReferenceClients: true,
          ),
        ),
      );
    } else if (reference.keyName == 'openings') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OpeningsScreen()),
      );
    }
  }

  Widget _buildReferenceCard(ReferenceItem reference) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToReference(reference),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: colors.surfacePrimary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: colors.borderSubtle,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: reference.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    reference.icon,
                    size: 28,
                    color: reference.color,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      reference.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReferencesLayout() {
    if (_references.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;

        int crossAxisCount;
        double childAspectRatio;

        if (screenWidth < 350) {
          crossAxisCount = 2;
          childAspectRatio = 0.9;
        } else if (screenWidth < 400) {
          crossAxisCount = 2;
          childAspectRatio = 1.0;
        } else if (screenWidth < 500) {
          crossAxisCount = 2;
          childAspectRatio = 1.1;
        } else if (screenWidth < 600) {
          crossAxisCount = 2;
          childAspectRatio = 1.2;
        } else if (screenWidth < 900) {
          crossAxisCount = 3;
          childAspectRatio = 1.1;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 1.0;
        }

        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - 32 - (spacing * (crossAxisCount - 1))) /
                crossAxisCount;
        final itemHeight = itemWidth / childAspectRatio;

        return ReorderableWrap(
          spacing: spacing,
          runSpacing: spacing,
          padding: const EdgeInsets.all(16),
          needsLongPressDraggable: true,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              final item = _references.removeAt(oldIndex);
              _references.insert(newIndex, item);
            });
            _saveReferenceOrder();
          },
          children: [
            for (final reference in _references)
              SizedBox(
                key: ValueKey(reference.keyName),
                width: itemWidth,
                height: itemHeight,
                child: _buildReferenceCard(reference),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNoPermissionsWidget() {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.translate('no_permissions') ??
                  'Нет доступа',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!
                      .translate('no_permissions_description') ??
                  'У вас нет прав доступа к справочникам. Обратитесь к администратору.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w400,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBarPage2(
          title: isClickAvatarIcon
              ? localizations.translate('appbar_settings') ?? 'Настройки'
              : localizations.translate('references') ?? 'Справочники',
          onClickProfileAvatar: () {
            setState(() {
              isClickAvatarIcon = !isClickAvatarIcon;
            });
          },
          clearButtonClickFiltr: (isSearching) {},
          showSearchIcon: false,
          showFilterIcon: false,
          showFilterOrderIcon: false,
          onChangedSearchInput: (input) {},
          textEditingController: TextEditingController(),
          focusNode: FocusNode(),
          clearButtonClick: (isSearching) {},
          currentFilters: {},
        ),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : _isLoading
              ? const Center(
                  child: PlayStoreImageLoading(
                    size: 80.0,
                    duration: Duration(milliseconds: 1000),
                  ),
                )
              : _references.isEmpty
                  ? _buildNoPermissionsWidget()
                  : Container(
                      color: colors.surfacePrimary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: _buildReferencesLayout(),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class ReferenceItem {
  final String keyName;
  final String title;
  final IconData icon;
  final Color color;

  ReferenceItem({
    required this.keyName,
    required this.title,
    required this.icon,
    required this.color,
  });
}
