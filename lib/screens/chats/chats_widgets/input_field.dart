import 'dart:io';

import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:crm_task_manager/bloc/chats/template_bloc/template_bloc.dart';
import 'package:crm_task_manager/bloc/chats/template_bloc/template_event.dart';
import 'package:crm_task_manager/core/theme/components/rich_text_field.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/tamplate_chat.dart';
import 'package:crm_task_manager/screens/chats/chat_appearance.dart';
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
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';

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
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  OverlayEntry? _overlayEntry;
  OverlayEntry? _formattingOverlay;
  bool _showTemplates = false;
  bool _showFormattingPanel = false;
  String _currentQuery = '';
  late AnimationController _animationController;
  late AnimationController _micPulseController;
  late Animation<double> _fadeAnimation;

  String _htmlContent = '';
  bool _wasKeyboardVisible = false;
  bool _hasText = false;
  bool _voicePressed = false;

  Timer? _selectionDebounce;
  bool _suppressFormattingPanel = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    widget.messageController.addListener(_handleSelectionChange);
    widget.messageController.addListener(_updateTextState);
    widget.focusNode.addListener(_handleFocusChange);

    _htmlContent = widget.messageController.text;
    _hasText = widget.messageController.text.isNotEmpty;

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _removeOverlay();
    _removeFormattingOverlay();
    _animationController.dispose();
    _micPulseController.dispose();
    _selectionDebounce?.cancel();
    widget.messageController.removeListener(_handleSelectionChange);
    widget.messageController.removeListener(_updateTextState);
    widget.focusNode.removeListener(_handleFocusChange);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _setVoicePressed(bool value) {
    if (_voicePressed == value) {
      return;
    }
    setState(() {
      _voicePressed = value;
    });
  }

  void _updateTextState() {
    final hasText = widget.messageController.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
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

  String _getHtmlContent() {
    return _htmlContent;
  }

  void _handleTextChange(String text) {
    _htmlContent = text;

    setState(() {
      if (text.startsWith('/')) {
        _closeFormattingPanel();
        _currentQuery = text.substring(1).toLowerCase();
        _showTemplates = true;
        context.read<TemplateBloc>().add(FilterTemplates(_currentQuery));
        _updateOverlay();
        _animationController.forward();
      } else {
        _showTemplates = false;
        _animationController.reverse().then((_) => _removeOverlay());
      }
    });
  }

  void _handleFocusChange() {
    if (!widget.focusNode.hasFocus) {
      _closeFormattingPanel();
    }
  }

  void _handleSelectionChange() {
    final selection = widget.messageController.selection;

    _selectionDebounce?.cancel();

    if (selection.isValid &&
        selection.start != selection.end &&
        widget.focusNode.hasFocus) {
      if (_suppressFormattingPanel) {
        return;
      }
      _selectionDebounce = Timer(const Duration(milliseconds: 100), () {
        if (!mounted || _suppressFormattingPanel || !widget.focusNode.hasFocus) {
          return;
        }
        SystemChannels.textInput.invokeMethod('TextInput.hideToolbar');

        setState(() {
          _showFormattingPanel = true;
          _updateFormattingOverlay();
          _animationController.forward();
        });
      });
    } else if (_showFormattingPanel &&
        (!selection.isValid || selection.start == selection.end)) {
      _closeFormattingPanel();
    }
  }

  void _showFormattingPanelOnLongPress() {
    _suppressFormattingPanel = false;
    SystemChannels.textInput.invokeMethod('TextInput.hideToolbar');
    _showFormattingPanel = true;
    _updateFormattingOverlay();
    setState(() {
      _animationController.forward();
    });
  }

  void _updateOverlay() {
    _removeOverlay();
    if (_showTemplates) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
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
      Overlay.of(context).insert(_formattingOverlay!);
    }
  }

  void _removeFormattingOverlay() {
    _formattingOverlay?.remove();
    _formattingOverlay = null;
  }

  void _closeFormattingPanel({bool restoreFocus = false}) {
    _selectionDebounce?.cancel();
    SystemChannels.textInput.invokeMethod('TextInput.hideToolbar');

    if (_showFormattingPanel || _formattingOverlay != null) {
      _suppressFormattingPanel = true;
      _showFormattingPanel = false;
      _removeFormattingOverlay();
      if (mounted) {
        setState(() {});
      }
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        _suppressFormattingPanel = false;
      });
    }

    if (restoreFocus && mounted) {
      widget.focusNode.requestFocus();
    }
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + 8,
        right: MediaQuery.of(context).size.width - (offset.dx + size.width - 8),
        top: offset.dy - 220,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: context.appColors.overlay.withValues(alpha: 0.0),
            child: Container(
              decoration: BoxDecoration(
                color: context.appColors.surfacePrimary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: context.appShadows.card,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: TemplateSuggestions(
                  query: _currentQuery,
                  onTemplateSelected: (templateText) {
                    final plainText = stripHtmlTags(templateText).trim();
                    widget.messageController.text = plainText;
                    _htmlContent = plainText;
                    setState(() {
                      _showTemplates = false;
                      _animationController
                          .reverse()
                          .then((_) => _removeOverlay());
                    });
                    widget.focusNode.requestFocus();
                  },
                ),
              ),
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
    final hasSelection = selection.isValid && selection.start != selection.end;
    final localizations = AppLocalizations.of(context);

    final buttons = [
      _buildFormattingButton(
        icon: Icons.copy_rounded,
        label: localizations?.translate('copy') ?? 'Копировать',
        onTap: _copy,
        isEnabled: hasSelection,
      ),
      _buildFormattingButton(
        icon: Icons.content_cut_rounded,
        label: localizations?.translate('cut') ?? 'Вырезать',
        onTap: _cut,
        isEnabled: hasSelection,
      ),
      _buildFormattingButton(
        icon: Icons.content_paste_rounded,
        label: localizations?.translate('paste') ?? 'Вставить',
        onTap: _paste,
        isEnabled: true,
      ),
      _buildFormattingButton(
        icon: Icons.select_all_rounded,
        label: localizations?.translate('select_all') ?? 'Выбрать все',
        onTap: _selectAll,
        isEnabled: widget.messageController.text.isNotEmpty,
      ),
      _buildFormattingButton(
        icon: Icons.format_bold_rounded,
        label: localizations?.translate('bold') ?? 'Жирный',
        onTap: () => _applyFormatting('bold'),
        isEnabled: hasSelection,
      ),
      _buildFormattingButton(
        icon: Icons.format_italic_rounded,
        label: localizations?.translate('italic') ?? 'Курсив',
        onTap: () => _applyFormatting('italic'),
        isEnabled: hasSelection,
      ),
      _buildFormattingButton(
        icon: Icons.link_rounded,
        label: localizations?.translate('link') ?? 'Ссылка',
        onTap: () => _applyLinkFormatting(context),
        isEnabled: hasSelection,
      ),
      _buildFormattingButton(
        icon: Icons.strikethrough_s_rounded,
        label: localizations?.translate('strikethrough') ?? 'Зачеркнутый',
        onTap: () => _applyFormatting('strikethrough'),
        isEnabled: hasSelection,
      ),
    ];

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + 8,
        right: MediaQuery.of(context).size.width - (offset.dx + size.width - 8),
        top: offset.dy - 70,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: context.appColors.overlay.withValues(alpha: 0.0),
            child: Container(
              decoration: BoxDecoration(
                color: context.appColors.surfacePrimary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: context.appShadows.card,
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: buttons
                      .map((btn) => Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: btn,
                          ))
                      .toList(),
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
    return Material(
      color: context.appColors.overlay.withValues(alpha: 0.0),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isEnabled
                ? context.appColors.overlay.withValues(alpha: 0.0)
                : context.appColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? context.appColors.buttonPrimaryBg.withValues(alpha: 0.1)
                      : context.appColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isEnabled
                      ? context.appColors.buttonPrimaryBg
                      : context.appColors.iconSecondary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: context.appTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isEnabled
                      ? context.appColors.buttonPrimaryBg
                      : context.appColors.iconSecondary,
                  letterSpacing: -0.2,
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

    _closeFormattingPanel(restoreFocus: true);
  }

  void _applyLinkFormatting(BuildContext context) async {
    final selection = widget.messageController.selection;
    if (!selection.isValid || selection.start == selection.end) {
      _closeFormattingPanel();
      return;
    }

    final text = widget.messageController.text;
    final selectedText = text.substring(selection.start, selection.end);
    final localizations = AppLocalizations.of(context);

    final urlController = TextEditingController();
    String? url;

    await showDialog(
      context: context,
      barrierColor: context.appColors.overlay,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.appColors.surfacePrimary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations?.translate('paste_link_title') ??
                    'Вставьте ссылку',
                style: context.appTextStyles.titleMd.copyWith(
                  color: context.appColors.textPrimary,
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.appColors.fieldBorder),
                  color: context.appColors.fieldBg,
                ),
                child: TextField(
                  controller: urlController,
                  autofocus: true,
                  style: context.appTextStyles.bodyMd,
                  decoration: InputDecoration(
                    hintText: 'https://example.com',
                    hintStyle: context.appTextStyles.bodyMd.copyWith(
                      color: context.appColors.fieldHint,
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      localizations?.translate('cancel') ?? 'Отмена',
                      style: context.appTextStyles.bodyMd.copyWith(
                        color: context.appColors.textSecondary,
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
                      backgroundColor: context.appColors.buttonPrimaryBg,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      localizations?.translate('add') ?? 'Добавить',
                      style: context.appTextStyles.bodyMd.copyWith(
                        color: context.appColors.buttonPrimaryFg,
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

    _closeFormattingPanel(restoreFocus: true);
  }

  void _selectAll() {
    widget.messageController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.messageController.text.length,
    );
    _closeFormattingPanel(restoreFocus: true);
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
    _closeFormattingPanel(restoreFocus: true);
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

    _closeFormattingPanel(restoreFocus: true);
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
    _htmlContent =
        _htmlContent.replaceRange(selection.start, selection.end, '');

    widget.messageController.text = newText;
    widget.messageController.selection = TextSelection.collapsed(
      offset: selection.start,
    );

    _closeFormattingPanel(restoreFocus: true);
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ChatAppearanceScope.of(context);
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

    if (editingMessage != null && widget.messageController.text.isEmpty) {
      widget.messageController.text = editingMessage.text;
      _htmlContent = editingMessage.text;
    }

    final textStyles = context.appTextStyles;
    final inputSurface = appearance.inputSurfaceColor(context);
    final accent = appearance.accentColor(context);
    final borderColor = context.adaptiveBorderOn(inputSurface);
    final primaryText = context.adaptiveForegroundOn(inputSurface);
    final hintText = context.adaptiveHintOn(inputSurface);

    return GestureDetector(
      onTap: () {
        if (_showFormattingPanel) {
          _closeFormattingPanel();
        }
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.only(left: 0, right: 0, top: 6, bottom: 20),
        child: Column(
          children: [
            if (replyingToMessage != null)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                decoration: BoxDecoration(
                  color: inputSurface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.55),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      height: 46,
                      margin: const EdgeInsets.only(right: 10, top: 2),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/chats/menu_icons/reply.svg',
                                width: 15,
                                height: 15,
                                colorFilter: ColorFilter.mode(
                                  context.appColors.iconSecondary,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: AppLocalizations.of(context)!
                                        .translate('in_answer'),
                                    style: textStyles.bodySm.copyWith(
                                      color: appearance.secondaryForeground(
                                        context,
                                        false,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: replyingToMessage.senderName,
                                        style: textStyles.bodySm.copyWith(
                                          color: accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  replyingToMessage.type == 'voice'
                                      ? AppLocalizations.of(context)!
                                          .translate('voice_message')
                                      : stripHtmlTags(replyingToMessage.text),
                                  style: textStyles.bodyMd.copyWith(
                                    color: primaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close,
                                    color: context.appColors.error, size: 22),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  context
                                      .read<MessagingCubit>()
                                      .clearReplyMessage();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (editingMessage != null)
              Container(
                decoration: BoxDecoration(
                  color: inputSurface.withValues(alpha: 0.94),
                  border: Border(
                    bottom: BorderSide(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(
                    left: 20, right: 6, top: 0, bottom: 0),
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
                          colorFilter: ColorFilter.mode(
                            context.appColors.iconSecondary,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 6),
                        RichText(
                          text: TextSpan(
                            text: AppLocalizations.of(context)!
                                .translate('edit_message'),
                            style: textStyles.bodySm.copyWith(
                              color: appearance.secondaryForeground(
                                context,
                                false,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: context.appColors.error, size: 28),
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

            // Поле ввода / голосовая запись
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: (context.watch<ListenSenderFileCubit>().state)
                  ? Container(
                      height: 42,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        color: context.appColors.buttonPrimaryBg,
                        strokeWidth: 2.5,
                      ),
                    )
                  : AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: _voicePressed ? 78 : 56,
                          maxHeight: _voicePressed ? 78 : 180,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: _voicePressed ? 0 : 1,
                              child: IgnorePointer(
                                ignoring: _voicePressed,
                                child: Container(
                                  clipBehavior: Clip.antiAlias,
                                  constraints:
                                      const BoxConstraints(minHeight: 56),
                                  decoration: BoxDecoration(
                                    color:
                                        inputSurface.withValues(alpha: 0.88),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 1.0,
                                    ),
                                    boxShadow: context.appShadows.card,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if (widget.isLeadChat)
                                        IconButton(
                                          icon: Image.asset(
                                            'assets/icons/chats/menu-button.png',
                                            width: 20,
                                            height: 20,
                                            color:
                                                context.appColors.iconPrimary,
                                          ),
                                          iconSize: 20,
                                          padding: const EdgeInsets.all(8),
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          onPressed: () {
                                            _closeFormattingPanel();
                                            _showTemplatesPanel(context);
                                          },
                                        ),
                                      Expanded(
                                        child: RichTextField(
                                          controller:
                                              widget.messageController,
                                          focusNode: widget.focusNode,
                                          onChanged: _handleTextChange,
                                          htmlContent: _htmlContent,
                                          onLongPress:
                                              _showFormattingPanelOnLongPress,
                                          hintText:
                                              AppLocalizations.of(context)!
                                                  .translate('enter_your_sms'),
                                          style: context.appTextStyles.bodyMd
                                              .copyWith(
                                            color: primaryText,
                                            fontSize:
                                                appearance.scaledFont(15),
                                            fontWeight:
                                                appearance.messageFontWeight,
                                            height: 1.3,
                                          ),
                                          hintStyle:
                                              textStyles.bodyMd.copyWith(
                                            color: hintText,
                                            fontWeight: FontWeight.w400,
                                            height: 1.3,
                                          ),
                                          fillColor: context
                                              .appColors.overlay
                                              .withValues(alpha: 0.0),
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 15,
                                          ),
                                          maxVisibleLines: 6,
                                          lineHeight: 20.0,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Image.asset(
                                          'assets/icons/chats/file.png',
                                          width: 20,
                                          height: 20,
                                          color:
                                              context.appColors.iconPrimary,
                                        ),
                                        iconSize: 20,
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        onPressed: widget.onAttachFile,
                                      ),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                            milliseconds: 250),
                                        transitionBuilder: (Widget child,
                                            Animation<double> animation) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: ScaleTransition(
                                              scale: animation,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: _hasText
                                            ? _buildSendButton(
                                                messagingCubit,
                                                editingMessage,
                                                replyMsgId)
                                            : const SizedBox(
                                                key: ValueKey(
                                                    'voice_placeholder'),
                                                width: 48,
                                                height: 48,
                                              ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (!_hasText || _voicePressed)
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildVoiceRecorder(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Кнопка отправки
  Widget _buildSendButton(
      MessagingCubit messagingCubit, editingMessage, String? replyMsgId) {
    final appearance = ChatAppearanceScope.of(context);
    final accent = appearance.accentColor(context);

    return (context.watch<ListenSenderTextCubit>().state)
        ? Container(
            key: ValueKey('loading'),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: context.appColors.buttonPrimaryBg,
                strokeWidth: 2,
              ),
            ),
          )
        : Material(
            key: ValueKey('send'),
            color: context.appColors.overlay.withValues(alpha: 0.0),
            child: InkWell(
              onTap: () {
                if (widget.messageController.text.isNotEmpty) {
                  if (editingMessage != null) {
                    messagingCubit.editMessage(_getHtmlContent());
                  } else {
                    widget.onSend(_getHtmlContent(), replyMsgId);
                    messagingCubit.clearReplyMessage();
                  }
                  widget.messageController.clear();
                  _htmlContent = '';
                  _closeFormattingPanel();
                  setState(() {
                    _showTemplates = false;
                    _animationController.reverse().then((_) {
                      _removeOverlay();
                    });
                  });
                }
              },
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/icons/chats/send.png',
                    width: 18,
                    height: 18,
                    color: accent,
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildVoiceRecorder() {
    final appearance = ChatAppearanceScope.of(context);
    final accent = appearance.accentColor(context);
    final inputSurface = appearance.inputSurfaceColor(context);
    final borderColor = context.adaptiveBorderOn(inputSurface);
    final primaryText = context.adaptiveForegroundOn(inputSurface);
    final cancelLabel = AppLocalizations.of(context)!.translate('cancel');

    final recorder = (context.watch<ListenSenderVoiceCubit>().state)
        ? Container(
            key: const ValueKey('voice_loading'),
            width: _voicePressed ? double.infinity : 48,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: inputSurface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor),
            ),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: accent,
                strokeWidth: 2.2,
              ),
            ),
          )
        : SocialMediaRecorder(
            key: const ValueKey('voice_recorder'),
            maxRecordTimeInSecond: 180,
            initRecordPackageWidth: 48,
            fullRecordPackageHeight: 52,
            startRecording: () {
              HapticFeedback.lightImpact();
              _setVoicePressed(true);
            },
            stopRecording: (time) {
              if (!mounted) return;
              _setVoicePressed(false);
            },
            sendRequestFunction: widget.sendRequestFunction,
            cancelText: cancelLabel,
            cancelTextStyle: context.appTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: primaryText.withValues(alpha: 0.72),
            ),
            slideToCancelText:
                AppLocalizations.of(context)!.translate('cancel_chat_sms'),
            slideToCancelTextStyle: context.appTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w500,
              color: primaryText.withValues(alpha: 0.72),
              letterSpacing: 0.1,
            ),
            cancelTextBackGroundColor: inputSurface.withValues(alpha: 0.96),
            recordIconBackGroundColor: accent,
            recordIconWhenLockBackGroundColor: accent,
            backGroundColor: inputSurface.withValues(alpha: 0.96),
            counterBackGroundColor: accent.withValues(alpha: 0.12),
            counterTextStyle: context.appTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w700,
              color: primaryText,
              letterSpacing: 0.4,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            recordIcon: _buildVoiceMicOrb(
              accent: accent,
              filled: true,
              size: 36,
            ),
            recordIconWhenLockedRecord: null,
            lockButton: Icon(
              Icons.lock_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: 0.95),
            ),
            sendButtonIcon: const Icon(
              Icons.send_rounded,
              size: 20,
              color: Colors.white,
            ),
            encode: AudioEncoderType.AAC,
            radius: BorderRadius.circular(999),
          );

    return SizedBox(
      width: _voicePressed ? double.infinity : 56,
      height: _voicePressed ? 72 : 56,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          // Expand bar width on the same frame as press to avoid Row overflow.
          _setVoicePressed(true);
        },
        onPointerCancel: (_) {
          // Keep true while package still records; stopRecording clears it.
        },
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerRight,
          children: [
            if (_voicePressed)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _micPulseController,
                  builder: (context, _) {
                    final t = _micPulseController.value;
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 96 + (t * 20),
                        height: 96 + (t * 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accent.withValues(alpha: 0.28),
                              accent.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _micPulseController,
                  builder: (context, _) {
                    final t = _micPulseController.value;
                    return Container(
                      width: 50 + (t * 5),
                      height: 50 + (t * 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.07 + (t * 0.04)),
                      ),
                    );
                  },
                ),
              ),
            recorder,
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceMicOrb({
    required Color accent,
    required bool filled,
    double size = 36,
  }) {
    final ringPad = _voicePressed ? 20.0 : 0.0;
    return SizedBox(
      width: size + ringPad,
      height: size + ringPad,
      child: AnimatedBuilder(
        animation: _micPulseController,
        builder: (context, _) {
          final t = _micPulseController.value;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (_voicePressed) ...[
                _pulseRing(accent: accent, progress: t, size: size + 20),
                _pulseRing(
                  accent: accent,
                  progress: (t + 0.5) % 1.0,
                  size: size + 20,
                ),
              ],
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? accent : accent.withValues(alpha: 0.16),
                  border: Border.all(
                    color: accent.withValues(alpha: filled ? 0.55 : 0.32),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          accent.withValues(alpha: _voicePressed ? 0.4 : 0.18),
                      blurRadius: _voicePressed ? 14 : 8,
                      spreadRadius: _voicePressed ? 1 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.mic_rounded,
                  size: size * 0.48,
                  color: filled ? Colors.white : accent,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pulseRing({
    required Color accent,
    required double progress,
    required double size,
  }) {
    final scale = 0.72 + progress * 0.78;
    final opacity = (1 - progress) * 0.42;
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: accent,
              width: 2.2 * (1 - progress * 0.6),
            ),
          ),
        ),
      ),
    );
  }

  void _showTemplatesPanel(BuildContext context) {
    _closeFormattingPanel();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.overlay.withValues(alpha: 0.0),
      enableDrag: true,
      isDismissible: true,
      builder: (BuildContext bottomSheetContext) => TemplatesPanel(
        onTemplateSelected: (String selectedText) {
          Navigator.of(bottomSheetContext).pop();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final plainText = stripHtmlTags(selectedText).trim();
            widget.messageController.text = plainText;
            _htmlContent = plainText;

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
