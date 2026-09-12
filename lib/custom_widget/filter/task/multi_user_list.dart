import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/user/user_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedUsers;
  final Function(List<UserData>) onSelectUsers;

  const UserMultiSelectWidget({
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
  bool allSelected = false;

  @override
  void initState() {
    super.initState();
    context.read<GetAllClientBloc>().add(GetAllClientEv());
  }

  // Функция для выделения/снятия выделения всех пользователей
  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      if (allSelected) {
        selectedUsersData = List.from(usersList); // Выбираем всех
      } else {
        selectedUsersData = []; // Снимаем выделение
      }
      widget.onSelectUsers(selectedUsersData);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return FormField<List<UserData>>(
      validator: (value) {
        if (selectedUsersData.isEmpty) {
          return AppLocalizations.of(context)!
              .translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<UserData>> field) {
        final labelStyle = TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          fontFamily: 'Gilroy',
          color: colors.textPrimary,
        );
        final valueStyle = TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Gilroy',
          color: colors.textPrimary,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('assignees_list'),
              style: labelStyle,
            ),
            const SizedBox(height: 8),
            BlocBuilder<GetAllClientBloc, GetAllClientState>(
                builder: (context, state) {
                  if (state is GetAllClientSuccess) {
                    usersList = state.dataUser.result ?? [];
                    if (widget.selectedUsers != null && usersList.isNotEmpty) {
                      selectedUsersData = usersList
                          .where((user) => widget.selectedUsers!
                              .contains(user.id.toString()))
                          .toList();
                      allSelected =
                          selectedUsersData.length == usersList.length;
                    }
                  }

                  return CustomDropdown<UserData>.multiSelectSearch(
                    items: usersList,
                    initialItems: selectedUsersData,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: colors.fieldBg,
                      expandedFillColor: colors.surfacePrimary,
                      closedBorder: Border.all(
                        color: field.hasError ? colors.error : colors.borderSubtle,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: colors.borderSubtle,
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                      hintStyle: valueStyle.copyWith(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                      headerStyle: valueStyle,
                      listItemStyle: valueStyle,
                      listItemDecoration: ListItemDecoration(
                        selectedColor:
                            colors.buttonPrimaryBg.withValues(alpha: 0.14),
                        highlightColor:
                            colors.buttonPrimaryBg.withValues(alpha: 0.08),
                        splashColor: Colors.transparent,
                      ),
                      searchFieldDecoration: SearchFieldDecoration(
                        fillColor: colors.fieldBg,
                        textStyle: valueStyle.copyWith(fontSize: 14),
                        hintStyle: valueStyle.copyWith(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                        prefixIcon:
                            Icon(Icons.search, color: colors.iconSecondary),
                        suffixIcon: (onClear) => IconButton(
                          onPressed: onClear,
                          icon: Icon(Icons.close_rounded,
                              color: colors.iconSecondary),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.fieldBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.buttonPrimaryBg),
                        ),
                      ),
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      // Добавляем "Выделить всех" как первый элемент
                      if (usersList.indexOf(item) == 0) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: GestureDetector(
                                onTap: _toggleSelectAll,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: colors.buttonPrimaryBg,
                                            width: 1),
                                        borderRadius: BorderRadius.circular(4),
                                        color: allSelected
                                            ? colors.buttonPrimaryBg
                                            : Colors.transparent,
                                      ),
                                      child: allSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 14,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .translate('select_all'),
                                        style: valueStyle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(height: 20, color: colors.fieldBorder),
                            _buildListItem(context, item, isSelected,
                                onItemSelect, valueStyle),
                          ],
                        );
                      }
                      // Обычные элементы списка
                      return _buildListItem(
                          context, item, isSelected, onItemSelect, valueStyle);
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
                        style: valueStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!
                          .translate('select_assignees_list'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: colors.textSecondary,
                      ),
                    ),
                    onListChanged: (values) {
                      widget.onSelectUsers(values);
                      setState(() {
                        selectedUsersData = values;
                        allSelected = values.length == usersList.length;
                      });
                      field.didChange(values);
                    },
                  );
                },
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 0),
                child: Text(
                  field.errorText ?? '',
                  style: TextStyle(
                    color: colors.error,
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

  Widget _buildListItem(
    BuildContext context,
    UserData item,
    bool isSelected,
    Function() onItemSelect,
    TextStyle valueStyle,
  ) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onItemSelect,
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.buttonPrimaryBg,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color: isSelected ? colors.buttonPrimaryBg : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${item.name ?? ''} ${item.lastname ?? ''}',
                style: valueStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
