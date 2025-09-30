import 'dart:io';

import 'package:crm_task_manager/bloc/chats/template_bloc/template_bloc.dart';
import 'package:crm_task_manager/bloc/chats/template_bloc/template_event.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/tamplate_chat.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/templates_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_media_recorder/audio_encoder_type.dart';
import 'package:social_media_recorder/screen/social_media_recorder.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_file_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_text_cubit.dart';
import 'package:crm_task_manager/bloc/cubit/listen_sender_voice_cubit.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:flutter_svg/svg.dart';

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

class _InputFieldState extends State<InputField> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  OverlayEntry? _overlayEntry;
  OverlayEntry? _formattingOverlay;
  bool _showTemplates = false;
  bool _showFormattingPanel = false;
  String _currentQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _htmlContent = '';
  String _displayText = '';
  bool _wasKeyboardVisible = false;
  DateTime _pointerDownTime = DateTime.now(); // Добавьте в класс _InputFieldState


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

    widget.messageController.addListener(_handleSelectionChange);
    _htmlContent = widget.messageController.text;
    _displayText = _htmlToDisplayText(_htmlContent);

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _removeOverlay();
    _removeFormattingOverlay();
    _animationController.dispose();
    widget.messageController.removeListener(_handleSelectionChange);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (_wasKeyboardVisible != isKeyboardVisible) {
      setState(() {
        if (!isKeyboardVisible && _showFormattingPanel) {
          _showFormattingPanel = false;
          _animationController.reset();
          _removeFormattingOverlay();
        }
        _wasKeyboardVisible = isKeyboardVisible;
      });
    }
  }

  String _htmlToDisplayText(String html) {
    return html
        .replaceAll('<strong>', '')
        .replaceAll('</strong>', '')
        .replaceAll('<em>', '')
        .replaceAll('</em>', '')
        .replaceAll('<s>', '')
        .replaceAll('</s>', '')
        .replaceAllMapped(RegExp(r'<a href="[^"]*"[^>]*>([^<]*)</a>'), (match) => match.group(1) ?? '');
  }

  String _getHtmlContent() {
    return _htmlContent;
  }

  void _handleTextChange(String text) {
    print('InputField: _handleTextChange called with text: "$text"');

    _displayText = text;
    _htmlContent = text;

    setState(() {
      if (text.startsWith('/')) {
        print('InputField: Detected template query: ${text.substring(1)}');
        _currentQuery = text.substring(1).toLowerCase();
        _showTemplates = true;
        context.read<TemplateBloc>().add(FilterTemplates(_currentQuery));
        _updateOverlay();
        _animationController.forward();
      } else {
        print('InputField: Normal text input, hiding templates');
        _showTemplates = false;
        _animationController.reverse().then((_) => _removeOverlay());
      }
    });
  }


void _handleSelectionChange() {
  final selection = widget.messageController.selection;

  if (selection.isValid && selection.start != selection.end && widget.focusNode.hasFocus) {
    SystemChannels.textInput.invokeMethod('TextInput.hideToolbar');
    setState(() {
      _showFormattingPanel = true;
      _updateFormattingOverlay();
      _animationController.forward();
    });
  } else {
    _closeFormattingPanel();
  }
}

