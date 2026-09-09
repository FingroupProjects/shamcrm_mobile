import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

enum ChatTextFormat { bold, italic, strikethrough }

class ChatFormatFlags {
  const ChatFormatFlags({
    this.bold = false,
    this.italic = false,
    this.strikethrough = false,
    this.link = false,
  });

  final bool bold;
  final bool italic;
  final bool strikethrough;
  final bool link;
}

class _Style {
  const _Style({
    this.bold = false,
    this.italic = false,
    this.strike = false,
    this.href,
  });

  final bool bold;
  final bool italic;
  final bool strike;
  final String? href;

  _Style copyWith({
    bool? bold,
    bool? italic,
    bool? strike,
    String? href,
    bool clearHref = false,
  }) {
    return _Style(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      strike: strike ?? this.strike,
      href: clearHref ? null : (href ?? this.href),
    );
  }

  bool matches(_Style other) {
    return bold == other.bold &&
        italic == other.italic &&
        strike == other.strike &&
        href == other.href;
  }
}

class _StyledChar {
  _StyledChar(this.char, this.style);

  final String char;
  _Style style;
}

class ChatHtmlFormatter {
  static const _blockTags = {
    'p',
    'div',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'blockquote',
    'li',
  };

  static String plainText(String html) {
    return _parseToChars(html).map((char) => char.char).join();
  }

  static ChatFormatFlags flagsInRange(String html, int start, int end) {
    final chars = _parseToChars(html);
    final range = _clampRange(start, end, chars.length);
    if (range.start >= range.end) {
      return const ChatFormatFlags();
    }

    final selected = chars.sublist(range.start, range.end);
    return ChatFormatFlags(
      bold: selected.every((char) => char.style.bold),
      italic: selected.every((char) => char.style.italic),
      strikethrough: selected.every((char) => char.style.strike),
      link: selected.every((char) => (char.style.href ?? '').isNotEmpty),
    );
  }

  static String toggleFormat({
    required String html,
    required int start,
    required int end,
    required ChatTextFormat format,
  }) {
    final chars = _parseToChars(html);
    final range = _clampRange(start, end, chars.length);
    if (range.start >= range.end) {
      return serialize(chars);
    }

    final selected = chars.sublist(range.start, range.end);
    final alreadyApplied = switch (format) {
      ChatTextFormat.bold => selected.every((char) => char.style.bold),
      ChatTextFormat.italic => selected.every((char) => char.style.italic),
      ChatTextFormat.strikethrough =>
        selected.every((char) => char.style.strike),
    };

    for (var i = range.start; i < range.end; i++) {
      final style = chars[i].style;
      chars[i].style = switch (format) {
        ChatTextFormat.bold => style.copyWith(bold: !alreadyApplied),
        ChatTextFormat.italic => style.copyWith(italic: !alreadyApplied),
        ChatTextFormat.strikethrough => style.copyWith(strike: !alreadyApplied),
      };
    }

    return serialize(chars);
  }

  static String applyLink({
    required String html,
    required int start,
    required int end,
    required String url,
  }) {
    final chars = _parseToChars(html);
    final range = _clampRange(start, end, chars.length);
    if (range.start >= range.end) {
      return serialize(chars);
    }

    final normalized = url.trim();
    for (var i = range.start; i < range.end; i++) {
      chars[i].style = chars[i].style.copyWith(href: normalized);
    }
    return serialize(chars);
  }

  static String replacePlainRange({
    required String html,
    required int start,
    required int end,
    required String replacement,
  }) {
    final chars = _parseToChars(html);
    final range = _clampRange(start, end, chars.length);
    final inherit = range.start < chars.length
        ? chars[range.start].style
        : (range.start > 0 ? chars[range.start - 1].style : const _Style());

    final inserted = <_StyledChar>[
      for (var i = 0; i < replacement.length; i++)
        _StyledChar(replacement[i], inherit),
    ];
    chars.replaceRange(range.start, range.end, inserted);
    return serialize(chars);
  }

