import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class StateSingleSelectWidget extends StatefulWidget {
  final RegionData? selectedState;
  final ValueChanged<RegionData?> onChanged;

  const StateSingleSelectWidget({
    super.key,
    required this.onChanged,
    this.selectedState,
  });

  @override
  State<StateSingleSelectWidget> createState() =>
      _StateSingleSelectWidgetState();
}

class _StateSingleSelectWidgetState extends State<StateSingleSelectWidget> {
  final ApiService _apiService = ApiService();
  List<RegionData> _states = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAllState();
      if (!mounted) return;
      setState(() {
        _states = response.result ?? [];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _states = [];
        _isLoading = false;
      });
    }
  }

  /// CustomDropdown asserts `items.contains(initialItem)`. RegionData has no
  /// value equality, so a restored filter object is never identical to the
  /// freshly loaded list item — resolve by id instead.
  RegionData? get _resolvedInitialItem {
    final selected = widget.selectedState;
    if (selected == null || _states.isEmpty) return null;
    for (final state in _states) {
      if (state.id == selected.id) return state;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );
    final hintStyle = textStyle.copyWith(
      fontSize: 14,
      color: context.appColors.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('oblast'),
          style: textStyle.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.appColors.fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appColors.borderSubtle),
          ),
          child: _isLoading
              ? Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: context.appColors.buttonPrimaryBg,
                    ),
                  ),
                )
              : CustomDropdown<RegionData>.search(
                  items: _states,
                  initialItem: _resolvedInitialItem,
                  searchHintText:
                      AppLocalizations.of(context)!.translate('search'),
                  hintText:
                      AppLocalizations.of(context)!.translate('select_oblast'),
                  overlayHeight: 400,
                  decoration: CustomDropdownDecoration(
                    closedFillColor: context.appColors.fieldBg,
                    expandedFillColor: context.appColors.surfacePrimary,
                    closedBorder: Border.all(color: Colors.transparent),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder:
                        Border.all(color: context.appColors.borderSubtle),
                    expandedBorderRadius: BorderRadius.circular(12),
                    hintStyle: hintStyle,
                    headerStyle: textStyle,
                    listItemStyle: textStyle,
                    listItemDecoration: ListItemDecoration(
                      selectedColor: context.appColors.buttonPrimaryBg
                          .withValues(alpha: 0.14),
                      highlightColor: context.appColors.buttonPrimaryBg
                          .withValues(alpha: 0.08),
                      splashColor: Colors.transparent,
                    ),
                    searchFieldDecoration: SearchFieldDecoration(
                      fillColor: context.appColors.fieldBg,
                      textStyle: textStyle.copyWith(fontSize: 14),
                      hintStyle: hintStyle,
                      prefixIcon: Icon(
                        Icons.search,
                        color: context.appColors.textSecondary,
                      ),
                      suffixIcon: (onClear) => IconButton(
                        onPressed: onClear,
                        icon: Icon(
                          Icons.close_rounded,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: context.appColors.borderSubtle,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: context.appColors.buttonPrimaryBg,
                        ),
                      ),
                    ),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Text(
                        item.name,
                        style: textStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                  headerBuilder: (context, item, enabled) {
                    return Text(
                      item.name,
                      style: textStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                  hintBuilder: (context, hint, enabled) {
                    return Text(
                      AppLocalizations.of(context)!.translate('select_oblast'),
                      style: hintStyle,
                    );
                  },
                  onChanged: widget.onChanged,
                ),
        ),
      ],
    );
  }
}
