import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/directory_bloc/directory_bloc.dart';
import 'package:crm_task_manager/bloc/directory_bloc/directory_event.dart';
import 'package:crm_task_manager/bloc/directory_bloc/directory_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/directory_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';

class AddCustomDirectoryDialog extends StatefulWidget {
  final void Function(Directory) onAddDirectory;

  AddCustomDirectoryDialog({required this.onAddDirectory});

  @override
  _AddCustomDirectoryDialogState createState() =>
      _AddCustomDirectoryDialogState();
}

class _AddCustomDirectoryDialogState extends State<AddCustomDirectoryDialog> {
  Directory? selectedDirectory;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    return AlertDialog(
      backgroundColor: colors.surfacePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.borderSubtle),
      ),
      title: Text(
        AppLocalizations.of(context)!.translate('add_directory'),
        style: textStyles.titleMd.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DirectoryGroupWidget(
                onSelectDirectory: (Directory directory) {
                  setState(() {
                    selectedDirectory = directory;
                  });
                },
                selectedDirectory: null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: CustomButton(
                buttonText: AppLocalizations.of(context)!.translate('cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                buttonColor: colors.buttonDangerBg,
                textColor: colors.buttonDangerFg,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomButton(
                buttonText: AppLocalizations.of(context)!.translate('add'),
                onPressed: () async {
                  if (selectedDirectory != null) {
                    widget.onAddDirectory(selectedDirectory!);
                    Navigator.of(context).pop();
                  }
                },
                buttonColor: colors.buttonPrimaryBg,
                textColor: colors.buttonPrimaryFg,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DirectoryGroupWidget extends StatefulWidget {
  final String? selectedDirectory;
  final Function(Directory) onSelectDirectory;

  DirectoryGroupWidget({
    super.key,
    required this.onSelectDirectory,
    this.selectedDirectory,
  });

  @override
  State<DirectoryGroupWidget> createState() => _DirectoryGroupWidgetState();
}

class _DirectoryGroupWidgetState extends State<DirectoryGroupWidget> {
  List<Directory> directoriesList = [];
  Directory? selectedDirectoryData;

  @override
  void initState() {
    super.initState();
    selectedDirectoryData = null;
    context.read<GetDirectoryBloc>().add(GetDirectoryEv());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final directoryTextStyle = textStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      fontFamily: 'Gilroy',
      color: colors.textPrimary,
    );

    return FormField<Directory>(
      validator: (value) {
        if (selectedDirectoryData == null) {
          return AppLocalizations.of(context)!
              .translate('field_required_directory');
        }
        return null;
      },
      builder: (FormFieldState<Directory> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('directory'),
              style: directoryTextStyle.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colors.fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError ? colors.error : colors.borderSubtle,
                ),
              ),
              child: BlocBuilder<GetDirectoryBloc, GetDirectoryState>(
                builder: (context, state) {
                  if (state is GetDirectorySuccess) {
                    directoriesList = state.dataDirectory.result ?? [];
                    if (widget.selectedDirectory != null &&
                        directoriesList.isNotEmpty) {
                      try {
                        selectedDirectoryData = directoriesList.firstWhere(
                          (directory) =>
                              directory.id.toString() ==
                              widget.selectedDirectory,
                          orElse: () =>
                              selectedDirectoryData ?? directoriesList.first,
                        );
                      } catch (e) {
                        selectedDirectoryData = null;
                      }
                    } else {
                      selectedDirectoryData = null;
                    }
                  } else if (state is GetDirectoryError) {
                    return Text(
                      state.message,
                      style: TextStyle(color: colors.error),
                    );
                  }

                  return CustomDropdown<Directory>.search(
                    closeDropDownOnClearFilterSearch: true,
                    items: directoriesList,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: colors.fieldBg,
                      expandedFillColor: colors.surfacePrimary,
                      closedBorder: Border.all(
                        color: colors.overlay.withValues(alpha: 0),
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: colors.borderSubtle,
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                      hintStyle: textStyles.bodyMd.copyWith(
                        color: colors.fieldHint,
                      ),
                      headerStyle: directoryTextStyle,
                      listItemStyle: directoryTextStyle,
                      searchFieldDecoration: SearchFieldDecoration(
                        fillColor: colors.fieldBg,
                        hintStyle: textStyles.bodyMd.copyWith(
                          color: colors.fieldHint,
                        ),
                        textStyle: textStyles.bodyLg.copyWith(
                          color: colors.textPrimary,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: colors.iconSecondary,
                        ),
                        suffixIcon: (onClear) => IconButton(
                          onPressed: onClear,
                          icon: Icon(
                            Icons.close_rounded,
                            color: colors.iconSecondary,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.borderPrimary),
                        ),
                      ),
                      listItemDecoration: ListItemDecoration(
                        selectedColor: colors.surfaceElevated,
                        highlightColor:
                            colors.surfaceElevated.withValues(alpha: 0.72),
                        splashColor: colors.overlay.withValues(alpha: 0),
                      ),
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          item.name,
                          style: directoryTextStyle,
                        ),
                      );
                    },
                    headerBuilder: (context, selectedItem, enabled) {
                      return Text(
                        selectedItem.name,
                        style: directoryTextStyle,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!
                          .translate('select_directory'),
                      style: directoryTextStyle.copyWith(
                        fontSize: 14,
                        color: colors.fieldHint,
                      ),
                    ),
                    excludeSelected: false,
                    initialItem: selectedDirectoryData,
                    onChanged: (value) {
                      if (value != null) {
                        widget.onSelectDirectory(value);
                        setState(() {
                          selectedDirectoryData = value;
                        });
                        field.didChange(value);
                        FocusScope.of(context).unfocus();
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
}
