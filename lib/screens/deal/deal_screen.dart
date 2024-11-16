import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:flutter/material.dart';

class DealScreen extends StatefulWidget {
  @override
  State<DealScreen> createState() => _DealScreenState();
}

class _DealScreenState extends State<DealScreen> {
  TextEditingController searchController = TextEditingController();
  FocusNode focusNode = FocusNode();
  bool isClickAvatarIcon = false;

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 1,

        title: CustomAppBar(title: 'Сделки',
          onClickProfileAvatar: () {

            setState(() {
              isClickAvatarIcon = !isClickAvatarIcon;
            });

          },
          onChangedSearchInput: (value) {}, textEditingController: searchController, focusNode: focusNode,
        ),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Сделки',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}