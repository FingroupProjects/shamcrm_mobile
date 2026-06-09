import re

with open('lib/screens/chats/chat_target_details_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
content = content.replace(
    "import 'package:flutter/material.dart';",
    "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';"
)

# Fix title
old_title = """                  Text(
                    advertising.name.isNotEmpty
                        ? advertising.name
                        : localizations.translate('advertising'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),"""

new_title = """                  GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(
                          text: advertising.name.isNotEmpty
                              ? advertising.name
                              : localizations.translate('advertising')));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
                            style: TextStyle(fontFamily: 'Gilroy'),
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Text(
                      advertising.name.isNotEmpty
                          ? advertising.name
                          : localizations.translate('advertising'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),"""
content = content.replace(old_title, new_title)

# Fix description
old_description = """                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.black87,
                      ),
                    ),"""

new_description = """                    GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(text: description));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
                              style: TextStyle(fontFamily: 'Gilroy'),
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: Colors.black87,
                        ),
                      ),
                    ),"""
content = content.replace(old_description, new_description)

# Fix InfoChip
old_infochip = """  Widget build(BuildContext context) {
    return Container("""

new_infochip = """  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: label));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
              style: TextStyle(fontFamily: 'Gilroy'),
            ),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container("""

old_infochip_end = """      ),
    );
  }
}"""

new_infochip_end = """      ),
    ));
  }
}"""

content = content.replace(old_infochip, new_infochip)
content = content.replace(old_infochip_end, new_infochip_end)

# Fix ActionTile
old_actiontile = """      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF2754C7)),"""

new_actiontile = """      child: ListTile(
        onTap: onTap,
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: subtitle));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
                style: TextStyle(fontFamily: 'Gilroy'),
              ),
              duration: Duration(seconds: 2),
            ),
          );
        },
        leading: Icon(icon, color: const Color(0xFF2754C7)),"""
content = content.replace(old_actiontile, new_actiontile)

with open('lib/screens/chats/chat_target_details_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done chat")
