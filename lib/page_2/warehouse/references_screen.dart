import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/goods/goods_screen.dart';
import 'package:crm_task_manager/page_2/money/money_references/cash_desk/cash_desk_screen.dart';
import 'package:crm_task_manager/page_2/money/money_references/expense/expense_screen.dart';
import 'package:crm_task_manager/page_2/money/money_references/income/income_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/measure_units/measue_units_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/price_type/pricetype_creen.dart';
import 'package:crm_task_manager/page_2/warehouse/ware_house/ware_house_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier/supplier_creen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';

class ReferencesScreen extends StatefulWidget {
  @override
  _ReferencesScreenState createState() => _ReferencesScreenState();
}

class _ReferencesScreenState extends State<ReferencesScreen> {
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
    } finally {
      setState(() {
        _isLoading = false;
      });
      _initializeReferences();
    }
  }

  void _initializeReferences() {
    final Color refColor = const Color(0xff1E2E52);
    List<ReferenceItem> allReferences = [];

    // Добавляем справочники только если есть соответствующее право
    if (_hasStorage) {
      allReferences.add(
        ReferenceItem(
          title: AppLocalizations.of(context)!.translate('warehouse') ?? 'Склад',
          icon: Icons.warehouse_outlined,
          color: refColor,
        ),
      );
    }

    if (_hasUnit) {
      allReferences.add(
        ReferenceItem(
          title: AppLocalizations.of(context)!.translate('units_of_measurement') ?? 'Единицы измерения',
          icon: Icons.straighten_outlined,
          color: refColor,
        ),
      );
    }

    if (_hasSupplier) {
      allReferences.add(
        ReferenceItem(
          title: AppLocalizations.of(context)!.translate('supplier') ?? 'Поставщик',
          icon: Icons.business_outlined,
          color: refColor,
        ),
      );
    }

    if (_hasProduct) {
      allReferences.add(
        ReferenceItem(
          title: AppLocalizations.of(context)!.translate('product') ?? 'Товар',
          icon: Icons.inventory_2_outlined,
          color: refColor,
        ),
      );
    }

    if (_hasPriceType) {
      allReferences.add(
        ReferenceItem(
          title: AppLocalizations.of(context)!.translate('price_type') ?? 'Тип цены',
          icon: Icons.price_change_outlined,
          color: refColor,
        ),
      );
    }

    if (_hasCashRegister) {
      allReferences.add(
        ReferenceItem(
          title: AppLocalizations.of(context)!.translate('cash_desk') ?? 'Касса',
          icon: Icons.account_balance_wallet,
          color: refColor,
        ),
      );
    }

    if (_hasRkoArticle) {
      allReferences.add(
        ReferenceItem(
          title: AppLocalizations.of(context)!.translate('expense_articles') ?? 'Статьи расходов',
          icon: Icons.trending_down,
          color: refColor,
        ),
      );
    }

    if (_hasPkoArticle) {
      allReferences.add(
        ReferenceItem(
          title: AppLocalizations.of(context)!.translate('income_articles') ?? 'Статьи доходов',
          icon: Icons.trending_up,
          color: refColor,
        ),
      );
    }

    setState(() {
      _references = allReferences;
    });
  }

  void _navigateToReference(ReferenceItem reference) {
    if (reference.title == (AppLocalizations.of(context)!.translate('supplier') ?? 'Поставщик')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SupplierCreen()),
      );
    } else if (reference.title == (AppLocalizations.of(context)!.translate('warehouse') ?? 'Склад')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WareHouseScreen()),
      );
    } else if (reference.title == (AppLocalizations.of(context)!.translate('units_of_measurement') ?? 'Единицы измерения')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MeasureUnitsScreen()),
      );
    } else if (reference.title == (AppLocalizations.of(context)!.translate('product') ?? 'Товар')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GoodsScreen()),
      );
    } else if (reference.title == (AppLocalizations.of(context)!.translate('price_type') ?? 'Тип цены')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PriceTypeScreen()),
      );
    } else if (reference.title == (AppLocalizations.of(context)!.translate('cash_desk') ?? 'Касса')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CashDeskScreen()),
      );
    } else if (reference.title == (AppLocalizations.of(context)!.translate('expense_articles') ?? 'Статьи расходов')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ExpenseScreen()),
      );
    } else if (reference.title == (AppLocalizations.of(context)!.translate('income_articles') ?? 'Статьи доходов')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => IncomeScreen()),
      );
    }
  }

  Widget _buildReferenceCard(ReferenceItem reference) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToReference(reference),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: const Color(0xffE5E9F2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: reference.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  reference.icon,
                  size: 28,
                  color: reference.color,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  reference.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferencesLayout() {
    if (_references.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _references.length,
      itemBuilder: (context, index) {
        return _buildReferenceCard(_references[index]);
      },
    );
  }

  Widget _buildNoPermissionsWidget() {
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
              AppLocalizations.of(context)!.translate('no_permissions') ?? 'Нет доступа',
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.translate('no_permissions_description') ?? 
                  'У вас нет прав доступа к справочникам. Обратитесь к администратору.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w400,
                color: Color(0xff99A4BA),
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
                      color: const Color(0xffF8F9FB),
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.translate('reference_data') ?? 'Справочные данные',
                              style: const TextStyle(
                                fontSize: 18,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w600,
                                color: Color(0xff1E2E52),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              localizations.translate('select_reference_type') ??
                                  'Выберите тип справочника для работы с данными',
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w400,
                                color: Color(0xff99A4BA),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildReferencesLayout(),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

class ReferenceItem {
  final String title;
  final IconData icon;
  final Color color;

  ReferenceItem({
    required this.title,
    required this.icon,
    required this.color,
  });
}