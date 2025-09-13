import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/goods/goods_screen.dart';
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

  // Список справочников (убрали "Скидки")
  List<ReferenceItem> _references = [];
  ReferenceItem? _warehouseReference;

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

    // Выделяем "Склад" в отдельную переменную
    _warehouseReference = ReferenceItem(
      title: AppLocalizations.of(context)!.translate('warehouse') ?? 'Склад',
      icon: Icons.warehouse_outlined,
      color: refColor,
    );

    // Остальные справочники (убрали "Скидки")
    _references = [
      ReferenceItem(
        title:
            AppLocalizations.of(context)!.translate('units_of_measurement') ??
                'Единицы измерения',
        icon: Icons.straighten_outlined,
        color: refColor,
      ),
      ReferenceItem(
        title:
            AppLocalizations.of(context)!.translate('supplier') ?? 'Поставщик',
        icon: Icons.business_outlined,
        color: refColor,
      ),
      ReferenceItem(
        title: AppLocalizations.of(context)!.translate('product') ?? 'Товар',
        icon: Icons.inventory_2_outlined,
        color: refColor,
      ),
      ReferenceItem(
        title:
            AppLocalizations.of(context)!.translate('price_type') ?? 'Тип цены',
        icon: Icons.price_change_outlined,
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
  }

  Widget _buildReferenceCard(ReferenceItem reference, {bool isWide = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToReference(reference),
        child: Container(
          height: isWide ? 100 : 120, // Немного разная высота для широкой карточки
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
          child: isWide
              ? Row(
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
                    const SizedBox(width: 16),
                    // Название
                    Text(
                      reference.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ],
                )
              : Column(
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
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
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
    return Column(
      children: [
        // Широкая карточка "Склад" на всю ширину
        if (_warehouseReference != null)
          _buildReferenceCard(_warehouseReference!, isWide: true),
        
        const SizedBox(height: 12),
        
        // Остальные справочники в сетке 2x2
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _references.length,
          itemBuilder: (context, index) {
            return _buildReferenceCard(_references[index]);
          },
        ),
      ],
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
                      // Новый компактный layout
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