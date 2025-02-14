import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/author/get_all_author_bloc.dart';
import 'package:crm_task_manager/models/author_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthorMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedAuthors;
  final Function(List<AuthorData>) onSelectAuthors;

  AuthorMultiSelectWidget({
    super.key,
    required this.onSelectAuthors,
    this.selectedAuthors,
  });

  @override
  State<AuthorMultiSelectWidget> createState() => _AuthorMultiSelectWidgetState();
}

class _AuthorMultiSelectWidgetState extends State<AuthorMultiSelectWidget> {
  List<AuthorData> authorsList = [];
  List<AuthorData> selectedAuthorsData = [];

  final TextStyle authorTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    context.read<GetAllAuthorBloc>().add(GetAllAuthorEv());
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<AuthorData>>(
      validator: (value) {
        if (selectedAuthorsData.isEmpty) {
          return AppLocalizations.of(context)!
              .translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<AuthorData>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('author_list'),
              style: authorTextStyle.copyWith(
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
                  width: 1,
                  color: field.hasError ? Colors.red : const Color(0xFFE5E7EB),
                ),
              ),
              child: BlocBuilder<GetAllAuthorBloc, GetAllAuthorState>(
                builder: (context, state) {
                  if (state is GetAllAuthorSuccess) {
                    authorsList = state.dataAuthor.result ?? [];
                    if (widget.selectedAuthors != null && authorsList.isNotEmpty) {
                      selectedAuthorsData = authorsList
                          .where((author) => widget.selectedAuthors!
                              .contains(author.id.toString()))
                          .toList();
                    }
                  }

                  return CustomDropdown<AuthorData>.multiSelectSearch(
                    items: authorsList,
                    initialItems: selectedAuthorsData,
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xff1E2E52),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                color: isSelected
                                    ? const Color(0xff1E2E52)
                                    : Colors.transparent,
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
                                '${item.name!} ${item.lastname ?? ''}', // Добавляем фамилию
                                style: authorTextStyle,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    headerListBuilder: (context, hint, enabled) {
                      String selectedAuthorsNames = selectedAuthorsData.isEmpty
                          ? AppLocalizations.of(context)!
                              .translate('select_author_list')
                          : selectedAuthorsData
                              .map((e) => '${e.name} ${e.lastname ?? ''}')
                              .join(', ');

                      return Text(
                        selectedAuthorsNames,
                        style: authorTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!
                          .translate('select_author_list'),
                      style: authorTextStyle.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    onListChanged: (values) {
                      widget.onSelectAuthors(values);
                      setState(() {
                        selectedAuthorsData = values;
                      });
                      field.didChange(values);
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
