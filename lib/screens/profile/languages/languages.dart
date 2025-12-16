import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/main.dart';
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
              return Center(child: CircularProgressIndicator());
            }

            // Если язык не выбран, по умолчанию выбираем русский
            final currentLanguage = snapshot.data ?? 'ru';

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      localizations!.selectLanguage,
                      style: TextStyle(
                        color: Color(0xff1E2E52),
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
                      buttonColor: Color(0xff1E2E52),
                      textColor: Colors.white,
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

  Widget _languageOption(BuildContext context, String language, String iconPath, String languageCode, String currentLanguage) {
    final isSelected = currentLanguage == languageCode;

    return ListTile(
      leading: Image.asset(iconPath, width: 24, height: 24),
      title: Text(language),
      trailing: isSelected
          ? Icon(Icons.check, color: Color(0xff1E2E52))
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
        debugPrint('LanguageButtonWidget: Язык успешно изменён на сервере: $languageCode');
        
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
              content: Text('Ошибка при изменении языка'),
              backgroundColor: Colors.red,
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
            content: Text('Ошибка при изменении языка'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
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
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 223, 225, 249),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.language,
              color: Color.fromARGB(255, 91, 77, 235),
              size: 24,
            ),
          ),
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