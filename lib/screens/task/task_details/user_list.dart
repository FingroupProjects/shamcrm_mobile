import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedUsers;
  final Function(List<UserData>) onSelectUsers;

  UserMultiSelectWidget({
    super.key,
    required this.onSelectUsers,
    this.selectedUsers,
  });

  @override
  State<UserMultiSelectWidget> createState() => _UserMultiSelectWidgetState();
}

class _UserMultiSelectWidgetState extends State<UserMultiSelectWidget> {
  List<UserData> usersList = [];
  List<UserData> selectedUsersData = [];

  final TextStyle userTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    context.read<GetAllClientBloc>().add(GetAllClientEv());
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<UserData>>(
      validator: (value) {
        if (selectedUsersData.isEmpty) {
          return AppLocalizations.of(context)!.translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<UserData>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('assignees_list'),
              style: userTextStyle.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError ? Colors.red : Colors.white,
                ),
              ),
              child: BlocBuilder<GetAllClientBloc, GetAllClientState>(
                builder: (context, state) {
                  if (state is GetAllClientSuccess) {
                    usersList = state.dataUser.result ?? [];
                    if (widget.selectedUsers != null && usersList.isNotEmpty) {
                      selectedUsersData = usersList
                          .where((user) => widget.selectedUsers!
                              .contains(user.id.toString()))
                          .toList();
                    }
                  }

                  return CustomDropdown<UserData>.multiSelectSearch(
                    items: usersList,
                    initialItems: selectedUsersData,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: const Color(0xffF4F7FD),
                      expandedFillColor: Colors.white,
                      closedBorder: Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                    ),
                      listItemBuilder: (context, item, isSelected, onItemSelect) {
                        return ListTile(
                         onTap: () {
                           onItemSelect();
                           WidgetsBinding.instance.addPostFrameCallback((_) {
                             FocusScope.of(context).unfocus();
                           });
                           WidgetsBinding.instance.addPostFrameCallback((_) {
                             FocusScope.of(context).unfocus();
                           });
                         },
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
                                    border: Border.all(color: Color(0xff1E2E52), width: 1),
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
                                Text('${item.name} ${item.lastname ?? ''}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Gilroy',
                                      color: Color(0xff1E2E52),
                                    )),
                              ],
                            ),
                          ),
                       
                        );
                      },
                    headerListBuilder: (context, hint, enabled) {
                      String selectedUsersNames = selectedUsersData.isEmpty
                          ? AppLocalizations.of(context)!
                              .translate('select_assignees_list')
                          : selectedUsersData
                              .map((e) => '${e.name} ${e.lastname ?? ''}')
                              .join(', ');

                      return Text(
                        selectedUsersNames,
                        style: userTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!
                          .translate('select_assignees_list'),
                      style: userTextStyle.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    onListChanged: (values) {
                      widget.onSelectUsers(values);
                      setState(() {
                        selectedUsersData = values;
                      });
                      field.didChange(values);
                      // FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 0),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
