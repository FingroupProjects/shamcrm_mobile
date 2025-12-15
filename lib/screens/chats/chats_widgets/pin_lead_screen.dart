import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class PinnedLeadMessageWidget extends StatelessWidget {
  final String message;
  final String? channelType;
  final VoidCallback? onTap;

  const PinnedLeadMessageWidget({
    Key? key,
    required this.message,
    this.channelType,
    this.onTap,
  }) : super(key: key);

  static const channelIconMap = {
    'mini_app': 'assets/icons/leads/telegram.png',
    'telegram_bot': 'assets/icons/leads/telegram.png',
    'telegram_account': 'assets/icons/leads/telegram.png',
    'whatsapp': 'assets/icons/leads/whatsapp.png',
    'instagram': 'assets/icons/leads/instagram.png',
    'facebook': 'assets/icons/leads/messenger.png',
    'email': 'assets/icons/leads/email.png',
    'site': '', // Используется Flutter иконка Icons.language
  };

  String _getChannelIcon(String? channelType) {
    debugPrint('Channel type received: $channelType');
    final icon = channelIconMap[channelType] ?? 'assets/icons/leads/default.png';
    debugPrint('Selected icon: $icon');
    return icon;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: ChatSmsStyles.messageBubbleSenderColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            channelType == 'site'
                ? Icon(
                    Icons.language,
                    size: 28,
                    color: Color(0xff1E2E52),
                  )
                : Image.asset(
              _getChannelIcon(channelType),
              width: 28,
              height: 28,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading icon: $error');
                return Image.asset(
                  'assets/icons/leads/default.png',
                  width: 28,
                  height: 28,
                );
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('account_request'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ChatSmsStyles.messageBubbleSenderColor,
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}