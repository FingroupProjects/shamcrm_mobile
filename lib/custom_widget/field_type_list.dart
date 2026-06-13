import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class FieldTypeList extends StatefulWidget {
  final String? selectedFieldType;
  final Function(String? value, String? key) onChanged;

  const FieldTypeList({
    Key? key,
    required this.selectedFieldType,
    required this.onChanged,
  }) : super(key: key);

  @override
  _FieldTypeListState createState() => _FieldTypeListState();
}

class _FieldTypeListState extends State<FieldTypeList> {
  // Статичные данные типов полей
  List<Map<String, dynamic>> getFieldTypes(BuildContext context) {
    return [
      {'key': 'string', 'name': AppLocalizations.of(context)!.translate('field_type_text')},
      {'key': 'number', 'name': AppLocalizations.of(context)!.translate('field_type_number')},
      {'key': 'date', 'name': AppLocalizations.of(context)!.translate('field_type_date')},
      {'key': 'datetime', 'name': AppLocalizations.of(context)!.translate('field_type_datetime')},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fieldTypes = getFieldTypes(context);
    
    List<DropdownMenuItem<String>> dropdownItems = fieldTypes
        .map<DropdownMenuItem<String>>((fieldType) {
      return DropdownMenuItem<String>(
        value: fieldType['key'],
          child: Text(
          fieldType['name'],
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('field_type'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: colors.surfacePrimary.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            menuMaxHeight: 400,
            value: dropdownItems.any((item) => item.value == widget.selectedFieldType)
                ? widget.selectedFieldType
                : null,
            hint: Text(
              AppLocalizations.of(context)!.translate('select_field_type'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.fieldHint,
              ),
            ),
            items: dropdownItems,
            onChanged: (String? value) {
              if (value != null) {
                final selectedFieldType = fieldTypes
                    .firstWhere((fieldType) => fieldType['key'] == value);
                widget.onChanged(selectedFieldType['name'], selectedFieldType['key']);
              } else {
                widget.onChanged(null, null);
              }
            },
            validator: (value) {
              if (value == null) {
                return AppLocalizations.of(context)!.translate('field_required');
              }
              return null;
            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: colors.borderSubtle),
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.borderSubtle),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.buttonPrimaryBg),
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colors.surfacePrimary,
            ),
            dropdownColor: colors.surfacePrimary,
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
