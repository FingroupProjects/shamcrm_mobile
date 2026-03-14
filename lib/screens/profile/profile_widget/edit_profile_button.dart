import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/edit_profile.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_settings_tile.dart';
import 'package:flutter/material.dart';

class ProfileEdit extends StatelessWidget {
  const ProfileEdit({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileEditPage(),
          ),
        );
      },
      child: _buildPinOption(context),
    );
  }

  Widget _buildPinOption(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return ProfileSettingsTile(
      title:
          localizations?.translate('profile_editor') ?? 'Редактировать профиль',
      icon: Icons.person_outline_rounded,
    );
  }
}
