import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class MultiDirectoryDropdownWidget extends StatefulWidget {
  final int directoryId;
  final String directoryName;
  final Function(List<MainField>) onSelectFields;
  final List<int>? selectedFieldIds;

  const MultiDirectoryDropdownWidget({
    super.key,
    required this.directoryId,
    required this.directoryName,
    required this.onSelectFields,
    this.selectedFieldIds,
  });

  @override
  State<MultiDirectoryDropdownWidget> createState() => _MultiDirectoryDropdownWidgetState();
}

class _MultiDirectoryDropdownWidgetState extends State<MultiDirectoryDropdownWidget> {
  List<MainField> mainFieldsList = [];
  List<MainField> selectedFields = [];
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
    _fetchMainFields();
  }

  @override
  void didUpdateWidget(MultiDirectoryDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFieldIds != oldWidget.selectedFieldIds) {
      _syncSelectedFields();
    }
  }

  void _syncSelectedFields() {
    if (widget.selectedFieldIds == null || widget.selectedFieldIds!.isEmpty) {
      setState(() {
        selectedFields = [];
      });
      return;
    }

    final ids = widget.selectedFieldIds!.toSet();
    final matched = mainFieldsList.where((e) => ids.contains(e.id)).toList();
    setState(() {
      selectedFields = matched;
    });
  }

  Future<void> _fetchMainFields() async {
    try {
      final response = await ApiService().getMainFields(widget.directoryId);
      if (!mounted) return;
      setState(() {
        mainFieldsList = response.result ?? [];
      });
      _syncSelectedFields();
    } catch (e) {
      if (!mounted) return;
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
              : CustomDropdown<MainField>.multiSelectSearch(
                  items: mainFieldsList,
                  initialItems: selectedFields,
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
                                color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              item.value,
                              style: statusTextStyle,
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
                    final count = selectedFields.length;
                    return Text(
                      count == 0
                          ? AppLocalizations.of(context)!.translate('select_field')
                          : '${AppLocalizations.of(context)!.translate('select_field')} $count',
                      style: statusTextStyle,
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_field'),
                    style: statusTextStyle.copyWith(fontSize: 14),
                  ),
                  onListChanged: (values) {
                    setState(() {
                      selectedFields = values;
                    });
                    widget.onSelectFields(values);
                  },
                ),
        ),
      ],
    );
  }
}


