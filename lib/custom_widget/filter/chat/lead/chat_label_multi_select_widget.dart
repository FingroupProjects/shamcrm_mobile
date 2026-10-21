import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class ChatLabelMultiSelectWidget extends StatefulWidget {
  final List<ChatLabel>? selectedLabels;
  final Function(List<ChatLabel>) onSelectLabels;

  const ChatLabelMultiSelectWidget({
    super.key,
    required this.onSelectLabels,
    this.selectedLabels,
  });

  @override
  State<ChatLabelMultiSelectWidget> createState() =>
      _ChatLabelMultiSelectWidgetState();
}

class _ChatLabelMultiSelectWidgetState
    extends State<ChatLabelMultiSelectWidget> {
  static List<ChatLabel>? _cachedLabels;

  List<ChatLabel> labelsList = [];
  List<ChatLabel> selectedLabelsData = [];
  bool allSelected = false;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (_cachedLabels != null && _cachedLabels!.isNotEmpty) {
      labelsList = List.from(_cachedLabels!);
      _syncInitialSelection();
    }
    _fetchLabels();
  }

  @override
  void didUpdateWidget(covariant ChatLabelMultiSelectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLabels != oldWidget.selectedLabels) {
      _syncInitialSelection();
    }
  }

  void _syncInitialSelection() {
    if (widget.selectedLabels != null && labelsList.isNotEmpty) {
      final selectedIds = widget.selectedLabels!.map((l) => l.id).toSet();
      selectedLabelsData =
          labelsList.where((l) => selectedIds.contains(l.id)).toList();
      allSelected =
          selectedLabelsData.length == labelsList.length && labelsList.isNotEmpty;
    } else if (widget.selectedLabels != null && widget.selectedLabels!.isNotEmpty) {
      selectedLabelsData = List.from(widget.selectedLabels!);
    } else {
      selectedLabelsData = [];
      allSelected = false;
    }
  }

  Future<void> _fetchLabels() async {
    if (_cachedLabels == null || _cachedLabels!.isEmpty) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final fetched = await ApiService().getChatLabels();
      if (!mounted) return;
      _cachedLabels = fetched;
      setState(() {
        labelsList = fetched;
        isLoading = false;
        errorMessage = null;
        _syncInitialSelection();
      });
    } catch (e) {
      if (!mounted) return;
      if (labelsList.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      if (allSelected) {
        selectedLabelsData = List.from(labelsList);
      } else {
        selectedLabelsData = [];
      }
      widget.onSelectLabels(selectedLabelsData);
    });
  }

  Color _parseLabelColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) {
      return const Color(0xFF6366F1);
    }
    try {
      String hex = colorStr.replaceAll('#', '').trim();
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
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
      color: context.appColors.textSecondary,
    );
    final surfaceColor =
        context.appColors.surfacePrimary.withValues(alpha: 0.78);
    final borderColor =
        context.appColors.borderSubtle.withValues(alpha: 0.36);
    final overlayColor = context.appColors.surfacePrimary;

    final labelsTitle =
        AppLocalizations.of(context)!.translate('labels');
    final selectLabelsHint =
        AppLocalizations.of(context)!.translate('select_labels');

    return FormField<List<ChatLabel>>(
      builder: (FormFieldState<List<ChatLabel>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              labelsTitle,
              style: statusTextStyle.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  width: 1,
                  color: field.hasError
                      ? context.appColors.error
                      : borderColor,
                ),
              ),
              child: _buildContent(
                context: context,
                surfaceColor: surfaceColor,
                overlayColor: overlayColor,
                borderColor: borderColor,
                statusTextStyle: statusTextStyle,
                hintStyle: hintStyle,
                selectLabelsHint: selectLabelsHint,
                field: field,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required Color surfaceColor,
    required Color overlayColor,
    required Color borderColor,
    required TextStyle statusTextStyle,
    required TextStyle hintStyle,
    required String selectLabelsHint,
    required FormFieldState<List<ChatLabel>> field,
  }) {
    if (isLoading && labelsList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.appColors.buttonPrimaryBg,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              selectLabelsHint,
              style: hintStyle.copyWith(fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null && labelsList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Ошибка загрузки меток',
                style: hintStyle.copyWith(
                  color: context.appColors.error,
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: context.appColors.buttonPrimaryBg,
                size: 20,
              ),
              onPressed: _fetchLabels,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    return CustomDropdown<ChatLabel>.multiSelectSearch(
      items: labelsList,
      initialItems: selectedLabelsData,
      searchHintText: AppLocalizations.of(context)!.translate('search'),
      noResultFoundText:
          AppLocalizations.of(context)!.translate('nothing_found'),
      overlayHeight: 400,
      decoration: CustomDropdownDecoration(
        closedFillColor: surfaceColor,
        expandedFillColor: overlayColor,
        closedBorder: Border.all(
          color: context.appColors.borderSubtle,
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
        final isFirst = labelsList.isNotEmpty && labelsList.first == item;
        if (isFirst) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: GestureDetector(
                  onTap: _toggleSelectAll,
                  child: Row(
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
                          color: allSelected
                              ? context.appColors.buttonPrimaryBg
                              : Colors.transparent,
                        ),
                        child: allSelected
                            ? Icon(
                                Icons.check,
                                color: context.appColors.buttonPrimaryFg,
                                size: 14,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!
                              .translate('select_all'),
                          style: statusTextStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 20, color: borderColor),
              _buildListItem(context, item, isSelected, onItemSelect, statusTextStyle),
            ],
          );
        }
        return _buildListItem(context, item, isSelected, onItemSelect, statusTextStyle);
      },
      headerListBuilder: (context, hint, enabled) {
        final selectedNames = selectedLabelsData.isEmpty
            ? selectLabelsHint
            : selectedLabelsData.map((e) => e.name).join(', ');
        return Text(
          selectedNames,
          style: statusTextStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
      hintBuilder: (context, hint, enabled) => Text(
        selectLabelsHint,
        style: hintStyle.copyWith(fontSize: 14),
      ),
      onListChanged: (values) {
        widget.onSelectLabels(values);
        setState(() {
          selectedLabelsData = values;
          allSelected =
              values.length == labelsList.length && labelsList.isNotEmpty;
        });
        field.didChange(values);
      },
    );
  }

  Widget _buildListItem(
    BuildContext context,
    ChatLabel item,
    bool isSelected,
    VoidCallback onItemSelect,
    TextStyle statusTextStyle,
  ) {
    final itemColor = _parseLabelColor(item.color);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onItemSelect,
        child: Row(
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
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: itemColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                style: statusTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
