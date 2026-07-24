import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/label_list_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_add.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_details_screen.dart';
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
  final bool isTojsokhtmontjTenant;
  final String? availabilityStatus;
  final String? characteristicsSummary;
  final List<String> characteristics;
  final int? orderId;
  final String? orderNumber;
  final double? goodsPrice;

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
    this.isTojsokhtmontjTenant = false,
    this.availabilityStatus,
    this.characteristicsSummary,
    this.characteristics = const [],
    this.orderId,
    this.orderNumber,
    this.goodsPrice,
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

  void _navigateToOrderDetails() {
    final orderId = widget.orderId;
    if (orderId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(
          orderId: orderId,
          categoryName: '',
          order: Order(
            id: orderId,
            phone: '',
            orderNumber: widget.orderNumber ?? orderId.toString(),
            delivery: false,
            lead: OrderLead(id: 0, name: '', channels: const [], phone: ''),
            orderStatus: OrderStatusName(id: 0, name: ''),
            goods: const [],
          ),
        ),
      ),
    );
  }

  bool get _isFreeForTojsokhtmontjOrder {
    if (!widget.isTojsokhtmontjTenant) return false;
    final normalized = (widget.availabilityStatus ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('ё', 'е');
    return normalized.contains('свобод');
  }

  void _navigateToCreateOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderAddScreen(
          initialGoodsItem: {
            'id': widget.goodsId,
            'name': widget.goodsName,
            'price': widget.goodsPrice ?? 0.0,
            'quantity': 1,
            'imagePath': _getMainImage()?.path,
          },
        ),
      ),
    );
  }

  Widget _buildCreateOrderIconButton() {
    if (!_isFreeForTojsokhtmontjOrder) return const SizedBox.shrink();

    return IconButton(
      onPressed: _navigateToCreateOrder,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xff1D2D51),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.add_rounded, size: 22),
      tooltip: 'Создать заказ',
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

  Widget _buildImageWidget(GoodsFile file, {double size = 100}) {
    // Строим полный URL для изображения
    //print('🔧 [GoodsCard] Строим URL изображения...');
    //print('🔧 [GoodsCard] baseUrl: "$baseUrl"');
    //print('🔧 [GoodsCard] file.path: "${file.path}"');

    final imageUrl = baseUrl != null ? '${file.path}' : null;

    //print('🌐 [GoodsCard] Финальный imageUrl: "$imageUrl"');

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                //print('❌ [GoodsCard] Ошибка загрузки изображения: $error');
                //print('❌ [GoodsCard] URL с ошибкой: "$imageUrl"');
                return Container(
                  width: size,
                  height: size,
                  color: Colors.white,
                  child: const Icon(Icons.broken_image,
                      size: 40, color: Color(0xff99A4BA)),
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
                  width: size,
                  height: size,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            )
          : Container(
              width: size,
              height: size,
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
          padding:
              const EdgeInsets.symmetric(horizontal: labelPadding, vertical: 2),
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
    if (widget.isTojsokhtmontjTenant) {
      final statusText = widget.availabilityStatus?.trim() ?? '';
      if (statusText.isEmpty) return const SizedBox.shrink();

      final colors = _tojsokhtmontjStatusColors(statusText);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.$1,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          statusText,
          style: TextStyle(
            color: colors.$2,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Gilroy',
          ),
        ),
      );
    }

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

  Widget _buildOrderLink() {
    if (!widget.isTojsokhtmontjTenant || widget.orderId == null) {
      return const SizedBox.shrink();
    }

    final number = widget.orderNumber?.trim();
    final label = number == null || number.isEmpty
        ? 'Заказ #${widget.orderId}'
        : 'Заказ №$number';

    return InkWell(
      onTap: _navigateToOrderDetails,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xffEEF0FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 15, color: Color(0xff4759FF)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TaskCardStyles.priorityStyle.copyWith(
                fontSize: 12,
                color: const Color(0xff4759FF),
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTojsokhtmontjCard(GoodsFile? mainImage) {
    final hasCharacteristics = widget.characteristics.isNotEmpty ||
        (widget.characteristicsSummary?.trim().isNotEmpty ?? false);
    const imageSize = 82.0;

    return GestureDetector(
      onTap: _navigateToGoodsDetails,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffE4E9F2)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: mainImage != null
                          ? _buildImageWidget(mainImage, size: imageSize)
                          : Container(
                              decoration: BoxDecoration(
                                color: const Color(0xffF4F7FD),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.image_not_supported,
                                  size: 30, color: Color(0xff99A4BA)),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: imageSize),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              widget.goodsName,
                              style: TaskCardStyles.titleStyle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.goodsCategory,
                              style: TaskCardStyles.priorityStyle.copyWith(
                                color: const Color(0xff6F7E98),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (hasCharacteristics)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  widget.characteristicsSummary ??
                                      widget.characteristics.join(' / '),
                                  style: TaskCardStyles.priorityStyle.copyWith(
                                    color: const Color(0xff1E2E52),
                                    fontSize: 12,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xffE9EDF4)),
                const SizedBox(height: 9),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: _buildOrderLink()),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusLabel(),
                        if (_isFreeForTojsokhtmontjOrder) ...[
                          const SizedBox(width: 8),
                          _buildCreateOrderIconButton(),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color) _tojsokhtmontjStatusColors(String status) {
    final normalized = status.trim().toLowerCase().replaceAll('ё', 'е');
    if (normalized.contains('свобод')) {
      return (const Color(0xFFE0F6E9), const Color(0xFF11B95C));
    }
    if (normalized.contains('брон')) {
      return (const Color(0xFFFFF4DD), const Color(0xFFE18A00));
    }
    if (normalized.contains('прод')) {
      return (const Color(0xFFFFE3E3), const Color(0xFFFF3B30));
    }
    if (normalized.contains('резерв')) {
      return (const Color(0xFFE4EFFF), const Color(0xFF1D7CFF));
    }
    return (const Color(0xFFF1F4FA), const Color(0xFF61708A));
  }

  Widget _buildCharacteristics() {
    final values = widget.characteristics
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (values.isEmpty) {
      final summary = widget.characteristicsSummary?.trim();
      if (summary == null || summary.isEmpty) return const SizedBox.shrink();
      values.addAll(summary
          .split(RegExp(r'\s*/\s*|,\s*'))
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: values.map((value) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xffF4F7FD),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xffE1E7F0)),
          ),
          child: Text(
            value,
            style: TaskCardStyles.priorityStyle.copyWith(
              fontSize: 11,
              color: const Color(0xff61708A),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainImage = _getMainImage();
    if (widget.isTojsokhtmontjTenant) {
      return _buildTojsokhtmontjCard(mainImage);
    }

    final imageSize = widget.isTojsokhtmontjTenant ? 74.0 : 100.0;
    return GestureDetector(
      onTap: _navigateToGoodsDetails,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: TaskCardStyles.taskCardDecoration,
          child: Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
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
                        maxLines: widget.isTojsokhtmontjTenant ? 1 : 2,
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
                                  TextSpan(
                                      text: '\n\u200B',
                                      style: TaskCardStyles.priorityStyle),
                                ],
                              )
                            : const TextSpan(
                                text: '\n\u200B',
                                style: TaskCardStyles.priorityStyle),
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
                      if (widget.isTojsokhtmontjTenant &&
                          (widget.characteristics.isNotEmpty ||
                              (widget.characteristicsSummary
                                      ?.trim()
                                      .isNotEmpty ??
                                  false))) ...[
                        const SizedBox(height: 4),
                        _buildCharacteristics(),
                      ],
                      const SizedBox(height: 4),
                      _buildStatusLabel(),
                      if (widget.isTojsokhtmontjTenant &&
                          widget.orderId != null) ...[
                        const SizedBox(height: 4),
                        _buildOrderLink(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: imageSize,
                  height: imageSize,
                  child: mainImage != null
                      ? _buildImageWidget(mainImage, size: imageSize)
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.image_not_supported,
                            size: widget.isTojsokhtmontjTenant ? 32 : 40,
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
