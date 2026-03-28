import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class DirectoryDropdownWidget extends StatefulWidget {
  final int directoryId;
  final String directoryName;
  final Function(MainField?) onSelectField;
  final MainField? initialField;

  DirectoryDropdownWidget({
    super.key,
    required this.directoryId,
    required this.directoryName,
    required this.onSelectField,
    this.initialField,
  });

  @override
  State<DirectoryDropdownWidget> createState() => _DirectoryDropdownWidgetState();
}

class _DirectoryDropdownWidgetState extends State<DirectoryDropdownWidget> {
  List<MainField> mainFieldsList = [];
  MainField? selectedField;
  String? errorMessage;

  final TextStyle statusTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    _syncSelectedField();
    _fetchMainFields();
  }

  @override
  void didUpdateWidget(DirectoryDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialField != oldWidget.initialField) {
      _syncSelectedField();
    }
  }

  void _syncSelectedField() {
    if (widget.initialField == null || !mainFieldsList.contains(widget.initialField)) {
      setState(() {
        selectedField = null;
      });
    } else {
      setState(() {
        selectedField = widget.initialField;
      });
    }
  }

  Future<void> _fetchMainFields() async {
    try {
      final response = await ApiService().getMainFields(widget.directoryId);
      if (mounted) {
        setState(() {
          mainFieldsList = response.result ?? [];
          _syncSelectedField(); // Синхронизируем selectedField после загрузки данных
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage!,
              style: statusTextStyle.copyWith(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.red,
            elevation: 3,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppLocalizations.of(context)!.translate('directory')}(${widget.directoryName})',
          style: statusTextStyle.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 1,
              color: const Color(0xFFF4F7FD),
            ),
          ),
          child: errorMessage != null
              ? const SizedBox.shrink()
              : CustomDropdown<MainField>.search(
                  closeDropDownOnClearFilterSearch: true,
                  items: mainFieldsList,
                  searchHintText: AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
                  decoration: CustomDropdownDecoration(
                    closedFillColor: const Color(0xFFF4F7FD),
                    expandedFillColor: Colors.white,
                    closedBorder: Border.all(
                      color: const Color(0xFFF4F7FD),
                      width: 1,
                    ),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(
                      color: const Color(0xFFF4F7FD),
                      width: 1,
                    ),
                    expandedBorderRadius: BorderRadius.circular(12),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(item.value, style: statusTextStyle),
                    );
                  },
                  headerBuilder: (context, selectedItem, isFocused) {
                    return Text(
                      selectedItem?.value ?? AppLocalizations.of(context)!.translate('select_field'),
                      style: statusTextStyle,
                    );
                  },
                  hintBuilder: (context, hint, isFocused) {
                    return Text(
                      AppLocalizations.of(context)!.translate('select_field'),
                      style: statusTextStyle.copyWith(fontSize: 14),
                    );
                  },
                  excludeSelected: false,
                  initialItem: selectedField,
                  onChanged: (MainField? value) {
                    setState(() {
                      selectedField = value;
                    });
                    widget.onSelectField(value);
                  },
                ),
        ),
      ],
    );
  }
}