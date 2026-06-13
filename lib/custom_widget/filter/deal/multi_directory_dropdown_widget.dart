import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Colors.white,
            ),
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
    final statusTextStyle = context.appTextStyles.bodyMd.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );
    final hintStyle = statusTextStyle.copyWith(
      fontSize: 14,
      color: context.appColors.textSecondary,
    );
    final fieldColor = context.appColors.surfacePrimary.withValues(alpha: 0.78);
    final borderColor = context.appColors.borderSubtle.withValues(alpha: 0.36);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppLocalizations.of(context)!.translate('directory')}(${widget.directoryName})',
          style: statusTextStyle.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              width: 1,
              color: borderColor,
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
                    closedFillColor: fieldColor,
                    expandedFillColor: context.appColors.surfacePrimary,
                    closedBorder: Border.all(
                      color: Colors.transparent,
                      width: 1,
                    ),
                    closedBorderRadius: BorderRadius.circular(18),
                    expandedBorder: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                    expandedBorderRadius: BorderRadius.circular(18),
                    hintStyle: hintStyle,
                    headerStyle: statusTextStyle,
                    listItemStyle: statusTextStyle,
                    listItemDecoration: ListItemDecoration(
                      selectedColor:
                          context.appColors.buttonPrimaryBg.withValues(alpha: 0.14),
                      highlightColor:
                          context.appColors.buttonPrimaryBg.withValues(alpha: 0.08),
                      splashColor: Colors.transparent,
                    ),
                    searchFieldDecoration: SearchFieldDecoration(
                      fillColor: context.appColors.backgroundPrimary,
                      textStyle: statusTextStyle,
                      hintStyle: hintStyle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: GestureDetector(
                        onTap: () {
                          onItemSelect();
                          FocusScope.of(context).unfocus();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: context.appColors.buttonPrimaryBg,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                color: isSelected
                                    ? context.appColors.buttonPrimaryBg
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: context.appColors.buttonPrimaryFg,
                                      size: 16,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.value,
                                style: statusTextStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  headerListBuilder: (context, hint, enabled) {
                    final count = selectedFields.length;
                    return Text(
                      count == 0
                          ? AppLocalizations.of(context)!.translate('select_field')
                          : '${AppLocalizations.of(context)!.translate('select_field')} $count',
                      style: statusTextStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_field'),
                    style: hintStyle,
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
