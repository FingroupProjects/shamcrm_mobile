import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier_return_document/supplier_return_document_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SupplierReturnCard extends StatefulWidget {
  final IncomingDocument document;
  final VoidCallback? onUpdate;
  final Function()? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool hasUpdatePermission;
  final bool hasDeletePermission;

  const SupplierReturnCard({
    Key? key,
    required this.document,
    this.onUpdate,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onTap,
    this.hasUpdatePermission = false,
    this.hasDeletePermission = false,
  }) : super(key: key);

  @override
  State<SupplierReturnCard> createState() => _SupplierReturnCardState();
}

class _SupplierReturnCardState extends State<SupplierReturnCard> {
  String _formatDate(DateTime? date) {
    if (date == null) return AppLocalizations.of(context)!.translate('no_date') ?? 'Нет даты';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _getLocalizedStatus() {
    final localizations = AppLocalizations.of(context)!;
    final doc = widget.document;
    
    // Приоритет: сначала проверяем deleted_at
    if (doc.deletedAt != null) {
      return localizations.translate('deleted_supplier_return') ?? 'Удален';
    }
    
    // Затем проверяем approved
    if (doc.approved == 1) {
      return localizations.translate('approved_supplier_return') ?? 'Проведен';
    } else {
      return localizations.translate('not_approved_supplier_return') ?? 'Не проведен';
    }
  }
   
  Color _getStatusColor() {
    final doc = widget.document;
    
    // Приоритет: сначала проверяем deleted_at
    if (doc.deletedAt != null) {
      return Colors.red; // Красный цвет для удаленных документов
    }
    
    // Затем проверяем approved
    return doc.approved == 1 ? Colors.green : Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final localizations = AppLocalizations.of(context)!;
    
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SupplierReturnDocumentDetailsScreen(
                documentId: doc.id!,
                docNumber: doc.docNumber ?? 'N/A',
                onDocumentUpdated: widget.onUpdate,
                hasUpdatePermission: widget.hasUpdatePermission,
                hasDeletePermission: widget.hasDeletePermission,
              ),
            ),
          );
        }
      },
      onLongPress: widget.onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? const Color(0xFFDDE8F5)
              : const Color(0xFFE9EDF5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${localizations.translate('empty_0') ?? 'Возврат поставщику'}№${doc.docNumber ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getLocalizedStatus(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 12,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${localizations.translate('date') ?? 'Дата'} ${_formatDate(doc.date)}',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w400,
                color: Color(0xff99A4BA),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${localizations.translate('supplier') ?? 'Поставщик'}: ${doc.model?.name ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${localizations.translate('storage') ?? 'Склад'}: ${doc.storage?.name ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w400,
                color: Color(0xff99A4BA),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${localizations.translate('author') ?? 'Автор'}: ${doc.author?.name ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                ),
                // show price from documentGoods
                Text(
                  '${localizations.translate('total') ?? 'Итого'} ${parseNumberToString(doc.totalSum.toStringAsFixed(2))}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
              ],
            ),
            if (doc.comment != null && doc.comment!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${localizations.translate('comment') ?? 'Примечание'}: ${doc.comment}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff99A4BA),
                  ),
                ),
              ),
                ],
              ),
            ),
            if (widget.isSelectionMode) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  widget.isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
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