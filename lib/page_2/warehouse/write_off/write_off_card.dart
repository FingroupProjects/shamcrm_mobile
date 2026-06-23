import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WriteOffCard extends StatelessWidget {
  final IncomingDocument document;
  final VoidCallback? onUpdate;
  final Function() onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;

  const WriteOffCard({
    super.key,
    required this.document,
    this.onUpdate,
    required this.onLongPress,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
  });

  String _getLocalizedStatus(BuildContext context, IncomingDocument document) {
    final localizations = AppLocalizations.of(context)!;

    if (document.deletedAt != null) {
      return localizations.translate('deleted') ?? 'Удален';
    }

    if (document.approved == 1) {
      return localizations.translate('approved') ?? 'Проведен';
    } else {
      return localizations.translate('not_approved') ?? 'Не проведен';
    }
  }

  Color _getStatusColor() {
    if (document.deletedAt != null) {
      return Colors.red;
    }

    return document.approved == 1 ? Colors.green : Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colors.surfaceElevated : colors.surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08), blurRadius: 4)
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
                          '№${document.docNumber ?? ''}',
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
                          color: _getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getLocalizedStatus(context, document),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: _getStatusColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('date') ?? 'Дата'} ${document.date != null ? DateFormat('dd.MM.yyyy').format(document.date!) : 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('storage') ?? 'Склад'}: ${document.storage?.name ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('total_quantity') ?? 'Общее количество'}: ${document.totalQuantity}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  // if (document.comment != null && document.comment!.isNotEmpty) ...[
                  //   const SizedBox(height: 8),
                  //   Text(
                  //     '${localizations.translate('comment') ?? 'Комментарий'}: ${document.comment}',
                  //     style: const TextStyle(
                  //       fontSize: 12,
                  //       fontFamily: 'Gilroy',
                  //       fontWeight: FontWeight.w400,
                  //       color: Color(0xff99A4BA),
                  //     ),
                  //     maxLines: 2,
                  //     overflow: TextOverflow.ellipsis,
                  //   ),
                  // ],
                ],
              ),
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
