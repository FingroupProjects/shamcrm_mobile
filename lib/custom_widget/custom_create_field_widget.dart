import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:intl/intl.dart';

class CustomFieldWidget extends StatelessWidget {
  final String fieldName;
  final TextEditingController valueController;
  final VoidCallback? onRemove;
  final bool isDirectory;
  final String? type;
  final bool isCustomField; // Новый флаг
  final String? Function(String?)? validator;
  final TextInputType? keyboardTypeOverride;
  final List<TextInputFormatter>? inputFormattersOverride;
  final int? maxLength;
  final bool showBorder;
  final AutovalidateMode? autovalidateMode;
  final bool? readOnlyOverride;
  final ValueChanged<String>? onChanged;

  const CustomFieldWidget({
    super.key,
    required this.fieldName,
    required this.valueController,
    this.onRemove,
    this.isDirectory = false,
    this.type,
    this.isCustomField = false, // По умолчанию false
    this.validator,
    this.keyboardTypeOverride,
    this.inputFormattersOverride,
    this.maxLength,
    this.showBorder = true,
    this.autovalidateMode,
    this.readOnlyOverride,
    this.onChanged,
  });

  Future<void> _selectDate(BuildContext context,
      {bool withTime = false}) async {
    // Пытаемся получить дату из контроллера, если она уже выбрана
    DateTime initialDate = DateTime.now();
    TimeOfDay initialTime = TimeOfDay.now();

    if (valueController.text.isNotEmpty) {
      try {
        if (withTime) {
          // Парсим дату и время в формате dd/MM/yyyy HH:mm
          final parsedDateTime =
              DateFormat('dd/MM/yyyy HH:mm').parse(valueController.text);
          initialDate = parsedDateTime;
          initialTime = TimeOfDay(
              hour: parsedDateTime.hour, minute: parsedDateTime.minute);
        } else {
          // Парсим только дату в формате dd/MM/yyyy
          initialDate = DateFormat('dd/MM/yyyy').parse(valueController.text);
        }
      } catch (e) {
        // Если не удалось распарсить, используем текущую дату
        debugPrint('Ошибка парсинга даты: $e');
      }
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
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
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (withTime) {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: initialTime,
          builder: (context, child) {
            final colors = context.appColors;
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: colors.buttonPrimaryBg,
                      onPrimary: colors.buttonPrimaryFg,
                    ),
              ),
              child: child!,
            );
          },
        );
        if (pickedTime != null) {
          final formattedDateTime = DateFormat('dd/MM/yyyy HH:mm').format(
            DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            ),
          );
          valueController.text = formattedDateTime;
        }
      } else {
        final formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
        valueController.text = formattedDate;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fieldFill = colors.fieldBg;
    final primaryText = context.adaptiveForegroundOn(fieldFill);
    final hintTextColor = context.adaptiveHintOn(fieldFill);

    TextInputType keyboardType;
    List<TextInputFormatter>? inputFormatters;
    bool readOnly = false;
    String hintText;

    // Определяем подсказку и настройки в зависимости от type
    switch (type) {
      case 'number':
        keyboardType = TextInputType.number;
        inputFormatters = [FilteringTextInputFormatter.digitsOnly];
        hintText = AppLocalizations.of(context)!.translate('enter_number');
        break;
      case 'date':
        keyboardType = TextInputType.none;
        readOnly = true;
        hintText = AppLocalizations.of(context)!.translate('enter_date');
        break;
      case 'datetime':
        keyboardType = TextInputType.none;
        readOnly = true;
        hintText = AppLocalizations.of(context)!.translate('enter_datetime');
        break;
      default: // string
        keyboardType = TextInputType.text;
        inputFormatters = null;
        hintText =
            AppLocalizations.of(context)!.translate('enter_textfield_text');
        break;
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fieldName,
                style: context.appTextStyles.labelLg.copyWith(
                  fontWeight: FontWeight.w500,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 8),
              if (!isDirectory)
                TextFormField(
                  controller: valueController,
                  keyboardType: keyboardTypeOverride ?? keyboardType,
                  inputFormatters: inputFormattersOverride ?? inputFormatters,
                  maxLength: maxLength,
                  validator: validator,
                  autovalidateMode: autovalidateMode,
                  readOnly: readOnlyOverride ?? readOnly,
                  onChanged: onChanged,
                  onTap: type == 'date' || type == 'datetime'
                      ? () => _selectDate(context, withTime: type == 'datetime')
                      : null,
                  decoration: InputDecoration(
                    hintText: hintText, // Используем динамическую подсказку
                    hintStyle: context.appTextStyles.bodyMd.copyWith(
                      color: hintTextColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: showBorder
                          ? BorderSide(color: colors.borderSubtle, width: 1)
                          : BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: showBorder
                          ? BorderSide(color: colors.borderSubtle, width: 1)
                          : BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: showBorder
                          ? BorderSide(
                              color: colors.buttonPrimaryBg.withValues(alpha: 0.6),
                              width: 1.2,
                            )
                          : BorderSide.none,
                    ),
                    filled: true,
                    fillColor: fieldFill,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    counterText: '',
                    errorMaxLines: 2,
                  ),
                  style: context.appTextStyles.bodyLg.copyWith(
                    color: primaryText,
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: fieldFill,
                    borderRadius: context.appRadius.input,
                    border: showBorder
                        ? Border.all(color: colors.borderSubtle, width: 1)
                        : null,
                  ),
                  child: Text(
                    fieldName,
                    style: context.appTextStyles.bodyLg.copyWith(
                      color: primaryText,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (onRemove != null)
          IconButton(
            icon: Icon(
              Icons.remove_circle,
              color: context.appColors.buttonDanger,
            ),
            onPressed: onRemove,
          ),
      ],
    );
  }
}
