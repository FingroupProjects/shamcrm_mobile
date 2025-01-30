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
    String? extractImageUrlFromSvg(String svg) {
      if (svg.contains('href="')) {
        final start = svg.indexOf('href="') + 6;
        final end = svg.indexOf('"', start);
        return svg.substring(start, end);
      }
      return null;
    }

    Color? extractBackgroundColorFromSvg(String svg) {
      final fillMatch = RegExp(r'fill="(#[A-Fa-f0-9]+)"').firstMatch(svg);
      if (fillMatch != null) {
        final colorHex = fillMatch.group(1);
        if (colorHex != null) {
          final hex = colorHex.replaceAll('#', '');
          return Color(int.parse('FF$hex', radix: 16));
        }
      }
      return null;
    }

    Widget buildSvgAvatar(String svg, {double size = 32}) {
      if (svg.contains('image href=')) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(extractImageUrlFromSvg(svg) ?? ''),
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        final backgroundColor =
            extractBackgroundColorFromSvg(svg) ?? Color(0xFF2C2C2C);

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: EdgeInsets.all(size * 0.3),
                child: Text(
                  RegExp(r'>([^<]+)</text>').firstMatch(svg)?.group(1) ?? '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }
    }

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
        '${AppLocalizations.of(context)!.translate('lead_deal_card')} ${widget.event.lead.name}',
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
                // Instead of widget.event.users.image
                widget.event.users.isNotEmpty // Check if there are any users
                    ? Stack(
                        children: [
                          if (widget.event.users.isNotEmpty &&
                              widget.event.users[0].image != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: widget.event.users[0].image!
                                      .startsWith('<svg')
                                  ? buildSvgAvatar(widget.event.users[0].image!)
                                  : Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: NetworkImage(
                                              widget.event.users[0].image!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                            ),
                          if (widget.event.users.length > 1 &&
                              widget.event.users[1].image != null)
                            Positioned(
                              left: 20,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: widget.event.users[1].image!.isNotEmpty
                                    ? widget.event.users[1].image!
                                            .startsWith('<svg')
                                        ? buildSvgAvatar(
                                            widget.event.users[1].image!)
                                        : Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: NetworkImage(widget
                                                    .event.users[1].image!),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          )
                                    : const CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.purple,
                                      ),
                              ),
                            ),
                        ],
                      )
                    : const SizedBox(),
                if (widget.event.users.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      '+${widget.event.users.length - 2}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff1E2E52),
                      ),
                    ),
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
            AppLocalizations.of(context)!.translate('author_contact'),
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
