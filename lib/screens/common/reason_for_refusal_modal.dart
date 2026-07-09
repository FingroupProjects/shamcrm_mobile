import 'package:crm_task_manager/models/reason_for_refusal_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/common/reason_for_refusal_dropdown.dart';
import 'package:flutter/material.dart';

class ReasonForRefusalSubmitData {
  final int reasonId;
  final String? comment;

  const ReasonForRefusalSubmitData({
    required this.reasonId,
    this.comment,
  });
}

Future<ReasonForRefusalSubmitData?> showReasonForRefusalDialog({
  required BuildContext context,
  required String type,
}) {
  return showDialog<ReasonForRefusalSubmitData>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _ReasonForRefusalDialog(type: type),
  );
}

class _ReasonForRefusalDialog extends StatefulWidget {
  final String type;

  const _ReasonForRefusalDialog({
    required this.type,
  });

  @override
  State<_ReasonForRefusalDialog> createState() =>
      _ReasonForRefusalDialogState();
}

class _ReasonForRefusalDialogState extends State<_ReasonForRefusalDialog> {
  final TextEditingController _commentController = TextEditingController();
  ReasonForRefusalData? _selectedReason;
  bool _showValidation = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_selectedReason == null) {
      setState(() {
        _showValidation = true;
      });
      return;
    }

    final comment = _commentController.text.trim();
    Navigator.of(context).pop(
      ReasonForRefusalSubmitData(
        reasonId: _selectedReason!.id,
        comment: comment.isEmpty ? null : comment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height - keyboardInset - 24;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(12, 12, 12, keyboardInset + 12),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: availableHeight > 260 ? availableHeight : 260,
            ),
            child: Material(
              color: colors.surfacePrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: colors.borderSubtle),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Причина отказа',
                      style: textStyles.titleLg.copyWith(
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: colors.borderSubtle),
                    const SizedBox(height: 10),
                    ReasonForRefusalDropdown(
                      type: widget.type,
                      showError: _showValidation,
                      onSelectReason: (reason) {
                        setState(() {
                          _selectedReason = reason;
                          _showValidation = false;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Комментарий',
                      style: textStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _commentController,
                      minLines: 2,
                      maxLines: 3,
                      style: textStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Введите комментарий',
                        hintStyle: textStyles.bodyLg.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                        filled: true,
                        fillColor: colors.fieldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.borderSubtle.withValues(alpha: 0.7),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.borderSubtle.withValues(alpha: 0.7),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.buttonPrimaryBg,
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor:
                                  colors.buttonSecondaryBg.withValues(alpha: 0.14),
                              foregroundColor: colors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: colors.borderSubtle),
                              ),
                            ),
                            child: Text(
                              'Отмена',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _onConfirm,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: colors.buttonPrimaryBg,
                              foregroundColor: colors.buttonPrimaryFg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Подтвердить',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.buttonPrimaryFg,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
