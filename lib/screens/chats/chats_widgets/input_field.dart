import 'dart:io';

import 'package:crm_task_manager/bloc/cubit/listen_sender_file_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_text_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_voice_cubit.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_recorder/audio_encoder_type.dart';
import 'package:social_media_recorder/screen/social_media_recorder.dart';

class InputField extends StatelessWidget {
  final Function onSend;
  final VoidCallback onAttachFile;
  final Function onRecordVoice;
  final TextEditingController messageController;
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

final replyingToMessage = context.watch<MessagingCubit>().state is ReplyingToMessageState
    ? (context.read<MessagingCubit>().state as ReplyingToMessageState).replyingMessage
    : null;

    final String? replyMsgId=replyingToMessage?.id.toString();
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 20),
      child: Column(
        children: [
          // Виджет отображения режима ответа
          if (replyingToMessage != null)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xfff4f4f4),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                      child: Text(
                        replyingToMessage.type == 'voice' 
                            ? 'Голосовое сообщение' 
                            : replyingToMessage.text, 
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontStyle: FontStyle.italic,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      // Очистить режим ответа
                      context.read<MessagingCubit>().clearReplyMessage();
                    },
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    (context.watch<ListenSenderFileCubit>().state)
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(color: Color(0xff1E2E52)),
                          )
                        : Container(
                            height: 50,
                            child: Container(
                              padding: const EdgeInsets.only(left: 16),
                              child: TextField(
                                controller: messageController,
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!.translate('enter_your_sms'),
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
                        icon: Image.asset('assets/icons/chats/file.png', width: 24, height: 24),
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
                          child: CircularProgressIndicator(color: Color(0xff1E2E52)),
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
                        cancelText: AppLocalizations.of(context)!.translate('cancel'),
                        cancelTextStyle: TextStyle(fontSize: 16, fontFamily: 'Gilroy', fontWeight: FontWeight.w500),
                        slideToCancelText: AppLocalizations.of(context)!.translate('cancel_chat_sms'),
                        slideToCancelTextStyle: TextStyle(fontSize: 16, fontFamily: 'Gilroy', fontWeight: FontWeight.w500),
                        recordIconBackGroundColor: Color(0xfff4F40EC),
                        counterTextStyle: TextStyle(fontSize: 14, fontFamily: 'Gilroy', fontWeight: FontWeight.w500),
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
                          child: CircularProgressIndicator(color: Color(0xff1E2E52)),
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
                      if (messageController.text.isNotEmpty) {
                        onSend(messageController.text, replyMsgId);
                        context.read<MessagingCubit>().clearReplyMessage(); 
                      }
                    },
                ),
            ],
          ),
        ],
      ),
    );
  
}
}