  static String syncPlainChange({
    required String html,
    required String oldPlain,
    required String newPlain,
  }) {
    if (oldPlain == newPlain) {
      return html;
    }
    if (oldPlain.isEmpty) {
      return _escapeText(newPlain);
    }
    if (newPlain.isEmpty) {
      return '';
    }

    var prefix = 0;
    final maxPrefix = oldPlain.length < newPlain.length
        ? oldPlain.length
        : newPlain.length;
    while (prefix < maxPrefix && oldPlain[prefix] == newPlain[prefix]) {
      prefix++;
    }

    var oldSuffix = oldPlain.length;
    var newSuffix = newPlain.length;
    while (oldSuffix > prefix &&
        newSuffix > prefix &&
        oldPlain[oldSuffix - 1] == newPlain[newSuffix - 1]) {
      oldSuffix--;
      newSuffix--;
    }

    return replacePlainRange(
      html: html,
      start: prefix,
      end: oldSuffix,
      replacement: newPlain.substring(prefix, newSuffix),
    );
  }

  static TextSpan buildTextSpan({
    required String html,
    required String plainText,
    TextStyle? style,
    TextRange composing = TextRange.empty,
  }) {
    final chars = _parseToChars(html);
    final parsedPlain = chars.map((char) => char.char).join();
    if (parsedPlain != plainText) {
      return _plainSpan(plainText, style, composing);
    }
    if (chars.isEmpty) {
      return TextSpan(style: style, text: '');
    }

    final children = <InlineSpan>[];
    var runStart = 0;
    var runStyle = chars.first.style;

    void flush(int runEnd) {
      if (runStart >= runEnd) {
        return;
      }
      children.addAll(
        _spansForRun(
          text: parsedPlain.substring(runStart, runEnd),
          runStart: runStart,
          style: style,
          charStyle: runStyle,
          composing: composing,
        ),
      );
    }

    for (var i = 1; i < chars.length; i++) {
      if (!chars[i].style.matches(runStyle)) {
        flush(i);
        runStart = i;
        runStyle = chars[i].style;
      }
    }
    flush(chars.length);

    return TextSpan(style: style, children: children);
  }

