import 'dart:async';
import 'dart:io';

import 'package:crm_task_manager/bloc/cubit/listen_sender_file_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_text_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_voice_cubit.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';

class InputField extends StatelessWidget {
  final Function onSend;
  final VoidCallback onAttachFile;
  final Function onRecordVoice;
  final TextEditingController messageController;
  final Function(File soundFile, String time) sendRequestFunction;
  final FocusNode focusNode;

  const InputField({
    super.key,
    required this.onSend,
    required this.onAttachFile,
    required this.onRecordVoice,
    required this.messageController,
    required this.sendRequestFunction,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final messagingCubit = context.read<MessagingCubit>();
    final editingMessage =
        context.watch<MessagingCubit>().state is EditingMessageState
            ? (context.read<MessagingCubit>().state as EditingMessageState)
                .editingMessage
            : null;

    final replyingToMessage =
        context.watch<MessagingCubit>().state is ReplyingToMessageState
            ? (context.read<MessagingCubit>().state as ReplyingToMessageState)
                .replyingMessage
            : null;

    final String? replyMsgId = replyingToMessage?.id.toString();

    if (editingMessage != null && messageController.text.isEmpty) {
      messageController.text = editingMessage.text;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 0, right: 0, top: 6, bottom: 20),
      child: Column(
        children: [
          if (replyingToMessage != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xfff4F40EC),
                    width: 1,
                  ),
                ),
              ),
              padding:
                  const EdgeInsets.only(left: 20, right: 6, top: 0, bottom: 0),
              margin: const EdgeInsets.only(bottom: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/chats/menu_icons/reply.svg',
                        width: 16,
                        height: 16,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      RichText(
                        text: TextSpan(
                          text: "В ответ ",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                            fontFamily: 'Gilroy',
                          ),
                          children: [
                            TextSpan(
                              text: replyingToMessage.senderName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ChatSmsStyles.messageBubbleSenderColor,
                                fontFamily: 'Gilroy',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          replyingToMessage.type == 'voice'
                              ? 'Голосовое сообщение'
                              : replyingToMessage.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.red, size: 28),
                        padding: EdgeInsets.only(bottom: 20),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          context.read<MessagingCubit>().clearReplyMessage();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (editingMessage != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xfff4F40EC),
                    width: 1,
                  ),
                ),
              ),
              padding:const EdgeInsets.only(left: 20, right: 6, top: 0, bottom: 0),
              margin: const EdgeInsets.only(bottom: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/chats/menu_icons/edit.svg',
                        width: 16,
                        height: 16,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      RichText(
                        text: TextSpan(
                          text: "Редактирование сообщения",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 28),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      messagingCubit.clearEditingMessage();
                      messageController.clear();
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
                            child: CircularProgressIndicator(
                                color: Color(0xff1E2E52)),
                          )
                        : Container(
                            height: 50,
                            child: Container(
                                padding: const EdgeInsets.only(left: 16),
                                child: TextField(
                                  controller: messageController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .translate('enter_your_sms'),
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: ChatSmsStyles.hintTextColor,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Gilroy',
                                    ),
                                    fillColor:
                                        ChatSmsStyles.inputBackgroundColor,
                                    filled: true,
                                    contentPadding:
                                        EdgeInsets.only(left: 10, right: 40),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          ChatSmsStyles.inputBorderRadius,
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  keyboardType: TextInputType.multiline,
                                  minLines: 1, 
                                  maxLines: 5, 
                                  style: ChatSmsStyles.messageTextStyle,
                                )),
                          ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: Image.asset('assets/icons/chats/file.png',
                            width: 24, height: 24),
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
                          child: CircularProgressIndicator(
                              color: Color(0xff1E2E52)),
                        ),
                      ],
                    )
                  : VoiceRecorderWidget(
                      sendRequestFunction: sendRequestFunction,
                    ),
              (context.watch<ListenSenderTextCubit>().state)
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                              color: Color(0xff1E2E52)),
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
                          if (editingMessage != null) {
                            messagingCubit.editMessage(messageController.text);
                          } else {
                            onSend(messageController.text, replyMsgId);
                            messagingCubit.clearReplyMessage();
                          }
                          messageController.clear();
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

class VoiceRecorderWidget extends StatefulWidget {
  final Function(File soundFile, String time) sendRequestFunction;

  const VoiceRecorderWidget({super.key, required this.sendRequestFunction});

  @override
  _VoiceRecorderWidgetState createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  late FlutterSoundRecorder _audioRecorder;
  bool _isRecording = false;
  String _recordFilePath = '';
  DateTime? _startTime;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await _audioRecorder.openRecorder();
  }
Future<void> _startRecording() async {
  final dir = await getTemporaryDirectory();
  // Generate a timestamp for the filename
  String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final path = '${dir.path}/audio_$timestamp.m4a'; 
  print('start RECORDING PATH: $path');
  
  await _audioRecorder.startRecorder(
    toFile: path,
    codec: Codec.aacMP4,
  );
  
  setState(() {
    _isRecording = true;
    _recordFilePath = path;
    _startTime = DateTime.now();
    _elapsedSeconds = 0;
  });
  
  _startTimer();
}
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stopRecorder();
    _timer?.cancel();
    final endTime = DateTime.now();
    setState(() {
      _isRecording = false;
    });

    if (_startTime != null) {
      final duration = endTime.difference(_startTime!);
      widget.sendRequestFunction(File(_recordFilePath), duration.toString());
    }
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isRecording)
          Text(
            '$_elapsedSeconds s',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Gilroy'),
          ),
        SizedBox(width: 4),
        AnimatedContainer(
          duration: Duration(milliseconds: 3),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _isRecording ? Colors.redAccent : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: _isRecording ? Colors.white : Colors.black,
            ),
            onPressed: () {
              if (_isRecording) {
                _stopRecording();
              } else {
                _startRecording();
              }
            },
          ),
        ),
      ],
    );
  }
}


