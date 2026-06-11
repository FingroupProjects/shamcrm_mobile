import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/bloc/chats/groupe_chat/group_chat_bloc.dart';
import 'package:crm_task_manager/bloc/chats/groupe_chat/group_chat_event.dart';
import 'package:crm_task_manager/bloc/chats/groupe_chat/group_chat_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteChatDialog extends StatelessWidget {
  final int chatId;
  final int userId;
  final Function onUserAdded;

  DeleteChatDialog({
    required this.chatId,
    required this.userId,
    required this.onUserAdded,
  });

  String? MessageSneckbar;

  @override
  Widget build(BuildContext context) {
    return BlocListener<GroupChatBloc, GroupChatState>(
      listener: (context, state) {
        if (state is GroupChatError) {
          MessageSneckbar = state.message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${state.message}',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textInverse,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: context.appColors.error,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );
        } else if (state is GroupChatDeleted) {
          Future.delayed(Duration(seconds: 1), () {
            onUserAdded();
          });
          MessageSneckbar = state.message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${state.message}',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textInverse,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: context.appColors.success,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      child: AlertDialog(
        backgroundColor: context.appColors.surfacePrimary,
        title: Center(
          child: Text(
            AppLocalizations.of(context)!.translate('delete_user'), 
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
            ),
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.translate('confirm_delete_user'), 
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: context.appColors.textPrimary,
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('cancel'), 
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  buttonColor: context.appColors.buttonDangerBg,
                  textColor: context.appColors.buttonDangerFg,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('delete'), 
                  onPressed: () {
                    final parentContext = context;
                    final localizations = AppLocalizations.of(context)!;
                    context.read<GroupChatBloc>().add(DeleteUserFromGroup(
                          chatId: chatId,
                          userId: userId,
                          localizations: localizations,
                        ));

                    Future.delayed(Duration(seconds: 1), () {
                      Navigator.of(context).pop();
                    });

                    Future.microtask(() {
                      if (MessageSneckbar != null) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              MessageSneckbar!,
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: context.appColors.textInverse,
                              ),
                            ),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: MessageSneckbar!
                                    .contains(AppLocalizations.of(context)!
                                        .translate('deleted'))
                                ? context.appColors.success
                                : context.appColors.error,
                            elevation: 3,
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    });
                  },
                  buttonColor: context.appColors.buttonPrimaryBg,
                  textColor: context.appColors.buttonPrimaryFg,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
