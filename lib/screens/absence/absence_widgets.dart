import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/models/absence/absence_models.dart';
import 'package:crm_task_manager/screens/absence/absence_logic.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

String absenceTr(BuildContext context, String key) {
  return AppLocalizations.of(context)?.translate(key) ?? key;
}

TextStyle absenceStyle(
  BuildContext context, {
  double size = 15,
  FontWeight weight = FontWeight.w500,
  Color? color,
  double height = 1.35,
}) {
  return TextStyle(
    fontFamily: 'Gilroy',
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color ?? context.appColors.textPrimary,
  );
}

/// На маленьком экране лист занимает всю высоту, иначе почти всю.
Future<T?> showAbsenceSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final full = MediaQuery.sizeOf(context).height < 700;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.appColors.surfacePrimary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(full ? 0 : 20),
      ),
    ),
    builder: (sheetContext) {
      final size = MediaQuery.sizeOf(sheetContext);
      final inset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: full ? size.height : size.height * 0.92,
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: sheetContext.appColors.borderPrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Flexible(child: builder(sheetContext)),
            ],
          ),
        ),
      );
    },
  );
}

class AbsenceSheetHeader extends StatelessWidget {
  const AbsenceSheetHeader({
    super.key,
    required this.title,
    this.onClose,
  });

  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: absenceStyle(context, size: 20, weight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: onClose ?? () => Navigator.pop(context),
            tooltip: absenceTr(context, 'close'),
            icon: Icon(Icons.close, color: context.appColors.iconPrimary),
          ),
        ],
      ),
    );
  }
}

InputDecoration absenceFieldDecoration(
  BuildContext context, {
  required String label,
  bool required = false,
  String? error,
}) {
  final colors = context.appColors;
  final text = required ? '$label *' : label;
  return InputDecoration(
    labelText: text,
    errorText: error,
    filled: true,
    fillColor: colors.fieldBg,
    labelStyle: absenceStyle(context, size: 13, color: colors.textMuted),
    errorStyle: absenceStyle(context, size: 12, color: colors.error, height: 1.2),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.fieldBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.fieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.buttonPrimaryBg, width: 1.4),
    ),
  );
}

/// Цвет статуса всегда идёт вместе с текстом.
class AbsenceStatusBadge extends StatelessWidget {
  const AbsenceStatusBadge({
    super.key,
    required this.status,
    required this.label,
  });

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkTheme;
    final colors = _colors(dark);
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.$1,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: absenceStyle(
            context,
            size: 12,
            weight: FontWeight.w600,
            color: colors.$2,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  (Color, Color) _colors(bool dark) {
    switch (status) {
      case 'pending':
        return dark
            ? (const Color(0xFF3D3115), const Color(0xFFF0C36A))
            : (const Color(0xFFFDF0D2), const Color(0xFF8A5A00));
      case 'approved':
        return dark
            ? (const Color(0xFF1B3A29), const Color(0xFF7FD29D))
            : (const Color(0xFFDFF1E5), const Color(0xFF1D6B3A));
      case 'rejected':
        return dark
            ? (const Color(0xFF432123), const Color(0xFFF0A0A0))
            : (const Color(0xFFF9DEDE), const Color(0xFF9A2A2A));
      default:
        return dark
            ? (const Color(0xFF232D38), const Color(0xFF93A0AD))
            : (const Color(0xFFE6ECF2), const Color(0xFF66727F));
    }
  }
}

String absenceStatusText(BuildContext context, AbsenceRequest request) {
  if (request.statusLabel.trim().isNotEmpty) return request.statusLabel.trim();
  final key = absenceStatusLabelKey(request.status);
  if (key.isEmpty) return request.status;
  return absenceTr(context, key);
}

String absenceTypeText(BuildContext context, AbsenceRequest request) {
  if (request.typeLabel.trim().isNotEmpty) return request.typeLabel.trim();
  final key = absenceTypeLabelKey(request.type);
  if (key.isEmpty) return request.type;
  return absenceTr(context, key);
}

class AbsenceWarningBanner extends StatelessWidget {
  const AbsenceWarningBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF3D3115) : const Color(0xFFFDF0D2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: absenceStyle(
          context,
          size: 13,
          color: dark ? const Color(0xFFF0C36A) : const Color(0xFF8A5A00),
        ),
      ),
    );
  }
}

/// Подпись над полем, как в остальных формах приложения.
class AbsenceFieldLabel extends StatelessWidget {
  const AbsenceFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Gilroy',
        ).copyWith(color: context.appColors.textPrimary),
      ),
    );
  }
}

/// Поле-кнопка для даты и времени. Выглядит так же, как обычное поле.
class AbsenceTapField extends StatelessWidget {
  const AbsenceTapField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.error,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? error;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasError = error != null && error!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AbsenceFieldLabel(label),
        Material(
          color: colors.fieldBg,
          borderRadius: AppFieldStyle.radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppFieldStyle.radius,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: AppFieldStyle.radius,
                border: Border.fromBorderSide(
                  AppFieldStyle.side(context, hasError: hasError),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: absenceStyle(context, size: 16),
                    ),
                  ),
                  if (onClear != null && value.isNotEmpty)
                    IconButton(
                      onPressed: onClear,
                      icon: Icon(Icons.close, color: colors.iconSecondary, size: 18),
                    )
                  else
                    Icon(Icons.keyboard_arrow_down_rounded, color: colors.iconSecondary),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(error!, style: AppFieldStyle.errorTextStyle(context)),
          ),
      ],
    );
  }
}

Widget absencePrimaryButton({
  required BuildContext context,
  required String label,
  required VoidCallback? onPressed,
  Widget? child,
}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      backgroundColor: context.appColors.buttonPrimaryBg,
      foregroundColor: context.appColors.textInverse,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: child ??
        Text(
          label,
          style: absenceStyle(
            context,
            size: 16,
            weight: FontWeight.w700,
            color: context.appColors.textInverse,
          ),
        ),
  );
}

Widget absenceSecondaryButton({
  required BuildContext context,
  required String label,
  required VoidCallback? onPressed,
  Color? foreground,
}) {
  final color = foreground ?? context.appColors.textPrimary;
  return OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      foregroundColor: color,
      side: BorderSide(
        color: foreground ?? context.appColors.borderSubtle,
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(
      label,
      style: absenceStyle(context, size: 15, weight: FontWeight.w700, color: color),
    ),
  );
}

ThemeData absencePickerTheme(BuildContext context) {
  final colors = context.appColors;
  return Theme.of(context).copyWith(
    colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: colors.buttonPrimaryBg,
          onPrimary: colors.buttonPrimaryFg,
          surface: colors.surfacePrimary,
          onSurface: colors.textPrimary,
        ),
    dialogTheme: Theme.of(context).dialogTheme.copyWith(
          backgroundColor: colors.surfacePrimary,
        ),
  );
}

class AbsenceSkeletonList extends StatelessWidget {
  const AbsenceSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.borderSubtle;
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        height: 84,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
