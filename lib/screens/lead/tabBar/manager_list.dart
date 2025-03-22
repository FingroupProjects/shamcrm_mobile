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

  ManagerRadioGroupWidget({
    super.key,
    required this.onSelectManager,
    this.selectedManager,
    this.currentUserId,
  });

  @override
  State<ManagerRadioGroupWidget> createState() =>
      _ManagerRadioGroupWidgetState();
}

class _ManagerRadioGroupWidgetState extends State<ManagerRadioGroupWidget> {
  List<ManagerData> managersList = [];
  ManagerData? selectedManagerData;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    // Инициализируем список с "Системой", но не выбираем ничего автоматически
    managersList = [
      ManagerData(
        id: -1,
        name: "Система",
        lastname: "",
      ),
    ];
    // Не устанавливаем selectedManagerData по умолчанию

    print(
        'ManagerRadioGroupWidget initState: currentUserId = ${widget.currentUserId}');
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
      print('Current userID: $userId');
    } catch (e) {
      print('Error getting current user ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<GetAllManagerBloc, GetAllManagerState>(
          builder: (context, state) {
            // Обработка ошибок
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
                        color: Colors.white,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.red,
                    elevation: 3,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: Duration(seconds: 3),
                  ),
                );
              });
            }

            // Обработка данных
            List<ManagerData> currentManagersList = managersList;
            ManagerData? currentSelectedManagerData = selectedManagerData;

            if (state is GetAllManagerSuccess) {
              currentManagersList = [
                ManagerData(
                  id: -1,
                  name: "Система",
                  lastname: "",
                ),
                ...?state.dataManager.result
              ];

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    managersList = currentManagersList;
                    // Не устанавливаем selectedManagerData автоматически
                    // Оставляем выбор только на основе widget.selectedManager, если он передан
                    if (widget.selectedManager != null &&
                        managersList.isNotEmpty) {
                      try {
                        selectedManagerData = managersList.firstWhere(
                          (manager) =>
                              manager.id.toString() == widget.selectedManager,
                        );
                      } catch (e) {
                        selectedManagerData = null; // Ничего не выбрано
                      }
                    }
                  });
                }
              });
            }

            // Отображаем UI
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.translate('manager'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  child: CustomDropdown<ManagerData>.search(
                    closeDropDownOnClearFilterSearch: true,
                    items: currentManagersList,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    enabled: true,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: Color(0xffF4F7FD),
                      expandedFillColor: Colors.white,
                      closedBorder: Border.all(
                        color: Color(0xffF4F7FD),
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: Color(0xffF4F7FD),
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      return Text(
                        '${item.name!} ${item.lastname ?? ''}'.trim(),
                        style: TextStyle(
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
                          AppLocalizations.of(context)!
                              .translate('select_manager'),
                          style: TextStyle(
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
                            : AppLocalizations.of(context)!
                                .translate('select_manager'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!.translate('select_manager'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    excludeSelected: false,
                    initialItem: currentSelectedManagerData,
                    onChanged: (value) {
                      if (value != null) {
                        widget.onSelectManager(value);
                        setState(() {
                          selectedManagerData = value;
                        });
                      }
                    },
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