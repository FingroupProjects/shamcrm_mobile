import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class PinnedLeadMessageWidget extends StatelessWidget {
  final String message;
  final String? channelType;
  final VoidCallback? onTap;

  const PinnedLeadMessageWidget({
    super.key,
    required this.message,
    this.channelType,
    this.onTap,
  });

  static const channelIconMap = {
    'mini_app': 'assets/icons/leads/telegram.png',
    'telegram_bot': 'assets/icons/leads/telegram.png',
    'telegram_account': 'assets/icons/leads/telegram.png',
    'whatsapp': 'assets/icons/leads/whatsapp.png',
    'green_api': 'assets/icons/leads/whatsapp.png',
    'instagram': 'assets/icons/leads/instagram.png',
    'instagram_comment': 'assets/icons/leads/instagram.png',
    'facebook': 'assets/icons/leads/messenger.png',
    'email': 'assets/icons/leads/email.png',
    'site': '',
  };

  String _getChannelIcon(String? channelType) {
    final normalized = (channelType ?? '').replaceAll('channel-', '');
    return channelIconMap[normalized] ?? 'assets/icons/leads/default.png';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
        decoration: BoxDecoration(
          color: context.appColors.surfacePrimary,
          border: Border.all(
            color: context.appColors.borderSubtle,
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
                    color: context.appColors.textPrimary,
                  )
                : Image.asset(
                    _getChannelIcon(channelType),
                    width: 28,
                    height: 28,
                    errorBuilder: (context, error, stackTrace) {
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
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ChatSmsStyles.messageBubbleSenderColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: context.appTextStyles.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textPrimary,
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
