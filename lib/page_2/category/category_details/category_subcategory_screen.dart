import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_by_id/catgeoryById_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_by_id/catgeoryById_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_by_id/catgeoryById_state.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/page_2/subCategoryById.dart';
import 'package:crm_task_manager/page_2/category/category_details/subCategory/subCategory_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategorySubCategoryScreen extends StatefulWidget {
  final int categoryId;

  const CategorySubCategoryScreen({Key? key, required this.categoryId}) : super(key: key);

  @override
  _CategorySubCategoryState createState() => _CategorySubCategoryState();
}

class _CategorySubCategoryState extends State<CategorySubCategoryScreen> {
  final ApiService _apiService = ApiService();
  String? baseUrl;

  Future<void> _initializeBaseUrl() async {
    try {
      final enteredDomainMap = await _apiService.getEnteredDomain();
      setState(() {
        baseUrl = 'https://${enteredDomainMap['enteredMainDomain']}/storage/';
      });
    } catch (error) {
      setState(() {
        baseUrl = 'https://shamcrm.com/storage/';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<CategoryByIdBloc>().add(FetchCategoryByIdEvent(categoryId: widget.categoryId));
    _initializeBaseUrl();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryByIdBloc, CategoryByIdState>(
      builder: (context, state) {
        if (state is CategoryByIdLoading) {
          return Center(child: CircularProgressIndicator(color: const Color(0xff1E2E52)));
        } else if (state is CategoryByIdError) {
          return Center(child: Text(state.message));
        } else if (state is CategoryByIdLoaded) {
          return _buildSubCategoryList(state.category.categories);
        } else {
          return Center(child: Text('Нет данных'));
        }
      },
    );
  }

  Widget _buildSubCategoryList(List<CategoryDataById> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow(AppLocalizations.of(context)!.translate('Подкатегории')),
        SizedBox(height: 8),
        if (categories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: TaskCardStyles.taskCardDecoration,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.translate('empty'),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: MediaQuery.of(context).size.height * 0.75,
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return _buildSubCategoryItem(categories[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSubCategoryItem(CategoryDataById category) {
  return GestureDetector(
    onTap: () => _navigateToSubCategoryDetails(category),
    child: Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color(0xffF4F7FD),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black12,
        //     blurRadius: 6,
        //     offset: Offset(0, 2),
        //   ),
        // ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: category.image != null 
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      '$baseUrl/${category.image}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildNoPhotoPlaceholder(),
                    ),
                  )
                : _buildNoPhotoPlaceholder(),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                if (category.attributes.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Характеристики:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff99A4BA),
                        ),
                      ),
                      SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          ...category.attributes.take(4).map((attr) => 
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                attr.name.length > 10 ? '${attr.name.substring(0, 7)}...' : attr.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xff1E2E52),
                                ),
                              ),
                            ),
                          ),
                          if (category.attributes.length > 3)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+${category.attributes.length - 3}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xff1E2E52),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
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

Widget _buildNoPhotoPlaceholder() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.photo_camera, size: 30, color: Color(0xff99A4BA)),
      SizedBox(height: 4),
      Text( 'Нет фото',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xff99A4BA),
          fontFamily: 'Gilroy',
        ),
      ),
    ],
  );
}

  void _navigateToSubCategoryDetails(CategoryDataById category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubCategoryDetailsScreen(
          category: category,
        ),
      ),
    );
  }

  Row _buildTitleRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TaskCardStyles.titleStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (context) => SubCategoryAddScreen()),
            // );
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: Color(0xff1E2E52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.translate('add'),
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}


