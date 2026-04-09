import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/reason_for_refusal_model.dart';
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
    final borderColor =
        widget.showError ? const Color(0xffE45454) : const Color(0xffF4F7FD);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Причина',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
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
            closedFillColor: const Color(0xffF4F7FD),
            expandedFillColor: Colors.white,
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
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Text(
              item.text,
              style: const TextStyle(
                color: Color(0xff1E2E52),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
          headerBuilder: (context, selectedItem, enabled) {
            if (_isLoading) {
              return const Text(
                'Загрузка...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              );
            }
            return Text(
              selectedItem.text.isEmpty
                  ? 'Выберите причину'
                  : selectedItem.text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => const Text(
            'Выберите причину',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
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
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xffE45454),
              ),
            ),
          ),
      ],
    );
  }
}
