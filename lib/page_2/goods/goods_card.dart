import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/label_list_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
import 'package:crm_task_manager/page_2/widgets/product_network_image.dart';
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
  final double? goodsPrice;
  final int? orderId;
  final String? orderNumber;

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
    this.goodsPrice,
    this.orderId,
    this.orderNumber,
  }) : super(key: key);

  @override
  _GoodsCardState createState() => _GoodsCardState();
}

class _GoodsCardState extends State<GoodsCard> {
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
    return widget.orderId == null &&
        (widget.availabilityStatus ?? '')
            .trim()
            .toLowerCase()
            .replaceAll('ё', 'е')
            .contains('свобод');
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
            'availabilityStatus': widget.availabilityStatus,
            'imagePath': _getMainImage()?.path,
          },
        ),
      ),
    );
  }

  Widget _buildCreateOrderButton() {
    if (!_isFreeForTojsokhtmontjOrder) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 34,
        child: TextButton.icon(
          onPressed: _navigateToCreateOrder,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Создать заказ'),
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

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: _navigateToOrderDetails,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: context.appColors.buttonSecondaryBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 15,
                color: context.appColors.buttonPrimaryBg,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TaskCardStyles.priorityStyle(context).copyWith(
                    fontSize: 12,
                    color: context.appColors.buttonPrimaryBg,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  GoodsFile? _getMainImage() {
    if (widget.goodsFiles.isEmpty) {
      return null;
    }

    final mainImage = widget.goodsFiles.firstWhere(
      (file) => file.isMain,
      orElse: () => widget.goodsFiles.first,
    );

    return mainImage;
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
    final colors = context.appColors;
    return isActive == true
        ? colors.success.withValues(alpha: 0.15)
        : colors.error.withValues(alpha: 0.15);
  }

  Color _getStatusTextColor(bool? isActive) {
    final colors = context.appColors;
    return isActive == true ? colors.success : colors.error;
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
            style: TaskCardStyles.priorityStyle(context).copyWith(
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
    final colors = context.appColors;
    final mainImage = _getMainImage();
    return GestureDetector(
      onTap: _navigateToGoodsDetails,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: TaskCardStyles.taskCardDecoration(context),
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
                        style: TaskCardStyles.titleStyle(context),
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
                                style: TaskCardStyles.priorityStyle(context)
                                    .copyWith(
                                  fontSize: 12,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: '\n\u200B',
                                      style: TaskCardStyles.priorityStyle(
                                          context)),
                                ],
                              )
                            : TextSpan(
                                text: '\n\u200B',
                                style: TaskCardStyles.priorityStyle(context)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppLocalizations.of(context)!.translate('subcategory_card')}${widget.goodsCategory}',
                        style: TaskCardStyles.priorityStyle(context).copyWith(
                          fontSize: 14,
                          color: colors.textPrimary,
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
                      _buildOrderLink(),
                      _buildCreateOrderButton(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ProductNetworkImage(
                  imageUrl: mainImage?.path,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
