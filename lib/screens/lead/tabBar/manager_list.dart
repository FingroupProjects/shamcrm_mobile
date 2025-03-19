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
  bool _autoSelectionPerformed = false;

  @override
  void initState() {
    super.initState();
    // Инициализируем список с "Системой"
    managersList = [
      ManagerData(
        id: -1,
        name: "Система",
        lastname: "",
      ),
    ];
    selectedManagerData =
        managersList.first; // Устанавливаем "Систему" по умолчанию

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
        // Вызываем автовыбор после загрузки ID асинхронно
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_autoSelectionPerformed) {
            _autoSelectCurrentUserAsManager(managersList);
          }
        });
      }
      print('Current userID: $userId');
    } catch (e) {
      print('Error getting current user ID: $e');
    }
  }

  void _autoSelectCurrentUserAsManager(List<ManagerData> managers) {
    if (currentUserId == null ||
        currentUserId!.isEmpty ||
        _autoSelectionPerformed) {
      return;
    }

    for (var manager in managers) {
      if (manager.id.toString() == currentUserId) {
        setState(() {
          selectedManagerData = manager;
          _autoSelectionPerformed = true;
        });
        widget.onSelectManager(manager);
        break;
      }
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
              // Показ ошибки через addPostFrameCallback - это правильно
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

            // Обработка данных - НЕ МЕНЯЙТЕ состояние здесь
            List<ManagerData> currentManagersList = managersList;
            ManagerData? currentSelectedManagerData = selectedManagerData;

            // Обновление списка менеджеров
            if (state is GetAllManagerSuccess) {
              currentManagersList = [
                ManagerData(
                  id: -1,
                  name: "Система",
                  lastname: "",
                ),
                ...?state.dataManager.result
              ];

              // Вместо setState() просто обновляем локальную переменную
              if (widget.selectedManager != null &&
                  currentManagersList.isNotEmpty) {
                try {
                  currentSelectedManagerData = currentManagersList.firstWhere(
                    (manager) =>
                        manager.id.toString() == widget.selectedManager,
                  );
                } catch (e) {
                  currentSelectedManagerData = currentManagersList[0];
                }
              } else if (currentSelectedManagerData == null ||
                  !currentManagersList.contains(currentSelectedManagerData)) {
                currentSelectedManagerData = currentManagersList[0];
                // Вызов onSelectManager перенесем в отложенный колбэк
              }

              // Выносим обновление состояния после build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    managersList = currentManagersList;
                    selectedManagerData = currentSelectedManagerData;
                    // Если managerId = 0, выбираем "Систему"
                    if (widget.selectedManager == "0") {
                      selectedManagerData = managersList[0]; // "Система"
                    } else if (widget.selectedManager != null &&
                        managersList.isNotEmpty) {
                      try {
                        selectedManagerData = managersList.firstWhere(
                          (manager) =>
                              manager.id.toString() == widget.selectedManager,
                        );
                      } catch (e) {
                        selectedManagerData =
                            managersList[0]; // По умолчанию "Система"
                      }
                    } else if (selectedManagerData == null ||
                        !managersList.contains(selectedManagerData)) {
                      selectedManagerData = managersList[0];
                      widget.onSelectManager(managersList[0]);
                    }
                    // Если это первая загрузка, и нет выбора, устанавливаем значение по умолчанию
                    if (!_autoSelectionPerformed) {
                      widget.onSelectManager(currentSelectedManagerData!);
                      _autoSelectCurrentUserAsManager(currentManagersList);
                    }
                  });
                }
              });
            }

            // Отображаем UI на основе текущих данных
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
                        return Row(
                          children: [
                            SizedBox(),
                            Text(
                              AppLocalizations.of(context)!
                                  .translate('select_manager'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xff1E2E52),
                              ),
                            ),
                          ],
                        );
                      }
                      return Text(
                        '${selectedItem.name ?? ''} ${selectedItem.lastname ?? ''}'
                                .trim()
                                .isNotEmpty
                            ? '${selectedItem.name ?? ''} ${selectedItem.lastname ?? ''}'
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
                    initialItem: currentManagersList.isNotEmpty &&
                            currentSelectedManagerData != null &&
                            currentManagersList
                                .contains(currentSelectedManagerData)
                        ? currentSelectedManagerData
                        : currentManagersList.isNotEmpty
                            ? currentManagersList[0]
                            : null,
                    onChanged: (value) {
                      if (value != null) {
                        widget.onSelectManager(value);
                        setState(() {
                          selectedManagerData = value;
                        });
                        FocusScope.of(context).unfocus();
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
