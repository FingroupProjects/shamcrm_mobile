import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

/// Диалог подтверждения выхода с несохранёнными данными
class ConfirmExitDialog extends StatelessWidget {
  final String? title;
  final String? message;
  
  const ConfirmExitDialog({
    Key? key,
    this.title,
    this.message,
  }) : super(key: key);

  /// Показать диалог подтверждения выхода
  /// Возвращает true, если пользователь подтвердил выход
  static Future<bool> show(BuildContext context, {
    String? title,
    String? message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Нельзя закрыть нажатием вне диалога
      builder: (context) => ConfirmExitDialog(
        title: title,
        message: message,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка предупреждения
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xffFF9800).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xffFF9800),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            
            // Заголовок
            Text(
              title ?? localizations.translate('exit_confirmation') ?? 'Подтверждение выхода',
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Сообщение
            Text(
              message ?? localizations.translate('unsaved_changes_message') ?? 
                'У вас есть несохранённые изменения. Вы действительно хотите выйти?',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w400,
                color: Color(0xff99A4BA),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Кнопки
            Row(
              children: [
                // Кнопка "Отмена" (остаться)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xff4759FF),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      localizations.translate('cancel') ?? 'Отмена',
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff4759FF),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Кнопка "Выйти"
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffF44336),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      localizations.translate('exit') ?? 'Выйти',
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}