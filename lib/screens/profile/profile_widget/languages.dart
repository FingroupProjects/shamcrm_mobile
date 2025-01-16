import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/languages_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        text: localizations.language,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  localizations.selectLanguage,
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
                      ),
                      _languageOption(
                        context,
                        localizations.uzbek,
                        'assets/icons/languages/uzbek.png',
                        'uz',
                      ),
                      _languageOption(
                        context,
                        localizations.english,
                        'assets/icons/languages/usa.png',
                        'en',
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
  }

  Widget _languageOption(
    BuildContext context,
    String language,
    String iconPath,
    String languageCode,
  ) {
    return GestureDetector(
      onTap: () {
        print('Changing language to: $languageCode');
        context.read<LocaleCubit>().setLocale(Locale(languageCode));
        print('Language changed, current locale: ${context.read<LocaleCubit>().state}');
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 16),
            Text(
              language,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xFF1E1E1E),
              ),
            ),
          ],
        ),
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
}