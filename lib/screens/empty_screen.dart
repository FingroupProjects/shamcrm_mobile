import 'package:auto_size_text/auto_size_text.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';

class EmptyScreen extends StatefulWidget {
  @override
  _EmptyScreenState createState() => _EmptyScreenState();
}

class _EmptyScreenState extends State<EmptyScreen> {
  bool isClickAvatarIcon = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBar(
          title: isClickAvatarIcon
              ? localizations!.translate('appbar_settings')
              : "",
          onClickProfileAvatar: () {
            setState(() {
              isClickAvatarIcon = !isClickAvatarIcon;
            });
          },
          onChangedSearchInput: (input) {},
          textEditingController: TextEditingController(),
          focusNode: FocusNode(),
          clearButtonClick: (isSearching) {},
          showSearchIcon: false,
          showFilterTaskIcon: false,
          showFilterIcon: false,
          showMyTaskIcon: true,
          showEvent: false,
          showSeparateMyTasks: true,
          showMenuIcon: false,
          clearButtonClickFiltr: (bool) {},
        ),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AutoSizeText(
                    'Добро пожаловать!',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    minFontSize: 12,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Image.asset('assets/icons/shamCRM.jpg', height: 80),
                ],
              ),
            ),
    );
  }
}
