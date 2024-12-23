import 'package:crm_task_manager/bloc/chats/groupe_chat/group_chat_bloc.dart';
import 'package:crm_task_manager/bloc/chats/groupe_chat/group_chat_event.dart';
import 'package:crm_task_manager/bloc/user/create_cleant/create_client_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/one_user_list_.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/scheduler.dart';

class AddUserToGroupDialog extends StatefulWidget {
  final int chatId;

  const AddUserToGroupDialog({required this.chatId, super.key});


  @override
  State<AddUserToGroupDialog> createState() => _AddUserToGroupDialogState();
}

class _AddUserToGroupDialogState extends State<AddUserToGroupDialog> {
  UserData? selectedUserData;
  final TextEditingController groupNameController = TextEditingController();
  List<UserData> selectedUsers = [];

  String? groupNameError;
  String? selectedUsersError;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Center(
        child: Text(
          'Добавть участника',
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
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
                ClientRadioGroupWidget(
                  onSelectUser: (data) {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        selectedUserData = data;
                      });
                    });
                  },
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
                buttonText: 'Отмена',
                onPressed: () {
                  Navigator.of(context).pop(); // Закрываем диалог
                },
                buttonColor: Colors.red,
                textColor: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: CustomButton(
                buttonText: 'Добавить',
                onPressed: () {
                 if (selectedUserData != null) {
                  context.read<GroupChatBloc>().add(
                    AddUserToGroup(
                      chatId: widget.chatId.toString(),
                      userId: [selectedUserData!.id], // Теперь ошибка невозможна
                    ),
                  );
                } else {
                  setState(() {
                    selectedUsersError = 'Пожалуйста, выберите пользователя';
                  });
                }

                },

                buttonColor: Color(0xff1E2E52),
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return CustomButton(
      buttonText: 'Создать',
      buttonColor: AppColors.primaryBlue,
      textColor: Colors.white,
      onPressed: () {
        bool hasError = false;
        setState(() {
            if (selectedUserData == null) {
              selectedUsersError = 'Пожалуйста, выберите пользователя';
              hasError = true;
            } else {
              selectedUsersError = null;
            }

            if (!hasError) {
              context.read<CreateClientBloc>().add(
                CreateClientEv(userId: selectedUserData!.id.toString()),
              );
            }
          }
        );
        });
      }

  }
