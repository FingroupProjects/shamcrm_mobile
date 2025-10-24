import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/page_2/openings/supplier_openings_model.dart';

class SupplierCard extends StatelessWidget {
  final SupplierOpening supplier;
  final Function(SupplierOpening) onClick;
  final Function(SupplierOpening) onLongPress;
  final Function(SupplierOpening)? onDelete;
  final bool isSelectionMode;
  final bool isSelected;

  const SupplierCard({
    Key? key,
    required this.supplier,
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

    return GestureDetector(
      onTap: () => onClick(supplier),
      onLongPress: () => onLongPress(supplier),
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
                    'Название: ${supplier.counterparty?.name ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Наш долг: ${_formatAmount(supplier.ourDuty ?? '0')}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Долг поставщика: ${_formatAmount(supplier.debtToUs ?? '0')}',
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
                onTap: () => onDelete!(supplier),
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
