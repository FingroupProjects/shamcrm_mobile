import 'dart:ui';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

/// Открывает шторку «Настройки ИИ» с двумя переключателями.
/// [aiEnabled] и [followupEnabled] — начальное состояние (инверсия пауз).
Future<void> showChatAiSettingsSheet({
  required BuildContext context,
  required int chatId,
  required ApiService apiService,
  required bool aiEnabled,
  required bool followupEnabled,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _ChatAiSettingsSheet(
      chatId: chatId,
      apiService: apiService,
      aiEnabled: aiEnabled,
      followupEnabled: followupEnabled,
    ),
  );
}

class _ChatAiSettingsSheet extends StatefulWidget {
  const _ChatAiSettingsSheet({
    required this.chatId,
    required this.apiService,
    required this.aiEnabled,
    required this.followupEnabled,
  });

  final int chatId;
  final ApiService apiService;
  final bool aiEnabled;
  final bool followupEnabled;

  @override
  State<_ChatAiSettingsSheet> createState() => _ChatAiSettingsSheetState();
}

class _ChatAiSettingsSheetState extends State<_ChatAiSettingsSheet> {
  late bool _aiEnabled = widget.aiEnabled;
  late bool _followupEnabled = widget.followupEnabled;
  bool _aiBusy = false;
  bool _followupBusy = false;

  /// Меняет переключатель оптимистично, при ошибке откатывает назад.
  Future<void> _toggle({
    required bool value,
    required bool isFollowup,
  }) async {
    // Не даём дёргать, пока идёт предыдущий запрос по этому же тумблеру.
    if (isFollowup ? _followupBusy : _aiBusy) return;

    setState(() {
      if (isFollowup) {
        _followupEnabled = value;
        _followupBusy = true;
      } else {
        _aiEnabled = value;
        _aiBusy = true;
      }
    });

    try {
      if (isFollowup) {
        await widget.apiService.setChatFollowupEnabled(widget.chatId, value);
      } else {
        await widget.apiService.setChatAiEnabled(widget.chatId, value);
      }
    } catch (error) {
      if (!mounted) return;
      // Откат значения, чтобы UI не врал про реальное состояние.
      setState(() {
        if (isFollowup) {
          _followupEnabled = !value;
        } else {
          _aiEnabled = !value;
        }
      });
      showCustomSnackBar(
        context: context,
        message: AppLocalizations.of(context)?.translate('ai_settings_error') ??
            'Не удалось изменить настройку',
        isSuccess: false,
        aboveDialogs: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          if (isFollowup) {
            _followupBusy = false;
          } else {
            _aiBusy = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final loc = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfacePrimary.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Полоска-«ручка» вверху шторки.
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: colors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 20, color: colors.buttonPrimaryBg),
                  const SizedBox(width: 8),
                  Text(
                    loc?.translate('ai_settings') ?? 'Настройки ИИ',
                    style: context.appTextStyles.titleMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildToggleRow(
                title: loc?.translate('ai_in_chat') ?? 'ИИ в чате',
                value: _aiEnabled,
                busy: _aiBusy,
                onChanged: (v) => _toggle(value: v, isFollowup: false),
              ),
              const SizedBox(height: 12),
              _buildToggleRow(
                title: loc?.translate('ai_followup') ?? 'Дожим',
                value: _followupEnabled,
                busy: _followupBusy,
                onChanged: (v) => _toggle(value: v, isFollowup: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required bool value,
    required bool busy,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceElevated.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.appTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          // Пока идёт запрос, вместо переключателя — маленький спиннер.
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF22C55E),
            ),
        ],
      ),
    );
  }
}
