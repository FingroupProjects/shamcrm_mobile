import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

List<TextSpan> parseHtmlToTextSpans(String html, TextStyle baseStyle) {
  // Регулярное выражение для поиска тегов
  final RegExp htmlRegExp = RegExp(
    r'<(b|i|s|a href="([^"]*)")(.*?)>(.*?)</\1>',
    multiLine: true,
    caseSensitive: false,
  );

  List<TextSpan> spans = [];
  int lastEnd = 0;

  // Находим все совпадения тегов
  for (final match in htmlRegExp.allMatches(html)) {
    // Добавляем текст до тега
    if (match.start > lastEnd) {
      spans.add(TextSpan(
        text: html.substring(lastEnd, match.start),
        style: baseStyle,
      ));
    }

    // Определяем тип тега и текст внутри
    String tag = match.group(1)!.toLowerCase();
    String content = match.group(4)!;
    String? href = tag.startsWith('a href') ? match.group(2) : null;

    // Применяем стили в зависимости от тега
    if (tag.startsWith('b')) {
      spans.add(TextSpan(
        text: content,
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      ));
    } else if (tag.startsWith('i')) {
      spans.add(TextSpan(
        text: content,
        style: baseStyle.copyWith(fontStyle: FontStyle.italic),
      ));
    } else if (tag.startsWith('s')) {
      spans.add(TextSpan(
        text: content,
        style: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
      ));
    } else if (tag.startsWith('a') && href != null) {
      spans.add(TextSpan(
        text: content,
        style: baseStyle.copyWith(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final url = Uri.parse(href);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
      ));
    }

    lastEnd = match.end;
  }

  // Добавляем оставшийся текст после последнего тега
  if (lastEnd < html.length) {
    spans.add(TextSpan(
      text: html.substring(lastEnd),
      style: baseStyle,
    ));
  }

  // Если нет тегов, возвращаем весь текст как TextSpan
  if (spans.isEmpty) {
    spans.add(TextSpan(text: html, style: baseStyle));
  }

  return spans;
}