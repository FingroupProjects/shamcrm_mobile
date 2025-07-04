import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
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
    Key? key,
    required this.onSelectManager,
    this.selectedManager,
    this.currentUserId,
    this.hasError = false,
  }) : super(key: key);

  @override
  State<ManagerForLead> createState() => _ManagerForLeadState();
}

class _ManagerForLeadState extends State<ManagerForLead> {
  List<ManagerData> managersList = [];
  ManagerData? selectedManagerData;
  String? currentUserId;
  bool isInitialized = false;

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
    if (widget.selectedManager != oldWidget.selectedManager && widget.selectedManager != null) {
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

  @override
  Widget build(BuildContext context) {
    //print('ManagerForLead: Building with selectedManager: ${widget.selectedManager}, selectedManagerData: ${selectedManagerData?.id}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<GetAllManagerBloc, GetAllManagerState>(
          builder: (context, state) {
            //print('ManagerForLead: BlocBuilder state: $state');
            if (state is GetAllManagerError) {
              //print('ManagerForLead: Error loading managers: ${state.message}');
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
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.red,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
            }

            if (state is GetAllManagerSuccess && !isInitialized) {
              managersList = state.dataManager.result ?? [];
              //print('ManagerForLead: Loaded ${managersList.length} managers');
              isInitialized = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateSelectedManagerData();
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.translate('manager'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                const SizedBox(height: 4),
                CustomDropdown<ManagerData>.search(
                  closeDropDownOnClearFilterSearch: true,
                  items: managersList,
                  searchHintText: AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
                  enabled: true,
                  decoration: CustomDropdownDecoration(
                    closedFillColor: Color(0xffF4F7FD),
                    expandedFillColor: Colors.white,
                    closedBorder: Border.all(
                      color: widget.hasError ? Colors.red : Color(0xffF4F7FD),
                      width: 1.5,
                    ),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(
                      color: widget.hasError ? Colors.red : Color(0xffF4F7FD),
                      width: 1.5,
                    ),
                    expandedBorderRadius: BorderRadius.circular(12),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Text(
                      '${item.name!} ${item.lastname ?? ''}'.trim(),
                      style: const TextStyle(
                        color: Color(0xff1E2E52),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                      ),
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    if (state is GetAllManagerLoading) {
                      //print('ManagerForLead: Displaying loading state');
                      return Text(
                        AppLocalizations.of(context)!.translate('select_manager'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                      );
                    }
                    //print('ManagerForLead: Displaying selected item: ${selectedItem?.id} (${selectedItem?.name})');
                    return Text(
                      selectedItem != null
                          ? '${selectedItem.name ?? ''} ${selectedItem.lastname ?? ''}'.trim()
                          : AppLocalizations.of(context)!.translate('select_manager'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_manager'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
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
                    style: const TextStyle(color: Color.fromARGB(255, 241, 50, 36)),
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