import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManagerMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedManagers;
  final Function(List<ManagerData>) onSelectManagers;

  ManagerMultiSelectWidget({
    super.key,
    required this.onSelectManagers,
    this.selectedManagers,
  });

  @override
  State<ManagerMultiSelectWidget> createState() => _ManagersMultiSelectWidgetState();
}

class _ManagersMultiSelectWidgetState extends State<ManagerMultiSelectWidget> {
  List<ManagerData> managersList = [];
  List<ManagerData> selectedManagersData = [];
  bool isSystemSelected = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<GetAllManagerBloc, GetAllManagerState>(
          builder: (context, state) {
            if (state is GetAllManagerLoading) {
              // return Center(child: CircularProgressIndicator());
            }
            if (state is GetAllManagerError) {
              return Text(state.message);
            }
            if (state is GetAllManagerSuccess) {
              // Создаем системного менеджера
              final systemManager = ManagerData(
                id: 0, 
                name: AppLocalizations.of(context)!.translate('system'), 
                lastname: ""
              );
              
              // Добавляем "Система" с id = 0 в начало списка менеджеров
              managersList = [
                systemManager,
                ...state.dataManager.result ?? []
              ];
              
              if (widget.selectedManagers != null && managersList.isNotEmpty) {
                // Проверяем, есть ли "0" в списке выбранных ID
                if (widget.selectedManagers!.contains("0")) {
                  isSystemSelected = true;
                }
                
                // Получаем выбранных менеджеров из списка
                selectedManagersData = managersList
                    .where((manager) =>
                        widget.selectedManagers!.contains(manager.id.toString()))
                    .toList();
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('managers'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xfff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    child: CustomDropdown<ManagerData>.multiSelectSearch(
                      items: managersList,
                      initialItems: selectedManagersData,
                      searchHintText:
                          AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
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
                      listItemBuilder:
                          (context, item, isSelected, onItemSelect) {
                        // Особая обработка для системного менеджера
                        if (item.id == 0) {
                          isSelected = isSelected || isSystemSelected;
                        }
                        
                        return ListTile(
                          minTileHeight: 1,
                          minVerticalPadding: 2,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Padding(
                            padding: EdgeInsets.zero,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Color(0xff1E2E52), width: 1),
                                    color: isSelected
                                        ? Color(0xff1E2E52)
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? Icon(Icons.check,
                                          color: Colors.white, size: 16)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Text(item.id == 0 ? item.name : '${item.name} ${item.lastname}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Gilroy',
                                      color: Color(0xff1E2E52),
                                    )),
                              ],
                            ),
                          ),
                          onTap: () {
                            // Особая обработка клика по системному менеджеру
                            if (item.id == 0) {
                              setState(() {
                                isSystemSelected = !isSystemSelected;
                                if (isSystemSelected) {
                                  if (!selectedManagersData.any((m) => m.id == 0)) {
                                    selectedManagersData.add(systemManager);
                                  }
                                } else {
                                  selectedManagersData.removeWhere((m) => m.id == 0);
                                }
                                // Обновляем список выбранных менеджеров
                                widget.onSelectManagers(selectedManagersData);
                              });
                            } else {
                              onItemSelect();
                            }
                            FocusScope.of(context).unfocus();
                          },
                        );
                      },
                      headerListBuilder: (context, hint, enabled) {
                        int selectedManagersCount = selectedManagersData.length;

                        return Text(
                          selectedManagersCount == 0
                              ? AppLocalizations.of(context)!
                                  .translate('select_manager')
                              : '${AppLocalizations.of(context)!.translate('select_manager')} $selectedManagersCount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                          AppLocalizations.of(context)!
                              .translate('select_manager'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          )),
                      onListChanged: (values) {
                        // Убедимся, что системный менеджер сохраняется, если был выбран
                        if (isSystemSelected && !values.any((m) => m.id == 0)) {
                          values.add(systemManager);
                        }
                        widget.onSelectManagers(values);
                        setState(() {
                          selectedManagersData = values;
                        });
                      },
                    ),
                  ),
                ],
              );
            }
            return SizedBox();
          },
        ),
      ],
    );
  }
}