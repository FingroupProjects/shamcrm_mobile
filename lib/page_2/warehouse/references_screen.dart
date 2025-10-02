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

// ReferencesScreen - страница справочников
class ReferencesScreen extends StatefulWidget {
  @override
  _ReferencesScreenState createState() => _ReferencesScreenState();
}

class _ReferencesScreenState extends State<ReferencesScreen> {
  final ApiService _apiService = ApiService();
  bool isClickAvatarIcon = false;
  bool _isLoading = true;

  // Список справочников (теперь все 8, включая Склад)
  List<ReferenceItem> _references = [];
  // NEW: Убрали _warehouseReference — теперь в _references

  @override
  void initState() {
    super.initState();
    // _initializeReferences перенесён в didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeReferences();
  }

  void _initializeReferences() {
    // Единый цвет для всех справочников
    final Color refColor = const Color(0xff1E2E52);

    // NEW: Все справочники в одном списке (8 элементов)
    _references = [
      // Склад (теперь обычная карточка)
      ReferenceItem(
        title: AppLocalizations.of(context)!.translate('warehouse') ?? 'Склад',
        icon: Icons.warehouse_outlined,
        color: refColor,
      ),
      ReferenceItem(
        title: AppLocalizations.of(context)!.translate('units_of_measurement') ??
            'Единицы измерения',
        icon: Icons.straighten_outlined,
        color: refColor,
      ),
      ReferenceItem(
        title: AppLocalizations.of(context)!.translate('supplier') ?? 'Поставщик',
        icon: Icons.business_outlined,
        color: refColor,
      ),
      ReferenceItem(
        title: AppLocalizations.of(context)!.translate('product') ?? 'Товар',
        icon: Icons.inventory_2_outlined,
        color: refColor,
      ),
      ReferenceItem(
        title: AppLocalizations.of(context)!.translate('price_type') ?? 'Тип цены',
        icon: Icons.price_change_outlined,
        color: refColor,
      ),
      // NEW: Три новых справочника
      ReferenceItem(
        title: AppLocalizations.of(context)!.translate('cash_desk') ?? 'Касса',
        icon: Icons.account_balance_wallet,
        color: refColor,
      ),
      ReferenceItem(
        title: AppLocalizations.of(context)!.translate('expense_articles') ?? 'Статьи расходов',
        icon: Icons.trending_down,
        color: refColor,
      ),
      ReferenceItem(
        title: AppLocalizations.of(context)!.translate('income_articles') ?? 'Статьи доходов',
        icon: Icons.trending_up,
        color: refColor,
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  void _navigateToReference(ReferenceItem reference) {
    if (reference.title ==
        (AppLocalizations.of(context)!.translate('supplier') ?? 'Поставщик')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SupplierCreen()),
      );
    }
    if (reference.title ==
        (AppLocalizations.of(context)!.translate('warehouse') ?? 'Склад')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WareHouseScreen()),
      );
    }

    if (reference.title ==
        (AppLocalizations.of(context)!.translate('units_of_measurement') ??
            'Единицы измерения')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MeasureUnitsScreen()),
      );
    }

    if (reference.title ==
        (AppLocalizations.of(context)!.translate('product') ?? 'Товар')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GoodsScreen()),
      );
    }

    if (reference.title ==
        (AppLocalizations.of(context)!.translate('price_type') ?? 'Тип цены')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PriceTypeScreen()),
      );
    }
    // NEW: Добавлена навигация для новых справочников
    if (reference.title ==
        (AppLocalizations.of(context)!.translate('cash_desk') ?? 'Касса')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CashDeskScreen()),
      );
    }
    if (reference.title ==
        (AppLocalizations.of(context)!.translate('expense_articles') ?? 'Статьи расходов')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ExpenseScreen()),
      );
    }
    if (reference.title ==
        (AppLocalizations.of(context)!.translate('income_articles') ?? 'Статьи доходов')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => IncomeScreen()),
      );
    }
  }

  // NEW: Упрощённый метод — все карточки одинаковые (убрали isWide)
  Widget _buildReferenceCard(ReferenceItem reference) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToReference(reference),
        child: Container(
          // height: 120, // Убрали фиксированную высоту — Grid подстроит
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
              // Иконка
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
              // Название справочника
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  reference.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,  // Немного уменьшили для лучшего fit
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

  // NEW: Упрощённый layout — только одна сетка 2x4 для 8 карточек
  Widget _buildReferencesLayout() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,  // Чуть выше для текста
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _references.length,  // Теперь 8
      itemBuilder: (context, index) {
        return _buildReferenceCard(_references[index]);
      },
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
              : Container(
                  color: const Color(0xffF8F9FB),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок секции
                      Text(
                        localizations.translate('reference_data') ??
                            'Справочные данные',
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
                      // Новый layout с 8 карточками
                      _buildReferencesLayout(),
                    ],
                  ),
                ),
    );
  }
}

// Класс для хранения информации о справочнике
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