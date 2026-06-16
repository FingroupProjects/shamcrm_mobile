import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedUsers;
  final Function(List<UserData>) onSelectUsers;
  final String? customLabelText;
  final bool hasError;
  final bool isRequired;

  const UserMultiSelectWidget({
    super.key,
    required this.onSelectUsers,
    this.selectedUsers,
    this.customLabelText,
    this.hasError = false,
    this.isRequired = true,
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
    final response = await _apiService.getAllUser(
      search: query,
      page: 1,
      perPage: _pageSize,
    );
    final result = response.result ?? <UserData>[];
    if (mounted) {
      setState(() {
        usersList = result;
      });
    }
    return [selectAllItem, ...result];
  }

  void _syncSelectedUsers({bool notifyParent = false}) {
    if (usersList.isEmpty) return;

    final selectedIds = widget.selectedUsers ?? const <String>[];
    final nextSelected = usersList
        .where((user) => selectedIds.contains(user.id.toString()))
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
        .map((user) => '${user.name} ${user.lastname}'.trim())
        .where((name) => name.isNotEmpty)
        .join(', ');
  }

  bool get _allVisible {
    if (usersList.isEmpty) return false;
    return usersList.every(
      (u) => selectedUsersData.any((s) => s.id == u.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final userTextStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );
    final hintStyle = userTextStyle.copyWith(
      fontSize: 14,
      color: context.appColors.textSecondary,
    );
    final borderColor = context.appColors.borderSubtle;

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
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.appColors.fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: (widget.hasError || field.hasError)
                      ? context.appColors.error
                      : context.appColors.borderSubtle,
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
                      items: usersList.isEmpty
                          ? const []
                          : [selectAllItem, ...usersList],
                      searchHintText: localizations.translate('search'),
                      overlayHeight: 400,
                      decoration: CustomDropdownDecoration(
                        closedFillColor: context.appColors.fieldBg,
                        expandedFillColor: context.appColors.surfacePrimary,
                        closedBorder: Border.all(
                          color: Colors.transparent,
                          width: 1,
                        ),
                        closedBorderRadius: BorderRadius.circular(12),
                        expandedBorder: Border.all(
                          color: context.appColors.borderSubtle,
                          width: 1,
                        ),
                        expandedBorderRadius: BorderRadius.circular(12),
                        hintStyle: hintStyle,
                        headerStyle: userTextStyle,
                        listItemStyle: userTextStyle,
                        listItemDecoration: ListItemDecoration(
                          selectedColor: context.appColors.buttonPrimaryBg
                              .withValues(alpha: 0.14),
                          highlightColor: context.appColors.buttonPrimaryBg
                              .withValues(alpha: 0.08),
                          splashColor: Colors.transparent,
                        ),
                        searchFieldDecoration: SearchFieldDecoration(
                          fillColor: context.appColors.backgroundPrimary,
                          textStyle: userTextStyle,
                          hintStyle: hintStyle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: context.appColors.buttonPrimaryBg,
                            ),
                          ),
                        ),
                      ),
                      listItemBuilder:
                          (context, item, isSelected, onItemSelect) {
                        final isSelectAll = item.id == -1;

                        if (isSelectAll) {
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
                                            color:
                                                context.appColors.textPrimary,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          color: _allVisible
                                              ? context
                                                  .appColors.buttonPrimaryBg
                                              : Colors.transparent,
                                        ),
                                        child: _allVisible
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
                                          localizations.translate('select_all'),
                                          style: userTextStyle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Divider(
                                height: 20,
                                color: context.appColors.borderSubtle,
                              ),
                            ],
                          );
                        }

                        return _buildListItem(
                          context,
                          item,
                          isSelected,
                          onItemSelect,
                          userTextStyle,
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
                        style: hintStyle,
                      ),
                      onListChanged: (values) {
                        final filteredValues = _normalizeSelection(values);
                        final currentIds =
                            selectedUsersData.map((u) => u.id).toList()
                              ..sort();
                        final newIds =
                            filteredValues.map((u) => u.id).toList()..sort();

                        if (listEquals(currentIds, newIds)) return;

                        setState(() {
                          selectedUsersData = filteredValues;
                        });
                        widget.onSelectUsers(filteredValues);
                        field.didChange(filteredValues);
                      },
                    ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  field.errorText!,
                  style: context.appTextStyles.bodyMd.copyWith(
                    color: context.appColors.error,
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
    TextStyle textStyle,
  ) {
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
                  color: context.appColors.textPrimary,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color: isSelected
                    ? context.appColors.buttonPrimaryBg
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${item.name} ${item.lastname}'.trim(),
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}