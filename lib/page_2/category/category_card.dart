import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/page_2/category/category_details/category_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CategoryCard extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final List<SubCategoryResponse> subcategories;
  final List<Attribute> attributes;
  final String? image;

  CategoryCard({
    Key? key,
    required this.categoryId,
    required this.categoryName,
    required this.subcategories,
    required this.attributes,
    required this.image,
  }) : super(key: key);

  @override
  _CategoryCardState createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  String formatDate(String dateString) {
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Объединяем имена подкатегорий в одну строку, разделяя запятыми
    final subcategoriesText = widget.subcategories.isNotEmpty
        ? widget.subcategories.map((subcategory) => subcategory.name).join(', ')
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailsScreen(
              categoryId: widget.categoryId,
              categoryName: widget.categoryName,
              imageUrl: widget.image,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: TaskCardStyles.taskCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: widget.categoryName,
                style: TaskCardStyles.titleStyle,
                children: const <TextSpan>[
                  TextSpan(
                    text: '\n\u200B',
                    style: TaskCardStyles.titleStyle,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: AppLocalizations.of(context)!.translate('subcategory_card'),
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                    TextSpan(
                      text: subcategoriesText.isNotEmpty ? ' $subcategoriesText' : '',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}