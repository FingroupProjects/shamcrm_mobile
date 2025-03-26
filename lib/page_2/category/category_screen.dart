import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/category/category_add_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
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

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(FetchCategories());
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBarPage2(
          title: isClickAvatarIcon
              ? localizations!.translate('appbar_settings')
              : localizations!.translate('appbar_categories'),
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
          : BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoading) {
                  return Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
                } else if (state is CategoryError) {
                  return Center(child: Text(state.message));
                } else if (state is CategoryLoaded) {
                    return ListView.builder(
                      padding: EdgeInsets.only(left: 16, right: 16, top: 8),
                      itemCount: state.categories.length,
                      itemBuilder: (context, index) {
                        final category = state.categories[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CategoryCard(
                            categoryId: category.id ?? 0,
                            categoryName: category.name,
                            subCategoryName: category.subcategories.isNotEmpty
                                ? category.subcategories[0].name
                                : '',
                            attributes: [],
                            image: category.image ?? 'assets/images/user1.jpg',
                          ),
                        );
                      },
                    );
                  }
                return Center(child: Text('No categories found'));
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