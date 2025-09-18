import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/page_2/warehouse/write_off/write_off_details.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WriteOffCard extends StatelessWidget {
  final IncomingDocument document;
  final VoidCallback? onUpdate;

  const WriteOffCard({
    super.key,
    required this.document,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WriteOffDocumentDetailsScreen(
              documentId: document.id!,
              docNumber: document.docNumber ?? '',
              onDocumentUpdated: onUpdate,
            ),
          ),
        );
        if (result == true && onUpdate != null) {
          onUpdate!();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: TaskCardStyles.taskCardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${localizations.translate('empty_0') ?? 'Документ'}№${document.docNumber ?? ''}',
                        style: TaskCardStyles.titleStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: document.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getLocalizedStatus(context, document),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: document.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xff99A4BA),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      document.date != null
                          ? DateFormat('dd.MM.yyyy').format(document.date!)
                          : localizations.translate('empty_o') ?? 'Дата не указана',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.warehouse,
                      size: 16,
                      color: Color(0xff99A4BA),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        document.storage?.name ?? localizations.translate('empty_o') ?? 'Склад не указан',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          color: Color(0xff99A4BA),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${localizations.translate('total_quantity') ?? 'Общее количество'}: ${document.totalQuantity}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ],
                ),
                if (document.comment != null && document.comment!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('comment') ?? 'Комментарий'}: ${document.comment}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff99A4BA),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

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
}