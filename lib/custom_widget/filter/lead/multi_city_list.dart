import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/city_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class CityMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedCities;
  final int? parentId;
  final Function(List<CityData>) onSelectCities;

  const CityMultiSelectWidget({
    super.key,
    required this.onSelectCities,
    this.selectedCities,
    this.parentId,
  });

  @override
  State<CityMultiSelectWidget> createState() => _CityMultiSelectWidgetState();
}

class _CityMultiSelectWidgetState extends State<CityMultiSelectWidget> {
  final ApiService _apiService = ApiService();

  List<CityData> citiesList = [];
  List<CityData> selectedCitiesData = [];
  bool allSelected = false;
  bool isLoading = false;

  final TextStyle cityTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void didUpdateWidget(covariant CityMultiSelectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parentId != widget.parentId) {
      selectedCitiesData = [];
      allSelected = false;
      _loadCities();
    }
  }

  Future<void> _loadCities() async {
    setState(() => isLoading = true);
    try {
      final response = await _apiService.getAllCity(parentId: widget.parentId);
      if (!mounted) return;

      final loadedCities = response.result ?? [];
      setState(() {
        citiesList = loadedCities;
        selectedCitiesData = loadedCities
            .where((city) =>
                widget.selectedCities?.contains(city.id.toString()) == true)
            .toList();
        allSelected = citiesList.isNotEmpty &&
            selectedCitiesData.length == citiesList.length;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        citiesList = [];
        selectedCitiesData = [];
        allSelected = false;
        isLoading = false;
      });
    }
  }

  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      selectedCitiesData = allSelected ? List.from(citiesList) : [];
      widget.onSelectCities(selectedCitiesData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<CityData>>(
      validator: (value) {
        if (selectedCitiesData.isEmpty) {
          return AppLocalizations.of(context)!
              .translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<CityData>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('city'),
              style: cityTextStyle.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError ? Colors.red : const Color(0xFFE5E7EB),
                ),
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : CustomDropdown<CityData>.multiSelectSearch(
                      items: citiesList,
                      initialItems: selectedCitiesData,
                      enabled: true,
                      searchHintText:
                          AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
                      decoration: CustomDropdownDecoration(
                        closedFillColor: const Color(0xffF4F7FD),
                        expandedFillColor: Colors.white,
                        closedBorder: Border.all(color: Colors.transparent),
                        closedBorderRadius: BorderRadius.circular(12),
                        expandedBorder:
                            Border.all(color: const Color(0xFFE5E7EB)),
                        expandedBorderRadius: BorderRadius.circular(12),
                      ),
                      listItemBuilder:
                          (context, item, isSelected, onItemSelect) {
                        if (citiesList.indexOf(item) == 0) {
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: GestureDetector(
                                  onTap: _toggleSelectAll,
                                  child: Row(
                                    children: [
                                      _buildCheckbox(allSelected),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .translate('select_all'),
                                          style: cityTextStyle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(
                                  height: 20, color: Color(0xFFE5E7EB)),
                              _buildListItem(item, isSelected, onItemSelect),
                            ],
                          );
                        }
                        return _buildListItem(item, isSelected, onItemSelect);
                      },
                      headerListBuilder: (context, hint, enabled) {
                        final selectedCitiesNames = selectedCitiesData.isEmpty
                            ? AppLocalizations.of(context)!
                                .translate('select_city')
                            : selectedCitiesData.map((e) => e.name).join(', ');
                        return Text(
                          selectedCitiesNames,
                          style: cityTextStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                        AppLocalizations.of(context)!.translate('select_city'),
                        style: cityTextStyle.copyWith(fontSize: 14),
                      ),
                      onListChanged: (values) {
                        widget.onSelectCities(values);
                        setState(() {
                          selectedCitiesData = values;
                          allSelected = values.length == citiesList.length;
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
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCheckbox(bool isSelected) {
    return Container(
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
    );
  }

  Widget _buildListItem(
      CityData item, bool isSelected, Function() onItemSelect) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onItemSelect,
        child: Row(
          children: [
            _buildCheckbox(isSelected),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                style: cityTextStyle,
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
