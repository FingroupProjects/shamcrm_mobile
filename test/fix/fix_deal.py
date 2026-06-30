import re

with open('lib/screens/deal/tabBar/deal_details_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
content = content.replace(
    "import 'package:flutter/material.dart';",
    "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';"
)

# Fix _buildValue
old_build_value = """  Widget _buildValue(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xff1E2E52),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }"""

new_build_value = """  Widget _buildValue(String value) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
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
        value,
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: Color(0xff1E2E52),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }"""

content = content.replace(old_build_value, new_build_value)

# Fix status change tap
old_status = """          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openStatusChangeSheet,
            child: Row("""

new_status = """          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openStatusChangeSheet,
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: value));
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
            child: Row("""

content = content.replace(old_status, new_status)

# Fix assignees tap
old_assignees = """          return GestureDetector(
            onTap: () => _showUsersDialog(value),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,"""

new_assignees = """          return GestureDetector(
            onTap: () => _showUsersDialog(value),
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: value));
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,"""
content = content.replace(old_assignees, new_assignees)

# Fix full text dialog tap
old_fulltext = """          return GestureDetector(
            onTap: () {
              if (value.isNotEmpty) {
                _showFullTextDialog(label.replaceAll(':', ''), value);
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,"""

new_fulltext = """          return GestureDetector(
            onTap: () {
              if (value.isNotEmpty) {
                _showFullTextDialog(label.replaceAll(':', ''), value);
              }
            },
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: value));
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,"""
content = content.replace(old_fulltext, new_fulltext)

# Fix deal lead card
old_leadcard = """          return GestureDetector(
            onTap: () {
              if (currentDeal?.lead?.id != null) {
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => LeadDetailsScreen(
                      leadId: currentDeal!.lead!.id.toString(),
                      leadName: value,
                      leadStatus: "",
                      statusId: 0,
                    ),
                  ),
                );
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,"""

new_leadcard = """          return GestureDetector(
            onTap: () {
              if (currentDeal?.lead?.id != null) {
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => LeadDetailsScreen(
                      leadId: currentDeal!.lead!.id.toString(),
                      leadName: value,
                      leadStatus: "",
                      statusId: 0,
                    ),
                  ),
                );
              }
            },
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: value));
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,"""
content = content.replace(old_leadcard, new_leadcard)

with open('lib/screens/deal/tabBar/deal_details_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
