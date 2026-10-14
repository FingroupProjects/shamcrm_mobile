import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/absence/absence_widgets.dart';
import 'package:flutter/material.dart';

/// Причина отклонения заявки. Это ручной текст, не список причин как у лида.
/// В заявку уходит введённая строка как rejection_reason.
Future<String?> showAbsenceRejectDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _AbsenceRejectDialog(),
  );
}

class _AbsenceRejectDialog extends StatefulWidget {
  const _AbsenceRejectDialog();

  @override
  State<_AbsenceRejectDialog> createState() => _AbsenceRejectDialogState();
}

class _AbsenceRejectDialogState extends State<_AbsenceRejectDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _showValidation = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _showValidation = true);
      return;
    }
    Navigator.of(context).pop(reason);
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
                      absenceTr(context, 'absence_reject_reason'),
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
                    Text(
                      absenceTr(context, 'absence_reason'),
                      style: textStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _reasonController,
                      minLines: 3,
                      maxLines: 6,
                      onChanged: (_) {
                        if (_showValidation) {
                          setState(() => _showValidation = false);
                        }
                      },
                      style: textStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        errorText: _showValidation
                            ? absenceTr(context, 'field_required')
                            : null,
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
                            color: _showValidation
                                ? colors.error
                                : colors.borderSubtle.withValues(alpha: 0.7),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.buttonPrimaryBg),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
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
                              absenceTr(context, 'cancel'),
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
                              absenceTr(context, 'confirm'),
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
