import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManagerFilterPopup extends StatefulWidget {
  final Function(List<dynamic>)? onManagerSelected;

  const ManagerFilterPopup({
    Key? key,
    this.onManagerSelected,
  }) : super(key: key);

  @override
  _ManagerFilterPopupState createState() => _ManagerFilterPopupState();
}

class _ManagerFilterPopupState extends State<ManagerFilterPopup> {
  Set<dynamic> selectedManagers = {};
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  void updateSelection(dynamic manager) {
    setState(() {
      if (selectedManagers.contains(manager)) {
        selectedManagers.remove(manager);
      } else {
        selectedManagers.add(manager);
      }
    });
    _notifySelectionChanged();
  }

  void _notifySelectionChanged() {
    if (widget.onManagerSelected != null) {
      final managerIds = selectedManagers.map((manager) => manager.id).toList();
      widget.onManagerSelected!(managerIds);
    }
  }

  void toggleSelectAll(List<dynamic> managers) {
    setState(() {
      if (selectedManagers.length == managers.length) {
        // Если все выбраны - снимаем выбор
        selectedManagers.clear();
      } else {
        // Иначе выбираем всех
        selectedManagers = Set.from(managers);
      }
    });
    _notifySelectionChanged();
  }

  List<dynamic> filterManagers(List<dynamic> managers) {
    if (searchQuery.isEmpty) return managers;
    return managers.where((manager) {
      final name = manager.name?.toString().toLowerCase() ?? '';
      return name.contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      constraints: BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocBuilder<GetAllManagerBloc, GetAllManagerState>(
            builder: (context, state) {
              final allManagers = state is GetAllManagerSuccess
                  ? state.dataManager.result ?? []
                  : [];
              final isAllSelected = allManagers.isNotEmpty &&
                  selectedManagers.length == allManagers.length;

              return Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    // Select All Checkbox
                    Container(
                      width: 24,
                      height: 24,
                      margin: EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => toggleSelectAll(allManagers),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isAllSelected
                                ? Color(0xFF4339F2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isAllSelected
                                  ? Color(0xFF4339F2)
                                  : Color(0xFFCCCCCC),
                              width: 1,
                            ),
                          ),
                          child: isAllSelected
                              ? Icon(Icons.check, size: 18, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                    // Search Field
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Поиск',
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFEEEEEE)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFEEEEEE)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF1E2E52)),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<GetAllManagerBloc, GetAllManagerState>(
              builder: (context, state) {
                if (state is GetAllManagerLoading) {
                  return Center(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                            color: Color(0xff1E2E52))),
                  );
                } else if (state is GetAllManagerError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        state.message,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                } else if (state is GetAllManagerSuccess) {
                  final managers = state.dataManager.result;
                  if (managers == null) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Нет доступных менеджеров',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                    );
                  }

                  final filteredManagers = filterManagers(managers);

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredManagers.length,
                    itemBuilder: (context, index) {
                      final manager = filteredManagers[index];
                      final name = manager.name ?? 'Без имени';
                      final isSelected = selectedManagers.contains(manager);

                      return InkWell(
                        onTap: () => updateSelection(manager),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFEEEEEE),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                margin: EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Color(0xFF4339F2)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isSelected
                                        ? Color(0xFF4339F2)
                                        : Color(0xFFCCCCCC),
                                    width: 1,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(Icons.check,
                                        size: 18, color: Colors.white)
                                    : null,
                              ),
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 14,
                                    color: Color(0xFF1E2E52),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return Container();
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: () {
                _notifySelectionChanged();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4339F2),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Применить',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}