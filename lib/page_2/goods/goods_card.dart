import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class GoodsCard extends StatefulWidget {
  final int goodsId;
  final String goodsName;
  final String goodsDescription;
  final String goodsCategory;
  final int goodsStockQuantity;
  final List<GoodsFile> goodsFiles;

  GoodsCard({
    Key? key,
    required this.goodsId,
    required this.goodsName,
    required this.goodsDescription,
    required this.goodsCategory,
    required this.goodsStockQuantity,
    required this.goodsFiles,
  }) : super(key: key);

  @override
  _GoodsCardState createState() => _GoodsCardState();
}

class _GoodsCardState extends State<GoodsCard> {
  final ApiService _apiService = ApiService();
  String? baseUrl;

  Future<void> _initializeBaseUrl() async {
    try {
      final enteredDomainMap = await _apiService.getEnteredDomain();
      String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
      String? enteredDomain = enteredDomainMap['enteredDomain'];

      setState(() {
        baseUrl = 'https://$enteredDomain-back.$enteredMainDomain/storage';
        print('GoodsCard: baseUrl set to $baseUrl');
      });
    } catch (error) {
      setState(() {
        baseUrl = 'https://shamcrm.com/storage/';
        print('GoodsCard: Error initializing baseUrl: $error');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
  }

  void _navigateToGoodsDetails() {
    print('GoodsCard: Navigating to GoodsDetailsScreen for ID ${widget.goodsId}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoodsDetailsScreen(
          id: widget.goodsId,
        ),
      ),
    );
  }

  GoodsFile? _getMainImage() {
    if (widget.goodsFiles.isEmpty) {
      print('GoodsCard: No images available for goods ID ${widget.goodsId}');
      return null;
    }

    // Ищем изображение с is_main: true
    final mainImage = widget.goodsFiles.firstWhere(
      (file) => file.isMain,
      orElse: () => widget.goodsFiles.first,
    );

    print('GoodsCard: Selected image for goods ID ${widget.goodsId}: ${mainImage.path} (isMain: ${mainImage.isMain})');
    return mainImage;
  }

  Widget _buildImageWidget(GoodsFile file) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        '$baseUrl/${file.path}',
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('GoodsCard: Image load error for ${file.path}: $error');
          return Container(
            width: 100,
            height: 100,
            color: Colors.white,
            child: Icon(Icons.broken_image, size: 40, color: Color(0xff99A4BA)),
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

  @override
  Widget build(BuildContext context) {
    final mainImage = _getMainImage();
    return GestureDetector(
      onTap: _navigateToGoodsDetails,
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
                        widget.goodsName,
                        style: TaskCardStyles.titleStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: widget.goodsDescription != 'null'
                            ? TextSpan(
                                text: widget.goodsDescription,
                                style: TaskCardStyles.priorityStyle.copyWith(
                                  fontSize: 12,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff1E2E52),
                                ),
                                children: const <TextSpan>[
                                  TextSpan(
                                    text: '\n\u200B',
                                    style: TaskCardStyles.priorityStyle,
                                  ),
                                ],
                              )
                            : const TextSpan(
                                text: '\n\u200B',
                                style: TaskCardStyles.priorityStyle),
                      ),
                      RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          text: '\n\u200B',
                          style: TaskCardStyles.priorityStyle.copyWith(
                            fontSize: 12,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: AppLocalizations.of(context)!
                                  .translate('subcategory_card'),
                              style: TaskCardStyles.priorityStyle.copyWith(
                                color: Color(0xff99A4BA),
                              ),
                            ),
                            TextSpan(
                              text: widget.goodsCategory,
                              style: TaskCardStyles.priorityStyle.copyWith(
                                color: Color(0xff1E2E52),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  width: 100,
                  height: 100,
                  child: mainImage != null
                      ? _buildImageWidget(mainImage)
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.image_not_supported,
                              size: 40, color: Color(0xff99A4BA)),
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