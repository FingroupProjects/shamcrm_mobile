import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

/// Шторка «Подсказка для ИИ»:
/// - Поле ввода для подсказки
/// - Чекбокс «Отправить сразу»
/// - Кнопка «Отправить»
class ChatAiInstructSheet extends StatefulWidget {
  final Future<void> Function(String instruction, String type) onInstruct;

  const ChatAiInstructSheet({
    super.key,
    required this.onInstruct,
  });

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(String instruction, String type) onInstruct,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChatAiInstructSheet(
        onInstruct: onInstruct,
      ),
    );
  }

  @override
  State<ChatAiInstructSheet> createState() => _ChatAiInstructSheetState();
}

class _ChatAiInstructSheetState extends State<ChatAiInstructSheet> {
  final TextEditingController _instructionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _sendImmediately = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _instructionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleInstruct() async {
    final text = _instructionController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final type = _sendImmediately ? 'immediate' : 'draft';
    try {
      Navigator.of(context).pop();
      await widget.onInstruct(text, type);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final loc = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasText = _instructionController.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ручка шторки
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Заголовок: Подсказка для ИИ + Закрыть
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc?.translate('ai_prompt_title') ?? 'Подсказка для ИИ',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Поле ввода подсказки
              TextField(
                controller: _instructionController,
                focusNode: _focusNode,
                minLines: 3,
                maxLines: 5,
                enabled: !_isSubmitting,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: loc?.translate('ai_instruction_hint') ??
                      'Например: предложи скидку 50%',
                  hintStyle: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                  filled: true,
                  fillColor: colors.backgroundSecondary.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: colors.buttonPrimaryBg, width: 1.5),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 12),

              // Чекбокс: Отправить сразу
              InkWell(
                onTap: _isSubmitting
                    ? null
                    : () => setState(() => _sendImmediately = !_sendImmediately),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _sendImmediately,
                          activeColor: colors.buttonPrimaryBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: _isSubmitting
                              ? null
                              : (v) => setState(
                                  () => _sendImmediately = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loc?.translate('ai_send_immediately') ??
                            'Отправить сразу',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Кнопка: всегда "Отправить"
              CustomButton(
                buttonText: loc?.translate('send') ?? 'Отправить',
                buttonColor: colors.buttonPrimaryBg,
                textColor: colors.buttonPrimaryFg,
                isLoading: _isSubmitting,
                onPressed: (!hasText || _isSubmitting) ? null : _handleInstruct,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
