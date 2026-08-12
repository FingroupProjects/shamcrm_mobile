import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/app/my_app.dart';
import 'package:crm_task_manager/screens/profile/languages/local_manager_lang.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_localizations.dart';

class LanguageButtonWidget extends StatelessWidget {
  const LanguageButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () {
        _showLanguageDialog(context);
      },
      child: _buildProfileOption(
        context: context,
        iconPath: 'assets/icons/languages/global2.png',
        text: localizations!.language,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<String?>(
          future: LanguageManager.getLanguage(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.appColors.buttonPrimaryBg,
                  ),
                ),
              );
            }

            // Если язык не выбран, по умолчанию выбираем русский
            final currentLanguage = snapshot.data ?? 'ru';

            return Dialog(
              backgroundColor: context.appColors.surfacePrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      localizations!.selectLanguage,
                      style: TextStyle(
                        color: context.appColors.textPrimary,
                        fontSize: 18,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    constraints: BoxConstraints(maxHeight: 400),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _languageOption(
                            context,
                            localizations.russian,
                            'assets/icons/languages/russian.png',
                            'ru',
                            currentLanguage,
                          ),
                          _languageOption(
                            context,
                            localizations.uzbek,
                            'assets/icons/languages/uzbek.png',
                            'uz',
                            currentLanguage,
                          ),
                          _languageOption(
                            context,
                            localizations.english,
                            'assets/icons/languages/usa.png',
                            'en',
                            currentLanguage,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: CustomButton(
                      buttonText: localizations.close,
                      onPressed: () => Navigator.pop(context),
                      buttonColor: context.appColors.buttonPrimaryBg,
                      textColor: context.appColors.buttonPrimaryFg,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _languageOption(BuildContext context, String language, String iconPath,
      String languageCode, String currentLanguage) {
    final isSelected = currentLanguage == languageCode;

    return ListTile(
      tileColor: context.appColors.surfacePrimary,
      leading: Image.asset(iconPath, width: 24, height: 24),
      title: Text(
        language,
        style: TextStyle(color: context.appColors.textPrimary),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: context.appColors.buttonPrimaryBg)
          : null,
      onTap: () {
        _changeLanguage(context, languageCode);
        Navigator.pop(context); // Закрыть диалог сразу после выбора языка
      },
    );
  }

  void _changeLanguage(BuildContext context, String languageCode) async {
    try {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(
              color: Color(0xff1E2E52),
            ),
          );
        },
      );

      // ✅ Отправляем POST запрос на сервер для смены языка
      final apiService = context.read<ApiService>();
      final success = await apiService.changeLanguage(languageCode);

      if (success) {
        debugPrint(
            'LanguageButtonWidget: Язык успешно изменён на сервере: $languageCode');

        // Применяем язык локально
        Locale newLocale = Locale(languageCode);
        MyApp.setLocale(context, newLocale);
        await LanguageManager.saveLanguage(languageCode);

        // Закрываем индикатор загрузки
        if (context.mounted) {
          Navigator.pop(context);
        }

        debugPrint('LanguageButtonWidget: Язык применён локально');
      } else {
        debugPrint('LanguageButtonWidget: Не удалось изменить язык на сервере');

        // Закрываем индикатор загрузки
        if (context.mounted) {
          Navigator.pop(context);
        }

        // Показываем сообщение об ошибке
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)
                        ?.translate('language_change_error') ??
                    'Ошибка при изменении языка',
              ),
              backgroundColor: context.appColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('LanguageButtonWidget: Ошибка при смене языка: $e');

      // Закрываем индикатор загрузки
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Показываем сообщение об ошибке
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                      ?.translate('language_change_error') ??
                  'Ошибка при изменении языка',
            ),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }
  }
}

Widget _buildProfileOption({
  required BuildContext context,
  required String iconPath,
  required String text,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: context.appColors.surfacePrimary.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: context.appColors.borderSubtle.withValues(alpha: 0.42),
      ),
      boxShadow: context.appShadows.card,
    ),
    child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.appColors.surfaceAccent.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.language,
                color: context.appColors.buttonPrimaryBg,
                size: 22,
              ),
            ),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: context.appColors.textPrimary,
            ),
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: context.appColors.iconSecondary,
        ),
      ],
    ),
  );
}