// ← ДОБАВЬТЕ ЭТОТ МЕТОД СЮДА
void _showFormattingPanelOnLongPress() {
  SystemChannels.textInput.invokeMethod('TextInput.hideToolbar');
  setState(() {
    _showFormattingPanel = true;
    _updateFormattingOverlay();
    _animationController.forward();
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

  void _updateFormattingOverlay() {
    _removeFormattingOverlay();
    if (_showFormattingPanel) {
      _formattingOverlay = _createFormattingOverlayEntry();
      Overlay.of(context)!.insert(_formattingOverlay!);
    }
  }

  void _removeFormattingOverlay() {
    _formattingOverlay?.remove();
    _formattingOverlay = null;
  }

  void _closeFormattingPanel() {
    setState(() {
      _showFormattingPanel = false;
      _animationController.reverse().then((_) => _removeFormattingOverlay());
    });
    widget.focusNode.requestFocus();
  }

  Map<String, bool> _checkDeviceCapabilities() {
    return {
      'record': true,
    };
  }

  void _recordText() {
    final text = widget.messageController.text;
    print('Saving text: $text');
    _closeFormattingPanel();
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        right: MediaQuery.of(context).size.width - (offset.dx + size.width),
        top: offset.dy - 210,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: TemplateSuggestions(
              query: _currentQuery,
              onTemplateSelected: (templateText) {
                widget.messageController.text = templateText;
                _htmlContent = templateText;
                _displayText = templateText;
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

  OverlayEntry _createFormattingOverlayEntry() {
  final RenderBox renderBox = context.findRenderObject() as RenderBox;
  final Offset offset = renderBox.localToGlobal(Offset.zero);
  final Size size = renderBox.size;

  final selection = widget.messageController.selection;
  final hasSelection = selection.isValid && 
                       selection.start != selection.end;

  final buttons = [
    _buildFormattingButton(
      icon: Icons.copy,
      label: 'Копировать',
      onTap: _copy,
      isEnabled: hasSelection,
    ),
    _buildFormattingButton(
      icon: Icons.cut,
      label: 'Вырезать',
      onTap: _cut,
      isEnabled: hasSelection,
    ),
    _buildFormattingButton(
      icon: Icons.paste,
      label: 'Вставить',
      onTap: _paste,
      isEnabled: true, // Вставка всегда доступна
    ),
    _buildFormattingButton(
      icon: Icons.select_all,
      label: 'Выбрать все',
      onTap: _selectAll,
      isEnabled: widget.messageController.text.isNotEmpty,
    ),
    _buildFormattingButton(
      icon: Icons.format_bold,
      label: 'Жирный',
      onTap: () => _applyFormatting('bold'),
      isEnabled: hasSelection,
    ),
    _buildFormattingButton(
      icon: Icons.format_italic,
      label: 'Курсив',
      onTap: () => _applyFormatting('italic'),
      isEnabled: hasSelection,
    ),
    _buildFormattingButton(
      icon: Icons.link,
      label: 'Ссылка',
      onTap: () => _applyLinkFormatting(context),
      isEnabled: hasSelection,
    ),
    _buildFormattingButton(
      icon: Icons.format_strikethrough,
      label: 'Зачеркнутый',
      onTap: () => _applyFormatting('strikethrough'),
      isEnabled: hasSelection,
    ),
  ];

  return OverlayEntry(
    builder: (context) => Positioned(
      left: offset.dx,
      right: MediaQuery.of(context).size.width - (offset.dx + size.width),
      top: offset.dy - 60,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: buttons,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildFormattingButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  bool isEnabled = true,
}) {
  return InkWell(
    onTap: isEnabled ? onTap : null,
    borderRadius: BorderRadius.circular(8),
    child: Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 18, 
              color: isEnabled ? Color(0xff1E2E52) : Colors.grey,
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: isEnabled ? Color(0xff1E2E52) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _applyFormatting(String type) {
    final selection = widget.messageController.selection;
    if (!selection.isValid || selection.start == selection.end) {
      _closeFormattingPanel();
      return;
    }

    final text = widget.messageController.text;
    final selectedText = text.substring(selection.start, selection.end);

    String tagStart, tagEnd;
    switch (type) {
      case 'bold':
        tagStart = '<strong>';
        tagEnd = '</strong>';
        break;
      case 'italic':
        tagStart = '<em>';
        tagEnd = '</em>';
        break;
      case 'strikethrough':
        tagStart = '<s>';
        tagEnd = '</s>';
        break;
      default:
        _closeFormattingPanel();
        return;
    }

    _htmlContent = _htmlContent.replaceRange(
      selection.start,
      selection.end,
      '$tagStart$selectedText$tagEnd',
    );

    widget.messageController.text = text;
    widget.messageController.selection = TextSelection(
      baseOffset: selection.start,
      extentOffset: selection.end,
    );

    _closeFormattingPanel();
  }

  void _applyLinkFormatting(BuildContext context) async {
    final selection = widget.messageController.selection;
    if (!selection.isValid || selection.start == selection.end) {
      _closeFormattingPanel();
      return;
    }

    final text = widget.messageController.text;
    final selectedText = text.substring(selection.start, selection.end);

    final urlController = TextEditingController();
    String? url;

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Вставьте ссылку',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E2E52),
                  fontFamily: 'Gilroy',
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.grey.shade50,
                ),
                child: TextField(
                  controller: urlController,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'https://example.com',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      'Отмена',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      url = urlController.text;
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff1E2E52),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Добавить',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (url != null && url!.isNotEmpty) {
      _htmlContent = _htmlContent.replaceRange(
        selection.start,
        selection.end,
        '<a href="$url" target="_blank">$selectedText</a>',
      );

      widget.messageController.selection = TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.end,
      );
    }

    _closeFormattingPanel();
  }

  void _selectAll() {
    widget.messageController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.messageController.text.length,
    );
    _closeFormattingPanel();
  }

  void _paste() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      final selection = widget.messageController.selection;
      final text = widget.messageController.text;
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        clipboardData.text!,
      );
      widget.messageController.text = newText;
      _htmlContent = _htmlContent.replaceRange(
        selection.start,
        selection.end,
        clipboardData.text!,
      );
      widget.messageController.selection = TextSelection.collapsed(
        offset: selection.start + clipboardData.text!.length,
      );
    }
    _closeFormattingPanel();
  }

  void _copy() async {
    final selection = widget.messageController.selection;
    if (!selection.isValid || selection.start == selection.end) {
      _closeFormattingPanel();
      return;
    }

    final text = widget.messageController.text;
    final selectedText = text.substring(selection.start, selection.end);

    await Clipboard.setData(ClipboardData(text: selectedText));

    _closeFormattingPanel();
  }

  void _cut() async {
    final selection = widget.messageController.selection;
    if (!selection.isValid || selection.start == selection.end) {
      _closeFormattingPanel();
      return;
    }

    final text = widget.messageController.text;
    final selectedText = text.substring(selection.start, selection.end);

    await Clipboard.setData(ClipboardData(text: selectedText));

    final newText = text.replaceRange(selection.start, selection.end, '');
    _htmlContent = _htmlContent.replaceRange(selection.start, selection.end, '');

    widget.messageController.text = newText;
    widget.messageController.selection = TextSelection.collapsed(
      offset: selection.start,
    );

    _closeFormattingPanel();
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
    _htmlContent = editingMessage.text;
  }

  return GestureDetector(
    onTap: () {
      if (_showFormattingPanel) {
        _closeFormattingPanel();
      }
    },
    child: Container(
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
                      _htmlContent = '';
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
                    : Listener(
    onPointerDown: (event) {
      _pointerDownTime = DateTime.now();
    },
    onPointerUp: (event) {
      final duration = DateTime.now().difference(_pointerDownTime).inMilliseconds;
      if (duration > 500) { // 500ms = долгое нажатие
        _showFormattingPanelOnLongPress();
      }
    },
    child: Container(
      height: 50,
      child: Container(
        padding: const EdgeInsets.only(left: 16),
        child: TextField(
          controller: widget.messageController,
          focusNode: widget.focusNode,
          onChanged: _handleTextChange,
          enableInteractiveSelection: true,
          toolbarOptions: ToolbarOptions(
            copy: false,
            cut: false,
            paste: false,
            selectAll: false,
          ),
          contextMenuBuilder: (context, editableTextState) {
            return AdaptiveTextSelectionToolbar(
              anchors: editableTextState.contextMenuAnchors,
              children: [],
            );
          },
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
  ),
                    if (widget.isLeadChat)
                      Positioned(
                        right: 35,
                        child: IconButton(
                          icon: Image.asset('assets/icons/chats/menu-button.png', width: 24, height: 24),
                          onPressed: () {
                            _showTemplatesPanel(context);
                          },
                        ),
                      ),
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
                            messagingCubit.editMessage(_getHtmlContent());
                          } else {
                            widget.onSend(_getHtmlContent(), replyMsgId);
                            messagingCubit.clearReplyMessage();
                          }
                          widget.messageController.clear();
                          _htmlContent = '';
                          _displayText = '';
                          setState(() {
                            _showTemplates = false;
                            _showFormattingPanel = false;
                            _animationController.reverse().then((_) {
                              _removeOverlay();
                              _removeFormattingOverlay();
                            });
                          });
                        }
                      },
                    ),
            ],
          ),
        ],
      ),
    ),
  );
}

  void _showTemplatesPanel(BuildContext context) {
    print('InputField: Opening TemplatesPanel');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (BuildContext bottomSheetContext) => TemplatesPanel(
        onTemplateSelected: (String selectedText) {
          print('InputField: Selected template text: $selectedText');

          Navigator.of(bottomSheetContext).pop();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.messageController.text = selectedText;
            _htmlContent = selectedText;
            _displayText = selectedText;

            print('InputField: Message controller text: ${widget.messageController.text}');
            print('InputField: Template successfully applied');

            widget.focusNode.requestFocus();

            if (mounted) {
              setState(() {});
            }
          });
        },
      ),
    );
  }
}