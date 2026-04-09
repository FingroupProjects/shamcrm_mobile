import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
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

  final TextStyle executorTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

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
      debugPrint(
        'DealExecutorsMultiSelectWidget: loading executors from /department/get/users',
      );
      final response = await _apiService.getDealExecutors();
      if (!mounted) return;

      final loadedExecutors = response.result ?? [];
      debugPrint(
        'DealExecutorsMultiSelectWidget: loaded ${loadedExecutors.length} executors',
      );
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
      debugPrint(
        'DealExecutorsMultiSelectWidget: failed to load executors: $error',
      );
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

  @override
  Widget build(BuildContext context) {
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
              style: executorTextStyle.copyWith(
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
                  : CustomDropdown<UserData>.multiSelectSearch(
                      items: executorsList,
                      initialItems: selectedExecutorsData,
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
                                      _buildCheckbox(allSelected),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .translate('select_all'),
                                          style: executorTextStyle,
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
                        final selectedExecutorsNames =
                            selectedExecutorsData.isEmpty
                                ? AppLocalizations.of(context)!
                                    .translate('select_assignees_list')
                                : selectedExecutorsData
                                    .map((e) => '${e.name} ${e.lastname}')
                                    .join(', ');
                        return Text(
                          selectedExecutorsNames,
                          style: executorTextStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                        AppLocalizations.of(context)!
                            .translate('select_assignees_list'),
                        style: executorTextStyle.copyWith(fontSize: 14),
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

  Widget _buildCheckbox(bool isChecked) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xff1E2E52), width: 1),
        borderRadius: BorderRadius.circular(4),
        color: isChecked ? const Color(0xff1E2E52) : Colors.transparent,
      ),
      child: isChecked
          ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 14,
            )
          : null,
    );
  }

  Widget _buildListItem(
    UserData item,
    bool isSelected,
    VoidCallback onItemSelect,
  ) {
    return InkWell(
      onTap: onItemSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _buildCheckbox(isSelected),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${item.name} ${item.lastname}',
                style: executorTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
