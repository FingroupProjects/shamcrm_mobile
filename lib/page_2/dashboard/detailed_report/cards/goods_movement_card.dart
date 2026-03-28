import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/page_2/good_variants_model.dart';

class GoodsMovementCard extends StatelessWidget {
  final GoodVariantItem variant;
  final Function(GoodVariantItem) onClick;
  final Function(GoodVariantItem) onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const GoodsMovementCard({
    Key? key,
    required this.variant,
    required this.onClick,
    required this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onClick(variant),
      onLongPress: () => onLongPress(variant),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDDE8F5) : const Color(0xFFE9EDF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xff1E2E52) : const Color(0xffE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                variant.fullName ?? variant.good?.name ?? 'Неизвестный товар',
                style: const TextStyle(
                  fontSize: 15,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E2E52),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelectionMode) ...[
              const SizedBox(width: 12),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: const Color(0xff1E2E52),
                size: 24,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

