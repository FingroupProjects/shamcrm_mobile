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

  const GoodsCard({
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

  @override
  void initState() {
    super.initState();
    //print('🔵 [GoodsCard] initState для товара: ${widget.goodsName} (ID: ${widget.goodsId})');
    //print('🔵 [GoodsCard] Количество файлов: ${widget.goodsFiles.length}');
    
    // Выводим все файлы которые пришли от сервера
    for (int i = 0; i < widget.goodsFiles.length; i++) {
      final file = widget.goodsFiles[i];
      //print('🔵 [GoodsCard] Файл $i: path="${file.path}", isMain=${file.isMain}');
    }
    
    _initializeBaseUrl();
  }

  Future<void> _initializeBaseUrl() async {
    //print('⏳ [GoodsCard] Начинаем получение baseUrl...');
    try {
      final staticBaseUrl = await _apiService.getStaticBaseUrl();
      //print('✅ [GoodsCard] Получен baseUrl: "$staticBaseUrl"');
      setState(() {
        baseUrl = staticBaseUrl;
      });
    } catch (error) {
      //print('❌ [GoodsCard] Ошибка получения baseUrl: $error');
      // Fallback на дефолтный URL в случае ошибки
      setState(() {
        baseUrl = 'https://shamcrm.com/storage';
      });
      //print('⚠️ [GoodsCard] Используем fallback baseUrl: "$baseUrl"');
    }
  }

  void _navigateToGoodsDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoodsDetailsScreen(id: widget.goodsId),
      ),
    );
  }

  GoodsFile? _getMainImage() {
    if (widget.goodsFiles.isEmpty) {
      //print('⚠️ [GoodsCard] Нет файлов для товара ${widget.goodsName}');
      return null;
    }
    
    final mainImage = widget.goodsFiles.firstWhere(
      (file) => file.isMain,
      orElse: () => widget.goodsFiles.first,
    );
    
    //print('🖼️ [GoodsCard] Выбрано главное изображение: path="${mainImage.path}", isMain=${mainImage.isMain}');
    return mainImage;
  }

  Widget _buildImageWidget(GoodsFile file) {
    // Строим полный URL для изображения
    //print('🔧 [GoodsCard] Строим URL изображения...');
    //print('🔧 [GoodsCard] baseUrl: "$baseUrl"');
    //print('🔧 [GoodsCard] file.path: "${file.path}"');
    
    final imageUrl = baseUrl != null ? '$baseUrl/${file.path}' : null;
    
    //print('🌐 [GoodsCard] Финальный imageUrl: "$imageUrl"');
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageUrl != null 
          ? Image.network(
              imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                //print('❌ [GoodsCard] Ошибка загрузки изображения: $error');
                //print('❌ [GoodsCard] URL с ошибкой: "$imageUrl"');
                return Container(
                  width: 100,
                  height: 100,
                  color: Colors.white,
                  child: const Icon(Icons.broken_image, size: 40, color: Color(0xff99A4BA)),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  //print('✅ [GoodsCard] Изображение успешно загружено: "$imageUrl"');
                  return child;
                }
                final progress = loadingProgress.cumulativeBytesLoaded / 
                    (loadingProgress.expectedTotalBytes ?? 1);
                //print('⏳ [GoodsCard] Загрузка изображения: ${(progress * 100).toStringAsFixed(0)}%');
                return Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            )
          : Container(
              width: 100,
              height: 100,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
    );
  }

  List<Widget> _buildLabels() {
    List<Widget> labels = [];
    const double labelHeight = 18;
    const double labelPadding = 6;

    if (widget.label != null) {
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
    }

    return labels;
  }

  Color _getStatusBackgroundColor(bool? isActive) {
    return isActive == true ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
  }

  Color _getStatusTextColor(bool? isActive) {
    return isActive == true ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
  }

  Widget _buildStatusLabel() {
    final localizations = AppLocalizations.of(context)!;
    final isActive = widget.isActive ?? false;
    final statusText = isActive ? localizations.translate('active') : localizations.translate('inactive');

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
                                  color: const Color(0xff1E2E52),
                                ),
                                children: const <TextSpan>[
                                  TextSpan(text: '\n\u200B', style: TaskCardStyles.priorityStyle),
                                ],
                              )
                            : const TextSpan(text: '\n\u200B', style: TaskCardStyles.priorityStyle),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppLocalizations.of(context)!.translate('subcategory_card')}${widget.goodsCategory}',
                        style: TaskCardStyles.priorityStyle.copyWith(
                          fontSize: 14,
                          color: const Color(0xff1E2E52),
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