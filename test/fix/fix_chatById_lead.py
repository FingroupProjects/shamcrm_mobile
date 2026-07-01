import re

with open('lib/screens/chats/chats_widgets/chatById_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
content = content.replace(
    "import 'package:flutter/material.dart';",
    "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';"
)

snackbar_logic = """        onLongPress: () {
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
        },"""

# Patch all GestureDetectors in buildInfoRow
# 1. name
content = content.replace(
"""      content = GestureDetector(
        onTap: () {
          if (profile.id != null && profile.name.isNotEmpty) {""",
f"""      content = GestureDetector(
{snackbar_logic}
        onTap: () {{
          if (profile.id != null && profile.name.isNotEmpty) {{"""
)

# 2. phone
content = content.replace(
"""      content = GestureDetector(
        onTap: () => _makePhoneCall(value),""",
f"""      content = GestureDetector(
{snackbar_logic}
        onTap: () => _makePhoneCall(value),"""
)

# 3. whatsapp
content = content.replace(
"""      content = GestureDetector(
        onTap: () => _openWhatsApp(value),""",
f"""      content = GestureDetector(
{snackbar_logic}
        onTap: () => _openWhatsApp(value),"""
)

# 4. telegram
content = content.replace(
"""      content = GestureDetector(
        onTap: () => _openTelegram(value),""",
f"""      content = GestureDetector(
{snackbar_logic}
        onTap: () => _openTelegram(value),"""
)

# 5. instagram
content = content.replace(
"""      content = GestureDetector(
        onTap: () => _openInstagram(value),""",
f"""      content = GestureDetector(
{snackbar_logic}
        onTap: () => _openInstagram(value),"""
)

# 6. facebook
content = content.replace(
"""      content = GestureDetector(
        onTap: () => _openFacebook(value),""",
f"""      content = GestureDetector(
{snackbar_logic}
        onTap: () => _openFacebook(value),"""
)

# 7. else block
content = content.replace(
"""    } else {
      content = Text(value, style: normalStyle);
    }""",
f"""    }} else {{
      content = GestureDetector(
{snackbar_logic}
        child: Text(value, style: normalStyle),
      );
    }}"""
)


# Update buildStatusRow
old_status = """              Text(
                profile.leadStatus?.title ?? 'Не указано',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),"""

new_status = """              GestureDetector(
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: profile.leadStatus?.title ?? 'Не указано'));
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
                  profile.leadStatus?.title ?? 'Не указано',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
              ),"""
content = content.replace(old_status, new_status)


# Update manager
old_manager = """                                      Text(
                                        profile.manager!.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Gilroy',
                                          color: Color(0xff1E2E52),
                                        ),
                                      )"""

new_manager = """                                      GestureDetector(
                                        onLongPress: () {
                                          Clipboard.setData(ClipboardData(text: profile.manager!.name));
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
                                          profile.manager!.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Gilroy',
                                            color: Color(0xff1E2E52),
                                          ),
                                        ),
                                      )"""
content = content.replace(old_manager, new_manager)


with open('lib/screens/chats/chats_widgets/chatById_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done Lead Profile Chats")
