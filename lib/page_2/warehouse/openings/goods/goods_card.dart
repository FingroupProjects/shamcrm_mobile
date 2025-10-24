import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/page_2/openings/goods_openings_model.dart';

class GoodsCard extends StatelessWidget {
  final GoodsOpeningDocument goods;
  final Function(GoodsOpeningDocument) onClick;
  final Function(GoodsOpeningDocument) onLongPress;
  final Function(GoodsOpeningDocument)? onDelete;
  final bool isSelectionMode;
  final bool isSelected;

  const GoodsCard({
    Key? key,
    required this.goods,
    required this.onClick,
    required this.onLongPress,
    this.onDelete,
    this.isSelectionMode = false,
    this.isSelected = false,
  }) : super(key: key);

  String _formatAmount(String amount) {
    double amountValue = double.tryParse(amount.replaceAll(' ', '')) ?? 0.0;
    return NumberFormat('#,##0.00', 'ru_RU').format(amountValue);
  }

  @override
  Widget build(BuildContext context) {
    
    // Берем первый товар из документа для отображения основной информации
    final firstGood = goods.documentGoods != null && goods.documentGoods!.isNotEmpty ? goods.documentGoods!.first : null;

    return GestureDetector(
      onTap: () => onClick(goods),
      onLongPress: () => onLongPress(goods),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDDE8F5) : const Color(0xFFE9EDF5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Название: ${firstGood?.goodVariant?.fullName ?? goods.docNumber ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ед. изм.: ${firstGood?.unit?.shortName ?? ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Поставщик: ${goods.model?.name ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Склад: ${goods.storage?.name ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Кол-во: ${firstGood?.quantity ?? '0'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Цена: ${_formatAmount(firstGood?.price ?? '0')}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            if (onDelete != null)
              GestureDetector(
                child: Image.asset(
                  'assets/icons/delete.png',
                  width: 24,
                  height: 24,
                ),
                onTap: () => onDelete!(goods),
              ),
            if (isSelectionMode) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: const Color(0xff1E2E52),
                  size: 24,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
