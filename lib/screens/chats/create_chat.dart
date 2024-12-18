import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/bloc/chats/groupe_chat/group_chat_event.dart';
import 'package:crm_task_manager/bloc/chats/groupe_chat/group_chat_bloc.dart';
import 'package:crm_task_manager/bloc/chats/groupe_chat/group_chat_state.dart';
import 'package:crm_task_manager/bloc/user/create_cleant/create_client_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/multi_user_list.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/one_user_list_.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/scheduler.dart';

class AddClientDialog extends StatefulWidget {
  const AddClientDialog({super.key});

  @override
  State<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  UserData? selectedUserData;
  bool isGroupChat = false;
  final TextEditingController groupNameController = TextEditingController();
  List<UserData> selectedUsers = [];

  // Поля для ошибок валидации
  String? groupNameError;
  String? selectedUsersError;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Center(
        child: Text(
          'Создать чат',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Создать групповой чат',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Switch(
                    value: isGroupChat,
                    onChanged: (value) {
                      setState(() {
                        isGroupChat = value;
                        groupNameError = null;
                        selectedUsersError = null;
                      });
                    },
                    activeColor: Colors.white,
                    activeTrackColor: AppColors.primaryBlue,
                    inactiveThumbColor: Colors.black,
                    inactiveTrackColor: Colors.white,
                  )
                ],
              ),
              if (isGroupChat)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: groupNameController,
                        hintText: 'Введите название группы',
                        label: 'Название группы',
                        isPassword: false,
                        keyboardType: TextInputType.text,
                      ),
                      if (groupNameError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            groupNameError!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (isGroupChat)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserMultiSelectWidget(
                      onSelectUsers: (selectedUsersList) {
                        setState(() {
                          selectedUsers = selectedUsersList;
                          selectedUsersError = null;
                        });
                      },
                      selectedUsers: selectedUsers.isNotEmpty
                          ? selectedUsers.map((e) => e.id.toString()).toList()
                          : [],
                    ),
                    if (selectedUsersError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          selectedUsersError!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              if (!isGroupChat)
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
          children: [
            Expanded(
              child: CustomButton(
                buttonText: 'Отмена',
                onPressed: () {
                  Navigator.pop(context);
                },
                buttonColor: Colors.red,
                textColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: isGroupChat
                  ? BlocConsumer<GroupChatBloc, GroupChatState>(
                      listener: (context, state) {
                        if (state is GroupChatSuccess) {
                           WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Групповой чат успешно создан!',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.green,
                              elevation: 3,
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        });
                         
                          context.read<ChatsBloc>().add(FetchChats(endPoint: 'corporate'));
                          Navigator.pop(context);
                        }
                      },
                      builder: (context, state) {
                        if (state is GroupChatLoading) {
                          return Center(
                            child: CircularProgressIndicator(color: Color(0xff1E2E52))
                            );
                        }
                        return _buildCreateButton(context);
                      },
                    )
                  : BlocConsumer<CreateClientBloc, CreateClientState>(
                      listener: (context, state) {
                        if (state is CreateClientSuccess) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Чат с клиентом успешно создан!',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.green,
                              elevation: 3,
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        });
                          context.read<ChatsBloc>().add(FetchChats(endPoint: 'corporate'));
                          Navigator.pop(context);
                        }
                      },
                      builder: (context, state) {
                        if (state is CreateClientLoading) {
                          return Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
                        }
                        return _buildCreateButton(context);
                      },
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return CustomButton(
      buttonText: isGroupChat ? 'Создать' : 'Создать',
      onPressed: () {
        bool hasError = false;
        setState(() {
          // Validate for Group Chat
          if (isGroupChat) {
            if (groupNameController.text.isEmpty) {
              groupNameError = 'Введите название группы';
              hasError = true;
            } else {
              groupNameError = null;
            }

            if (selectedUsers.isEmpty) {
              selectedUsersError = 'Выберите хотя бы одного пользователя';
              hasError = true;
            } else {
              selectedUsersError = null;
            }

            if (!hasError) {
              context.read<GroupChatBloc>().add(
                CreateGroupChat(
                  name: groupNameController.text,
                  userId: selectedUsers.map((user) => user.id!).toList(),
                ),
              );
            }
          } else {
            // Validate for Single Client Chat
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
        });
      },
      buttonColor: AppColors.primaryBlue,
      textColor: Colors.white,
    );
  }
}