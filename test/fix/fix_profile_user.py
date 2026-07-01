import re

with open('lib/screens/chats/chats_widgets/profile_user_corporate.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
content = content.replace(
    "import 'package:flutter/material.dart';",
    "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';"
)

old_text_1 = """              title == "Номер телефона" || title == "Email"
                  ? GestureDetector(
                      onTap: () {
                        if (title == "Номер телефона") {
                          _makePhoneCall(value);
                        } else if (title == "Email") {
                          _sendEmail(value);
                        }
                      },
                      child: Text(
                        value,"""

new_text_1 = """              title == "Номер телефона" || title == "Email"
                  ? GestureDetector(
                      onTap: () {
                        if (title == "Номер телефона") {
                          _makePhoneCall(value);
                        } else if (title == "Email") {
                          _sendEmail(value);
                        }
                      },
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(
                        value,"""
content = content.replace(old_text_1, new_text_1)


old_text_2 = """                  : Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                    ),"""

new_text_2 = """                  : GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                      ),
                    ),"""
content = content.replace(old_text_2, new_text_2)

with open('lib/screens/chats/chats_widgets/profile_user_corporate.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done profile user")




