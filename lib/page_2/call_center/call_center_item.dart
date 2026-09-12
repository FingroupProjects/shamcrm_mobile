import 'package:crm_task_manager/models/page_2/call_center_model.dart';
import 'package:crm_task_manager/page_2/call_center/call_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

class CallLogItem extends StatelessWidget {
  final CallLogEntry callEntry;
  final VoidCallback? onTap;

  const CallLogItem({
    Key? key,
    required this.callEntry,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.appColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Иконка типа звонка
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getCallTypeColor(context).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    _getCallTypeIcon(),
                    color: _getCallTypeColor(context),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Информация о звонке
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Имя лида. Если имя совпадает с телефоном — одна строка.
                      Text(
                        callEntry.displayTitle,
                        style: context.appTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (callEntry.displaySubtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          callEntry.displaySubtitle!,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: context.appColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 2),

                      // Имя оператора
                      Text(
                        'Оператор: ${callEntry.operatorName ?? 'Не указан'}',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: context.appColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Время и длительность
                      Row(
                        children: [
                          Text(
                            _formatDate(callEntry.callDate),
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: context.appColors.textSecondary,
                            ),
                          ),
                          if (callEntry.duration != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(callEntry.duration!),
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                color: context.appColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Кнопка деталей
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CallDetailsScreen(callEntry: callEntry),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.info_outline,
                    color: context.appColors.buttonPrimaryBg,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCallTypeIcon() {
    switch (callEntry.callType) {
      case CallType.incoming:
        return Icons.call_received;
      case CallType.outgoing:
        return Icons.call_made;
      case CallType.missed:
        return Icons.call_missed;
      case CallType.outgoingMissed:
        return Icons.call_made;
    }
  }

  Color _getCallTypeColor(BuildContext context) {
    switch (callEntry.callType) {
      case CallType.incoming:
        return context.appColors.success;
      case CallType.outgoing:
        return context.appColors.buttonPrimaryBg;
      case CallType.missed:
        return context.appColors.error;
      case CallType.outgoingMissed:
        return context.appColors.error;
    }
  }

  String _formatDate(DateTime date) {
    // callDate is already converted to the device timezone.
    final localDate = date.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDate);

    if (difference.inMinutes < 0) {
      final hour = localDate.hour.toString().padLeft(2, '0');
      final minute = localDate.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else {
      final day = localDate.day.toString().padLeft(2, '0');
      final month = localDate.month.toString().padLeft(2, '0');
      final year = localDate.year;
      final hour = localDate.hour.toString().padLeft(2, '0');
      final minute = localDate.minute.toString().padLeft(2, '0');
      return '$day.$month.$year $hour:$minute';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  void _makeCall(String phoneNumber) {
    //print('Calling $phoneNumber');
  }
}
