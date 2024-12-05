import 'dart:io';

import 'package:crm_task_manager/bloc/cubit/listen_sender_file_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_text_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_voice_cubit.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_recorder/audio_encoder_type.dart';
import 'package:social_media_recorder/screen/social_media_recorder.dart';

class InputField extends StatefulWidget {
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
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
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
                            controller: widget.messageController,
                            onChanged: (str) {
                              setState(() {

                              });
                            },
                            enabled: !context.watch<ListenSenderFileCubit>().state,
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
                if(widget.messageController.text.isEmpty) (context.watch<ListenSenderFileCubit>().state)
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ) : Positioned(
                  right: 0,
                  child: IconButton(
                    icon: Image.asset('assets/icons/chats/file.png',
                        width: 20, height: 20),
                    onPressed: widget.onAttachFile,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          if(widget.messageController.text.isEmpty) (context.watch<ListenSenderVoiceCubit>().state)
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
                    size: Size(MediaQuery.of(context).size.width * .9, 400),
                  ),
                  child: SocialMediaRecorder(
                    startRecording: () {

                    },

                    slideToCancelText: 'Свайпните для отмены.',
                    slideToCancelTextStyle: TextStyle(fontSize: 12),
                    recordIconBackGroundColor: ChatSmsStyles.messageBubbleSenderColor,

                    stopRecording: (_time) {

                      // function called when stop recording, return the recording time
                    },
                    cancelText: 'Отмена',
                    recordIconWhenLockBackGroundColor: ChatSmsStyles.messageBubbleSenderColor,
                    sendRequestFunction:
                      widget.sendRequestFunction,
                    encode: AudioEncoderType.AAC,
                    radius: BorderRadius.circular(12),
                  ),
                ),

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
              :(widget.messageController.text.isNotEmpty) ? IconButton(
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
                   widget.onSend();
                  },
                ) : SizedBox(),
        ],
      ),
    );
  }
}
