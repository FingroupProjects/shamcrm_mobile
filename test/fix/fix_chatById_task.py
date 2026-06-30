import re

with open('lib/screens/chats/chats_widgets/chatById_task_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
content = content.replace(
    "import 'package:flutter/material.dart';",
    "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';"
)

snackbar_logic = """                        Clipboard.setData(ClipboardData(text: value));
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
                        );"""

# Update buildInfoRow in chatById_task_screen
old_task_name = """        onTap: () {
          if (task.id != null && task.name.isNotEmpty) {"""

new_task_name = f"""        onLongPress: () {{
{snackbar_logic}
        }},
        onTap: () {{
          if (task.id != null && task.name.isNotEmpty) {{"""
content = content.replace(old_task_name, new_task_name)

old_normal = """    } else {
      content = Text(value, style: normalStyle);
    }"""

new_normal = f"""    }} else {{
      content = GestureDetector(
        onLongPress: () {{
{snackbar_logic}
        }},
        child: Text(value, style: normalStyle),
      );
    }}"""
content = content.replace(old_normal, new_normal)

# Update buildStatusRow
old_status = """              Text(
                task.taskStatus.taskStatus?.name ?? "no_comment",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),"""

new_status = """              GestureDetector(
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: task.taskStatus.taskStatus?.name ?? "no_comment"));
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
                  task.taskStatus.taskStatus?.name ?? "no_comment",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
              ),"""
content = content.replace(old_status, new_status)

with open('lib/screens/chats/chats_widgets/chatById_task_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done Task Profile Chats")
