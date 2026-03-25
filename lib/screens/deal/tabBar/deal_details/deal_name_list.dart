import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal_name_list_bloc/deal_name_list_bloc.dart';
import 'package:crm_task_manager/bloc/deal_name_list_bloc/deal_name_list_event.dart';
import 'package:crm_task_manager/bloc/deal_name_list_bloc/deal_name_lists_state.dart';
import 'package:crm_task_manager/models/deal_name_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealNameSelectionWidget extends StatefulWidget {
  final String? selectedDealName;
  final Function(String) onSelectDealName;
  final bool hasError;

  const DealNameSelectionWidget({
    super.key,
    this.selectedDealName,
    required this.onSelectDealName,
    this.hasError = false,
  });

  @override
  State<DealNameSelectionWidget> createState() =>
      _DealNameSelectionWidgetState();
}

class _DealNameSelectionWidgetState extends State<DealNameSelectionWidget> {
  static const int _pageSize = 20;
  final ApiService _apiService = ApiService();
  List<DealNameData> dealNameList = [];
  DealNameData? selectedDealNameData;

  @override
  void initState() {
    super.initState();
    context.read<GetAllDealNameBloc>().add(GetAllDealNameEv());
  }

  @override
  void didUpdateWidget(covariant DealNameSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDealName != widget.selectedDealName) {
      _updateSelectedDealNameData();
    }
  }

  void _updateSelectedDealNameData() {
    if (widget.selectedDealName == null || dealNameList.isEmpty) {
      selectedDealNameData = null;
      return;
    }

    try {
      selectedDealNameData = dealNameList.firstWhere(
        (dealName) => dealName.title == widget.selectedDealName,
      );
    } catch (_) {
      selectedDealNameData = null;
    }
  }

  Future<CustomDropdownPaginatedResponse<DealNameData>> _searchDealNames(
    String query,
    int page,
  ) async {
    final response = await _apiService.getAllDealNames(
      search: query,
      page: page,
      perPage: _pageSize,
    );
    final items = response.result ?? <DealNameData>[];

    return CustomDropdownPaginatedResponse<DealNameData>(
      items: items,
      hasMore: items.length >= _pageSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('deal_name'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        BlocBuilder<GetAllDealNameBloc, GetAllDealNameState>(
          builder: (context, state) {
            if (state is GetAllDealNameError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.translate(state.message),
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.red,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
            }

            if (state is GetAllDealNameSuccess) {
              dealNameList = state.dataDealName.result ?? [];
              _updateSelectedDealNameData();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomDropdown<DealNameData>.searchRequestPaginated(
                  paginatedRequest: _searchDealNames,
                  futureRequestDelay: const Duration(milliseconds: 350),
                  closeDropDownOnClearFilterSearch: true,
                  items: dealNameList,
                  initialItem: selectedDealNameData,
                  searchHintText:
                      AppLocalizations.of(context)!.translate('search'),
                  hintText: AppLocalizations.of(context)!
                      .translate('select_deal_name'),
                  overlayHeight: 400,
                  enabled: true,
                  decoration: CustomDropdownDecoration(
                    closedFillColor: const Color(0xffF4F7FD),
                    expandedFillColor: Colors.white,
                    closedBorder: Border.all(
                      color: widget.hasError
                          ? Colors.red
                          : const Color(0xffF4F7FD),
                      width: 1.5,
                    ),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(
                      color: widget.hasError
                          ? Colors.red
                          : const Color(0xffF4F7FD),
                      width: 1.5,
                    ),
                    expandedBorderRadius: BorderRadius.circular(12),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    return Text(
                      selectedItem.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_deal_name'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  noResultFoundBuilder: (context, text) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          AppLocalizations.of(context)!
                              .translate('no_data_to_display'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                  excludeSelected: false,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    widget.onSelectDealName(value.title);
                    setState(() {
                      selectedDealNameData = value;
                    });
                    FocusScope.of(context).unfocus();
                  },
                ),
                if (widget.hasError)
                  Text(
                    ' ${AppLocalizations.of(context)!.translate('field_required_project')}',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 253, 38, 23),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
