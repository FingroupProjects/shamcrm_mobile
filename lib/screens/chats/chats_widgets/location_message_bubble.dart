import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chats/chat_appearance.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationMessageBubble extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String time;
  final bool isSender;
  final String senderName;
  final bool isRead;
  final bool isLeadChat;
  final bool? isGroupChat;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const LocationMessageBubble({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.time,
    required this.isSender,
    required this.senderName,
    required this.isRead,
    required this.isLeadChat,
    this.isGroupChat,
    this.isHighlighted = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final appearance = ChatAppearanceScope.of(context);
    final bubbleColor = isSender
        ? appearance.senderBubbleColor(context)
        : appearance.receiverBubbleColor(context);
    final foreground = isSender
        ? appearance.outgoingForeground(context)
        : appearance.incomingForeground(context);

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          if (isLeadChat || isGroupChat == true || !isSender)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                senderName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: appearance.senderNameColor(context),
                ),
              ),
            ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap ?? _openMap,
            onLongPress: onLongPress,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.72,
              margin: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: appearance.bubbleRadius(isSender),
                border: Border.all(
                  color: isHighlighted
                      ? appearance.accentColor(context)
                      : appearance.borderColor(context, isSender),
                  width: isHighlighted ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.appColors.shadow.withValues(alpha: 0.10),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 155,
                        child: IgnorePointer(
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(latitude, longitude),
                              initialZoom: 15,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.softtech.crm_task_manager',
                              ),
                            ],
                          ),
                        ),
                      ),
                      Icon(
                        Icons.location_pin,
                        color: context.appColors.error,
                        size: 42,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 9, 10, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: context.appColors.buttonPrimaryBg,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            localizations.translate('geolocation'),
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: appearance.scaledFont(14),
                              fontWeight: appearance.messageFontWeight,
                              color: foreground,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: appearance.scaledFont(11),
                            color: appearance.secondaryForeground(
                              context,
                              isSender,
                            ),
                            fontFamily: 'Gilroy',
                          ),
                        ),
                        if (isSender) ...[
                          const SizedBox(width: 3),
                          Icon(
                            Icons.done_all,
                            size: 16,
                            color: isRead
                                ? foreground
                                : appearance.secondaryForeground(
                                    context, isSender),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMap() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
