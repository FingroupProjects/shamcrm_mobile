import 'package:crm_task_manager/screens/chats/chats_widgets/chat_html_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applies bold, italic and strikethrough to the same selection', () {
    const plain = 'hello';
    var html = plain;

    html = ChatHtmlFormatter.toggleFormat(
      html: html,
      start: 0,
      end: 5,
      format: ChatTextFormat.bold,
    );
    html = ChatHtmlFormatter.toggleFormat(
      html: html,
      start: 0,
      end: 5,
      format: ChatTextFormat.italic,
    );
    html = ChatHtmlFormatter.toggleFormat(
      html: html,
      start: 0,
      end: 5,
      format: ChatTextFormat.strikethrough,
    );

    expect(html, '<s><em><strong>hello</strong></em></s>');
    expect(ChatHtmlFormatter.plainText(html), plain);

    final flags = ChatHtmlFormatter.flagsInRange(html, 0, 5);
    expect(flags.bold, isTrue);
    expect(flags.italic, isTrue);
    expect(flags.strikethrough, isTrue);
  });

  test('keeps existing formats when the user continues typing', () {
    var html = ChatHtmlFormatter.toggleFormat(
      html: 'hello',
      start: 0,
      end: 5,
      format: ChatTextFormat.bold,
    );

    html = ChatHtmlFormatter.syncPlainChange(
      html: html,
      oldPlain: 'hello',
      newPlain: 'hello!',
    );

    expect(html, '<strong>hello!</strong>');
  });

  test('toggles a single format off without dropping the others', () {
    var html = '<s><em><strong>hello</strong></em></s>';
    html = ChatHtmlFormatter.toggleFormat(
      html: html,
      start: 0,
      end: 5,
      format: ChatTextFormat.bold,
    );

    expect(html, '<s><em>hello</em></s>');
    expect(ChatHtmlFormatter.flagsInRange(html, 0, 5).bold, isFalse);
    expect(ChatHtmlFormatter.flagsInRange(html, 0, 5).italic, isTrue);
    expect(ChatHtmlFormatter.flagsInRange(html, 0, 5).strikethrough, isTrue);
  });
}
