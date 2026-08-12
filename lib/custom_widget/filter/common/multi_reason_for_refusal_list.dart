import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/lead/reason_for_refusal_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class ReasonForRefusalMultiSelectWidget extends StatefulWidget {
  final String type;
  final List<int>? selectedReasonIds;
  final Function(List<ReasonForRefusalData>) onSelectReasons;

  const ReasonForRefusalMultiSelectWidget({
    super.key,
    required this.type,
    required this.onSelectReasons,
    this.selectedReasonIds,
  });

  @override
  State<ReasonForRefusalMultiSelectWidget> createState() =>
      _ReasonForRefusalMultiSelectWidgetState();
}

class _ReasonForRefusalMultiSelectWidgetState
    extends State<ReasonForRefusalMultiSelectWidget> {
  final ApiService _apiService = ApiService();

  List<ReasonForRefusalData> _reasons = [];
  List<ReasonForRefusalData> _selectedReasons = [];
  bool _isLoading = true;
  bool _allSelected = false;

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  Future<void> _loadReasons() async {
    try {
      final reasons = await _apiService.getReasonsForRefusal(type: widget.type);
      if (!mounted) return;

      final selectedIds = widget.selectedReasonIds ?? const <int>[];
      setState(() {
        _reasons = reasons;
        _selectedReasons =
            reasons.where((reason) => selectedIds.contains(reason.id)).toList();
        _allSelected =
            _reasons.isNotEmpty && _selectedReasons.length == _reasons.length;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSelectAll() {
    setState(() {
      _allSelected = !_allSelected;
      _selectedReasons =
          _allSelected ? List<ReasonForRefusalData>.from(_reasons) : [];
    });
    widget.onSelectReasons(_selectedReasons);
  }

  Widget _buildListItem(
    ReasonForRefusalData item,
    bool isSelected,
    VoidCallback onItemSelect,
  ) {
    final colors = context.appColors;
    final textStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'Gilroy',
      color: colors.textPrimary,
    );
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
                border: Border.all(color: colors.buttonPrimaryBg, width: 1),
                borderRadius: BorderRadius.circular(4),
                color: isSelected ? colors.buttonPrimaryBg : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(item.text, style: textStyle),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final localizations = AppLocalizations.of(context)!;
    final textStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'Gilroy',
      color: colors.textPrimary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('reason_for_refusal'),
          style: textStyle.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: colors.fieldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.fieldBorder, width: 1),
            ),
            child: CustomDropdown<ReasonForRefusalData>.multiSelectSearch(
              items: _reasons,
              initialItems: _selectedReasons,
              searchHintText: localizations.translate('search'),
              overlayHeight: 400,
              decoration: CustomDropdownDecoration(
                closedFillColor: colors.fieldBg,
                expandedFillColor: colors.surfacePrimary,
                closedBorder: Border.all(color: Colors.transparent),
                closedBorderRadius: BorderRadius.circular(12),
                expandedBorder: Border.all(
                  color: colors.fieldBorder,
                  width: 1,
                ),
                expandedBorderRadius: BorderRadius.circular(12),
                hintStyle: textStyle.copyWith(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
                headerStyle: textStyle,
                listItemStyle: textStyle,
                listItemDecoration: ListItemDecoration(
                  selectedColor: colors.buttonPrimaryBg.withValues(alpha: 0.14),
                  highlightColor:
                      colors.buttonPrimaryBg.withValues(alpha: 0.08),
                  splashColor: Colors.transparent,
                ),
                searchFieldDecoration: SearchFieldDecoration(
                  fillColor: colors.fieldBg,
                  textStyle: textStyle.copyWith(fontSize: 14),
                  hintStyle: textStyle.copyWith(
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                  prefixIcon: Icon(Icons.search, color: colors.iconSecondary),
                  suffixIcon: (onClear) => IconButton(
                    onPressed: onClear,
                    icon:
                        Icon(Icons.close_rounded, color: colors.iconSecondary),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.fieldBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.buttonPrimaryBg),
                  ),
                ),
              ),
              listItemBuilder: (context, item, isSelected, onItemSelect) {
                if (_reasons.isNotEmpty && _reasons.first.id == item.id) {
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
                                    color: colors.buttonPrimaryBg,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  color: _allSelected
                                      ? colors.buttonPrimaryBg
                                      : Colors.transparent,
                                ),
                                child: _allSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  localizations.translate('select_all'),
                                  style: textStyle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 20, color: colors.fieldBorder),
                      _buildListItem(item, isSelected, onItemSelect),
                    ],
                  );
                }

                return _buildListItem(item, isSelected, onItemSelect);
              },
              headerListBuilder: (context, hint, enabled) {
                final selectedText = _selectedReasons.isEmpty
                    ? localizations.translate('select_reason_for_refusal')
                    : _selectedReasons.map((e) => e.text).join(', ');
                return Text(
                  selectedText,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
              hintBuilder: (context, hint, enabled) => Text(
                localizations.translate('select_reason_for_refusal'),
                style: textStyle.copyWith(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
              onListChanged: (values) {
                setState(() {
                  _selectedReasons = values;
                  _allSelected =
                      _reasons.isNotEmpty && values.length == _reasons.length;
                });
                widget.onSelectReasons(values);
              },
            ),
          ),
      ],
    );
  }
}
