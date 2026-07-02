import 'package:auto_size_text/auto_size_text.dart';
import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EmptyScreen extends StatefulWidget {
  const EmptyScreen({super.key});

  @override
  State<EmptyScreen> createState() => _EmptyScreenState();
}

class _EmptyScreenState extends State<EmptyScreen> {
  bool isClickAvatarIcon = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final themeController = context.watch<AppThemeController>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBar(
          title: isClickAvatarIcon
              ? localizations!.translate('appbar_settings')
              : localizations!.translate('appbar_dashboard'),
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
          showCallCenter: true,
          showEvent: false,
          showSeparateMyTasks: false,
          showMenuIcon: true,
          showCalendarDashboard: false,
          clearButtonClickFiltr: (_) {},
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AppBackgroundOverlay(
            preset: themeController.backgroundPreset == AppBackgroundPreset.none
                ? AppBackgroundPreset.aurora
                : themeController.backgroundPreset,
            imagePath: themeController.backgroundImagePath,
            assetPath: themeController.backgroundAssetPath,
            blurSigma: themeController.backgroundBlurSigma,
          ),
          if (isClickAvatarIcon)
            ProfileScreen()
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AutoSizeText(
                      AppLocalizations.of(context)!.translate('welcome'),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Gilroy',
                        color: context.appColors.textPrimary,
                      ),
                      maxLines: 1,
                      minFontSize: 12,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Image.asset(
                      'assets/icons/newLogo.png',
                      height: 92,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
