import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
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
    _initializeDocuments();
  }

  void _initializeDocuments() {
    // Единый скромный цвет для всех документов
    final Color docColor = const Color(0xff1E2E52);

    _documents = [
      WarehouseDocument(
        title: 'Приход',
        // subtitle: 'Поступление товаров',
        icon: Icons.add_box_outlined,
        color: docColor,
      ),
      WarehouseDocument(
        title: 'Перемещение',
        // subtitle: 'Между складами',
        icon: Icons.swap_horiz,
        color: docColor,
      ),
      WarehouseDocument(
        title: 'Списание',
        // subtitle: 'Убыль товаров',
        icon: Icons.remove_circle_outline,
        color: docColor,
      ),
      WarehouseDocument(
        title: 'Реализация клиент',
        // subtitle: 'Продажа товаров',
        icon: Icons.shopping_cart_outlined,
        color: docColor,
      ),
      WarehouseDocument(
        title: 'Инвентаризация',
        // subtitle: 'Сверка остатков',
        icon: Icons.inventory_2_outlined,
        color: docColor,
      ),
      WarehouseDocument(
        title: 'Возврат от клиента',
        // subtitle: 'Возврат товаров',
        icon: Icons.keyboard_return,
        color: docColor,
      ),
      WarehouseDocument(
        title: 'Возврат поставщику',
        // subtitle: 'Возврат поставщику',
        icon: Icons.undo,
        color: docColor,
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  void _navigateToDocument(WarehouseDocument document) {
    // TODO: Реализовать переход на страницу документа
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Переход к документу: ${document.title}'),
        backgroundColor: document.color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDocumentCard(WarehouseDocument document) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDocument(document),
        child: Container(
          height: 100, // Увеличиваем высоту для вертикального расположения
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: const Color(0xffE5E9F2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Иконка сверху
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: document.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    document.icon,
                    size: 24,
                    color: document.color,
                  ),
                ),
                const SizedBox(height: 8),
                // Название документа снизу
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
                // Стрелка убирается, так как она менее уместна в вертикальном дизайне
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideDocumentCard(WarehouseDocument document) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDocument(document),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: const Color(0xffE5E9F2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Иконка немного больше для широкой карточки
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: document.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    document.icon,
                    size: 20,
                    color: document.color,
                  ),
                ),

                const SizedBox(width: 16),

                // Текст
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        document.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      // const SizedBox(height: 2),
                      // Text(
                      //   document.subtitle,
                      //   style: const TextStyle(
                      //     fontSize: 13,
                      //     fontFamily: 'Gilroy',
                      //     fontWeight: FontWeight.w400,
                      //     color: Color(0xff99A4BA),
                      //   ),
                      // ),
                    ],
                  ),
                ),

                // Стрелка
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: const Color(0xff99A4BA),
                ),
              ],
            ),
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
              ? localizations.translate('appbar_settings')
              : 'Учет склада',
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок секции
                        Text(
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
                          'Выберите тип документа для работы со складом',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w400,
                            color: Color(0xff99A4BA),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Компактная сетка документов - занимает только пол страницы
                        // Компактная сетка документов
                        SizedBox(
                          height: MediaQuery.of(context).size.height *
                              0.70, // Увеличиваем высоту
                          child: Column(
                            children: [
                              // Первый документ - широкий
                              _buildWideDocumentCard(_documents[0]),

                              const SizedBox(height: 12),

                              // Остальные 6 документов в сетке 2x3
                              Expanded(
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio:
                                        1.2, // Изменяем для вертикального дизайна
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: 6, // Остальные 6 документов
                                  itemBuilder: (context, index) {
                                    return _buildDocumentCard(
                                        _documents[index + 1]);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// Класс для хранения информации о документе склада
class WarehouseDocument {
  final String title;
  // final String subtitle;
  final IconData icon;
  final Color color;

  WarehouseDocument({
    required this.title,
    // required this.subtitle,
    required this.icon,
    required this.color,
  });
}
