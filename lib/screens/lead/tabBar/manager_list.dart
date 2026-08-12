import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/lead/manager_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagerRadioGroupWidget extends StatefulWidget {
  final String? selectedManager;
  final Function(ManagerData) onSelectManager;
  final String? currentUserId;
  final bool hasError;

  const ManagerRadioGroupWidget({
    super.key,
    required this.onSelectManager,
    this.selectedManager,
    this.currentUserId,
    this.hasError = false,
  });

  @override
  State<ManagerRadioGroupWidget> createState() =>
      _ManagerRadioGroupWidgetState();
}

class _ManagerRadioGroupWidgetState extends State<ManagerRadioGroupWidget> {
  static const int _pageSize = 20;
  final ApiService _apiService = ApiService();
  List<ManagerData> managersList = [];
  ManagerData? selectedManagerData;
  String? currentUserId;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    managersList = [
      ManagerData(
        id: 0,
        name: "Система",
        lastname: "",
      ),
    ];
    if (widget.currentUserId != null) {
      currentUserId = widget.currentUserId;
    } else {
      _loadCurrentUserId();
    }
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
  }

  Future<void> _loadCurrentUserId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userID') ?? '';
      if (mounted) {
        setState(() {
          currentUserId = userId;
        });
      }
      //print('Current userID: $userId');
    } catch (e) {
      //print('Error getting current user ID: $e');
    }
  }

  Future<CustomDropdownPaginatedResponse<ManagerData>> _searchManagers(
    String query,
    int page,
  ) async {
    final response = await _apiService.getAllManager(
      search: query,
      page: page,
      perPage: _pageSize,
    );
    final items = response.result ?? <ManagerData>[];

    return CustomDropdownPaginatedResponse<ManagerData>(
      items: page == 1
          ? [
              ManagerData(
                id: 0,
                name: "Система",
                lastname: "",
              ),
              ...items,
            ]
          : items,
      hasMore: items.length >= _pageSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fieldFill = colors.fieldBg;
    final primaryText = context.adaptiveForegroundOn(fieldFill);
    final hintTextColor = context.adaptiveHintOn(fieldFill, lightAlpha: 0.62);
    final fieldBorder = context.adaptiveBorderOn(fieldFill);
    final dropdownFill = colors.surfacePrimary;
    final dropdownSelected = colors.surfaceElevated;
    final dropdownIcon = primaryText.withValues(alpha: 0.92);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<GetAllManagerBloc, GetAllManagerState>(
          builder: (context, state) {
            if (state is GetAllManagerError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.translate(state.message),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textInverse,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: context.appColors.error,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
            }

            if (state is GetAllManagerSuccess && !isInitialized) {
              managersList = [
                ManagerData(
                  id: 0,
                  name: "Система",
                  lastname: "",
                ),
                ...?state.dataManager.result,
              ];

              if (widget.selectedManager != null && managersList.isNotEmpty) {
                selectedManagerData = managersList.firstWhere(
                  (manager) => manager.id.toString() == widget.selectedManager,
                  orElse: () => managersList[0],
                );
              }
              isInitialized = true;
            }

            debugPrint("ManagerList managerList dropdown : $managersList");

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.translate('manager'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                CustomDropdown<ManagerData>.searchRequestPaginated(
                  paginatedRequest: _searchManagers,
                  futureRequestDelay: const Duration(milliseconds: 350),
                  closeDropDownOnClearFilterSearch: true,
                  items: managersList,
                  searchHintText:
                      AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
                  enabled: true,
                  decoration: CustomDropdownDecoration(
                    closedFillColor: fieldFill,
                    expandedFillColor: dropdownFill,
                    closedBorder: Border.all(
                      color: widget.hasError ? colors.error : fieldBorder,
                      width: 1.5,
                    ),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(
                      color: widget.hasError ? colors.error : fieldBorder,
                      width: 1.5,
                    ),
                    expandedBorderRadius: BorderRadius.circular(12),
                    closedSuffixIcon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: dropdownIcon),
                    expandedSuffixIcon: Icon(Icons.keyboard_arrow_up_rounded,
                        color: dropdownIcon),
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: hintTextColor,
                    ),
                    headerStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: primaryText,
                    ),
                    listItemStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: primaryText,
                    ),
                    searchFieldDecoration: SearchFieldDecoration(
                      fillColor: fieldFill,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: hintTextColor,
                      ),
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: primaryText,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: hintTextColor,
                      ),
                      suffixIcon: (onClear) => IconButton(
                        onPressed: onClear,
                        icon: Icon(Icons.close_rounded, color: hintTextColor),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: fieldBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: fieldBorder, width: 1.2),
                      ),
                    ),
                    listItemDecoration: ListItemDecoration(
                      selectedColor: dropdownSelected,
                      highlightColor: dropdownSelected.withValues(alpha: 0.72),
                      splashColor:
                          context.appColors.overlay.withValues(alpha: 0),
                    ),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Text(
                      '${item.name} ${item.lastname ?? ''}'.trim(),
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    if (state is GetAllManagerLoading) {
                      return Text(
                        AppLocalizations.of(context)!
                            .translate('select_manager'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: hintTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                    return Text(
                      '${selectedItem.name} ${selectedItem.lastname ?? ''}'
                          .trim(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_manager'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: hintTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  excludeSelected: false,
                  initialItem: selectedManagerData,
                  onChanged: (value) {
                    if (value != null) {
                      widget.onSelectManager(value);
                      setState(() {
                        selectedManagerData = value;
                      });
                    }
                  },
                ),
                if (widget.hasError) ...[
                  Text(
                    ' ${AppLocalizations.of(context)!.translate('field_required_project')}',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 241, 50, 36),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
