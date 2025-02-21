import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/edit_profile.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_details.dart';
import 'package:flutter/material.dart';

class ProfileEdit extends StatelessWidget {

  const ProfileEdit({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileEditPage(), // Передаем user
          ),
        );
      },
      child: _buildPinOption(context),
    );
  }
  Widget _buildPinOption(BuildContext context) { // Принимаем context
    final localizations = AppLocalizations.of(context); // Получаем локализацию

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F7FD),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 223, 225, 249),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.person,
              color: Color.fromARGB(255, 91, 77, 235),
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            localizations!.translate('profile_editor'), 
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
