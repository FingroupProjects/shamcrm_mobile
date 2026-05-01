import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
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
                  color:
                      isSender ? Colors.grey.shade600 : const Color(0xff1E2E52),
                ),
              ),
            ),
          GestureDetector(
            onTap: _openMap,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.72,
              margin: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHighlighted
                      ? const Color(0xff1E2E52)
                      : const Color(0xffD9E4F4),
                  width: isHighlighted ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
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
                      const Icon(
                        Icons.location_pin,
                        color: Color(0xffEA4335),
                        size: 42,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 9, 10, 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: Color(0xff1E2E52),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            localizations.translate('geolocation'),
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                        if (isSender) ...[
                          const SizedBox(width: 3),
                          Icon(
                            Icons.done_all,
                            size: 16,
                            color: isRead
                                ? const Color(0xff1E2E52)
                                : Colors.grey.shade500,
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
