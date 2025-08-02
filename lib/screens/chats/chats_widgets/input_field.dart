
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
import 'package:social_media_recorder/audio_encoder_type.dart';
import 'package:social_media_recorder/screen/social_media_recorder.dart';

class InputField extends StatefulWidget {
  final Function onSend;
  final VoidCallback onAttachFile;
  final Function onRecordVoice;
  final TextEditingController messageController;
  final Function(File soundFile, String time) sendRequestFunction;
  final FocusNode focusNode;
  final bool isLeadChat;

  const InputField({
    super.key,
    required this.onSend,
    required this.onAttachFile,
    required this.onRecordVoice,
    required this.messageController,
    required this.sendRequestFunction,
    required this.focusNode,
    required this.isLeadChat,
  });

  @override
  _InputFieldState createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> with SingleTickerProviderStateMixin {
  final Map<String, String> templates = {
    '/1С Строительство': 'Уточните, пожалуйста, детали проекта. Мы свяжемся с вами в течение 24 часов.',
    '/shamCRM': 'Наш разработчик подготовит демонстрацию. Ожидайте звонка.',
    '/Общий запрос': 'Спасибо за обращение! Мы обработаем ваш запрос и ответим скоро.',
    '/Техподдержка': 'Проблема зафиксирована. Ожидайте решение в течение 48 часов.',
    '/Консультация': 'Запишитесь на консультацию через форму на сайте.',
    '/Обновление': 'Новый релиз shamCRM доступен. Хотите обновить?',
    '/Ошибка 1С': 'Опишите ошибку подробнее, приложите скриншот.',
    '/Срочный запрос': 'Пожалуйста, укажите срочность и детали задачи.',
    '/Документация': 'Высылаем документацию на ваш email.',
    '/Тестирование': 'Тестирование shamCRM завершено, готовы к демонстрации.',
    '/Цена': 'Уточните бюджет, чтобы мы подобрали решение.',
    '/Интеграция': 'Интеграция с 1С возможна, обсудим детали.',
    '/Установка': 'Установка займет 2-3 дня, согласуем дату.',
    '/Обучение': 'Предлагаем обучение по shamCRM, запишитесь сейчас.',
    '/Поддержка 24/7': 'Обращайтесь в любое время для экстренной помощи.',
  };

  OverlayEntry? _overlayEntry;
  bool _showTemplates = false;
  String _currentQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _handleTextChange(String text) {
    setState(() {
      if (text.startsWith('/')) {
        _currentQuery = text.substring(1).toLowerCase();
        _showTemplates = true;
        _updateOverlay();
        _animationController.forward();
      } else {
        _showTemplates = false;
        _animationController.reverse().then((_) => _removeOverlay());
      }
    });
  }

  void _updateOverlay() {
    _removeOverlay();
    if (_showTemplates) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context)!.insert(_overlayEntry!);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        right: MediaQuery.of(context).size.width - (offset.dx + size.width),
        top: offset.dy - 210, // Позиционируем на 210 пикселей выше поля ввода
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: TemplateSuggestions(
              templates: templates,
              query: _currentQuery,
              onTemplateSelected: (templateText) {
                widget.messageController.text = templateText;
                setState(() {
                  _showTemplates = false;
                  _animationController.reverse().then((_) => _removeOverlay());
                });
                widget.focusNode.requestFocus();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagingCubit = context.read<MessagingCubit>();
    final editingMessage = context.watch<MessagingCubit>().state is EditingMessageState
        ? (context.read<MessagingCubit>().state as EditingMessageState).editingMessage
        : null;

    final replyingToMessage = context.watch<MessagingCubit>().state is ReplyingToMessageState
        ? (context.read<MessagingCubit>().state as ReplyingToMessageState).replyingMessage
        : null;

    final String? replyMsgId = replyingToMessage?.id.toString();

    if (editingMessage != null && widget.messageController.text.isEmpty) {
      widget.messageController.text = editingMessage.text;
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
              padding: const EdgeInsets.only(left: 20, right: 6, top: 0, bottom: 0),
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
                          text: AppLocalizations.of(context)!.translate('in_answer'),
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
                              ? AppLocalizations.of(context)!.translate('voice_message')
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
                        icon: const Icon(Icons.close, color: Colors.red, size: 28),
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
              padding: const EdgeInsets.only(left: 20, right: 6, top: 0, bottom: 0),
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
                          text: AppLocalizations.of(context)!.translate('edit_message'),
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
                      widget.messageController.clear();
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
                                controller: widget.messageController,
                                focusNode: widget.focusNode,
                                onChanged: _handleTextChange,
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
                                  contentPadding: widget.isLeadChat
                                      ? EdgeInsets.only(left: 10, right: 65)
                                      : EdgeInsets.only(left: 10, right: 40),
                                  border: OutlineInputBorder(
                                    borderRadius: ChatSmsStyles.inputBorderRadius,
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                keyboardType: TextInputType.multiline,
                                minLines: 1,
                                maxLines: 5,
                                style: ChatSmsStyles.messageTextStyle,
                              ),
                            ),
                          ),
                    // if (widget.isLeadChat)
                    //   Positioned(
                    //     right: 35,
                    //     child: IconButton(
                    //       icon: Image.asset('assets/icons/chats/menu-button.png', width: 24, height: 24),
                    //       onPressed: () {
                    //         _showTemplatesPanel(context);
                    //       },
                    //     ),
                    //   ),
                    Positioned(
                      right: widget.isLeadChat ? 0 : 0,
                      child: IconButton(
                        icon: Image.asset('assets/icons/chats/file.png', width: 24, height: 24),
                        onPressed: widget.onAttachFile,
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
                          padding: const EdgeInsets.all(8),
                          child: CircularProgressIndicator(color: Color(0xff1E2E52)),
                        ),
                      ],
                    )
                  : widget.isLeadChat
                      ? SizedBox.shrink()
                      : MediaQuery(
                          data: MediaQueryData(size: Size(330, 400)),
                          child: SocialMediaRecorder(
                            maxRecordTimeInSecond: 180,
                            initRecordPackageWidth: 48,
                            fullRecordPackageHeight: 48,
                            startRecording: () {},
                            stopRecording: (_time) {},
                            sendRequestFunction: widget.sendRequestFunction,
                            cancelText: AppLocalizations.of(context)!.translate('cancel'),
                            cancelTextStyle: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                            ),
                            slideToCancelText: AppLocalizations.of(context)!.translate('cancel_chat_sms'),
                            slideToCancelTextStyle: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                            ),
                            recordIconBackGroundColor: Color(0xfff4F40EC),
                            counterTextStyle: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                            ),
                            encode: AudioEncoderType.AAC,
                            radius: BorderRadius.circular(8),
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
                        if (widget.messageController.text.isNotEmpty) {
                          if (editingMessage != null) {
                            messagingCubit.editMessage(widget.messageController.text);
                          } else {
                            widget.onSend(widget.messageController.text, replyMsgId);
                            messagingCubit.clearReplyMessage();
                          }
                          widget.messageController.clear();
                          setState(() {
                            _showTemplates = false;
                            _animationController.reverse().then((_) => _removeOverlay());
                          });
                        }
                      },
                    ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTemplatesPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TemplatesPanel(
        onTemplateSelected: (text) {
          widget.messageController.text = text;
          Navigator.pop(context);
        },
      ),
    );
  }
}

