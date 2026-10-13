import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/models/absence/absence_models.dart';
import 'package:crm_task_manager/screens/absence/absence_logic.dart';
import 'package:crm_task_manager/screens/absence/absence_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Лимиты на месяц. Пустое поле — лимита нет, 0 — такой тип одобрять нельзя.
class AbsenceSettingsSheet extends StatefulWidget {
  const AbsenceSettingsSheet({super.key});

  @override
  State<AbsenceSettingsSheet> createState() => _AbsenceSettingsSheetState();
}

class _AbsenceSettingsSheetState extends State<AbsenceSettingsSheet> {
  final ApiService _api = ApiService();
  final TextEditingController _fullDay = TextEditingController();
  final TextEditingController _partial = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _offline = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullDay.dispose();
    _partial.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _offline = false;
      _error = null;
    });
    try {
      final settings = await _api.getAbsenceSettings();
      if (!mounted) return;
      _fullDay.text = _text(settings.fullDayLimit);
      _partial.text = _text(settings.partialLimit);
      setState(() => _loading = false);
    } on AbsenceApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _offline = error.network;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  String _text(int? value) => value == null ? '' : '$value';

  Future<void> _save() async {
    late final Map<String, dynamic> body;
    try {
      body = absenceSettingsBody(
        fullDay: _fullDay.text,
        partial: _partial.text,
      );
    } on FormatException {
      setState(() => _error = 'absence_err_limits');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.updateAbsenceSettings(body);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on AbsenceApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.fieldErrors.isNotEmpty
            ? error.fieldErrors.values.join('\n')
            : error.message;
      });
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AbsenceSheetHeader(title: absenceTr(context, 'absence_settings')),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_offline) {
      return _Message(
        text: absenceTr(context, 'absence_offline'),
        action: absenceTr(context, 'absence_retry'),
        onPressed: _load,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        _limitField(
          controller: _fullDay,
          label: absenceTr(context, 'absence_limit_full'),
        ),
        const SizedBox(height: 14),
        _limitField(
          controller: _partial,
          label: absenceTr(context, 'absence_limit_partial'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            absenceTr(context, _error!),
            style: absenceStyle(context, size: 13, color: context.appColors.error),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: absencePrimaryButton(
            context: context,
            label: absenceTr(context, 'save'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.appColors.textInverse,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _limitField({
    required TextEditingController controller,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AbsenceFieldLabel(label),
        TextField(
          controller: controller,
          enabled: !_saving,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: absenceStyle(context, size: 16),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: context.appColors.fieldBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: AppFieldStyle.outline(context),
            enabledBorder: AppFieldStyle.outline(context),
            focusedBorder: AppFieldStyle.outline(context, focused: true),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.text,
    required this.action,
    required this.onPressed,
  });

  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center, style: absenceStyle(context)),
            const SizedBox(height: 12),
            absencePrimaryButton(
              context: context,
              label: action,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}
