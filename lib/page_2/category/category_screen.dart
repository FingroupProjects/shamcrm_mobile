import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/category/category_add_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'category_card.dart';

class CategoryScreen extends StatefulWidget {
  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool isClickAvatarIcon = false;

  final List<Map<String, dynamic>> testCategories = [
    {
      'id': 1,
      'name': 'Электроника',
      'subCategory': 'Смартфоны',
      'description': 'Смартфоны разных производителей',
    },
    {
      'id': 2,
      'name': 'Одежда',
      'subCategory': 'Футболки',
      'description': 'Стильные футболки для мужчин и женщин',
    },
    {
      'id': 3,
      'name': 'Бытовая техника',
      'subCategory': 'Холодильники',
      'description': 'Широкий выбор холодильников',
    },
    {
      'id': 4,
      'name': 'Книги',
      'subCategory': 'Фантастика',
      'description': 'Лучшие фантастические произведения',
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
              : localizations!.translate('Категории'),
          onClickProfileAvatar: () {
            setState(() {
              isClickAvatarIcon = !isClickAvatarIcon;
            });
          },
          clearButtonClickFiltr: (isSearching) {},
          showSearchIcon: true,
          showFilterIcon: false,
          showFilterOrderIcon: false,
          onChangedSearchInput: (input) {},
          textEditingController: TextEditingController(),
          focusNode: FocusNode(),
          clearButtonClick: (isSearching) {},
        ),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : ListView.builder(
              padding: EdgeInsets.only(left: 16, right: 16, top: 8),
              itemCount: testCategories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CategoryCard(
                    categoryId: testCategories[index]['id']!,
                    categoryName: testCategories[index]['name']!,
                    subCategoryName: testCategories[index]['subCategory']!,
                    categoryDescription: testCategories[index]['description']!,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          CategoryAddBottomSheet.show(context);
        },
        backgroundColor: const Color(0xff1E2E52),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