  static String serialize(List<_StyledChar> chars) {
    if (chars.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    var runStart = 0;
    var runStyle = chars.first.style;

    void flush(int runEnd) {
      if (runStart >= runEnd) {
        return;
      }
      var inner = _escapeText(
        chars.sublist(runStart, runEnd).map((char) => char.char).join(),
      );
      if (runStyle.bold) {
        inner = '<strong>$inner</strong>';
      }
      if (runStyle.italic) {
        inner = '<em>$inner</em>';
      }
      if (runStyle.strike) {
        inner = '<s>$inner</s>';
      }
      final href = runStyle.href;
      if (href != null && href.isNotEmpty) {
        inner =
            '<a href="${_escapeAttribute(href)}" target="_blank">$inner</a>';
      }
      buffer.write(inner);
    }

    for (var i = 1; i < chars.length; i++) {
      if (!chars[i].style.matches(runStyle)) {
        flush(i);
        runStart = i;
        runStyle = chars[i].style;
      }
    }
    flush(chars.length);
    return buffer.toString();
  }

  static List<_StyledChar> _parseToChars(String html) {
    if (html.isEmpty) {
      return [];
    }
    if (!html.contains('<')) {
      return [
        for (var i = 0; i < html.length; i++) _StyledChar(html[i], const _Style()),
      ];
    }

    final chars = <_StyledChar>[];
    final document = html_parser.parse(html);

    void addText(String text, _Style style) {
      for (var i = 0; i < text.length; i++) {
        chars.add(_StyledChar(text[i], style));
      }
    }

    void walk(dom.Node node, _Style style) {
      if (node is dom.Text) {
        addText(node.text, style);
        return;
      }
      if (node is! dom.Element) {
        return;
      }

      final name = node.localName ?? '';
      if (name == 'br') {
        addText('\n', style);
        return;
      }

      var next = style;
      if (name == 'strong' || name == 'b') {
        next = next.copyWith(bold: true);
      } else if (name == 'em' || name == 'i') {
        next = next.copyWith(italic: true);
      } else if (name == 's' || name == 'strike' || name == 'del') {
        next = next.copyWith(strike: true);
      } else if (name == 'a') {
        next = next.copyWith(href: node.attributes['href']);
      }

      if (_blockTags.contains(name) &&
          chars.isNotEmpty &&
          chars.last.char != '\n') {
        addText('\n', style);
      }

      for (final child in node.nodes) {
        walk(child, next);
      }
    }

    final body = document.body;
    if (body != null) {
      for (final child in body.nodes) {
        walk(child, const _Style());
      }
    }
    return chars;
  }

  static ({int start, int end}) _clampRange(int start, int end, int length) {
    final safeStart = start.clamp(0, length);
    final safeEnd = end.clamp(safeStart, length);
    return (start: safeStart, end: safeEnd);
  }

  static String _escapeText(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  static String _escapeAttribute(String value) {
    return value.replaceAll('&', '&amp;').replaceAll('"', '&quot;');
  }

  static TextSpan _plainSpan(
    String text,
    TextStyle? style,
    TextRange composing,
  ) {
    if (!composing.isValid || !composing.isNormalized) {
      return TextSpan(style: style, text: text);
    }
    return TextSpan(
      style: style,
      children: [
        TextSpan(text: text.substring(0, composing.start)),
        TextSpan(
          text: text.substring(composing.start, composing.end),
          style: const TextStyle(decoration: TextDecoration.underline),
        ),
        TextSpan(text: text.substring(composing.end)),
      ],
    );
  }

  static List<InlineSpan> _spansForRun({
    required String text,
    required int runStart,
    required TextStyle? style,
    required _Style charStyle,
    required TextRange composing,
  }) {
    final decorations = <TextDecoration>[
      if (charStyle.strike) TextDecoration.lineThrough,
      if ((charStyle.href ?? '').isNotEmpty) TextDecoration.underline,
    ];

    final runStyle = (style ?? const TextStyle()).copyWith(
      fontWeight: charStyle.bold ? FontWeight.bold : style?.fontWeight,
      fontStyle: charStyle.italic ? FontStyle.italic : style?.fontStyle,
      decoration: decorations.isEmpty ? null : TextDecoration.combine(decorations),
      decorationColor: decorations.isEmpty ? null : style?.color,
      color: (charStyle.href ?? '').isNotEmpty
          ? style?.color
          : style?.color,
    );

    final runEnd = runStart + text.length;
    if (!composing.isValid ||
        composing.start >= runEnd ||
        composing.end <= runStart) {
      return [TextSpan(text: text, style: runStyle)];
    }

    final localStart = (composing.start - runStart).clamp(0, text.length);
    final localEnd = (composing.end - runStart).clamp(0, text.length);
    return [
      if (localStart > 0)
        TextSpan(text: text.substring(0, localStart), style: runStyle),
      TextSpan(
        text: text.substring(localStart, localEnd),
        style: runStyle.copyWith(
          decoration: TextDecoration.combine([
            ...decorations,
            TextDecoration.underline,
          ]),
        ),
      ),
      if (localEnd < text.length)
        TextSpan(text: text.substring(localEnd), style: runStyle),
    ];
  }
}

class ChatComposerController extends TextEditingController {
  ChatComposerController({String? text, String htmlContent = ''})
      : _htmlContent = htmlContent,
        super(text: text);

  String _htmlContent;

  String get htmlContent => _htmlContent;

  set htmlContent(String value) {
    if (_htmlContent == value) {
      return;
    }
    _htmlContent = value;
    notifyListeners();
  }

  @override
  void clear() {
    _htmlContent = '';
    super.clear();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return ChatHtmlFormatter.buildTextSpan(
      html: _htmlContent,
      plainText: text,
      style: style,
      composing: withComposing ? value.composing : TextRange.empty,
    );
  }
}
