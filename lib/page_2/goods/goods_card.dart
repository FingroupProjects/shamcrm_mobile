import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/label_list_model.dart';
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
  final bool? isActive;
  final Label? label;

  GoodsCard({
    Key? key,
    required this.goodsId,
    required this.goodsName,
    required this.goodsDescription,
    required this.goodsCategory,
    required this.goodsStockQuantity,
    required this.goodsFiles,
    this.isActive,
    this.label,
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

  List<Widget> _buildLabels() {
    List<Widget> labels = [];
    const double labelHeight = 18;
    const double labelPadding = 6;

    // Отображаем метку, если она существует, независимо от showOnMain
    if (widget.label != null) {
      print('GoodsCard: Displaying label, name=${widget.label!.name}, color=${widget.label!.color}, showOnMain=${widget.label!.showOnMain}');
      String colorString = widget.label!.color;
      Color labelColor;
      try {
        if (colorString.startsWith('#')) {
          colorString = colorString.replaceFirst('#', '');
        }
        if (colorString.length == 6) {
          colorString = 'ff$colorString';
        }
        labelColor = Color(int.parse(colorString, radix: 16));
      } catch (e) {
        print('GoodsCard: Invalid color format for label: ${widget.label!.color}, error: $e');
        labelColor = Colors.grey;
      }

      labels.add(
        Container(
          height: labelHeight,
          margin: const EdgeInsets.only(right: 8, bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: labelPadding, vertical: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [labelColor, labelColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            widget.label!.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'Gilroy',
            ),
          ),
        ),
      );
    } else {
      print('GoodsCard: No label to display');
    }

    return labels;
  }

  Color _getStatusBackgroundColor(bool? isActive) {
    if (isActive == true) {
      return const Color(0xFFE8F5E9);
    } else {
      return const Color(0xFFFFEBEE);
    }
  }

  Color _getStatusTextColor(bool? isActive) {
    if (isActive == true) {
      return const Color(0xFF2E7D32);
    } else {
      return const Color(0xFFC62828);
    }
  }

  Widget _buildStatusLabel() {
    final localizations = AppLocalizations.of(context)!;
    final isActive = widget.isActive ?? false;
    final statusText = isActive
        ? localizations.translate('active')
        : localizations.translate('inactive');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusBackgroundColor(isActive),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: _getStatusTextColor(isActive),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Gilroy',
        ),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 0,
                        runSpacing: 4,
                        children: _buildLabels(),
                      ),
                      const SizedBox(height: 4),
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
                                style: TaskCardStyles.priorityStyle,
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppLocalizations.of(context)!.translate('subcategory_card')}: ${widget.goodsCategory}',
                        style: TaskCardStyles.priorityStyle.copyWith(
                          fontSize: 14,
                          color: Color(0xff1E2E52),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _buildStatusLabel(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
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
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Color(0xff99A4BA),
                          ),
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