import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManagerRadioGroupWidget extends StatefulWidget {
  final String? selectedManager;
  final Function(ManagerData) onSelectManager;

  ManagerRadioGroupWidget(
      {super.key, required this.onSelectManager, this.selectedManager});

  @override
  State<ManagerRadioGroupWidget> createState() =>
      _ManagerRadioGroupWidgetState();
}

class _ManagerRadioGroupWidgetState extends State<ManagerRadioGroupWidget> {
  List<ManagerData> managersList = [];
  ManagerData? selectedManagerData;

  @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
  }

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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                  AppLocalizations.of(context)!.translate(state.message), // Локализация сообщения
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16, 
                      fontWeight: FontWeight.w500, 
                      color: Colors.white, 
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), 
                  ),
                  backgroundColor: Colors.red, 
                  elevation: 3,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), 
                  duration: Duration(seconds: 3),
                ),
              );
            }
            if (state is GetAllManagerSuccess) {
              managersList = state.dataManager.result ?? [];
              if (widget.selectedManager != null && managersList.isNotEmpty) {
                try {
                  selectedManagerData = managersList.firstWhere(
                    (manager) =>
                        manager.id.toString() == widget.selectedManager,
                  );
                } catch (e) {
                  selectedManagerData = null;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                   AppLocalizations.of(context)!.translate('manager'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xfff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    child: CustomDropdown<ManagerData>.search(
                      closeDropDownOnClearFilterSearch: true,
                      items: managersList,
                      searchHintText: AppLocalizations.of(context)!.translate('search'),
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
                        return Text(
                          item.name!,
                          style: TextStyle(
                            color: Color(0xff1E2E52),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                          ),
                        );
                      },
                      headerBuilder: (context, selectedItem, enabled) {
                        return Text(
                          selectedItem.name ?? AppLocalizations.of(context)!.translate('select_manager'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        );
                      },
                      hintBuilder: (context, hint, enabled) =>
                          Text(AppLocalizations.of(context)!.translate('select_manager'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xff1E2E52),
                              )),
                      excludeSelected: false,
                      initialItem: selectedManagerData,
                      validator: (value) {
                        if (value == null) {
                          return AppLocalizations.of(context)!.translate('field_required_project');
                        }
                        return null;
                      },
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
            }
            return SizedBox();
          },
        ),
      ],
    );
  }
}
