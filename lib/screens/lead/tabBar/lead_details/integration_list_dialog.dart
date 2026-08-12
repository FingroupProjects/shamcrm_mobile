import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';

class IntegrationListDialog extends StatelessWidget {
  final List<dynamic> integrations;
  final int leadId;
  final String leadName;
  final bool canSendMessage;
  final String initialChannelName;

  const IntegrationListDialog({
    Key? key,
    required this.integrations,
    required this.leadId,
    required this.leadName,
    required this.canSendMessage,
    required this.initialChannelName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //print('IntegrationListDialog: Building with ${integrations.length} integrations: $integrations');

    // Если только одна интеграция, автоматически переходим в чат
    if (integrations.length == 1) {
      //print('IntegrationListDialog: Single integration found, navigating to chat ID: ${integrations[0]['id']}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigateToChatScreen(context, integrations[0]['id'], canSendMessage);
      });
      return Container();
    }

    // Если интеграций больше одной, показываем модальное окно
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Dialog(
      backgroundColor: colors.surfacePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              AppLocalizations.of(context)!.translate('select_integration'),
              textAlign: TextAlign.center,
              style: textStyles.titleLg.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 300,
            child: integrations.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!
                          .translate('no_integrations'),
                      style: textStyles.bodyLg.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    itemCount: integrations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final integration = integrations[index];
                      final username = integration['username'].isNotEmpty
                          ? integration['username']
                          : AppLocalizations.of(context)!
                              .translate('no_username');
                      return Material(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            navigateToChatScreen(
                                context, integration['id'], canSendMessage);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: colors.borderSubtle.withValues(alpha: 0.7),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: colors.buttonPrimaryBg
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 20,
                                    color: colors.buttonPrimaryBg,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    username,
                                    style: textStyles.bodyLg.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: colors.iconSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: CustomButton(
              buttonText: AppLocalizations.of(context)!.translate('close'),
              onPressed: () {
                Navigator.pop(context);
              },
              buttonColor: colors.buttonSecondaryBg.withValues(alpha: 0.14),
              textColor: colors.textPrimary,
              borderColor: colors.borderSubtle,
            ),
          ),
        ],
      ),
    );
  }

  void navigateToChatScreen(
      BuildContext context, int chatId, bool canSendMessage) {
    //print('IntegrationListDialog: Navigating to chat screen with ID: $chatId, canSendMessage: $canSendMessage');
    Navigator.pop(context);
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => MessagingCubit(ApiService()),
          child: ChatSmsScreen(
            chatItem: Chats(
              id: chatId,
              image: '',
              name: leadName,
              taskFrom: "",
              taskTo: "",
              description: "",
              channel: "",
              lastMessage: "",
              messageType: "",
              createDate: "",
              unreadCount: 0,
              canSendMessage: canSendMessage,
              chatUsers: [],
            ).toChatItem(),
            chatId: chatId,
            endPointInTab: 'lead',
            canSendMessage: canSendMessage,
            initialChannelName: initialChannelName,
          ),
        ),
      ),
    );
  }
}
