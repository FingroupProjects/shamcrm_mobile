import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/money/money_income/money_income_screen.dart';
import 'package:crm_task_manager/page_2/money/money_outcome/money_outcome_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/client_return/client_return_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/client_sales_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/incoming_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/movement/movement_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/references_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier_return_document/supplier_return_document_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/write_off/write_off_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';

class WarehouseAccountingScreen extends StatefulWidget {
  @override
  _WarehouseAccountingScreenState createState() =>
      _WarehouseAccountingScreenState();
}

class _WarehouseAccountingScreenState extends State<WarehouseAccountingScreen> {
  final ApiService _apiService = ApiService();
  bool isClickAvatarIcon = false;
  bool _isLoading = true;

  List<WarehouseDocument> _documents = [];

  // Флаги прав доступа для каждого документа
  bool _hasIncomeDocument = false;
  bool _hasMovementDocument = false;
  bool _hasWriteOffDocument = false;
  bool _hasExpenseDocument = false;
  bool _hasClientReturnDocument = false;
  bool _hasSupplierReturnDocument = false;
  bool _hasMoneyIncome = false;
  bool _hasMoneyOutcome = false;
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
    setState(() {
      _isLoading = true;
    });

    try {
      // Проверяем права для каждого документа отдельно
      _hasIncomeDocument = await _apiService.hasPermission('income_document.read');
      _hasMovementDocument = await _apiService.hasPermission('movement_document.read');
      _hasWriteOffDocument = await _apiService.hasPermission('write_off_document.read');
      _hasExpenseDocument = await _apiService.hasPermission('expense_document.read');
      _hasClientReturnDocument = await _apiService.hasPermission('client_return_document.read');
      _hasSupplierReturnDocument = await _apiService.hasPermission('supplier_return_document.read');
      _hasMoneyIncome = await _apiService.hasPermission('checking_account_pko.read');
      _hasMoneyOutcome = await _apiService.hasPermission('checking_account_rko.read');

      // Проверяем права для справочников
      final hasStorage = await _apiService.hasPermission('storage.read');
      final hasUnit = await _apiService.hasPermission('unit.read');
      final hasSupplier = await _apiService.hasPermission('supplier.read');
      final hasCashRegister = await _apiService.hasPermission('cash_register.read');
      final hasRkoArticle = await _apiService.hasPermission('rko_article.read');
      final hasPkoArticle = await _apiService.hasPermission('pko_article.read');

      // Справочники показываются если есть хотя бы одно право из документов или справочников
      _showReferences = _hasIncomeDocument ||
          _hasMovementDocument ||
          _hasWriteOffDocument ||
          _hasExpenseDocument ||
          _hasClientReturnDocument ||
          _hasSupplierReturnDocument ||
          _hasMoneyIncome ||
          _hasMoneyOutcome ||
          hasStorage ||
          hasUnit ||
          hasSupplier ||
          hasCashRegister ||
          hasRkoArticle ||
          hasPkoArticle;

    } catch (e) {
      debugPrint('Ошибка при проверке прав доступа: $e');
      _hasIncomeDocument = false;
      _hasMovementDocument = false;
      _hasWriteOffDocument = false;
      _hasExpenseDocument = false;
      _hasClientReturnDocument = false;
      _hasSupplierReturnDocument = false;
      _hasMoneyIncome = false;
      _hasMoneyOutcome = false;
      _showReferences = false;
    } finally {
      setState(() {
        _isLoading = false;
      });
      _initializeDocuments();
    }
  }

  void _initializeDocuments() {
    final Color docColor = const Color(0xff1E2E52);
    List<WarehouseDocument> allDocuments = [];
    if (_hasExpenseDocument) {
      allDocuments.add(
        WarehouseDocument(
          title: AppLocalizations.of(context)!.translate('client_sale') ?? 'Продажа',
          icon: Icons.shopping_cart_outlined,
          color: docColor,
        ),
      );
    }


    if (_hasClientReturnDocument) {
      allDocuments.add(
        WarehouseDocument(
          title: AppLocalizations.of(context)!.translate('client_return') ?? 'Возврат от клиента',
          icon: Icons.keyboard_return,
          color: docColor,
        ),
      );
    }

    // Добавляем документы только если есть соответствующее право
    if (_hasIncomeDocument) {
      allDocuments.add(
        WarehouseDocument(
          title: AppLocalizations.of(context)!.translate('income_goods') ?? 'Приход',
          icon: Icons.add_box_outlined,
          color: docColor,
        ),
      );
    }

    if (_hasMovementDocument) {
      allDocuments.add(
        WarehouseDocument(
          title: AppLocalizations.of(context)!.translate('transfer') ?? 'Перемещение',
          icon: Icons.swap_horiz,
          color: docColor,
        ),
      );
    }

    if (_hasWriteOffDocument) {
      allDocuments.add(
        WarehouseDocument(
          title: AppLocalizations.of(context)!.translate('write_off') ?? 'Списание',
          icon: Icons.remove_circle_outline,
          color: docColor,
        ),
      );
    }




    if (_hasSupplierReturnDocument) {
      allDocuments.add(
        WarehouseDocument(
          title: AppLocalizations.of(context)!.translate('supplier_return') ?? 'Возврат поставщику',
          icon: Icons.undo,
          color: docColor,
        ),
      );
    }

    if (_hasMoneyIncome) {
      allDocuments.add(
        WarehouseDocument(
          title: AppLocalizations.of(context)!.translate('money_income') ?? 'Приход денег',
          icon: Icons.add_circle_outline,
          color: docColor,
        ),
      );
    }

    if (_hasMoneyOutcome) {
      allDocuments.add(
        WarehouseDocument(
          title: AppLocalizations.of(context)!.translate('money_outcome') ?? 'Расход денег',
          icon: Icons.remove_circle_outline,
          color: docColor,
        ),
      );
    }

    setState(() {
      _documents = allDocuments;
    });
  }

  void _navigateToDocument(WarehouseDocument document) {
    if (document.title == AppLocalizations.of(context)!.translate('income_goods') ||
        document.title == 'Приход') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => IncomingScreen()),
      );
    } else if (document.title == AppLocalizations.of(context)!.translate('client_sale') ||
        document.title == 'Реализация клиент') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ClientSaleScreen()),
      );
    } else if (document.title == AppLocalizations.of(context)!.translate('supplier_return') ||
        document.title == 'Возврат поставщику') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SupplierReturnScreen()),
      );
    } else if (document.title == AppLocalizations.of(context)!.translate('client_return') ||
        document.title == 'Возврат от клиента') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ClientReturnScreen()),
      );
    } else if (document.title == AppLocalizations.of(context)!.translate('write_off') ||
        document.title == 'Списание') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WriteOffScreen()),
      );
    } else if (document.title == AppLocalizations.of(context)!.translate('transfer') ||
        document.title == 'Перемещение') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MovementScreen(organizationId: 1)),
      );
    } else if (document.title == AppLocalizations.of(context)!.translate('money_income') ||
        document.title == 'Приход денег') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MoneyIncomeScreen()),
      );
    } else if (document.title == AppLocalizations.of(context)!.translate('money_outcome') ||
        document.title == 'Расход денег') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MoneyOutcomeScreen()),
      );
    }
  }

  void _navigateToReferences() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReferencesScreen()),
    );
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

        return GridView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _documents.length,
          itemBuilder: (context, index) {
            return _buildDocumentCard(_documents[index]);
          },
        );
      },
    );
  }

  Widget _buildDocumentCard(WarehouseDocument document) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDocument(document),
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
      ),
    );
  }

  Widget _buildReferencesButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _navigateToReferences,
        child: Container(
          width: double.infinity,
          height: 72,
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
          child: Row(
            children: [
              const SizedBox(width: 20),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xff1E2E52).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.library_books_outlined,
                  size: 28,
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                AppLocalizations.of(context)!.translate('references') ?? 'Справочники',
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E2E52),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xff99A4BA),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
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
                  'У вас нет прав доступа к данному разделу. Обратитесь к администратору.',
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
              : localizations.translate('warehouse_accounting') ?? 'Учет склада',
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
          : _documents.isEmpty && !_showReferences
          ? _buildNoPermissionsWidget()
          : Container(
        color: const Color(0xffF8F9FB),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.translate('warehouse_documents') ?? 'Документы склада',
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.translate('select_document_type') ??
                    'Выберите тип документа для работы со складом',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w400,
                  color: Color(0xff99A4BA),
                ),
              ),
              const SizedBox(height: 20),
              if (_documents.isNotEmpty) _buildDocumentGrid(),
              if (_showReferences) ...[
                const SizedBox(height: 16),
                _buildReferencesButton(),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class WarehouseDocument {
  final String title;
  final IconData icon;
  final Color color;

  WarehouseDocument({
    required this.title,
    required this.icon,
    required this.color,
  });
}