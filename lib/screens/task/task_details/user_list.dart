import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/user/user_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedUsers;
  final Function(List<UserData>) onSelectUsers;
  final String? customLabelText;
  final bool hasError;
  final bool isRequired;
  final Color? backgroundColor;

  const UserMultiSelectWidget({
    super.key,
    required this.onSelectUsers,
    this.selectedUsers,
    this.customLabelText,
    this.hasError = false,
    this.isRequired = true,
    this.backgroundColor,
  });

  @override
  State<UserMultiSelectWidget> createState() => _UserMultiSelectWidgetState();
}

class _UserMultiSelectWidgetState extends State<UserMultiSelectWidget> {
  static const int _pageSize = 20;
  final ApiService _apiService = ApiService();
  final MultiSelectController<UserData> _selectedUsersController =
      MultiSelectController<UserData>([]);

  final UserData selectAllItem = UserData(
    id: -1,
    name: 'select_all',
    lastname: '',
  );

  List<UserData> usersList = [];
  List<UserData> initialUsersList = [];
  List<UserData> selectedUsersData = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialUsers();
  }

  @override
  void didUpdateWidget(covariant UserMultiSelectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.selectedUsers, widget.selectedUsers)) {
      _syncSelectedUsers();
    }
  }

  @override
  void dispose() {
    _selectedUsersController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialUsers() async {
    setState(() => isLoading = true);
    try {
      await _apiService.ensureInitialized();
      final response = await _apiService.getAllUser(
        page: 1,
        perPage: _pageSize,
      );
      if (!mounted) return;

      final loadedUsers = response.result ?? <UserData>[];
      setState(() {
        usersList = loadedUsers;
        initialUsersList = loadedUsers;
        isLoading = false;
      });
      _syncSelectedUsers(notifyParent: false);
    } catch (error) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('UserMultiSelectWidget: failed to load users: $error');
      }
      setState(() {
        usersList = [];
        selectedUsersData = [];
        isLoading = false;
      });
      _selectedUsersController.value = [];
    }
  }

  Future<List<UserData>> _searchUsers(String query) async {
    try {
      final normalizedQuery = query.trim();
      final response = await _apiService.getAllUser(
        search: normalizedQuery.isEmpty ? null : normalizedQuery,
        page: 1,
        perPage: _pageSize,
      );
      final result = response.result ?? <UserData>[];
      if (mounted) {
        setState(() {
          usersList = result;
          if (normalizedQuery.isEmpty) {
            initialUsersList = result;
          }
        });
        _selectedUsersController.value = List<UserData>.from(selectedUsersData);
      }
      return [selectAllItem, ...result];
    } catch (error) {
      if (kDebugMode) {
        debugPrint('UserMultiSelectWidget: failed to search users: $error');
      }
      return [selectAllItem, ...usersList];
    }
  }

  void _syncSelectedUsers({bool notifyParent = false}) {
    if (usersList.isEmpty) return;

    final selectedIds = widget.selectedUsers ?? const <String>[];
    final usersById = <int, UserData>{
      for (final user in selectedUsersData) user.id: user,
      for (final user in usersList) user.id: user,
    };
    final nextSelected = selectedIds
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .map((id) => usersById[id])
        .whereType<UserData>()
        .toList();

    final currentIds = selectedUsersData.map((u) => u.id).toList()..sort();
    final nextIds = nextSelected.map((u) => u.id).toList()..sort();

    if (!listEquals(currentIds, nextIds)) {
      setState(() {
        selectedUsersData = nextSelected;
      });
    }

    _selectedUsersController.value = List<UserData>.from(selectedUsersData);

    if (notifyParent) {
      widget.onSelectUsers(selectedUsersData);
    }
  }

  void _toggleSelectAll() {
    final visibleUsers = usersList;
    if (visibleUsers.isEmpty) return;

    final visibleSelectedCount = visibleUsers
        .where((visibleUser) =>
            selectedUsersData.any((selected) => selected.id == visibleUser.id))
        .length;

    final nextSelected = visibleSelectedCount == visibleUsers.length
        ? selectedUsersData
            .where((selected) => !visibleUsers
                .any((visibleUser) => visibleUser.id == selected.id))
            .toList()
        : _mergeSelections(selectedUsersData, visibleUsers);

    setState(() {
      selectedUsersData = nextSelected;
    });
    _selectedUsersController.value = List<UserData>.from(nextSelected);
    widget.onSelectUsers(nextSelected);
  }

  void _handleDropdownVisibility(bool isVisible) {
    if (!isVisible || initialUsersList.isEmpty) return;

    final currentIds = usersList.map((user) => user.id).toList()..sort();
    final initialIds = initialUsersList.map((user) => user.id).toList()..sort();
    if (listEquals(currentIds, initialIds)) return;

    setState(() {
      usersList = List<UserData>.from(initialUsersList);
    });
    _selectedUsersController.value = List<UserData>.from(selectedUsersData);
  }

  List<UserData> _normalizeSelection(List<UserData> values) {
    return values.where((user) => user.id != -1).toList();
  }

  List<UserData> _mergeSelections(
    List<UserData> currentSelection,
    List<UserData> visibleUsers,
  ) {
    final mergedById = <int, UserData>{
      for (final user in currentSelection) user.id: user,
    };
    for (final visibleUser in visibleUsers) {
      mergedById[visibleUser.id] = visibleUser;
    }
    return mergedById.values.toList();
  }

  String _selectedLabel(AppLocalizations localizations) {
    if (selectedUsersData.isEmpty) {
      return localizations.translate('select_assignees_list');
    }

    return selectedUsersData
        .map((user) => user.displayName)
        .where((name) => name.isNotEmpty)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final localizations = AppLocalizations.of(context)!;
    final fieldBackground = widget.backgroundColor ?? colors.fieldBg;
    final borderColor = colors.borderSubtle.withValues(alpha: 0.7);
    final accentColor = colors.buttonPrimaryBg;
    final userTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'Gilroy',
      color: colors.textPrimary,
    );

    return FormField<List<UserData>>(
      initialValue: selectedUsersData,
      validator: (value) {
        if (!widget.isRequired) return null;
        if ((value ?? const <UserData>[]).isEmpty) {
          return localizations.translate('field_required_project');
        }
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.customLabelText ??
                  localizations.translate('assignees_list'),
              style: userTextStyle.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: fieldBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: (widget.hasError || field.hasError)
                      ? Colors.red
                      : borderColor,
                ),
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : CustomDropdown<UserData>.multiSelectSearchRequest(
                      multiSelectController: _selectedUsersController,
                      futureRequest: _searchUsers,
                      futureRequestDelay: const Duration(milliseconds: 350),
                      closeDropDownOnClearFilterSearch: true,
                      visibility: _handleDropdownVisibility,
                      items: usersList.isEmpty
                          ? const []
                          : [selectAllItem, ...usersList],
                      searchHintText: localizations.translate('search'),
                      overlayHeight: 400,
                      decoration: CustomDropdownDecoration(
                        closedFillColor: fieldBackground,
                        expandedFillColor: colors.surfacePrimary,
                        closedBorder: Border.all(
                          color: borderColor,
                          width: 1,
                        ),
                        closedBorderRadius: BorderRadius.circular(12),
                        expandedBorder: Border.all(
                          color: borderColor,
                          width: 1,
                        ),
                        expandedBorderRadius: BorderRadius.circular(12),
                        hintStyle: userTextStyle.copyWith(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                        headerStyle: userTextStyle,
                        listItemStyle: userTextStyle,
                        listItemDecoration: ListItemDecoration(
                          selectedColor:
                              accentColor.withValues(alpha: 0.14),
                          highlightColor:
                              accentColor.withValues(alpha: 0.08),
                          splashColor: Colors.transparent,
                        ),
                        searchFieldDecoration: SearchFieldDecoration(
                          fillColor: fieldBackground,
                          textStyle: userTextStyle,
                          hintStyle: userTextStyle.copyWith(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colors.textMuted,
                          ),
                          suffixIcon: (onClear) => IconButton(
                            onPressed: onClear,
                            icon: Icon(
                              Icons.close,
                              color: colors.textMuted,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: accentColor),
                          ),
                        ),
                      ),
                      listItemBuilder:
                          (context, item, isSelected, onItemSelect) {
                        final isSelectAll = item.id == -1;
                        final visibleUsers =
                            usersList.where((user) => user.id != -1).toList();
                        final allVisibleSelected = visibleUsers.isNotEmpty &&
                            visibleUsers.every(
                              (visibleUser) => selectedUsersData.any(
                                (selected) => selected.id == visibleUser.id,
                              ),
                            );

                        return ListTile(
                          onTap: () {
                            if (isSelectAll) {
                              _toggleSelectAll();
                            } else {
                              onItemSelect();
                            }
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
                                      color: isSelectAll
                                          ? accentColor
                                          : (isSelected
                                              ? accentColor
                                              : colors.borderPrimary),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    color: isSelectAll
                                        ? (allVisibleSelected
                                            ? accentColor
                                            : Colors.transparent)
                                        : (isSelected
                                            ? accentColor
                                            : Colors.transparent),
                                  ),
                                  child: (isSelectAll && allVisibleSelected) ||
                                          (!isSelectAll && isSelected)
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isSelectAll
                                        ? localizations.translate('select_all')
                                        : item.displayName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Gilroy',
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      headerListBuilder: (context, hint, enabled) {
                        return Text(
                          _selectedLabel(localizations),
                          style: userTextStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                        localizations.translate('select_assignees_list'),
                        style: userTextStyle.copyWith(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                      onListChanged: (values) {
                        final filteredValues = _normalizeSelection(values);
                        final visibleUserIds =
                            usersList.map((user) => user.id).toSet();
                        final hiddenSelectedUsers = selectedUsersData
                            .where(
                              (user) => !visibleUserIds.contains(user.id),
                            )
                            .toList();
                        final nextSelected = _mergeSelections(
                          hiddenSelectedUsers,
                          filteredValues,
                        );
                        final currentIds =
                            selectedUsersData.map((u) => u.id).toList()..sort();
                        final newIds = nextSelected.map((u) => u.id).toList()
                          ..sort();

                        if (listEquals(currentIds, newIds)) {
                          return;
                        }

                        setState(() {
                          selectedUsersData = nextSelected;
                        });
                        _selectedUsersController.value =
                            List<UserData>.from(nextSelected);
                        widget.onSelectUsers(nextSelected);
                        field.didChange(nextSelected);
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
