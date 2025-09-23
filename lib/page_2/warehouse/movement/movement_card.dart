import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/page_2/warehouse/movement/movement_details.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MovementCard extends StatelessWidget {
  final IncomingDocument document;
  final VoidCallback? onUpdate;

  const MovementCard({
    super.key,
    required this.document,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      // Fallback если локализация недоступна
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () async {
        // Проверяем валидность данных документа
        if (document.id == null) return;
        
        try {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovementDocumentDetailsScreen(
                documentId: document.id!,
                docNumber: document.docNumber ?? '',
                onDocumentUpdated: onUpdate,
              ),
            ),
          );
          
          // Проверяем, что виджет все ещё смонтирован после возвращения
          if (context.mounted && result == true && onUpdate != null) {
            onUpdate!();
          }
        } catch (e) {
          // Обрабатываем возможные ошибки навигации
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка при открытии документа: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
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
                _buildDateRow(localizations),
                const SizedBox(height: 4),
                _buildSenderStorageRow(localizations),
                const SizedBox(height: 4),
                _buildRecipientStorageRow(localizations),
                const SizedBox(height: 8),
                _buildQuantityRow(localizations),
                // if (document.comment != null && document.comment!.isNotEmpty) ...[
                //   const SizedBox(height: 8),
                //   _buildCommentRow(localizations),
                // ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRow(AppLocalizations localizations) {
    return Row(
      children: [
        const Icon(
          Icons.calendar_today,
          size: 16,
          color: Color(0xff99A4BA),
        ),
        const SizedBox(width: 8),
        Text(
          document.date != null
              ? DateFormat('dd.MM.yyyy').format(document.date!)
              : (localizations.translate('empty_0') ?? 'Дата не указана'),
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w400,
            color: Color(0xff99A4BA),
          ),
        ),
      ],
    );
  }

  Widget _buildSenderStorageRow(AppLocalizations localizations) {
    return Row(
      children: [
        const Icon(
          Icons.warehouse,
          size: 16,
          color: Color(0xff99A4BA),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${localizations.translate('empty_0') ?? 'От'}${document.storage?.name ?? (localizations.translate('no_storage') ?? 'Склад не указан')}',
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
    );
  }

  Widget _buildRecipientStorageRow(AppLocalizations localizations) {
    return Row(
      children: [
        const Icon(
          Icons.warehouse_outlined,
          size: 16,
          color: Color(0xff99A4BA),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${localizations.translate('empty_0') ?? 'К'}${_getRecipientStorageName(document, localizations)}',
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
    );
  }

  Widget _buildQuantityRow(AppLocalizations localizations) {
    return Row(
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
    );
  }

  Widget _buildCommentRow(AppLocalizations localizations) {
    return Text(
      '${localizations.translate('comment') ?? 'Комментарий'}: ${document.comment}',
      style: const TextStyle(
        fontSize: 12,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: Color(0xff99A4BA),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getLocalizedStatus(BuildContext context, IncomingDocument document) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      // Fallback на английский/русский если локализация недоступна
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

  String _getRecipientStorageName(IncomingDocument document, AppLocalizations localizations) {
    // В реальном проекте здесь должно быть получение склада получателя из модели
    // Пока используем заглушку, так как в текущей модели нет поля для склада получателя
    
    // Сначала пытаемся получить данные из JSON документа (если есть поле recipient_storage)
    // или используем заглушку
    return localizations.translate('recipient_storage_name') ?? 'Склад получатель';
  }
}