import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Компактный выбор срока годности в карточке товара.
/// Хранит дату в формате yyyy-MM-dd для API.
class CompactExpirationDateField extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;

  const CompactExpirationDateField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static final DateFormat apiFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat uiFormat = DateFormat('dd/MM/yyyy');

  /// Приводит ответ API или UI-дату к yyyy-MM-dd.
  static String? toApiDate(dynamic raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    try {
      return apiFormat.format(DateTime.parse(text));
    } catch (_) {
      try {
        return apiFormat.format(uiFormat.parse(text));
      } catch (_) {
        return null;
      }
    }
  }

  /// Показывает дату в карточке: 20/09/2026.
  static String toUiDate(String? apiDate) {
    final normalized = toApiDate(apiDate);
    if (normalized == null) return '';
    try {
      return uiFormat.format(apiFormat.parse(normalized));
    } catch (_) {
      return normalized;
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    DateTime initialDate = DateTime.now();
    final parsed = toApiDate(value);
    if (parsed != null) {
      try {
        initialDate = apiFormat.parse(parsed);
      } catch (_) {}
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime(2101),
      fieldHintText: localizations?.translate('ddmmyyyy'),
      cancelText: localizations?.translate('back'),
      confirmText: localizations?.translate('ok'),
      helpText: localizations?.translate('select_date'),
      builder: (context, child) {
        final colors = context.appColors;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: colors.buttonPrimaryBg,
                  onPrimary: colors.buttonPrimaryFg,
                  surface: colors.surfacePrimary,
                  onSurface: colors.textPrimary,
                ),
            dialogTheme: Theme.of(context).dialogTheme.copyWith(
                  backgroundColor: colors.surfacePrimary,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (pickedDate != null) {
      onChanged(apiFormat.format(pickedDate));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final label = AppLocalizations.of(context)?.translate('goods_expiration_date') ??
        'Срок годности';
    final displayValue = toUiDate(value);
    final hasValue = displayValue.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w400,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _pickDate(context),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 16,
                  color: colors.buttonPrimaryBg,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasValue ? displayValue : label,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: hasValue ? colors.textPrimary : colors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasValue)
                  GestureDetector(
                    onTap: () => onChanged(''),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
