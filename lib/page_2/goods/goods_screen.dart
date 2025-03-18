import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/goods/goods_add_screen.dart';
import 'package:crm_task_manager/page_2/goods/goods_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';

class GoodsScreen extends StatefulWidget {
  @override
  _GoodsScreenState createState() => _GoodsScreenState();
}

class _GoodsScreenState extends State<GoodsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool isClickAvatarIcon = false;

  final List<Map<String, dynamic>> testGoods = [
    {
      'id': 1,
      'name': 'Смартфон XYZ Pro',
      'description':
          'Высокопроизводительный смартфон с 6,5-дюймовым экраном, 128 ГБ памяти и камерой 12 МП.',
      'category': 'Электроника',
      'price': 799.99,
      'discount': 15,
      'stockQuantity': 500,
      'imagePaths': [
        'assets/images/goods_photo2.jpg',
        'assets/images/goods_photo1.jpg'
      ],
      'status': true,
    },
    {
      'id': 2,
      'name': 'Стиральная машина Модель A100',
      'description':
          'Энергоэффективная стиральная машина с емкостью 7 кг и несколькими режимами стирки.',
      'category': 'Бытовая техника',
      'price': 450.00,
      'discount': 10,
      'stockQuantity': 150,
      'imagePaths': ['assets/images/goods_photo1.jpg'],
      'status': false,
    },
    {
      'id': 3,
      'name': 'Органический хлеб из цельного зерна',
      'description':
          'Свежевыпеченный органический хлеб из цельного зерна, сделанный из высококачественных ингредиентов.',
      'category': 'Продукты питания',
      'price': 3.50,
      'discount': 5,
      'stockQuantity': 2000,
      'imagePaths': [
        'assets/images/goods_photo.jpg',
        'assets/images/goods_photo1.jpg',
        'assets/images/goods_photo2.jpg'
      ],
      'status': true,
    },
    {
      'id': 4,
      'name': 'Смартфон XYZ Pro',
      'description':
          'Высокопроизводительный смартфон с 6,5-дюймовым экраном, 128 ГБ памяти и камерой 12 МП.',
      'category': 'Электроника',
      'price': 799.99,
      'discount': 15,
      'stockQuantity': 500,
      'imagePaths': [
        'assets/images/goods_photo2.jpg',
        'assets/images/goods_photo1.jpg'
      ],
      'status': true,
    },
  ];

  // void _onSearchChanged(String value) {}

  // void _onClearSearch() {
  //   setState(() {
  //     _isSearching = false;
  //     _searchController.clear();
  //   });
  // }

  // void _onProfileAvatarClick() {}

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBarPage2(
          title: isClickAvatarIcon
              ? localizations!.translate('appbar_settings')
              : localizations!.translate('Товары'),
          onClickProfileAvatar: () {
            setState(() {
              isClickAvatarIcon = !isClickAvatarIcon;
            });
          },
          clearButtonClickFiltr: (isSearching) {},
          showSearchIcon: true,
          showFilterOrderIcon: false,
          showFilterIcon: true,
          onChangedSearchInput: (input) {},
          textEditingController: TextEditingController(),
          focusNode: FocusNode(),
          clearButtonClick: (isSearching) {},
        ),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : ListView.builder(
              padding: EdgeInsets.only(left: 16, right: 16, top: 0),
              itemCount: testGoods.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 0),
                  child: GoodsCard(
                    goodsId: testGoods[index]['id']!,
                    goodsName: testGoods[index]['name']!,
                    goodsDescription: testGoods[index]['description']!,
                    goodsCategory: testGoods[index]['category']!,
                    goodsPrice: testGoods[index]['price']!,
                    goodsDiscountPrice: testGoods[index]['discount']!,
                    goodsStockQuantity: testGoods[index]['stockQuantity']!,
                    goodsImagePath: testGoods[index]['imagePaths']!,
                    goodsIsActive: testGoods[index]['status']!,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GoodsAddScreen()),
          );
        },
        backgroundColor: const Color(0xff1E2E52),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
