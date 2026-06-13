import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/services/app_logout_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LogoutButtonWidget extends StatelessWidget {
  const LogoutButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () async {
        await AppLogoutService.logoutAndReset(context: context);
      },
      child: _buildProfileOption(
        context: context,
        iconPath: 'assets/icons/Profile/logout_new.svg',
        text: localizations!.exit,
      ),
    );
  }

  Widget _buildProfileOption({
    required BuildContext context,
    required String iconPath,
    required String text,
  }) {
    // Чистый красный цвет — без альфа-каналов, чтобы не было розового
    final Color pureRed = const Color(0xFFE53935);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pureRed,
        ),
        boxShadow: context.appShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: pureRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: pureRed,
                width: 2,
              ),
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: 22,
                height: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Gilroy',
                color: pureRed,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: pureRed,
          ),
        ],
      ),
    );
  }
}
