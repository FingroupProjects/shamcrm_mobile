import re

with open('lib/screens/event/event_details/event_details_screen.dart', 'r', encoding='utf-8') as f:
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
      ),
    );
  }"""

content = content.replace(old_build_value, new_build_value)

# Fix assignees tap
old_assignees = """      if (label == AppLocalizations.of(context)!.translate('assignees')) {
        return GestureDetector(
          onTap: () => _showUsersDialog(value),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,"""

new_assignees = """      if (label == AppLocalizations.of(context)!.translate('assignees')) {
        return GestureDetector(
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

# Fix lead_name tap
old_leadname = """      if (label == AppLocalizations.of(context)!.translate('lead_name')) {
        return GestureDetector(
          onTap: () {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => LeadDetailsScreen(
                  leadId: leadId.toString(),
                  leadName: value,
                  leadStatus: "",
                  statusId: 1,
                ),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,"""

new_leadname = """      if (label == AppLocalizations.of(context)!.translate('lead_name')) {
        return GestureDetector(
          onTap: () {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => LeadDetailsScreen(
                  leadId: leadId.toString(),
                  leadName: value,
                  leadStatus: "",
                  statusId: 1,
                ),
              ),
            );
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
content = content.replace(old_leadname, new_leadname)

# Fix body tap
old_body = """      if (label == AppLocalizations.of(context)!.translate('body')) {
        return GestureDetector(
          onTap: () => _showFullTextDialog(label.replaceAll(':', ''), value),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,"""

new_body = """      if (label == AppLocalizations.of(context)!.translate('body')) {
        return GestureDetector(
          onTap: () => _showFullTextDialog(label.replaceAll(':', ''), value),
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
content = content.replace(old_body, new_body)

# Fix conclusions tap
old_conclusions = """      if (label == AppLocalizations.of(context)!.translate('conclusions')) {
        return GestureDetector(
          onTap: () => _showFullTextDialog(label.replaceAll(':', ''), value),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,"""

new_conclusions = """      if (label == AppLocalizations.of(context)!.translate('conclusions')) {
        return GestureDetector(
          onTap: () => _showFullTextDialog(label.replaceAll(':', ''), value),
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
content = content.replace(old_conclusions, new_conclusions)

with open('lib/screens/event/event_details/event_details_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done event")
