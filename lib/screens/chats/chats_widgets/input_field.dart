import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';

class InputField extends StatelessWidget {
  final Function onSend;
  final Function onAttachFile;
  final Function onRecordVoice;
  final TextEditingController messageController; // Контроллер для поля ввода

  const InputField({
    Key? key,
    required this.onSend,
    required this.onAttachFile,
    required this.onRecordVoice,
    required this.messageController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Container(
                  height: 50,
                  child: Container(
                    padding: const EdgeInsets.only(left: 16),
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: "Введите ваше сообщение...",
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: ChatSmsStyles.hintTextColor,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                        ),
                        fillColor: ChatSmsStyles.inputBackgroundColor,
                        filled: true,
                        contentPadding: EdgeInsets.only(left: 10, right: 40),
                        border: OutlineInputBorder(
                          borderRadius: ChatSmsStyles.inputBorderRadius,
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: ChatSmsStyles.messageTextStyle,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: Image.asset('assets/icons/chats/file.png',
                        width: 20, height: 20),
                    onPressed: () {
                      onAttachFile();
                    },
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ChatSmsStyles.inputBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                'assets/icons/chats/microphone.png',
                width: 20,
                height: 20,
              ),
            ),
            onPressed: () {
              onRecordVoice();
            },
          ),
          IconButton(
            icon: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xfff4F40EC),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                'assets/icons/chats/send.png',
                width: 20,
                height: 20,
              ),
            ),
            onPressed: () {
              onSend();
            },
          ),
        ],
      ),
    );
  }
}
