import 'package:crm_task_manager/api/service/api_service.dart';
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
  final ApiService _apiService = ApiService();
  String? baseUrl;

Future<Widget> _buildImageWidget() async {
  if (widget.image == null) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_not_supported,
        size: 40,
        color: Color(0xff99A4BA),
      ),
    );
  }

  // Получаем полный URL изображения через getFileUrl
  final imageUrl = await _apiService.getFileUrl(widget.image!);

  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      imageUrl,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 100,
          height: 100,
          color: Colors.white,
          child: const Icon(
            Icons.broken_image,
            size: 40,
            color: Color(0xff99A4BA),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 100,
          height: 100,
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    ),
  );
}

 Future<void> _initializeBaseUrl() async {
  try {
    final staticBaseUrl = await _apiService.getStaticBaseUrl();
    setState(() {
      baseUrl = staticBaseUrl;
    });
  } catch (error) {
    setState(() {
      baseUrl = 'https://shamcrm.com/storage';
    });
  }
}

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
  }

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
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: TaskCardStyles.taskCardDecoration,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.categoryName,
                      style: TaskCardStyles.titleStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: RichText(
                        maxLines: 4,
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
              const SizedBox(width: 16),
              Container(
                width: 100,
                height: 100,
                child: FutureBuilder<Widget>(
                  future: _buildImageWidget(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.white,
                        child: const Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Color(0xff99A4BA),
                        ),
                      );
                    }
                    return snapshot.data ?? Container(
                      width: 100,
                      height: 100,
                      color: Colors.white,
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Color(0xff99A4BA),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}