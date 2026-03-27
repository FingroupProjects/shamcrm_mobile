import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
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
  State<MultiDirectoryDropdownWidget> createState() => _MultiDirectoryDropdownWidgetState();
}

class _MultiDirectoryDropdownWidgetState extends State<MultiDirectoryDropdownWidget> {
  List<MainField> mainFieldsList = [];
  List<MainField> _selectedFields = [];
  String? errorMessage;
  bool _isLoading = false;
  bool allSelected = false;

  final TextStyle statusTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

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
    final filtered = mainFieldsList
        .where((item) => initialIds.contains(item.id))
        .toList();

    setState(() {
      _selectedFields = filtered;
      allSelected = mainFieldsList.isNotEmpty && _selectedFields.length == mainFieldsList.length;
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
            color: const Color(0xFFF4F7FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 1,
              color: hasError ? Colors.red : const Color(0xFFE5E7EB),
            ),
          ),
          child: _isLoading
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                ),
              ),
            ),
          )
              : hasError
              ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          )
              : CustomDropdown<MainField>.multiSelectSearch(
            items: mainFieldsList,
            initialItems: _selectedFields,
            searchHintText: AppLocalizations.of(context)!.translate('search'),
            overlayHeight: 400,
            decoration: CustomDropdownDecoration(
              closedFillColor: const Color(0xffF4F7FD),
              expandedFillColor: Colors.white,
              closedBorder: Border.all(color: Colors.transparent, width: 1),
              closedBorderRadius: BorderRadius.circular(12),
              expandedBorder: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              expandedBorderRadius: BorderRadius.circular(12),
            ),
            listItemBuilder: (context, item, isSelected, onItemSelect) {
              if (mainFieldsList.isNotEmpty && mainFieldsList.indexOf(item) == 0) {
                return Column(
                  children: [
                    _buildSelectAllTile(),
                    const Divider(height: 20, color: Color(0xFFE5E7EB)),
                    _buildListItem(item, isSelected, onItemSelect),
                  ],
                );
              }
              return _buildListItem(item, isSelected, onItemSelect);
            },
            headerListBuilder: (context, hint, enabled) {
              if (_selectedFields.isEmpty) {
                return Text(
                  AppLocalizations.of(context)!.translate('select_field'),
                  style: statusTextStyle,
                );
              }
              final display = _selectedFields.map((field) => field.value).join(', ');
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
                allSelected = _selectedFields.length == mainFieldsList.length && mainFieldsList.isNotEmpty;
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
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectAllTile() {
    final label = AppLocalizations.of(context)!.translate('select_all');

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
                border: Border.all(color: const Color(0xff1E2E52), width: 1),
                borderRadius: BorderRadius.circular(4),
                color: allSelected ? const Color(0xff1E2E52) : Colors.transparent,
              ),
              child: allSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
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

  Widget _buildListItem(MainField item, bool isSelected, VoidCallback onItemSelect) {
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
                border: Border.all(color: const Color(0xff1E2E52), width: 1),
                borderRadius: BorderRadius.circular(4),
                color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
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