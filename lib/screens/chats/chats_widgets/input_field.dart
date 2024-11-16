import 'dart:io';

import 'package:crm_task_manager/bloc/cubit/listen_sender_file_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_text_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_voice_cubit.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_recorder/audio_encoder_type.dart';
import 'package:social_media_recorder/screen/social_media_recorder.dart';

class InputField extends StatelessWidget {
  final Function onSend;
  final VoidCallback onAttachFile;
  final Function onRecordVoice;
  final TextEditingController messageController; // Контроллер для поля ввода
  final Function(File soundFile, String time) sendRequestFunction;

  const InputField({
    super.key,
    required this.onSend,
    required this.onAttachFile,
    required this.onRecordVoice,
    required this.messageController,
    required this.sendRequestFunction,
  });


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
                (context.watch<ListenSenderFileCubit>().state)
                    ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    )
                    : Container(
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
                              contentPadding:
                                  EdgeInsets.only(left: 10, right: 40),
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
                    onPressed: onAttachFile,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          (context.watch<ListenSenderVoiceCubit>().state)
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  ],
                )
              : MediaQuery(
                  data: MediaQueryData(
                    size: Size(300, 400),
                  ),
                  child: SocialMediaRecorder(
                    startRecording: () {
                      // function called when start recording
                    },
                    stopRecording: (_time) {
                      // function called when stop recording, return the recording time
                    },
                    sendRequestFunction: sendRequestFunction,
                    encode: AudioEncoderType.AAC,
                    radius: BorderRadius.circular(12),
                  ),
                ),

          /*

           */
          // IconButton(
          //   icon: Container(
          //     width: 48,
          //     height: 48,
          //     decoration: BoxDecoration(
          //       color: ChatSmsStyles.inputBackgroundColor,
          //       borderRadius: BorderRadius.circular(8),
          //     ),
          //     padding: const EdgeInsets.all(12),
          //     child: Image.asset(
          //       'assets/icons/chats/microphone.png',
          //       width: 20,
          //       height: 20,
          //     ),
          //   ),
          //   onPressed: () {
          //     onRecordVoice();
          //   },
          // ),
          (context.watch<ListenSenderTextCubit>().state)
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  ],
                )
              : IconButton(
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
