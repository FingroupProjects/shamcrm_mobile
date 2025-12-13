import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

class UserMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedUsers;
  final Function(List<UserData>) onSelectUsers;
  final String? customLabelText; // ✅ НОВОЕ: для кастомного заголовка
  final bool hasError; // Флаг для отображения ошибки

  UserMultiSelectWidget({
    super.key,
    required this.onSelectUsers,
    this.selectedUsers,
    this.customLabelText, // ✅ НОВОЕ
    this.hasError = false,
  });

  @override
  State<UserMultiSelectWidget> createState() => _UserMultiSelectWidgetState();
}

class _UserMultiSelectWidgetState extends State<UserMultiSelectWidget> {
  List<UserData> usersList = [];
  List<UserData> selectedUsersData = [];
  List<UserData> displayUsersList =
      []; // Список для отображения, включая "Выбрать всех"

  final TextStyle userTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  // Фиктивный элемент для "Выбрать всех"
  final UserData selectAllItem = UserData(
    id: -1,
    name: 'select_all', // Имя будет переведено в listItemBuilder
    lastname: '',
  );

  @override
  void initState() {
    super.initState();
    // Debug логи убраны для производительности
    context.read<GetAllClientBloc>().add(GetAllClientEv());
  }

  // Синхронизация selectedUsersData с widget.selectedUsers
  void _syncSelectedUsers() {
    if (widget.selectedUsers == null || usersList.isEmpty) {
      return;
    }

    final newSelectedUsersData = usersList
        .where((user) => widget.selectedUsers!.contains(user.id.toString()))
        .toList();

    // Проверяем, изменились ли выбранные пользователи
    if (!listEquals(
      selectedUsersData.map((u) => u.id).toList()..sort(),
      newSelectedUsersData.map((u) => u.id).toList()..sort(),
    )) {
      setState(() {
        selectedUsersData = newSelectedUsersData;
      });
    }
  }

  @override
  void didUpdateWidget(UserMultiSelectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Синхронизируем только если selectedUsers изменился
    if (!listEquals(oldWidget.selectedUsers, widget.selectedUsers) &&
        usersList.isNotEmpty) {
      _syncSelectedUsers();
    }
  }

  // Метод для выбора/снятия выбора всех пользователей
  void _toggleSelectAll() {
    if (usersList.isEmpty) return;
    
    final newSelectedUsersData = selectedUsersData.length == usersList.length
        ? <UserData>[]
        : List<UserData>.from(usersList);
    
    // Проверяем, изменились ли выбранные пользователи
    final currentIds = selectedUsersData.map((u) => u.id).toList()..sort();
    final newIds = newSelectedUsersData.map((u) => u.id).toList()..sort();
    
    if (!listEquals(currentIds, newIds)) {
      setState(() {
        selectedUsersData = newSelectedUsersData;
      });
      widget.onSelectUsers(newSelectedUsersData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<UserData>>(
      validator: (value) {
        if (selectedUsersData.isEmpty) {
          return AppLocalizations.of(context)!
              .translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<UserData>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Text(
  widget.customLabelText ?? // ✅ НОВОЕ: используем кастомный текст если есть
      AppLocalizations.of(context)!.translate('assignees_list'), // дефолтный текст
  style: userTextStyle.copyWith(
    fontWeight: FontWeight.w400,
    fontSize: 16,
  ),
),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: widget.hasError ? 2 : 1,
                  color: widget.hasError ? Colors.red : Colors.white,
                ),
              ),
              child: BlocConsumer<GetAllClientBloc, GetAllClientState>(
                listener: (context, state) {
                  // Обрабатываем изменения состояния в listener, а не в builder
                  if (state is GetAllClientSuccess) {
                    final newUsersList = state.dataUser.result ?? [];
                    
                    // Обновляем состояние только если список пользователей изменился
                    if (!listEquals(
                      usersList.map((u) => u.id).toList()..sort(),
                      newUsersList.map((u) => u.id).toList()..sort(),
                    )) {
                      // Синхронизируем выбранных пользователей перед setState
                      List<UserData> newSelectedUsersData = selectedUsersData;
                      if (widget.selectedUsers != null && newUsersList.isNotEmpty) {
                        newSelectedUsersData = newUsersList
                            .where((user) => widget.selectedUsers!.contains(user.id.toString()))
                            .toList();
                      } else if (widget.selectedUsers == null) {
                        newSelectedUsersData = [];
                      }
                      
                      setState(() {
                        usersList = newUsersList;
                        displayUsersList = [selectAllItem, ...usersList];
                        selectedUsersData = newSelectedUsersData;
                      });
                    }
                  }
                },
                builder: (context, state) {
                  // В builder только читаем данные, не изменяем состояние
                  final currentUsersList = usersList;
                  
                  final currentDisplayList = currentUsersList.isNotEmpty
                      ? [selectAllItem, ...currentUsersList]
                      : displayUsersList;

                  // Используем selectedUsersData напрямую без синхронизации в build()
                  // Синхронизация происходит только в listener при изменении данных
                  return CustomDropdown<UserData>.multiSelectSearch(
                    items: currentDisplayList,
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
                      // Проверяем, является ли элемент "Выбрать всех"
                      final isSelectAll = item.id == -1;
                      final allSelected =
                          selectedUsersData.length == currentUsersList.length &&
                          currentUsersList.isNotEmpty;

                      return ListTile(
                        onTap: () {
                          if (isSelectAll) {
                            _toggleSelectAll();
                          } else {
                            onItemSelect();
                          }
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
                                  border: Border.all(
                                      color: const Color(0xff1E2E52), width: 1),
                                  color: isSelectAll
                                      ? (allSelected
                                          ? const Color(0xff1E2E52)
                                          : Colors.transparent)
                                      : (isSelected
                                          ? const Color(0xff1E2E52)
                                          : Colors.transparent),
                                ),
                                child: (isSelectAll && allSelected) ||
                                        (!isSelectAll && isSelected)
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 16)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isSelectAll
                                    ? AppLocalizations.of(context)!
                                        .translate('select_all')
                                    : '${item.name} ${item.lastname}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Gilroy',
                                  color: Color(0xff1E2E52),
                                ),
                              ),
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
                              .map((e) => '${e.name} ${e.lastname}')
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
                      // Фильтруем фиктивный элемент "Выбрать всех" из выбранных
                      final filteredValues =
                          values.where((user) => user.id != -1).toList();
                      
                      // Проверяем, изменились ли выбранные пользователи
                      final currentIds = selectedUsersData.map((u) => u.id).toList()..sort();
                      final newIds = filteredValues.map((u) => u.id).toList()..sort();
                      
                      // Вызываем callback ТОЛЬКО если данные реально изменились
                      if (!listEquals(currentIds, newIds)) {
                        setState(() {
                          selectedUsersData = filteredValues;
                        });
                        // Вызываем callback только после обновления состояния
                        widget.onSelectUsers(filteredValues);
                        field.didChange(filteredValues);
                      }
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
            if (widget.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 0),
                child: Text(
                  AppLocalizations.of(context)!.translate('field_required'),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
