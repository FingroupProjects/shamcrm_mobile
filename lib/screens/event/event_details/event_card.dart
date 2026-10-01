import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/widgets/themed_asset_icon.dart';
import 'package:crm_task_manager/models/event/event_model.dart';
import 'package:crm_task_manager/screens/event/event_details/event_details_screen.dart';
import 'package:crm_task_manager/screens/event/event_details/notice_schedule_fields.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventCard extends StatefulWidget {
  final NoticeEvent event;
  final VoidCallback? onStatusUpdated;

  /// Интервал вкладки: past, today, tomorrow, upcoming.
  /// Нужен, чтобы незакрытое событие во «Прошедших» сразу было «Просрочено».
  final String? dateType;

  const EventCard({
    Key? key,
    required this.event,
    this.onStatusUpdated,
    this.dateType,
  }) : super(key: key);

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  /// Момент события: дата плюс «время до», иначе «время от».
  /// Полночь без часов не считаем просрочкой — это просто день.
  DateTime? _eventMoment() {
    final local = widget.event.date?.toLocal();
    if (local == null) return null;
    final clock = widget.event.timeTo ?? widget.event.timeFrom;
    if (clock != null && clock.contains(':')) {
      final parts = clock.split(':');
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return DateTime(local.year, local.month, local.day, hour, minute);
      }
    }
    if (local.hour == 0 && local.minute == 0) return null;
    return local;
  }

  String formatDate(String? dateString) {
    if (dateString == null) {
      return AppLocalizations.of(context)!.translate('date_not');
    }
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy HH:mm').format(dateTime.toLocal());
    } catch (e) {
      return AppLocalizations.of(context)!.translate('Invalid_date_format');
    }
  }

  /// Плашка на карточке — не вкладка.
  /// Завершено закрывает всё. Иначе прошедшее время — просрочка, остальное в процессе.
  _EventBadge _badge(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;

    if (widget.event.isFinished) {
      return _EventBadge(
        label: l10n.translate('finished'),
        color: colors.success,
      );
    }

    final reminder = _eventMoment();
    final timePassed = reminder != null && reminder.isBefore(DateTime.now());
    final inPastBucket = widget.dateType == EventDateType.past;
    if (timePassed || inPastBucket) {
      return _EventBadge(
        label: l10n.translate('event_overdue'),
        color: colors.error,
      );
    }

    return _EventBadge(
      label: l10n.translate('in_progress'),
      color: colors.buttonPrimaryBg,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final badge = _badge(context);
    final body = widget.event.body.trim();

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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(noticeId: widget.event.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          // На светлом фоне карточка совпадает со страницей, без рамки края не видно.
          border: Border.all(
            color: colors.borderPrimary,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: badge.color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.event.title.isEmpty
                                    ? AppLocalizations.of(context)!
                                        .translate('no_name')
                                    : widget.event.title,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusChip(badge: badge),
                          ],
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
                                  color: colors.textSecondary,
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
                                color: colors.textSecondary,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                        if (body.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            widget.event.users.isNotEmpty
                                ? Stack(
                                    children: [
                                      if (widget.event.users.isNotEmpty &&
                                          widget.event.users[0].image != null &&
                                          widget.event.users[0].image!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 20),
                                          child: widget.event.users[0].image!
                                                  .startsWith('<svg')
                                              ? buildSvgAvatar(
                                                  widget.event.users[0].image!)
                                              : Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    image: DecorationImage(
                                                      image: NetworkImage(widget
                                                          .event.users[0].image!),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      if (widget.event.users.length > 1 &&
                                          widget.event.users[1].image != null &&
                                          widget.event.users[1].image!.isNotEmpty)
                                        Positioned(
                                          left: 20,
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(right: 10),
                                            child: widget.event.users[1].image!
                                                    .startsWith('<svg')
                                                ? buildSvgAvatar(widget
                                                    .event.users[1].image!)
                                                : Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      image: DecorationImage(
                                                        image: NetworkImage(widget
                                                            .event
                                                            .users[1]
                                                            .image!),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                    ],
                                  )
                                : const SizedBox(width: 32, height: 32),
                            if (widget.event.users.length > 2)
                              Padding(
                                padding: const EdgeInsets.only(left: 2),
                                child: Text(
                                  '+${widget.event.users.length - 2}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            ThemedDateIcon(
                              size: 17,
                              color: colors.textSecondary,
                              background: colors.surfacePrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ' ${formatDate(widget.event.createdAt.toString())}',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        if (widget.event.date != null) const SizedBox(height: 5),
                        if (widget.event.date != null)
                          Row(
                            children: [
                              Text(
                                '${AppLocalizations.of(context)?.translate('reminder_date') ?? 'Напоминание'}: ${formatNoticeSchedule(
                                  widget.event.date,
                                  widget.event.timeFrom,
                                  widget.event.timeTo,
                                  fromLabel: AppLocalizations.of(context)!
                                      .translate('notice_from'),
                                  toLabel: AppLocalizations.of(context)!
                                      .translate('notice_to'),
                                )}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 5),
                        Text(
                          '${AppLocalizations.of(context)!.translate('author_contact')}${widget.event.author.name}',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventBadge {
  final String label;
  final Color color;

  const _EventBadge({required this.label, required this.color});
}

class _StatusChip extends StatelessWidget {
  final _EventBadge badge;

  const _StatusChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        badge.label,
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: badge.color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
