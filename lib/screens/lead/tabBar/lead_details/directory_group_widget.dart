import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/directory_bloc/directory_bloc.dart';
import 'package:crm_task_manager/bloc/directory_bloc/directory_event.dart';
import 'package:crm_task_manager/bloc/directory_bloc/directory_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/task/directory_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DirectoryGroupWidget extends StatefulWidget {
  final String? selectedDirectory;
  final Function(Directory) onSelectDirectory;

  const DirectoryGroupWidget({
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
    context.read<GetDirectoryBloc>().add(GetDirectoryEv());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return FormField<Directory>(
      validator: (value) {
        if (selectedDirectoryData == null) {
          return AppLocalizations.of(context)!.translate('field_required_directory');
        }
        return null;
      },
      builder: (FormFieldState<Directory> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('directory'),
              style: textStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
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
                    if (widget.selectedDirectory != null && directoriesList.isNotEmpty) {
                      try {
                        selectedDirectoryData = directoriesList.firstWhere(
                          (directory) =>
                              directory.id.toString() == widget.selectedDirectory,
                        );
                      } catch (e) {
                        selectedDirectoryData = null;
                      }
                    }
                  }

                  return CustomDropdown<Directory>.search(
                    closeDropDownOnClearFilterSearch: true,
                    items: directoriesList,
                      searchHintText: AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
                      decoration: CustomDropdownDecoration(
                      closedFillColor: colors.fieldBg,
                      expandedFillColor: colors.surfacePrimary,
                      closedBorder: Border.all(
                        color: colors.borderSubtle,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: colors.borderSubtle,
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                          child: Text(
                          item.name,
                          style: textStyles.bodyMd.copyWith(color: colors.textPrimary),
                        ),
                      );
                    },
                    headerBuilder: (context, selectedItem, enabled) {
                      return Text(
                        selectedItem.name,
                        style: textStyles.bodyMd.copyWith(color: colors.textPrimary),
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!.translate('select_directory'),
                      style: textStyles.bodyMd.copyWith(
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
