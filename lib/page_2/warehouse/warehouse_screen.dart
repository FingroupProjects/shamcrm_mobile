import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/client_sales_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/incoming_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/references_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';

// WarehouseAccountingScreen - страница учета склада с документами
class WarehouseAccountingScreen extends StatefulWidget {
  @override
  _WarehouseAccountingScreenState createState() =>
      _WarehouseAccountingScreenState();
}

class _WarehouseAccountingScreenState extends State<WarehouseAccountingScreen> {
  final ApiService _apiService = ApiService();
  bool isClickAvatarIcon = false;
  bool _isLoading = true;

  // Список документов склада
  List<WarehouseDocument> _documents = [];

  @override
  void initState() {
    super.initState();
    // _initializeDocuments перенесён в didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeDocuments();
  }

  void _initializeDocuments() {
    // Единый цвет для всех документов
    final Color docColor = const Color(0xff1E2E52);

    _documents = [
      WarehouseDocument(
        title: AppLocalizations.of(context)!.translate('incoming_document') ??
            'Приход',
        icon: Icons.add_box_outlined,
        color: docColor,
      ),
      WarehouseDocument(
        title: AppLocalizations.of(context)!.translate('transfer') ??
            'Перемещение',
        icon: Icons.swap_horiz,
        color: docColor,
      ),
      WarehouseDocument(
        title:
            AppLocalizations.of(context)!.translate('write_off') ?? 'Списание',
        icon: Icons.remove_circle_outline,
        color: docColor,
      ),
      WarehouseDocument(
        title: AppLocalizations.of(context)!.translate('client_sale') ??
            'Реализация клиент',
        icon: Icons.shopping_cart_outlined,
        color: docColor,
      ),
      WarehouseDocument(
        title: AppLocalizations.of(context)!.translate('client_return') ??
            'Возврат от клиента',
        icon: Icons.keyboard_return,
        color: docColor,
      ),
      WarehouseDocument(
        title: AppLocalizations.of(context)!.translate('supplier_return') ??
            'Возврат поставщику',
        icon: Icons.undo,
        color: docColor,
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  void _navigateToDocument(WarehouseDocument document) {
    if (document.title ==
            AppLocalizations.of(context)!.translate('incoming_document') ||
        document.title == 'Приход') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => IncomingScreen()),
      );
    } else if (document.title ==
            AppLocalizations.of(context)!.translate('client_sale') ||
        document.title == 'Реализация клиент') {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => ClientSaleScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!
                    .translate('navigate_to_document')
                    ?.replaceAll('{document}', document.title) ??
                'Переход к документу: ${document.title}',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: document.color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToReferences() {
    // Переход к странице справочников
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReferencesScreen()),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Иконка
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: document.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  document.icon,
                  size: 28,
                  color: document.color,
                ),
              ),
              const SizedBox(height: 12),
              // Название документа
              Text(
                document.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E2E52),
                ),
              ),
            ],
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
              // Иконка
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
              // Название
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
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
                        localizations.translate('warehouse_documents') ??
                            'Документы склада',
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
                      // Сетка 2x3 для документов
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _documents.length,
                        itemBuilder: (context, index) {
                          return _buildDocumentCard(_documents[index]);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Длинная кнопка "Справочники"
                      _buildReferencesButton(),
                    ],
                  ),
                ),
    );
  }
}

// Класс для хранения информации о документе склада
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