import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/author/get_all_author_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/user/author_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthorMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedAuthors;
  final ValueChanged<List<AuthorData>> onSelectAuthors;
  final String? title;
  final String? hintText;
  final bool isRequired;

  const AuthorMultiSelectWidget({
    super.key,
    required this.onSelectAuthors,
    this.selectedAuthors,
    this.title,
    this.hintText,
    this.isRequired = false,
  });

  @override
  State<AuthorMultiSelectWidget> createState() =>
      _AuthorMultiSelectWidgetState();
}

class _AuthorMultiSelectWidgetState extends State<AuthorMultiSelectWidget> {
  List<AuthorData> _authorsList = <AuthorData>[];
  List<AuthorData> _selectedAuthorsData = <AuthorData>[];
  bool _allSelected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authorBloc = context.read<GetAllAuthorBloc>();
      final state = authorBloc.state;
      if (state is GetAllAuthorSuccess) {
        _applyAuthors(
          state.dataAuthor.result ?? <AuthorData>[],
          triggerRebuild: true,
        );
      } else {
        authorBloc.add(GetAllAuthorEv());
      }
    });
  }

  @override
  void didUpdateWidget(covariant AuthorMultiSelectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedAuthors != widget.selectedAuthors) {
      _syncSelectedAuthors(triggerRebuild: true);
    }
  }

  void _applyAuthors(
    List<AuthorData> authors, {
    bool triggerRebuild = false,
  }) {
    _authorsList = authors;
    _syncSelectedAuthors(
      notifyParent: false,
      triggerRebuild: triggerRebuild,
    );
  }

  void _syncSelectedAuthors({
    bool notifyParent = false,
    bool triggerRebuild = false,
  }) {
    final selectedIds = widget.selectedAuthors ?? const <String>[];
    _selectedAuthorsData = _authorsList
        .where((author) => selectedIds.contains(author.id.toString()))
        .toList();
    _allSelected = _authorsList.isNotEmpty &&
        _selectedAuthorsData.length == _authorsList.length;

    if (notifyParent) {
      widget.onSelectAuthors(_selectedAuthorsData);
    }
    if (triggerRebuild && mounted) {
      setState(() {});
    }
  }

  void _toggleSelectAll() {
    setState(() {
      _allSelected = !_allSelected;
      _selectedAuthorsData =
          _allSelected ? List<AuthorData>.from(_authorsList) : <AuthorData>[];
    });
    widget.onSelectAuthors(_selectedAuthorsData);
  }

  String _selectedAuthorsLabel(AppLocalizations localizations) {
    if (_selectedAuthorsData.isEmpty) {
      return widget.hintText ?? localizations.translate('select_author_list');
    }
    return _selectedAuthorsData
        .map((author) => '${author.name} ${author.lastname}'.trim())
        .where((name) => name.isNotEmpty)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final authorTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'Gilroy',
      color: colors.textPrimary,
    );

    return FormField<List<AuthorData>>(
      initialValue: _selectedAuthorsData,
      validator: (value) {
        if (!widget.isRequired) return null;
        if ((value ?? const <AuthorData>[]).isEmpty) {
          return localizations.translate('field_required_project');
        }
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title ?? localizations.translate('author'),
              style: authorTextStyle.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colors.fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError ? colors.error : colors.fieldBorder,
                ),
              ),
              child: BlocBuilder<GetAllAuthorBloc, GetAllAuthorState>(
                builder: (context, state) {
                  if (state is GetAllAuthorSuccess) {
                    _applyAuthors(
                      state.dataAuthor.result ?? <AuthorData>[],
                    );
                  }

                  return CustomDropdown<AuthorData>.multiSelectSearch(
                    items: _authorsList,
                    initialItems: _selectedAuthorsData,
                    searchHintText: localizations.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: colors.fieldBg,
                      expandedFillColor: colors.surfacePrimary,
                      closedBorder: Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: colors.fieldBorder,
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                      hintStyle: authorTextStyle.copyWith(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                      headerStyle: authorTextStyle,
                      listItemStyle: authorTextStyle,
                      listItemDecoration: ListItemDecoration(
                        selectedColor:
                            colors.buttonPrimaryBg.withValues(alpha: 0.14),
                        highlightColor:
                            colors.buttonPrimaryBg.withValues(alpha: 0.08),
                        splashColor: Colors.transparent,
                      ),
                      searchFieldDecoration: SearchFieldDecoration(
                        fillColor: colors.fieldBg,
                        textStyle: authorTextStyle.copyWith(fontSize: 14),
                        hintStyle: authorTextStyle.copyWith(
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
                      final index = _authorsList.indexOf(item);
                      if (index == 0) {
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
                                    _SelectionBox(isSelected: _allSelected),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        localizations.translate('select_all'),
                                        style: authorTextStyle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(height: 20, color: colors.fieldBorder),
                            _buildListItem(item, isSelected, onItemSelect),
                          ],
                        );
                      }
                      return _buildListItem(item, isSelected, onItemSelect);
                    },
                    headerListBuilder: (context, hint, enabled) {
                      return Text(
                        _selectedAuthorsLabel(localizations),
                        style: authorTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) {
                      return Text(
                        widget.hintText ??
                            localizations.translate('select_author_list'),
                        style: authorTextStyle.copyWith(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      );
                    },
                    onListChanged: (values) {
                      setState(() {
                        _selectedAuthorsData = values;
                        _allSelected = _authorsList.isNotEmpty &&
                            values.length == _authorsList.length;
                      });
                      field.didChange(values);
                      widget.onSelectAuthors(values);
                    },
                  );
                },
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  field.errorText!,
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
    AuthorData item,
    bool isSelected,
    VoidCallback onItemSelect,
  ) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onItemSelect,
        child: Row(
          children: [
            _SelectionBox(isSelected: isSelected),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${item.name} ${item.lastname}'.trim(),
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
  }
}

class _SelectionBox extends StatelessWidget {
  final bool isSelected;

  const _SelectionBox({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(
          color: context.appColors.buttonPrimaryBg,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
        color:
            isSelected ? context.appColors.buttonPrimaryBg : Colors.transparent,
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 14,
            )
          : null,
    );
  }
}
