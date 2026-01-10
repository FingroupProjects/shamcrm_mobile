import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class LabelMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedLabels;
  final Function(List<String>) onSelectLabels;

  const LabelMultiSelectWidget({
    super.key,
    this.selectedLabels,
    required this.onSelectLabels,
  });

  @override
  State<LabelMultiSelectWidget> createState() => _LabelMultiSelectWidgetState();
}

class _LabelMultiSelectWidgetState extends State<LabelMultiSelectWidget> {
  final List<String> labelsList = ['hit', 'promotion', 'newest'];
  List<String> selectedLabelsData = [];

  @override
  void initState() {
    super.initState();
    if (widget.selectedLabels != null) {
      selectedLabelsData = widget.selectedLabels!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('label'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<String>.multiSelectSearch(
          items: labelsList,
          initialItems: selectedLabelsData,
          searchHintText: AppLocalizations.of(context)!.translate('search'),
          overlayHeight: 400,
          decoration:  CustomDropdownDecoration(
            closedFillColor: Color(0xffF4F7FD),
            expandedFillColor: Colors.white,
            closedBorder: Border.all(
              color: Color(0xffF4F7FD),
              width: 1,
            ),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(
              color: Color(0xffF4F7FD),
              width: 1,
            ),
            expandedBorderRadius: BorderRadius.circular(12),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return ListTile(
              minTileHeight: 1,
              minVerticalPadding: 2,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Padding(
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xff1E2E52), width: 1),
                        color: isSelected
                            ? const Color(0xff1E2E52)
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.translate(item),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                onItemSelect();
                FocusScope.of(context).unfocus();
              },
            );
          },
          headerListBuilder: (context, hint, enabled) {
            int selectedLabelsCount = selectedLabelsData.length;
            return Text(
              selectedLabelsCount == 0
                  ? AppLocalizations.of(context)!.translate('select_label')
                  : '${AppLocalizations.of(context)!.translate('select_label')} $selectedLabelsCount',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_label'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
          onListChanged: (values) {
            widget.onSelectLabels(values);
            setState(() {
              selectedLabelsData = values;
            });
          },
        ),
      ],
    );
  }
}