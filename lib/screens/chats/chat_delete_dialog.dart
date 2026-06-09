import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteChatDialog extends StatefulWidget {
  final int chatId;
  final String endPointInTab;

  const DeleteChatDialog({super.key, required this.chatId, required this.endPointInTab});

  @override
  _DeleteChatDialogState createState() => _DeleteChatDialogState();
}

class _DeleteChatDialogState extends State<DeleteChatDialog> {
  String? MessageSneckbar;
  String? dialogTitle;
  String? dialogContent;
  bool? isGroupChat;
    bool? isSupportChat;

  @override
  void initState() {
    super.initState();
    _fetchChatData();
  }

Future<void> _fetchChatData() async {
    final chatData = await ApiService().getChatById(widget.chatId);
    setState(() {
      isSupportChat = chatData.type == 'support';
      
      if (isSupportChat == true) {
        return;
      }
      
      if (chatData.chatUsers.length == 2 && chatData.group == null) {
        isGroupChat = false;
        dialogTitle = AppLocalizations.of(context)!.translate('delete_chat');
        dialogContent = AppLocalizations.of(context)!.translate('comfirm_delete_chat');
      } else if (chatData.group != null) {
        isGroupChat = true;
        dialogTitle = AppLocalizations.of(context)!.translate('delete_chat_group');
        dialogContent = AppLocalizations.of(context)!.translate('comfirm_delete_chat_group');
      } else {
        isGroupChat = false;
        dialogTitle = AppLocalizations.of(context)!.translate('delete_chat');
        dialogContent = AppLocalizations.of(context)!.translate('comfirm_delete_chat');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isSupportChat == true) {
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pop();
      });
      return Container();
    }

    return isGroupChat == null
        ? Stack(
            children: [
              Container(
                color: Colors.transparent,
              ),
              Center(
                // child: CircularProgressIndicator(),
              ),
            ],
          )
        : BlocListener<ChatsBloc, ChatsState>(
            listener: (context, state) {
              if (state is ChatsError) {
                MessageSneckbar = state.message;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: context.appTextStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textInverse,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: context.appColors.error,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else if (state is ChatsDeleted) {
                final chatsBloc = context.read<ChatsBloc>();
                chatsBloc.add(ClearChats());
                chatsBloc.add(FetchChats(endPoint: widget.endPointInTab));
                MessageSneckbar = state.message;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: context.appTextStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textInverse,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: context.appColors.success,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: AlertDialog(
              backgroundColor: context.appColors.surfacePrimary,
              title: Center(
                child: Text(
                  dialogTitle ?? AppLocalizations.of(context)!.translate('delete_chat'),
                  style: context.appTextStyles.titleLg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ),
              content: Text(
                dialogContent ?? AppLocalizations.of(context)!.translate('comfirm_delete_chat'),
                style: context.appTextStyles.bodyLg.copyWith(
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
                        textColor: context.appColors.buttonPrimaryFg,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        buttonText: AppLocalizations.of(context)!.translate('delete'),
                        onPressed: () async {
                          final parentContext = context;
                            final localizations = AppLocalizations.of(context)!;


                          if (isGroupChat == true) {

                            context.read<ChatsBloc>().add(DeleteChat(widget.chatId,localizations));
                          } else {
                            context.read<ChatsBloc>().add(DeleteChat(widget.chatId,localizations));
                          }

                          Future.delayed(Duration(seconds: 1), () {
                            Navigator.of(context).pop();
                          });

                          Future.microtask(() {
                            if (MessageSneckbar != null) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    MessageSneckbar!,
                                    style: context.appTextStyles.bodyLg.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: context.appColors.textInverse,
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: MessageSneckbar!.contains(AppLocalizations.of(context)!.translate('deleted'))
                                      ? context.appColors.success
                                      : context.appColors.error,
                                  elevation: 3,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          });
                        },
                        buttonColor: context.appColors.buttonPrimaryBg,
                        textColor: context.appColors.buttonPrimaryFg,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
  }
}
