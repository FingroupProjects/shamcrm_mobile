import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManagerMultiSelectWidget extends StatefulWidget {
  final List<int> selectedManagers;
  final Function(List<int>) onSelectManagers;

  const ManagerMultiSelectWidget({
    Key? key,
    required this.selectedManagers,
    required this.onSelectManagers,
  }) : super(key: key);

  @override
  State<ManagerMultiSelectWidget> createState() =>
      _ManagerMultiSelectWidgetState();
}

class _ManagerMultiSelectWidgetState extends State<ManagerMultiSelectWidget> {
  final TextEditingController _searchController = TextEditingController();
  bool isExpanded = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
  }

  List<ManagerData> filterManagers(List<ManagerData> managers) {
    if (searchQuery.isEmpty) return managers;
    return managers.where((manager) {
      final name = (manager.name?.toString().toLowerCase() ?? '');
      return name.contains(searchQuery.toLowerCase());
    }).toList();
  }

  void _toggleSelectAll(List<ManagerData> managers) {
    List<int> newSelection = List.from(widget.selectedManagers);
    if (newSelection.length == managers.length) {
      newSelection.clear();
    } else {
      newSelection = managers.map((manager) => manager.id).toList();
    }
    widget.onSelectManagers(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('select_managers'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            decoration: BoxDecoration(
              color: Color(0xffF4F7FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xffF4F7FD),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: BlocBuilder<GetAllManagerBloc, GetAllManagerState>(
                    builder: (context, state) {
                      if (state is GetAllManagerSuccess) {
                        final selectedNames = state.dataManager.result
                            ?.where((manager) =>
                                widget.selectedManagers.contains(manager.id))
                            .map((manager) =>
                                '${manager.name} ${manager.lastname ?? ''}')
                            .join(', ');

                        return Text(
                          selectedNames?.isNotEmpty == true
                              ? selectedNames!
                              : AppLocalizations.of(context)!
                                  .translate('select_m'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                      return Text(
                        AppLocalizations.of(context)!.translate('select_m'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                      );
                    },
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Color(0xff1E2E52),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xffF4F7FD)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          AppLocalizations.of(context)!.translate('search'),
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
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  child: BlocBuilder<GetAllManagerBloc, GetAllManagerState>(
                    builder: (context, state) {
                      if (state is GetAllManagerLoading) {
                        return Center(child: CircularProgressIndicator());
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
                        final managers = state.dataManager.result ?? [];
                        final filteredManagers = filterManagers(managers);
                        final allSelected = managers.isNotEmpty &&
                            widget.selectedManagers.length == managers.length;

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredManagers.length + 1, 
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return InkWell(
                                onTap: () {
                                  _toggleSelectAll(managers);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
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
                                          color: allSelected
                                              ? Color(0xFF4339F2)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: allSelected
                                                ? Color(0xFF4339F2)
                                                : Color(0xFFCCCCCC),
                                            width: 1,
                                          ),
                                        ),
                                        child: allSelected
                                            ? Icon(Icons.check,
                                                size: 18, color: Colors.white)
                                            : null,
                                      ),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .translate('select_all'),
                                          style: TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontSize: 14,
                                            color: Color(0xFF1E2E52),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final manager = filteredManagers[index - 1];
                            final isSelected =
                                widget.selectedManagers.contains(manager.id);

                            return InkWell(
                              onTap: () {
                                List<int> newSelection =
                                    List.from(widget.selectedManagers);
                                if (isSelected) {
                                  newSelection.remove(manager.id);
                                } else {
                                  newSelection.add(manager.id);
                                }
                                FocusScope.of(context).unfocus();
                                widget.onSelectManagers(newSelection);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
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
                                        '${manager.name} ${manager.lastname ?? ''}' ?? AppLocalizations.of(context)!.translate('no_name'),
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
              ],
            ),
          ),
      ],
    );
  }
}