class TemplateSuggestions extends StatelessWidget {
  final Map<String, String> templates;
  final String query;
  final Function(String) onTemplateSelected;

  const TemplateSuggestions({
    Key? key,
    required this.templates,
    required this.query,
    required this.onTemplateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filteredTemplates = templates.entries
        .where((entry) => entry.key.toLowerCase().contains(query))
        .toList();

    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      width: double.infinity, // Соответствует ширине TextField
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: filteredTemplates.isEmpty
          ? Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context)!.translate('no_templates_found'),
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: filteredTemplates.length,
              itemBuilder: (context, index) {
                final entry = filteredTemplates[index];
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      subtitle: Text(
                        entry.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          color: Color(0xff99A4BA),
                        ),
                      ),
                      onTap: () {
                        onTemplateSelected(entry.value);
                      },
                    ),
                    if (index < filteredTemplates.length - 1)
                      Divider(thickness: 0.5, height: 0.5, color: Colors.grey),
                  ],
                );
              },
            ),
    );
  }
}

class TemplatesPanel extends StatefulWidget {
  final Function(String) onTemplateSelected;

  const TemplatesPanel({super.key, required this.onTemplateSelected});

  @override
  _TemplatesPanelState createState() => _TemplatesPanelState();
}

class _TemplatesPanelState extends State<TemplatesPanel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(
      begin: Offset(0.0, 1.0),
      end: Offset(0.0, 0.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black.withOpacity(0.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                constraints: BoxConstraints(maxHeight: 500),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('templates'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: _buildTemplateList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateList() {
    final templates = [
      '1. 1С Строительство: Уточните, пожалуйста, детали проекта. Мы свяжемся с вами в течение 24 часов.',
      '2. shamCRM: Наш разработчик подготовит демонстрацию. Ожидайте звонка.',
      '3. Общий запрос: Спасибо за обращение! Мы обработаем ваш запрос и ответим скоро.',
      '4. Техподдержка: Проблема зафиксирована. Ожидайте решение в течение 48 часов.',
      '5. Консультация: Запишитесь на консультацию через форму на сайте.',
      '6. Обновление: Новый релиз shamCRM доступен. Хотите обновить?',
      '7. Ошибка 1С: Опишите ошибку подробнее, приложите скриншот.',
      '8. Срочный запрос: Пожалуйста, укажите срочность и детали задачи.',
      '9. Документация: Высылаем документацию на ваш email.',
      '10. Тестирование: Тестирование shamCRM завершено, готовы к демонстрации.',
      '11. Цена: Уточните бюджет, чтобы мы подобрали решение.',
      '12. Интеграция: Интеграция с 1С возможна, обсудим детали.',
      '13. Установка: Установка займет 2-3 дня, согласуем дату.',
      '14. Обучение: Предлагаем обучение по shamCRM, запишитесь сейчас.',
      '15. Поддержка 24/7: Обращайтесь в любое время для экстренной помощи.',
    ];
    return ListView.builder(
      shrinkWrap: true,
      itemCount: templates.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            ListTile(
              title: Text(
                templates[index],
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
              ),
              onTap: () {
                widget.onTemplateSelected(templates[index].split(': ')[1]);
              },
            ),
            if (index < templates.length - 1)
              Divider(thickness: 0.5, height: 0.5, color: Colors.grey),
          ],
        );
      },
    );
  }
}
