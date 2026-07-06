import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagerForLead extends StatefulWidget {
  final String? selectedManager;
  final Function(ManagerData) onSelectManager;
  final String? currentUserId;
  final bool hasError;

  const ManagerForLead({
    super.key,
    required this.onSelectManager,
    this.selectedManager,
    this.currentUserId,
    this.hasError = false,
  });

  @override
  State<ManagerForLead> createState() => _ManagerForLeadState();
}

class _ManagerForLeadState extends State<ManagerForLead> {
  static const int _pageSize = 20;
  final ApiService _apiService = ApiService();
  List<ManagerData> managersList = [];
  ManagerData? selectedManagerData;
  String? currentUserId;
  bool isInitialized = false;
  bool isLoadingManagers = true;

  @override
  void initState() {
    super.initState();
    //print('ManagerForLead: initState started');
    if (widget.currentUserId != null) {
      currentUserId = widget.currentUserId;
      //print('ManagerForLead: Current user ID from props: $currentUserId');
    } else {
      _loadCurrentUserId();
    }
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    //print('ManagerForLead: Dispatched GetAllManagerEv');
  }

  @override
  void didUpdateWidget(covariant ManagerForLead oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedManager != oldWidget.selectedManager &&
        widget.selectedManager != null) {
      //print('ManagerForLead: selectedManager changed to ${widget.selectedManager}');
      _updateSelectedManagerData();
    }
  }

  Future<void> _loadCurrentUserId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userID') ?? '';
      if (mounted) {
        setState(() {
          currentUserId = userId;
          //print('ManagerForLead: Loaded current user ID: $userId');
        });
      }
    } catch (e) {
      //print('ManagerForLead: Error getting current user ID: $e');
    }
  }

  void _updateSelectedManagerData() {
    //print('ManagerForLead: Updating selected manager, prop selectedManager: ${widget.selectedManager}');
    if (widget.selectedManager != null && managersList.isNotEmpty) {
      try {
        final newSelectedManager = managersList.firstWhere(
          (manager) => manager.id.toString() == widget.selectedManager,
        );
        if (selectedManagerData?.id != newSelectedManager.id) {
          setState(() {
            selectedManagerData = newSelectedManager;
            //print('ManagerForLead: Updated selectedManagerData to: ${newSelectedManager.id} (${newSelectedManager.name})');
          });
        } else {
          //print('ManagerForLead: Manager ${newSelectedManager.id} already selected, skipping update');
        }
      } catch (e) {
        //print('ManagerForLead: Manager not found for ID ${widget.selectedManager}: $e');
        setState(() {
          selectedManagerData = null;
        });
      }
    } else {
      //print('ManagerForLead: No selected manager or empty managers list, keeping selectedManagerData null');
      if (selectedManagerData != null) {
        setState(() {
          selectedManagerData = null;
        });
      }
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
      items: items,
      hasMore: items.length >= _pageSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    //print('ManagerForLead: Building with selectedManager: ${widget.selectedManager}, selectedManagerData: ${selectedManagerData?.id}');
    return BlocListener<GetAllManagerBloc, GetAllManagerState>(
      listener: (context, state) {
        if (state is GetAllManagerLoading) {
          if (!mounted) return;
          setState(() {
            isLoadingManagers = true;
          });
          return;
        }

        if (state is GetAllManagerError) {
          if (!mounted) return;
          setState(() {
            isLoadingManagers = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          return;
        }

        if (state is GetAllManagerSuccess) {
          managersList = state.dataManager.result ?? [];
          isInitialized = true;
          if (!mounted) return;
          setState(() {
            isLoadingManagers = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _updateSelectedManagerData();
          });
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('manager'),
            style: context.appTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w500,
              color: context.appColors.textPrimary,
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
                    closedFillColor: context.appColors.fieldBackground,
                    expandedFillColor: context.appColors.surfacePrimary,
                    closedBorder: Border.all(
                      color: widget.hasError
                          ? context.appColors.error
                          : context.appColors.fieldBorder,
                      width: 1.5,
                    ),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(
                      color: widget.hasError
                          ? context.appColors.error
                          : context.appColors.fieldBorder,
                      width: 1.5,
                    ),
                    expandedBorderRadius: BorderRadius.circular(12),
                    searchFieldDecoration: SearchFieldDecoration(
                      fillColor: context.appColors.fieldBackground,
                      hintStyle: context.appTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textSecondary,
                      ),
                      textStyle: context.appTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textPrimary,
                      ),
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
                          color: context.appColors.fieldBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: context.appColors.buttonPrimaryBg,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Text(
                      '${item.name} ${item.lastname ?? ''}'.trim(),
                      style: context.appTextStyles.bodyMd.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    if (isLoadingManagers) {
                      //print('ManagerForLead: Displaying loading state');
                      return Text(
                        AppLocalizations.of(context)!
                            .translate('select_manager'),
                        style: context.appTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textSecondary,
                        ),
                      );
                    }
                    //print('ManagerForLead: Displaying selected item: ${selectedItem?.id} (${selectedItem?.name})');
                    return Text(
                      '${selectedItem.name} ${selectedItem.lastname ?? ''}'
                          .trim(),
                      style: context.appTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textPrimary,
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_manager'),
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  excludeSelected: false,
                  initialItem: selectedManagerData,
                  onChanged: (value) {
                    if (value != null) {
                      //print('ManagerForLead: User selected manager: ${value.id} (${value.name})');
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
            ),
          ],
        ],
      ),
    );
  }
}
