import 'package:crm_task_manager/app/app_feature_flags.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/page_2/dashboard/detailed_report/detailed_report_screen.dart';
import 'package:crm_task_manager/page_2/money/money_income/money_income_screen.dart';
import 'package:crm_task_manager/page_2/money/money_outcome/money_outcome_screen.dart';
import 'package:crm_task_manager/page_2/order/order_screen.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/client_return/client_return_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/client_sales_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/fast_incoming_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/incoming_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/manufacture/manufacture_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/movement/movement_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/references_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier_return_document/supplier_return_document_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/write_off/write_off_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/pricing/pricing_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WarehouseAccountingScreen extends StatefulWidget {
  const WarehouseAccountingScreen({super.key});

  @override
  State<WarehouseAccountingScreen> createState() =>
      _WarehouseAccountingScreenState();
}

class _WarehouseAccountingScreenState extends State<WarehouseAccountingScreen> {
  static const String _documentOrderPrefsKey = 'warehouse_document_order';
  final ApiService _apiService = ApiService();
  bool isClickAvatarIcon = false;
  bool _isLoading = true;

  List<WarehouseDocument> _documents = [];

  // Флаги прав доступа для каждого документа
  bool _hasIncomeDocument = false;
  bool _hasMovementDocument = false;
  bool _hasManufactureDocument = false;
  bool _hasManufactureEnabled = false;
  bool _hasWriteOffDocument = false;
  bool _hasExpenseDocument = false;
  bool _hasClientReturnDocument = false;
  bool _hasSupplierReturnDocument = false;
  bool _hasMoneyIncome = false;
  bool _hasMoneyOutcome = false;
  bool _hasOrder = false; // Новое право для заказов
  bool _hasPricing = false;
  bool _showReferences = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoading) {
      _initializeDocuments();
    }
  }

  Future<void> _checkPermissions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await _apiService.getSettings(null);
      final settingsResult = settings['result'];
      _hasManufactureEnabled = settingsResult is Map<String, dynamic> &&
          (settingsResult['has_manufacture'] == true ||
              settingsResult['has_manufacture'] == 1);

      // Проверяем права для каждого документа отдельно
      _hasIncomeDocument =
          await _apiService.hasPermission('income_document.read');
      _hasMovementDocument =
          await _apiService.hasPermission('movement_document.read');
      _hasManufactureDocument =
          await _apiService.hasPermission('manufacture.read') ||
              await _apiService.hasPermission('manufacture_document.read');
      _hasManufactureDocument =
          _hasManufactureDocument && _hasManufactureEnabled;
      _hasWriteOffDocument =
          await _apiService.hasPermission('write_off_document.read');
      _hasExpenseDocument =
          await _apiService.hasPermission('expense_document.read');
      _hasClientReturnDocument =
          await _apiService.hasPermission('client_return_document.read');
      _hasSupplierReturnDocument =
          await _apiService.hasPermission('supplier_return_document.read');
      _hasMoneyIncome =
          await _apiService.hasPermission('checking_account_pko.read');
      _hasMoneyOutcome =
          await _apiService.hasPermission('checking_account_rko.read');
      _hasOrder = await _apiService.hasPermission('order.read');
      _hasPricing = await _apiService.hasPermission('pricing.read') ||
          await _apiService.hasPermission('price_type.read');

      // Проверяем права для справочников
      final hasStorage = await _apiService.hasPermission('storage.read');
      final hasUnit = await _apiService.hasPermission('unit.read');
      final hasSupplier = await _apiService.hasPermission('supplier.read');
      final hasProduct = await _apiService.hasPermission('product.read');
      final hasPriceType = await _apiService.hasPermission('price_type.read');
      final hasCategory = await _apiService.hasPermission('category.read');
      final hasLead = await _apiService.hasPermission('lead.read');
      final hasOpenings =
          await _apiService.hasPermission('initial_balance.read');
      final hasCashRegister =
          await _apiService.hasPermission('cash_register.read');
      final hasRkoArticle = await _apiService.hasPermission('rko_article.read');
      final hasPkoArticle = await _apiService.hasPermission('pko_article.read');

      // Справочники показываются если есть хотя бы одно право из документов или справочников
      _showReferences = _hasIncomeDocument ||
          _hasMovementDocument ||
          _hasManufactureDocument ||
          _hasWriteOffDocument ||
          _hasExpenseDocument ||
          _hasClientReturnDocument ||
          _hasSupplierReturnDocument ||
          _hasMoneyIncome ||
          _hasMoneyOutcome ||
          _hasOrder ||
          hasStorage ||
          hasUnit ||
          hasSupplier ||
          hasProduct ||
          hasPriceType ||
          hasCategory ||
          hasLead ||
          hasOpenings ||
          hasCashRegister ||
          hasRkoArticle ||
          hasPkoArticle;
    } catch (e) {
      debugPrint('Ошибка при проверке прав доступа: $e');
      _hasIncomeDocument = false;
      _hasMovementDocument = false;
      _hasManufactureDocument = false;
      _hasManufactureEnabled = false;
      _hasWriteOffDocument = false;
      _hasExpenseDocument = false;
      _hasClientReturnDocument = false;
      _hasSupplierReturnDocument = false;
      _hasMoneyIncome = false;
      _hasMoneyOutcome = false;
      _hasOrder = false;
      _hasPricing = false;
      _showReferences = false;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    _initializeDocuments();
  }

  void _initializeDocuments() {
    final colors = context.appColors;
    final Color docColor = colors.buttonPrimaryBg;
    List<WarehouseDocument> allDocuments = [];

    // Добавляем заказы первыми

    if (_hasExpenseDocument) {
      if (kShowRmk) {
        allDocuments.add(
          WarehouseDocument(
            keyName: 'rmk',
            title: 'РМК',
            icon: Icons.point_of_sale,
            color: docColor,
          ),
        );
      }
      if (kShowRmkSales) {
        // allDocuments.add(
        //   WarehouseDocument(
        //     keyName: 'rmk_sales',
        //     title: 'Продажа РМК',
        //     icon: Icons.receipt_long_outlined,
        //     color: docColor,
        //   ),
        // );
      }
      allDocuments.add(
        WarehouseDocument(
          keyName: 'client_sale',
          title: AppLocalizations.of(context)!.translate('client_sale') ??
              'Продажа',
          icon: Icons.shopping_cart_outlined,
          color: docColor,
        ),
      );
    }

    if (_hasClientReturnDocument) {
      allDocuments.add(
        WarehouseDocument(
          keyName: 'client_return',
          title: AppLocalizations.of(context)!.translate('client_return') ??
              'Возврат от клиента',
          icon: Icons.keyboard_return,
          color: docColor,
        ),
      );
    }

    // Добавляем документы только если есть соответствующее право
    if (_hasIncomeDocument) {
      allDocuments.add(
        WarehouseDocument(
          keyName: 'purchase_goods',
          title: 'Покупка товаров',
          icon: Icons.flash_on_outlined,
          color: docColor,
        ),
      );
      allDocuments.add(
        WarehouseDocument(
          keyName: 'income_goods',
          title: AppLocalizations.of(context)!.translate('income_goods') ??
              'Приход',
          icon: Icons.add_box_outlined,
          color: docColor,
        ),
      );
    }

    if (_hasMovementDocument) {
      allDocuments.add(
        WarehouseDocument(
          keyName: 'transfer',
          title: AppLocalizations.of(context)!.translate('transfer') ??
              'Перемещение',
          icon: Icons.swap_horiz,
          color: docColor,
        ),
      );
    }

    if (_hasWriteOffDocument) {
      allDocuments.add(
        WarehouseDocument(
          keyName: 'write_off',
          title: AppLocalizations.of(context)!.translate('write_off') ??
              'Списание',
          icon: Icons.remove_circle_outline,
          color: docColor,
        ),
      );
    }

    if (_hasSupplierReturnDocument) {
      allDocuments.add(
        WarehouseDocument(
          keyName: 'supplier_return',
          title: AppLocalizations.of(context)!.translate('supplier_return') ??
              'Возврат поставщику',
          icon: Icons.undo,
          color: docColor,
        ),
      );
    }

    if (_hasMoneyIncome) {
      allDocuments.add(
        WarehouseDocument(
          keyName: 'money_income',
          title: AppLocalizations.of(context)!.translate('money_income') ??
              'Приход денег',
          icon: Icons.add_circle_outline,
          color: docColor,
        ),
      );
    }

    if (_hasMoneyOutcome) {
      allDocuments.add(
        WarehouseDocument(
          keyName: 'money_outcome',
          title: AppLocalizations.of(context)!.translate('money_outcome') ??
              'Расход денег',
          icon: Icons.remove_circle_outline,
          color: docColor,
        ),
      );
    }

    if (_hasOrder) {
      allDocuments.add(
        WarehouseDocument(
          keyName: 'order',
          title: AppLocalizations.of(context)!.translate('appbar_orders') ??
              'Заказы',
          icon: Icons.receipt_long_outlined,
          color: docColor,
        ),
      );
    }

    if (_hasManufactureDocument) {
      allDocuments.add(
        WarehouseDocument(
          keyName: 'manufacture',
          title: AppLocalizations.of(context)!.translate('manufacture') ??
              'Производство',
          icon: Icons.precision_manufacturing_outlined,
          color: docColor,
        ),
      );
    }
    if (_hasPricing) {
      allDocuments.add(WarehouseDocument(
        keyName: 'pricing',
        title: 'Цены',
        icon: Icons.price_change_outlined,
        color: docColor,
      ));
    }
    //
    // if (_showReferences) {
    //   allDocuments.add(
    //     WarehouseDocument(
    //       title: AppLocalizations.of(context)!.translate('references') ?? 'Справочники',
    //       icon: Icons.library_books_outlined,
    //       color: docColor,
    //     ),
    //   );
    // }

    if (!mounted) return;
    setState(() {
      _documents = allDocuments;
    });
    _applySavedDocumentOrder(allDocuments);
  }

  Future<void> _applySavedDocumentOrder(
      List<WarehouseDocument> documents) async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrder = prefs.getStringList(_documentOrderPrefsKey) ?? const [];
    final byKey = {
      for (final document in documents) document.keyName: document
    };
    final ordered = <WarehouseDocument>[
      for (final key in savedOrder)
        if (byKey.containsKey(key)) byKey.remove(key)!,
      ...documents.where((document) => byKey.containsKey(document.keyName)),
    ];

    if (!mounted) return;
    setState(() {
      _documents = ordered;
    });
  }

  Future<void> _saveDocumentOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _documentOrderPrefsKey,
      _documents.map((document) => document.keyName).toList(),
    );
  }

  Future<void> _navigateToDocument(WarehouseDocument document) async {
    final organizationId = await _apiService.resolveSelectedOrganizationId();
    if (!mounted) return;

    if (document.keyName == 'purchase_goods') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FastIncomingScreen()),
      );
    } else if (document.keyName == 'income_goods') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                IncomingScreen(organizationId: organizationId)),
      );
    } else if (document.keyName == 'client_sale') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ClientSaleScreen(organizationId: organizationId)),
      );
    } else if (document.keyName == 'rmk') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RmkScreen()),
      );
      // } else if (document.keyName == 'rmk_sales') {
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(builder: (context) => const RmkSalesScreen()),
      //   );
    } else if (document.keyName == 'supplier_return') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SupplierReturnScreen(organizationId: organizationId)),
      );
    } else if (document.keyName == 'client_return') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ClientReturnScreen(organizationId: organizationId)),
      );
    } else if (document.keyName == 'write_off') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WriteOffScreen(organizationId: organizationId)),
      );
    } else if (document.keyName == 'transfer') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                MovementScreen(organizationId: organizationId)),
      );
    } else if (document.keyName == 'manufacture') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ManufactureScreen(organizationId: organizationId)),
      );
    } else if (document.keyName == 'money_income') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                MoneyIncomeScreen(organizationId: organizationId)),
      );
    } else if (document.keyName == 'money_outcome') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                MoneyOutcomeScreen(organizationId: organizationId)),
      );
    } else if (document.keyName == 'order') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => OrderScreen(organizationId: organizationId)),
      );
    } else if (document.keyName == 'pricing') {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const PricingScreen()));
    } else if (document.keyName == 'references') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReferencesScreen()),
      );
    }
  }

  Widget _buildDocumentGrid() {
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

        const spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
                crossAxisCount;
        final itemHeight = itemWidth / childAspectRatio;

        return ReorderableWrap(
          spacing: spacing,
          runSpacing: spacing,
          needsLongPressDraggable: true,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              final item = _documents.removeAt(oldIndex);
              _documents.insert(newIndex, item);
            });
            _saveDocumentOrder();
          },
          children: [
            for (final document in _documents)
              SizedBox(
                key: ValueKey(document.keyName),
                width: itemWidth,
                height: itemHeight,
                child: _buildDocumentCard(document),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDocumentCard(WarehouseDocument document) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDocument(document),
        child: Container(
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: document.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    document.icon,
                    size: 24,
                    color: document.color,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    document.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      height: 1.1,
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
                  'У вас нет прав доступа к данному разделу. Обратитесь к администратору.',
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBarPage2(
          title: isClickAvatarIcon
              ? localizations.translate('appbar_settings') ?? 'Настройки'
              : localizations.translate('warehouse_accounting') ??
                  'Учет склада',
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
          : Stack(
              fit: StackFit.expand,
              children: [
                const AppBackgroundOverlay(
                  preset: AppBackgroundPreset.aurora,
                ),
                if (_isLoading)
                  const Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: Duration(milliseconds: 1000),
                    ),
                  )
                else if (_documents.isEmpty)
                  _buildNoPermissionsWidget()
                else
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_documents.isNotEmpty) _buildDocumentGrid(),
                        if (_showReferences) ...[
                          const SizedBox(height: 16),
                          _buildReferencesButton(),
                        ],
                        const SizedBox(height: 16),
                        _buildDetailedReportButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  void _navigateToDetailedReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DetailedReportScreen(currentTabIndex: 0),
      ),
    );
  }

  void _navigateToReferences() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReferencesScreen()),
    );
  }

  Widget _buildDetailedReportButton() {
    return _buildWideSectionButton(
      title: 'Отчет',
      icon: Icons.assessment_outlined,
      onTap: _navigateToDetailedReport,
    );
  }

  Widget _buildReferencesButton() {
    return _buildWideSectionButton(
      title: AppLocalizations.of(context)!.translate('references') ??
          'Справочники',
      icon: Icons.library_books_outlined,
      onTap: _navigateToReferences,
    );
  }

  Widget _buildWideSectionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
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
          child: Row(
            children: [
              const SizedBox(width: 20),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: colors.buttonPrimaryBg,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class WarehouseDocument {
  final String keyName;
  final String title;
  final IconData icon;
  final Color color;

  WarehouseDocument({
    required this.keyName,
    required this.title,
    required this.icon,
    required this.color,
  });
}
