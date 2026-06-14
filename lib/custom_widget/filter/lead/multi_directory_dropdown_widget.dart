import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class MultiDirectoryDropdownWidget extends StatefulWidget {
  final int directoryId;
  final String directoryName;
  final Function(List<MainField>) onSelectField;
  final List<MainField>? initialFields;

  const MultiDirectoryDropdownWidget({
    super.key,
    required this.directoryId,
    required this.directoryName,
    required this.onSelectField,
    this.initialFields,
  });

  @override
  State<MultiDirectoryDropdownWidget> createState() =>
      _MultiDirectoryDropdownWidgetState();
}

class _MultiDirectoryDropdownWidgetState
    extends State<MultiDirectoryDropdownWidget> {
  List<MainField> mainFieldsList = [];
  List<MainField> _selectedFields = [];
  String? errorMessage;
  bool _isLoading = false;
  bool allSelected = false;

  @override
  void initState() {
    super.initState();
    _syncSelectedFields();
    _fetchMainFields();
  }

  @override
  void didUpdateWidget(covariant MultiDirectoryDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.directoryId != oldWidget.directoryId) {
      setState(() {
        mainFieldsList = [];
        _selectedFields = [];
        allSelected = false;
        errorMessage = null;
      });
      _fetchMainFields();
    }
    if (widget.initialFields != oldWidget.initialFields) {
      _syncSelectedFields();
    }
  }

  void _syncSelectedFields() {
    final initial = widget.initialFields ?? [];
    final initialIds = initial.map((e) => e.id).toSet();
    final filtered =
        mainFieldsList.where((item) => initialIds.contains(item.id)).toList();

    setState(() {
      _selectedFields = filtered;
      allSelected = mainFieldsList.isNotEmpty &&
          _selectedFields.length == mainFieldsList.length;
    });
  }

  Future<void> _fetchMainFields() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      errorMessage = null;
    });

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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSelectAll() {
    if (mainFieldsList.isEmpty || _isLoading || errorMessage != null) return;

    setState(() {
      allSelected = !allSelected;
      _selectedFields = allSelected ? List<MainField>.from(mainFieldsList) : [];
    });
    widget.onSelectField(_selectedFields);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null;
    final statusTextStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );
    final hintStyle = statusTextStyle.copyWith(
      fontSize: 14,
      color: context.appColors.textSecondary,
    );

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
            color: context.appColors.fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 1,
              color: hasError
                  ? context.appColors.error
                  : context.appColors.borderSubtle,
            ),
          ),
          child: _isLoading
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.appColors.buttonPrimaryBg,
                        ),
                      ),
                    ),
                  ),
                )
              : hasError
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: context.appColors.error,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : CustomDropdown<MainField>.multiSelectSearch(
                      items: mainFieldsList,
                      initialItems: _selectedFields,
                      searchHintText:
                          AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
                      decoration: CustomDropdownDecoration(
                        closedFillColor: context.appColors.fieldBg,
                        expandedFillColor: context.appColors.surfacePrimary,
                        closedBorder:
                            Border.all(color: Colors.transparent, width: 1),
                        closedBorderRadius: BorderRadius.circular(12),
                        expandedBorder: Border.all(
                          color: context.appColors.borderSubtle,
                          width: 1,
                        ),
                        expandedBorderRadius: BorderRadius.circular(12),
                        hintStyle: hintStyle,
                        headerStyle: statusTextStyle,
                        listItemStyle: statusTextStyle,
                        listItemDecoration: ListItemDecoration(
                          selectedColor: context.appColors.buttonPrimaryBg
                              .withValues(alpha: 0.14),
                          highlightColor: context.appColors.buttonPrimaryBg
                              .withValues(alpha: 0.08),
                          splashColor: Colors.transparent,
                        ),
                        searchFieldDecoration: SearchFieldDecoration(
                          fillColor: context.appColors.fieldBg,
                          textStyle: statusTextStyle.copyWith(fontSize: 14),
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
                      listItemBuilder:
                          (context, item, isSelected, onItemSelect) {
                        if (mainFieldsList.isNotEmpty &&
                            mainFieldsList.indexOf(item) == 0) {
                          return Column(
                            children: [
                              _buildSelectAllTile(),
                              Divider(
                                height: 20,
                                color: context.appColors.borderSubtle,
                              ),
                              _buildListItem(item, isSelected, onItemSelect),
                            ],
                          );
                        }
                        return _buildListItem(item, isSelected, onItemSelect);
                      },
                      headerListBuilder: (context, hint, enabled) {
                        if (_selectedFields.isEmpty) {
                          return Text(
                            AppLocalizations.of(context)!
                                .translate('select_field'),
                            style: statusTextStyle,
                          );
                        }
                        final display = _selectedFields
                            .map((field) => field.value)
                            .join(', ');
                        return Text(
                          display,
                          style: statusTextStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                        AppLocalizations.of(context)!.translate('select_field'),
                        style: statusTextStyle.copyWith(fontSize: 14),
                      ),
                      onListChanged: (values) {
                        setState(() {
                          _selectedFields = List<MainField>.from(values);
                          allSelected =
                              _selectedFields.length == mainFieldsList.length &&
                                  mainFieldsList.isNotEmpty;
                        });
                        widget.onSelectField(_selectedFields);
                      },
                    ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectAllTile() {
    final label = AppLocalizations.of(context)!.translate('select_all');
    final statusTextStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: _isLoading || errorMessage != null ? null : _toggleSelectAll,
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.appColors.textPrimary,
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
                      color: context.appColors.textInverse,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: statusTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(
      MainField item, bool isSelected, VoidCallback onItemSelect) {
    final statusTextStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
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
                border: Border.all(
                  color: context.appColors.textPrimary,
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
                      color: context.appColors.textInverse,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
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
  }
}
