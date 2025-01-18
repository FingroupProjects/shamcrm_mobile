import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_state.dart';

class UserFilterPopup extends StatelessWidget {
  final Function(dynamic)? onUserSelected;

  const UserFilterPopup({
    Key? key,
    this.onUserSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      constraints: BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Выберите пользователя',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E2E52),
                  ),
                ),
              ],
            ),
          ),
          Container(
            constraints: BoxConstraints(maxHeight: 300),
            child: BlocBuilder<UserTaskBloc, UserTaskState>(
              builder: (context, state) {
                if (state is UserTaskLoading) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: Color(0xff1E2E52)),
                    ),
                  );
                } else if (state is UserTaskError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        state.message,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                } else if (state is UserTaskLoaded) {
                  final users = state.users;
                  if (users.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Нет доступных пользователей',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: users.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return InkWell(
                          onTap: () {
                            if (onUserSelected != null) {
                              onUserSelected!(null);
                            }
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFFEEEEEE),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Text(
                              'Все',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E2E52),
                              ),
                            ),
                          ),
                        );
                      }
                      final user = users[index - 1];
                      final name = user.name.isNotEmpty ? user.name : 'Без имени';
                      final lastname = user.lastname.isNotEmpty ? user.lastname : '';
                      return InkWell(
                        onTap: () {
                          if (onUserSelected != null) {
                            onUserSelected!(user);
                          }
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            '$name $lastname',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 14,
                              color: Color(0xFF1E2E52),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }
}
