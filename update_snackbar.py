import re

files = [
    'lib/screens/lead/tabBar/lead_details_screen.dart',
    'lib/screens/task/task_details/task_details_screen.dart',
    'lib/screens/deal/tabBar/deal_details_screen.dart',
    'lib/screens/event/event_details/event_details_screen.dart',
    'lib/screens/chats/chat_target_details_screen.dart',
]

old_snackbar = """        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
              style: TextStyle(fontFamily: 'Gilroy'),
            ),
            duration: Duration(seconds: 2),
          ),
        );"""

old_snackbar_2 = """              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
                    style: TextStyle(fontFamily: 'Gilroy'),
                  ),
                  duration: Duration(seconds: 2),
                ),
              );"""

old_snackbar_3 = """            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
                  style: TextStyle(fontFamily: 'Gilroy'),
                ),
                duration: Duration(seconds: 2),
              ),
            );"""

old_snackbar_4 = """                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
                            style: TextStyle(fontFamily: 'Gilroy'),
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );"""

def replace_indent(match, indent):
    new_snack = f"""{indent}ScaffoldMessenger.of(context).showSnackBar(
{indent}  SnackBar(
{indent}    content: Text(
{indent}      AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
{indent}      style: const TextStyle(
{indent}        fontFamily: 'Gilroy',
{indent}        fontSize: 15,
{indent}        fontWeight: FontWeight.w500,
{indent}        color: Colors.white,
{indent}      ),
{indent}    ),
{indent}    backgroundColor: Colors.green,
{indent}    behavior: SnackBarBehavior.floating,
{indent}    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
{indent}    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
{indent}    duration: const Duration(seconds: 2),
{indent}  ),
{indent});"""
    return new_snack

for file in files:
    try:
        with open(file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Find all ScaffoldMessenger patterns dynamically to match any indentation
        pattern = r"(\s*)ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\(\s*AppLocalizations\.of\(context\)\?\.translate\('copied_to_clipboard'\)\s*\?\?\s*'Скопировано',\s*style:\s*TextStyle\(fontFamily:\s*'Gilroy'\),\s*\),\s*duration:\s*Duration\(seconds:\s*2\),\s*\),\s*\);"
        
        content = re.sub(pattern, lambda m: replace_indent(m, m.group(1)), content)

        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)
            
        print(f"Updated {file}")
    except Exception as e:
        print(f"Error updating {file}: {e}")

print("Done updating SnackBars")
