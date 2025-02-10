import 'dart:io';

import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/auth/auth_screen.dart';
import 'dart:ui' as ui; // Добавьте этот импорт

class LogoutButtonWidget extends StatelessWidget {
  const LogoutButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () async {
   ApiService apiService = ApiService();
    await apiService.logoutAccount();
        // Очистка SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token') ?? '';
        print('------=-=--=-==--=-=-=-=-=-=-TOKEN LOGOUT =-=-=-==--=-=-=-=-==--==-=-');
        print(token);
        await prefs.clear();


        await apiService.logout();


      //  await Future.delayed(Duration(seconds: 2)); // Задержка в 2 секунды

        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(builder: (context) => AuthScreen()),
        //   (Route<dynamic> route) => false,
        // );
   Restart.restartApp();

       
    exit(0);

             
      //  ui.window.onBeginFrame = null;
      //   ui.window.onDrawFrame = null;
        // main();
      },
      child: _buildProfileOption(
        iconPath: 'assets/icons/Profile/logout.png',
        text: localizations!.exit,
      ),
    );
  }

  Widget _buildProfileOption({required String iconPath, required String text}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Image.asset(
            iconPath,
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xFF1E1E1E),
              ),
            ),
          ),
          Image.asset(
            'assets/icons/arrow-right.png',
            width: 16,
            height: 16,
          ),
        ],
      ),
    );
  }
}