import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:html/parser.dart' show parse;

// Функция для удаления HTML тегов и получения чистого текста
String _stripHtmlTags(String html) {
  if (!html.contains('<') || !html.contains('>')) {
    return html; // Если нет HTML тегов, возвращаем как есть
  }
  
  try {
    final document = parse(html);
    return document.body?.text ?? html.replaceAll(RegExp(r'<[^>]*>'), '');
  } catch (e) {
    // Если парсинг не удался, используем регулярное выражение
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

class PinnedMessageWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onUnpin;
  final VoidCallback? onTap; // Добавляем обработчик нажатия

  const PinnedMessageWidget({
    super.key,
   required this.message,
     this.onUnpin,
    this.onTap, // Передаем обработчик нажатия
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Теперь весь контейнер кликабельный
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
        decoration: BoxDecoration(
          color: context.appColors.surfacePrimary,
          border: Border.all(
            color: context.appColors.borderSubtle,
            width: 1,
          ),//Обращение на аккаунта
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: ChatSmsStyles.messageBubbleSenderColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.translate('pinned_message'), 
                    style: context.appTextStyles.bodyLg.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ChatSmsStyles.messageBubbleSenderColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stripHtmlTags(message),
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textPrimary,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onUnpin,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: context.appColors.surfacePrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: SvgPicture.asset(
                  'assets/icons/chats/menu_icons/pin.svg',
                  width: 28,
                  height: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
