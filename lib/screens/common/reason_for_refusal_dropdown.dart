import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/lead/reason_for_refusal_model.dart';
import 'package:flutter/material.dart';

class ReasonForRefusalDropdown extends StatefulWidget {
  final String type;
  final String? selectedReasonId;
  final ValueChanged<ReasonForRefusalData> onSelectReason;
  final bool showError;
  final String errorText;

  const ReasonForRefusalDropdown({
    super.key,
    required this.type,
    required this.onSelectReason,
    this.selectedReasonId,
    this.showError = false,
    this.errorText = 'Поле обязательно для заполнения',
  });

  @override
  State<ReasonForRefusalDropdown> createState() =>
      _ReasonForRefusalDropdownState();
}

class _ReasonForRefusalDropdownState extends State<ReasonForRefusalDropdown> {
  final ApiService _apiService = ApiService();
  List<ReasonForRefusalData> _items = [];
  ReasonForRefusalData? _selected;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  Future<void> _loadReasons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _apiService.getReasonsForRefusal(
          type: widget.type, perPage: 100);
      if (!mounted) return;

      ReasonForRefusalData? selected;
      if (widget.selectedReasonId != null &&
          widget.selectedReasonId!.isNotEmpty) {
        try {
          selected = items.firstWhere(
            (item) => item.id.toString() == widget.selectedReasonId,
          );
        } catch (_) {
          selected = null;
        }
      }

      setState(() {
        _items = items;
        _selected = selected;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Не удалось загрузить причины отказа',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.red,
          elevation: 3,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final borderColor = widget.showError
        ? colors.error
        : colors.borderSubtle.withValues(alpha: 0.7);
    final fieldBackground = colors.fieldBg;
    final itemTextStyle = textStyles.bodyMd.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: colors.textPrimary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Причина',
          style: textStyles.bodyLg.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<ReasonForRefusalData>.search(
          closeDropDownOnClearFilterSearch: true,
          items: _items,
          searchHintText: 'Поиск',
          overlayHeight: 400,
          enabled: true,
          decoration: CustomDropdownDecoration(
            closedFillColor: fieldBackground,
            expandedFillColor: colors.surfacePrimary,
            closedBorder: Border.all(
              color: borderColor,
              width: 1,
            ),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(
              color: borderColor,
              width: 1,
            ),
            expandedBorderRadius: BorderRadius.circular(12),
            hintStyle: itemTextStyle.copyWith(color: colors.textSecondary),
            headerStyle: itemTextStyle,
            listItemStyle: itemTextStyle,
            listItemDecoration: ListItemDecoration(
              selectedColor: colors.buttonPrimaryBg.withValues(alpha: 0.14),
              highlightColor: colors.buttonPrimaryBg.withValues(alpha: 0.08),
              splashColor: Colors.transparent,
            ),
            searchFieldDecoration: SearchFieldDecoration(
              fillColor: fieldBackground,
              textStyle: itemTextStyle,
              hintStyle: itemTextStyle.copyWith(color: colors.textSecondary),
              prefixIcon: Icon(Icons.search, color: colors.textMuted),
              suffixIcon: (onClear) => IconButton(
                onPressed: onClear,
                icon: Icon(Icons.close, color: colors.textMuted),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.buttonPrimaryBg),
              ),
            ),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Text(
              item.text,
              style: itemTextStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
          headerBuilder: (context, selectedItem, enabled) {
            if (_isLoading) {
              return Text(
                'Загрузка...',
                style: itemTextStyle,
              );
            }
            return Text(
              selectedItem.text.isEmpty
                  ? 'Выберите причину'
                  : selectedItem.text,
              style: itemTextStyle,
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            'Выберите причину',
            style: itemTextStyle.copyWith(color: colors.textSecondary),
          ),
          excludeSelected: false,
          initialItem: _selected,
          onChanged: (value) {
            if (value == null) return;
            widget.onSelectReason(value);
            setState(() {
              _selected = value;
            });
            FocusScope.of(context).unfocus();
          },
        ),
        if (widget.showError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.errorText,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.error,
              ),
            ),
          ),
      ],
    );
  }
}
