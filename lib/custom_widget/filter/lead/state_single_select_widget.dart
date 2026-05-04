import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
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

  final TextStyle _textStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('oblast'),
          style: _textStyle.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                )
              : CustomDropdown<RegionData>.search(
                  items: _states,
                  initialItem: widget.selectedState,
                  searchHintText:
                      AppLocalizations.of(context)!.translate('search'),
                  hintText:
                      AppLocalizations.of(context)!.translate('select_oblast'),
                  overlayHeight: 400,
                  decoration: CustomDropdownDecoration(
                    closedFillColor: const Color(0xffF4F7FD),
                    expandedFillColor: Colors.white,
                    closedBorder: Border.all(color: Colors.transparent),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(color: const Color(0xFFE5E7EB)),
                    expandedBorderRadius: BorderRadius.circular(12),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Text(
                        item.name,
                        style: _textStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                  headerBuilder: (context, item, enabled) {
                    return Text(
                      item.name,
                      style: _textStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                  hintBuilder: (context, hint, enabled) {
                    return Text(
                      AppLocalizations.of(context)!.translate('select_oblast'),
                      style: _textStyle.copyWith(fontSize: 14),
                    );
                  },
                  onChanged: widget.onChanged,
                ),
        ),
      ],
    );
  }
}
