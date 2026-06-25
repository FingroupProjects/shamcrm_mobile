import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/category/category_add_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String _lastSearchQuery = '';
  bool _canCreateCategory = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(FetchCategories());
    _searchController.addListener(() {
      _onSearch(_searchController.text);
    });
    _checkPermissions();
  }

Future<void> _checkPermissions() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final bool integrationWith1C = prefs.getBool('integration_with_1C') ?? false;
    final bool canCreate = await _apiService.hasPermission('category.create');

    setState(() {
      _canCreateCategory = canCreate && !integrationWith1C;
    });
  } catch (e) {
    setState(() {
      _canCreateCategory = false;
    });
  }
}

  void _onSearch(String query) {
    setState(() {
      _lastSearchQuery = query;
      _isSearching = query.isNotEmpty;
    });
    context.read<CategoryBloc>().add(SearchCategories(query));
  }

  void _resetSearch() {
    setState(() {
      _isSearching = false;
      _lastSearchQuery = '';
      _searchController.clear();
    });
    context.read<CategoryBloc>().add(FetchCategories());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colors = context.appColors;
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
          onChangedSearchInput: (input) {
            _onSearch(input);
          },
          textEditingController: _searchController,
          focusNode: _searchFocusNode,
          clearButtonClick: (isSearching) {
            _resetSearch();
          },
          currentFilters: {},
        ),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : BlocConsumer<CategoryBloc, CategoryState>(
              listener: (context, state) {
                if (state is CategorySuccess) {
                  showCustomSnackBar(
                    context: context,
                    message: AppLocalizations.of(context)!.translate(state.message),
                    isSuccess: true,
                  );
                } else if (state is CategoryError) {
                  showCustomSnackBar(
                    context: context,
                    message: AppLocalizations.of(context)!.translate(state.message),
                    isSuccess: false,
                  );
                }
              },
              builder: (context, state) {
                if (state is CategoryLoading) {
                  return const Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                } else if (state is CategoryError) {
                  context.read<CategoryBloc>().add(FetchCategories());
                  return const Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                } else if (state is CategoryEmpty || (state is CategoryLoaded && state.categories.isEmpty)) {
                  return Center(
                    child: Text(
                      _isSearching
                          ? localizations!.translate('nothing_found')
                          : localizations!.translate('category_not_found'),
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  );
                } else if (state is CategoryLoaded) {
                  final categories = state.categories;
                  return ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CategoryCard(
                          categoryId: category.id ?? 0,
                          categoryName: category.name,
                          subcategories: category.subcategories,
                          attributes: [],
                          image: category.image,
                        ),
                      );
                    },
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
      floatingActionButton: _canCreateCategory
          ? FloatingActionButton(
              onPressed: () {
                CategoryAddBottomSheet.show(context);
              },
              backgroundColor: context.appColors.buttonPrimaryBg,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
