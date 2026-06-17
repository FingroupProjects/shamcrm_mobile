import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/page_2/expense_document_model.dart';

class ClientSalesCard extends StatefulWidget {
  final ExpenseDocument document;
  final VoidCallback? onUpdate;
  final Function() onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;

  const ClientSalesCard({
    super.key,
    required this.document,
    this.onUpdate,
    required this.onLongPress,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<ClientSalesCard> createState() => _ClientSalesCardState();
}

class _ClientSalesCardState extends State<ClientSalesCard> {
  String _formatDate(DateTime? date) {
    if (date == null) {
      return AppLocalizations.of(context)!.translate('no_date');
    }
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _getLocalizedStatus() {
    final localizations = AppLocalizations.of(context)!;
    final doc = widget.document;

    // Приоритет: сначала проверяем deleted_at
    if (doc.deletedAt != null) {
      return localizations.translate('deleted_incoming');
    }

    // Затем проверяем approved
    if (doc.approved == 1) {
      return localizations.translate('approved_incoming');
    } else {
      return localizations.translate('not_approved_incoming');
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
    final colors = context.appColors;

    return GestureDetector(
      onTap: () {
        widget.onTap();
      },
      onLongPress: () {
        widget.onLongPress();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? colors.surfaceElevated
              : colors.surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.06),
              blurRadius: 4,
            ),
          ],
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
                          '№${doc.docNumber ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withValues(alpha: 0.12),
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
                    '${AppLocalizations.of(context)!.translate('date')} ${_formatDate(doc.date)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizations.of(context)!.translate('client')} ${doc.model?.name ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizations.of(context)!.translate('storage')}: ${doc.storage?.name ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${AppLocalizations.of(context)!.translate('author')}: ${doc.author?.name ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w400,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      // show price from documentGoods
                      Text(
                        '${AppLocalizations.of(context)!.translate('total')} ${parseNumberToString(doc.totalSum.toStringAsFixed(2))}',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  // if (doc.comment != null && doc.comment!.isNotEmpty)
                  //   Padding(
                  //     padding: const EdgeInsets.only(top: 8),
                  //     child: Text(
                  //       '${AppLocalizations.of(context)!.translate('comment') ?? 'Примечание'}: ${doc.comment}',
                  //       style: const TextStyle(
                  //         fontSize: 14,
                  //         fontFamily: 'Gilroy',
                  //         fontWeight: FontWeight.w400,
                  //         color: Color(0xff99A4BA),
                  //       ),
                  //     ),
                  //   ),
                  // Показываем дату удаления для удаленных документов
                  // if (doc.deletedAt != null)
                  //   Padding(
                  //     padding: const EdgeInsets.only(top: 8),
                  //     child: Text(
                  //       '${localizations.translate('deleted_at') ?? 'Удален'}: ${_formatDate(doc.deletedAt)}',
                  //       style: const TextStyle(
                  //         fontSize: 14,
                  //         fontFamily: 'Gilroy',
                  //         fontWeight: FontWeight.w400,
                  //         color: Colors.red,
                  //       ),
                  //     ),
                  //   ),
                ],
              ),
            ),
            if (widget.isSelectionMode) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  widget.isSelected
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
