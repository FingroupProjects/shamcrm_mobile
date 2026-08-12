import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/models/user/user_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DealExecutorsMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedExecutors;
  final Function(List<UserData>) onSelectExecutors;

  const DealExecutorsMultiSelectWidget({
    super.key,
    required this.onSelectExecutors,
    this.selectedExecutors,
  });

  @override
  State<DealExecutorsMultiSelectWidget> createState() =>
      _DealExecutorsMultiSelectWidgetState();
}

class _DealExecutorsMultiSelectWidgetState
    extends State<DealExecutorsMultiSelectWidget> {
  final ApiService _apiService = ApiService();

  List<UserData> executorsList = [];
  List<UserData> selectedExecutorsData = [];
  bool allSelected = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExecutors();
  }

  @override
  void didUpdateWidget(covariant DealExecutorsMultiSelectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (listEquals(oldWidget.selectedExecutors, widget.selectedExecutors)) {
      return;
    }

    final selectedIds = widget.selectedExecutors ?? const <String>[];
    setState(() {
      selectedExecutorsData = executorsList
          .where((user) => selectedIds.contains(user.id.toString()))
          .toList();
      allSelected = executorsList.isNotEmpty &&
          selectedExecutorsData.length == executorsList.length;
    });
  }

  Future<void> _loadExecutors() async {
    setState(() => isLoading = true);
    try {
      await _apiService.ensureInitialized();
      final response = await _apiService.getDealExecutors();
      if (!mounted) return;

      final loadedExecutors = response.result ?? [];
      setState(() {
        executorsList = loadedExecutors;
        selectedExecutorsData = loadedExecutors
            .where((user) =>
                widget.selectedExecutors?.contains(user.id.toString()) == true)
            .toList();
        allSelected = executorsList.isNotEmpty &&
            selectedExecutorsData.length == executorsList.length;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        executorsList = [];
        selectedExecutorsData = [];
        allSelected = false;
        isLoading = false;
      });
    }
  }

  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      selectedExecutorsData = allSelected ? List.from(executorsList) : [];
      widget.onSelectExecutors(selectedExecutorsData);
    });
  }

  CustomDropdownDecoration _dropdownDecoration(
    AppThemeColors colors,
    TextStyle textStyle,
    TextStyle hintStyle,
  ) {
    return CustomDropdownDecoration(
      closedFillColor: colors.fieldBg,
      expandedFillColor: colors.fieldBg,
      closedBorder: Border.all(color: Colors.transparent, width: 1),
      closedBorderRadius: BorderRadius.circular(12),
      expandedBorder: Border.all(color: colors.fieldBorder, width: 1),
      expandedBorderRadius: BorderRadius.circular(12),
      hintStyle: hintStyle,
      headerStyle: textStyle,
      listItemStyle: textStyle,
      noResultFoundStyle: hintStyle,
      listItemDecoration: ListItemDecoration(
        selectedColor: colors.buttonPrimaryBg.withValues(alpha: 0.14),
        highlightColor: colors.buttonPrimaryBg.withValues(alpha: 0.08),
        splashColor: Colors.transparent,
      ),
      searchFieldDecoration: SearchFieldDecoration(
        fillColor: colors.surfaceElevated,
        textStyle: textStyle,
        hintStyle: hintStyle,
        prefixIcon: Icon(Icons.search, color: colors.iconSecondary),
        suffixIcon: (onClear) => IconButton(
          onPressed: onClear,
          icon: Icon(Icons.close_rounded, color: colors.iconSecondary),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.buttonPrimaryBg),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: colors.textPrimary,
    );
    final hintStyle = textStyle.copyWith(
      fontSize: 14,
      color: colors.textSecondary,
    );

    return FormField<List<UserData>>(
      validator: (value) {
        if (selectedExecutorsData.isEmpty) {
          return AppLocalizations.of(context)!
              .translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<UserData>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('executors'),
              style: textStyle.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colors.fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError ? colors.error : colors.fieldBorder,
                ),
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.buttonPrimaryBg,
                        ),
                      ),
                    )
                  : CustomDropdown<UserData>.multiSelectSearch(
                      items: executorsList,
                      initialItems: selectedExecutorsData,
                      searchHintText:
                          AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
                      decoration:
                          _dropdownDecoration(colors, textStyle, hintStyle),
                      listItemBuilder:
                          (context, item, isSelected, onItemSelect) {
                        if (executorsList.indexOf(item) == 0) {
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: GestureDetector(
                                  onTap: _toggleSelectAll,
                                  child: Row(
                                    children: [
                                      _buildCheckbox(allSelected, colors),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .translate('select_all'),
                                          style: textStyle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Divider(height: 20, color: colors.borderSubtle),
                              _buildListItem(
                                item,
                                isSelected,
                                onItemSelect,
                                textStyle,
                                colors,
                              ),
                            ],
                          );
                        }
                        return _buildListItem(
                          item,
                          isSelected,
                          onItemSelect,
                          textStyle,
                          colors,
                        );
                      },
                      headerListBuilder: (context, hint, enabled) {
                        final selectedExecutorsNames =
                            selectedExecutorsData.isEmpty
                                ? AppLocalizations.of(context)!
                                    .translate('select_assignees_list')
                                : selectedExecutorsData
                                    .map((e) => '${e.name} ${e.lastname}')
                                    .join(', ');
                        return Text(
                          selectedExecutorsNames,
                          style: selectedExecutorsData.isEmpty
                              ? hintStyle
                              : textStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                        AppLocalizations.of(context)!
                            .translate('select_assignees_list'),
                        style: hintStyle,
                      ),
                      onListChanged: (values) {
                        widget.onSelectExecutors(values);
                        setState(() {
                          selectedExecutorsData = values;
                          allSelected = values.length == executorsList.length;
                        });
                        field.didChange(values);
                      },
                    ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  field.errorText!,
                  style: context.appTextStyles.bodyMd.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCheckbox(bool isChecked, AppThemeColors colors) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(color: colors.textPrimary, width: 1),
        borderRadius: BorderRadius.circular(4),
        color: isChecked ? colors.buttonPrimaryBg : Colors.transparent,
      ),
      child: isChecked
          ? Icon(
              Icons.check,
              color: colors.buttonPrimaryFg,
              size: 14,
            )
          : null,
    );
  }

  Widget _buildListItem(
    UserData item,
    bool isSelected,
    VoidCallback onItemSelect,
    TextStyle textStyle,
    AppThemeColors colors,
  ) {
    return InkWell(
      onTap: onItemSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _buildCheckbox(isSelected, colors),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${item.name} ${item.lastname}',
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
