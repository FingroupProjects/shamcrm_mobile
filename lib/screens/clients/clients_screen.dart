import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';

class ClientsScreen extends StatefulWidget {
  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  TextEditingController searchController = TextEditingController();

  FocusNode focusNode = FocusNode();

  bool isClickAvatarIcon = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 1,
        title: CustomAppBar(title: 'Задачи',
          onClickProfileAvatar: () {

            setState(() {
              isClickAvatarIcon = !isClickAvatarIcon;
            });

          },
          onChangedSearchInput: (value) {}, textEditingController: searchController, focusNode: focusNode,
        ),
        backgroundColor: Colors.white,
      ),
      body:  isClickAvatarIcon == true ? ProfileScreen():Center(
        child: Text(
          'Задачи',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
