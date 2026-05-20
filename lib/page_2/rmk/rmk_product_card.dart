import 'package:cached_network_image/cached_network_image.dart';
import 'package:crm_task_manager/offline/db/app_database.dart';
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffE2E7F0)),
            borderRadius: BorderRadius.circular(8),
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
                        top: Radius.circular(8),
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
                            color: const Color(0xff1E2E52),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _formatQuantity(selectedQuantity),
                            style: const TextStyle(
                              color: Colors.white,
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
                      style: const TextStyle(
                        color: Color(0xff1E2E52),
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
                            'Остаток: ${_formatQuantity(good.quantity)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xff718096),
                              fontSize: 11,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                        ),
                        Text(
                          _formatMoney(good.price),
                          style: const TextStyle(
                            color: Color(0xff1E2E52),
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
    if (url == null || url!.isEmpty) {
      return const ColoredBox(
        color: Color(0xffEEF2F7),
        child: Icon(Icons.inventory_2_outlined, color: Color(0xff99A4BA)),
      );
    }

    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      memCacheWidth: 320,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, __) => const ColoredBox(color: Color(0xffEEF2F7)),
      errorWidget: (_, __, ___) => const ColoredBox(
        color: Color(0xffEEF2F7),
        child: Icon(Icons.inventory_2_outlined, color: Color(0xff99A4BA)),
      ),
    );
  }
}
