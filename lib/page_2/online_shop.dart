import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/category/category_screen.dart';
import 'package:crm_task_manager/page_2/goods/goods_screen.dart';
import 'package:crm_task_manager/page_2/order/order_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';

// OnlineStoreScreen - главная страница онлайн магазина

class OnlineStoreScreen extends StatefulWidget {
  @override
  _OnlineStoreScreenState createState() => _OnlineStoreScreenState();
}

class _OnlineStoreScreenState extends State<OnlineStoreScreen> {
  final ApiService _apiService = ApiService();
  bool isClickAvatarIcon = false;
  bool _isLoading = true;

  // Список доступных секций
  List<StoreSection> _availableSections = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    List<StoreSection> sections = [];
    
    try {
      // Категории
      if (await _apiService.hasPermission('category.read')) {
        sections.add(StoreSection(
          title: 'appbar_categories',
          icon: 'assets/icons/MyNavBar/category_ON.png',
          screen: CategoryScreen(),
          color: const Color(0xff4CAF50), // Зеленый
        ));
      }

      // Товары
      if (await _apiService.hasPermission('product.read')) {
        sections.add(StoreSection(
          title: 'appbar_goods',
          icon: 'assets/icons/MyNavBar/goods_ON.png',
          screen: GoodsScreen(),
          color: const Color(0xff2196F3), // Синий
        ));
      }

      // Заказы
      if (await _apiService.hasPermission('order.read')) {
        sections.add(StoreSection(
          title: 'appbar_orders',
          icon: 'assets/icons/MyNavBar/order_on_2.png',
          screen: OrderScreen(),
          color: const Color(0xffFF9800), // Оранжевый
        ));
      }

      if (mounted) {
        setState(() {
          _availableSections = sections;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('OnlineStoreScreen: Ошибка при проверке прав: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSection(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  Widget _buildSectionCard(StoreSection section) {
    final localizations = AppLocalizations.of(context)!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToSection(section.screen),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: const Color(0xffE5E9F2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Иконка с цветным фоном
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: section.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Image.asset(
                      section.icon,
                      width: 28,
                      height: 28,
                      color: section.color,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Текст и описание
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.translate(section.title),
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSectionDescription(section.title),
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

  String _getSectionDescription(String titleKey) {
    switch (titleKey) {
      case 'appbar_categories':
        return 'Управление категориями товаров';
      case 'appbar_goods':
        return 'Каталог товаров';
      case 'appbar_orders':
        return 'Управление заказами клиентов';
      default:
        return '';
    }
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
              : 'Онлайн магазин',
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
              : _availableSections.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.store_mall_directory_outlined,
                            size: 64,
                            color: const Color(0xff99A4BA),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Нет доступных разделов',
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff99A4BA),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Обратитесь к администратору для\nполучения необходимых прав доступа',
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
                    )
                  : Container(
                      color: const Color(0xffF8F9FB),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Заголовок секции
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Разделы магазина',
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w600,
                                color: Color(0xff1E2E52),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Список секций
                          ..._availableSections.map((section) => _buildSectionCard(section)),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
    );
  }
}

// Класс для хранения информации о секции магазина
class StoreSection {
  final String title;
  final String icon;
  final Widget screen;
  final Color color;

  StoreSection({
    required this.title,
    required this.icon,
    required this.screen,
    required this.color,
  });
}