import 'package:crm_task_manager/offline/db/app_database.dart';
import 'package:crm_task_manager/page_2/widgets/product_network_image.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_repository.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

class RmkProductCard extends StatelessWidget {
  const RmkProductCard({
    super.key,
    required this.good,
    required this.selectedQuantity,
    required this.onTap,
  });

  final RmkGood good;
  final double selectedQuantity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.surfacePrimary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: colors.buttonPrimaryBg.withValues(alpha: 0.05),
        highlightColor: colors.buttonPrimaryBg.withValues(alpha: 0.03),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colors.borderSubtle),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: _ProductImage(url: good.imageUrl),
                    ),
                    if (selectedQuantity > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.buttonPrimaryBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _formatQuantity(selectedQuantity),
                            style: TextStyle(
                              color: colors.buttonPrimaryFg,
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      good.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Остаток: ${_formatQuantity(good.quantity)} ${RmkRepository.unitLabelForGood(good)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                        ),
                        Text(
                          _formatMoney(good.price),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 12,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                          ),
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

  static String _formatQuantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  static String _formatMoney(double value) {
    if (value == value.roundToDouble()) return '${value.toInt()}';
    return value.toStringAsFixed(2);
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ProductNetworkImage(
      imageUrl: url,
      width: double.infinity,
      height: double.infinity,
      borderRadius: 0,
      emptyIcon: Icons.inventory_2_outlined,
      emptyIconSize: 28,
      memCacheWidth: 320,
    );
  }
}
