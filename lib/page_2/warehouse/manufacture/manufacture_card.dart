import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManufactureCard extends StatelessWidget {
  final IncomingDocument document;
  final VoidCallback? onUpdate;
  final Function() onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;

  const ManufactureCard({
    super.key,
    required this.document,
    this.onUpdate,
    required this.onLongPress,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }
    final colors = context.appColors;
    final cardBg = isSelected ? colors.surfaceElevated : colors.surfacePrimary;
    final primaryText = context.adaptiveForegroundOn(cardBg);
    final secondaryText = context.adaptiveHintOn(cardBg);
    final statusColor = document.statusColor;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
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
                            color: primaryText,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getLocalizedStatus(context, document),
                          style: TextStyle(
                            color: statusColor,
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
                    '${localizations.translate('date') ?? 'Дата'} ${document.date != null ? DateFormat('dd.MM.yyyy').format(document.date!) : 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('manufacture_writeoff_storage') ?? 'Склад списания'}: ${document.sender_storage_id?.name ?? document.storage?.name ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('manufacture_income_storage') ?? 'Склад прихода'}: ${document.recipient_storage_id?.name ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('total_quantity') ?? 'Общее количество'}: ${document.totalQuantity}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: primaryText,
                    ),
                  ),
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
                  color: primaryText,
                  size: 24,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getLocalizedStatus(BuildContext context, IncomingDocument document) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      if (document.deletedAt != null) return 'Удален';
      return document.approved == 1 ? 'Проведен' : 'Не проведен';
    }

    if (document.deletedAt != null) {
      return localizations.translate('deleted') ?? 'Удален';
    }

    if (document.approved == 1) {
      return localizations.translate('approved') ?? 'Проведен';
    } else {
      return localizations.translate('not_approved') ?? 'Не проведен';
    }
  }
}
