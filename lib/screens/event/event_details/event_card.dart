import 'package:crm_task_manager/models/event_model.dart';
import 'package:crm_task_manager/screens/event/event_details/event_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventCard extends StatefulWidget {
  final NoticeEvent event;
  final VoidCallback? onStatusUpdated;

  const EventCard({
    Key? key,
    required this.event,
    this.onStatusUpdated,
  }) : super(key: key);

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  String formatDate(String? dateString) {
    if (dateString == null) {
      return AppLocalizations.of(context)!.translate('date_not');
    }
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy').format(dateTime);
    } catch (e) {
      return AppLocalizations.of(context)!.translate('Invalid_date_format');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Переход на экран EventDetailsScreen с передачей noticeId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(noticeId: widget.event.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Color(0xffF4F7FD),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event.title,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Лид: ${widget.event.lead.name}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff99A4BA),
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ),
                Text(
                  widget.event.lead.phone,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xff99A4BA),
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Image.asset(
                  'assets/icons/tabBar/date.png',
                  width: 17,
                  height: 17,
                ),
                const SizedBox(width: 4),
                Text(
                  ' ${formatDate(widget.event.date?.toString())}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xff99A4BA),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  'Автор: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xff1E2E52),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.event.author.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}