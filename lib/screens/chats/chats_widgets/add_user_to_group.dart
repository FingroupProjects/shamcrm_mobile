import 'package:crm_task_manager/bloc/chats/groupe_chat/group_chat_bloc.dart';
import 'package:crm_task_manager/bloc/chats/groupe_chat/group_chat_event.dart';
import 'package:crm_task_manager/bloc/chats/groupe_chat/group_chat_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/user_list_group.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/scheduler.dart';

class AddUserToGroupDialog extends StatefulWidget {
  final int chatId;
  final Function onUserAdded;

  const AddUserToGroupDialog(
      {required this.chatId, required this.onUserAdded, super.key});

  @override
  State<AddUserToGroupDialog> createState() => _AddUserToGroupDialogState();
}

class _AddUserToGroupDialogState extends State<AddUserToGroupDialog> {
  UserData? selectedUserData;
  final TextEditingController groupNameController = TextEditingController();
  List<UserData> selectedUsers = [];

  String? groupNameError;
  String? selectedUsersError;
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
                AppLocalizations.of(context)!.translate(state.message),
                style: context.appTextStyles.bodyMd.copyWith(
                  color: context.appColors.textInverse,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
        } else if (state is GroupChatSuccess) {
          MessageSneckbar = state.message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),
                style: context.appTextStyles.bodyMd.copyWith(
                  color: context.appColors.textInverse,
                ),
                    maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
          Future.delayed(Duration(seconds: 1), () {
            widget.onUserAdded();
          });
        }
      },
      child: AlertDialog(
        backgroundColor: context.appColors.surfacePrimary,
        title: Center(
          child: Text(
            AppLocalizations.of(context)!.translate('add_user'),
            style: context.appTextStyles.titleMd.copyWith(
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
            ),
          ),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UserListGroup(
                  onSelectUser: (data) {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        selectedUserData = data;
                      });
                    });
                  }, chatId: widget.chatId.toString(),
                ),
                if (selectedUsersError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      selectedUsersError!,
                      style: context.appTextStyles.bodySm.copyWith(
                        color: context.appColors.error,
                      ),
                    ),
                  ),
              ],
            ),
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
                  buttonText: AppLocalizations.of(context)!.translate('add'),
                  onPressed: () {
                    if (selectedUserData != null) {
                        final localizations = AppLocalizations.of(context)!;

                      context.read<GroupChatBloc>().add(
                            AddUserToGroup(
                              chatId: widget.chatId,
                              userId: selectedUserData!.id,
                              localizations: localizations,
                            ),
                          );

                      Future.delayed(Duration(seconds: 1), () {
                        widget.onUserAdded();
                      });

                      Navigator.of(context).pop();
                  } else {
                    setState(() {
                      selectedUsersError = AppLocalizations.of(context)!
                          .translate('please_select_user');
                    });
                  }
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
