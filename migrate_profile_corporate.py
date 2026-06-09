#!/usr/bin/env python3

with open('lib/screens/chats/chats_widgets/profile_corporate_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import if not present
if "import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';" not in content:
    content = content.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';\nimport 'package:flutter/material.dart';"
    )

# Simple direct replacements
replacements = [
    # Colors
    ("Color(0xff1E2E52)", "context.appColors.textPrimary"),
    ("Color(0xff6E7C97)", "context.appColors.textSecondary"),
    ("Color(0xffE1E6F0)", "context.appColors.borderSubtle"),
    ("Color(0xffF4F7FD)", "context.appColors.backgroundPrimary"),
    ("Colors.white", "context.appColors.surfacePrimary"),
    ("Colors.green", "context.appColors.success"),
    ("Colors.black", "context.appColors.textPrimary"),
    ("Colors.transparent", "Colors.transparent"),  # Keep transparent
    # Fixes for buildDivider
    ("buildDivider()", "buildDivider(context)"),
]

for old, new in replacements:
    content = content.replace(old, new)

# Remove fontFamily declarations
import re
content = re.sub(r",\s*fontFamily:\s*'Gilroy'", "", content)
content = re.sub(r",\s*fontFamily:\s*'Golos'", "", content)

with open('lib/screens/chats/chats_widgets/profile_corporate_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done: profile_corporate_screen.dart")
