import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MovementCard extends StatelessWidget {
  final IncomingDocument document;
  final VoidCallback? onUpdate;
  final Function() onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;

  const MovementCard({
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
    final colors = context.appColors;
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: colors.shadow.withValues(alpha: 0.05), blurRadius: 4)
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
                          color: document.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getLocalizedStatus(context, document),
                          style: TextStyle(
                            color: document.statusColor,
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
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('sender_storage') ?? 'От'}: ${document.sender_storage_id?.name ?? document.storage?.name ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('recipient_storage') ?? 'К'}: ${document.recipient_storage_id?.name ?? 'N/A'}',
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
                  color: colors.iconPrimary,
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
