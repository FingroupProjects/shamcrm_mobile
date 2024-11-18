import 'package:crm_task_manager/bloc/user/create_cleant/create_client_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/client_item_widget.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BottomSheetAddClientDialog extends StatefulWidget {
  const BottomSheetAddClientDialog({super.key});

  @override
  State<BottomSheetAddClientDialog> createState() =>
      _BottomSheetAddClientDialogState();
}

class _BottomSheetAddClientDialogState
    extends State<BottomSheetAddClientDialog> {
  UserData? selectUserData;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            'Добавить клиента',
            style: TextStyle(color: AppColors.primaryBlue),
          ),
          heroTag: 'bottomSheetClients',
          transitionBetweenRoutes: false,
          automaticallyImplyLeading: false,
          trailing: CupertinoButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Закрывать',
              style: TextStyle(fontSize: 11, color: AppColors.primaryBlue),
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: MediaQuery.of(context).size.height,
            padding: EdgeInsets.only(top: 12),
            color: Colors.white,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * .7,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ClientRadioGroupWidget(
                      onSelectUser: (data) {
                        selectUserData = data;
                      },
                    ),
                  ),
                  Column(
                    children: [
                      BlocConsumer<CreateClientBloc, CreateClientState>(
                        builder: (context, state) {
                          if (state is CreateClientLoading) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (state is CreateClientError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(state.message)),
                            );
                          }

                          return CustomButton(
                            buttonText: 'Сохранить',
                            onPressed: () {
                              if(selectUserData != null) {
                                context.read<CreateClientBloc>().add(CreateClientEv(userId: selectUserData!.id.toString()));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Пожалуйста, выберите пользователя')),
                                );
                              }
                            },
                            buttonColor: AppColors.primaryBlue,
                            textColor: AppColors.backgroundPrimaryWhite100,
                          );
                        }, listener: (BuildContext context, CreateClientState state) {
                          if(state is CreateClientSuccess) {
                            Navigator.pop(context);
                          }
                      },
                      ),
                      SizedBox(
                        height: 40,
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
