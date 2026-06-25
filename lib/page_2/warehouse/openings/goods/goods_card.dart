import 'package:flutter/material.dart';

import '../../../../core/theme/helpers/theme_context_extension.dart';
import '../../../../models/page_2/openings/goods_openings_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';

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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;

    // Берем первый товар из документа для отображения основной информации
    final firstGood =
        goods.documentGoods != null && goods.documentGoods!.isNotEmpty
            ? goods.documentGoods!.first
            : null;

    return GestureDetector(
      onTap: () => onClick(goods),
      onLongPress: () => onLongPress(goods),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colors.fieldBg : colors.surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${localizations.translate('title_with_two_dots') ?? 'Название: '}${firstGood?.goodVariant?.fullName ?? goods.docNumber ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Text(
                  //   'Ед. изм.: ${firstGood?.unit?.shortName ?? ''}',
                  //   style: const TextStyle(
                  //     fontSize: 14,
                  //     fontFamily: 'Gilroy',
                  //     fontWeight: FontWeight.w400,
                  //     color: Color(0xff99A4BA),
                  //   ),
                  // ),
                  // const SizedBox(height: 8),
                  Text(
                    'Поставщик: ${goods.model?.name ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Склад: ${goods.storage?.name ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Text(
                  //   'Кол-во: ${firstGood?.quantity ?? '0'}',
                  //   style: const TextStyle(
                  //     fontSize: 14,
                  //     fontFamily: 'Gilroy',
                  //     fontWeight: FontWeight.w400,
                  //     color: Color(0xff99A4BA),
                  //   ),
                  // ),
                  // const SizedBox(height: 8),
                  // Text(
                  //   'Цена: ${parseNumberToString(firstGood?.price ?? '0')}',
                  //   style: const TextStyle(
                  //     fontSize: 14,
                  //     fontFamily: 'Gilroy',
                  //     fontWeight: FontWeight.w400,
                  //     color: Color(0xff99A4BA),
                  //   ),
                  // ),
                ],
              ),
            ),
            // Action buttons
            if (onDelete != null)
              GestureDetector(
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 24,
                  color: colors.buttonDangerBg,
                ),
                onTap: () => onDelete!(goods),
              ),
            if (isSelectionMode) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: colors.buttonPrimaryBg,
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
