import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/models/manager_model.dart';
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
  State<ManagerRadioGroupWidget> createState() => _ManagerRadioGroupWidgetState();
}

class _ManagerRadioGroupWidgetState extends State<ManagerRadioGroupWidget> {
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

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
            );
          },
        ),
      ],
    );
  }
}