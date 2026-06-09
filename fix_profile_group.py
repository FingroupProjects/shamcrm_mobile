import re

with open('lib/screens/chats/chats_widgets/profile_corporate_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
content = content.replace(
    "import 'package:flutter/material.dart';",
    "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';"
)

old_groupname = """            Text(
              groupName,
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
              ),
            ),"""

new_groupname = """            GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: groupName));
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
                groupName,
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),"""
content = content.replace(old_groupname, new_groupname)

# Notice there's an existing onLongPress for members that deletes the chat user:
old_member_longpress = """                        onLongPress: () {
                          if (!isDeletedAccount &&
                              !isCurrentUser &&
                              userIdCheck == ownerId) {
                            showDialog(
                              context: context,
                              builder: (context) => DeleteChatDialog(
                                chatId: widget.chatId,
                                userId: int.parse(memberDetails[index]['id']!),
                                onUserAdded: _fetchChatData,
                              ),
                            );
                          }
                        },"""

# We shouldn't break the existing onLongPress, so we will wrap the Text itself instead of the InkWell
old_member_text = """                              Expanded(
                                child: Text(
                                  members[index],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Gilroy',
                                    color: Colors.black,
                                  ),
                                    maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                                ),
                              ),"""

new_member_text = """                              Expanded(
                                child: GestureDetector(
                                  onLongPress: () {
                                    Clipboard.setData(ClipboardData(text: members[index]));
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
                                    members[index],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Gilroy',
                                      color: Colors.black,
                                    ),
                                      maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),"""
content = content.replace(old_member_text, new_member_text)

with open('lib/screens/chats/chats_widgets/profile_corporate_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done profile group")
