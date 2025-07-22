import 'package:crm_task_manager/models/page_2/call_center_model.dart';
import 'package:crm_task_manager/page_2/call_center/call_details_screen.dart';
import 'package:flutter/material.dart';

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                    color: _getCallTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    _getCallTypeIcon(),
                    color: _getCallTypeColor(),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Информация о звонке
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Имя лида
                      Text(
                        callEntry.leadName,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Номер телефона
                      Text(
                        callEntry.phoneNumber,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
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
                              color: Colors.grey.shade500,
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
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Кнопка повторного звонка
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
                    color: const Color(0xFF6C5CE7),
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
    }
  }

  Color _getCallTypeColor() {
    switch (callEntry.callType) {
      case CallType.incoming:
        return Colors.green;
      case CallType.outgoing:
        return Colors.blue;
      case CallType.missed:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  void _makeCall(String phoneNumber) {
    // Здесь будет логика для совершения звонка
    print('Calling $phoneNumber');
  }
}
