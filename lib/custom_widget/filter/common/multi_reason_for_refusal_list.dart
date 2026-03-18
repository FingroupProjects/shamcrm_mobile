import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/reason_for_refusal_model.dart';
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

  final TextStyle _textStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

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
                color:
                    isSelected ? const Color(0xff1E2E52) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(item.text, style: _textStyle),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Причина отказа',
          style: _textStyle.copyWith(fontWeight: FontWeight.w400),
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
              color: const Color(0xFFF4F7FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: CustomDropdown<ReasonForRefusalData>.multiSelectSearch(
              items: _reasons,
              initialItems: _selectedReasons,
              searchHintText: 'Поиск',
              overlayHeight: 400,
              decoration: CustomDropdownDecoration(
                closedFillColor: const Color(0xffF4F7FD),
                expandedFillColor: Colors.white,
                closedBorder: Border.all(color: Colors.transparent),
                closedBorderRadius: BorderRadius.circular(12),
                expandedBorder: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
                expandedBorderRadius: BorderRadius.circular(12),
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
                                    color: const Color(0xff1E2E52),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  color: _allSelected
                                      ? const Color(0xff1E2E52)
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
                                  'Выделить всех',
                                  style: _textStyle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 20, color: Color(0xFFE5E7EB)),
                      _buildListItem(item, isSelected, onItemSelect),
                    ],
                  );
                }

                return _buildListItem(item, isSelected, onItemSelect);
              },
              headerListBuilder: (context, hint, enabled) {
                final selectedText = _selectedReasons.isEmpty
                    ? 'Выберите причину отказа'
                    : _selectedReasons.map((e) => e.text).join(', ');
                return Text(
                  selectedText,
                  style: _textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
              hintBuilder: (context, hint, enabled) => Text(
                'Выберите причину отказа',
                style: _textStyle.copyWith(fontSize: 14),
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
