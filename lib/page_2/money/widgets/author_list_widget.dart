import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/author/get_all_author_bloc.dart';
import 'package:crm_task_manager/models/author_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthorRadioGroupWidget extends StatefulWidget {
  final String? selectedAuthor;
  final Function(AuthorData) onSelectAuthor;

  const AuthorRadioGroupWidget({
    super.key,
    required this.onSelectAuthor,
    this.selectedAuthor,
  });

  @override
  State<AuthorRadioGroupWidget> createState() => _AuthorRadioGroupWidgetState();
}

class _AuthorRadioGroupWidgetState extends State<AuthorRadioGroupWidget> {
  List<AuthorData> authorsList = [];
  AuthorData? selectedAuthorData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<GetAllAuthorBloc>().state;
        if (state is GetAllAuthorSuccess) {
          authorsList = state.dataAuthor.result ?? [];
          _updateSelectedAuthorData();
        }
        if (state is! GetAllAuthorSuccess) {
          context.read<GetAllAuthorBloc>().add(GetAllAuthorEv());
        }
      }
    });
  }

  void _updateSelectedAuthorData() {
    if (widget.selectedAuthor != null && authorsList.isNotEmpty) {
      try {
        selectedAuthorData = authorsList.firstWhere(
              (author) => author.id.toString() == widget.selectedAuthor,
        );
        if (selectedAuthorData != null) {
          widget.onSelectAuthor(selectedAuthorData!);
        }
      } catch (e) {
        // selectedAuthorData = null;
      }
    } else {
      // selectedAuthorData = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('author'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        BlocBuilder<GetAllAuthorBloc, GetAllAuthorState>(
          builder: (context, state) {
            if (state is GetAllAuthorSuccess) {
              authorsList = state.dataAuthor.result ?? [];
              _updateSelectedAuthorData();
            }

            return CustomDropdown<AuthorData>.search(
              closeDropDownOnClearFilterSearch: true,
              items: authorsList,
              searchHintText: AppLocalizations.of(context)!.translate('search'),
              overlayHeight: 400,
              enabled: true,
              decoration: CustomDropdownDecoration(
                closedFillColor: const Color(0xffF4F7FD),
                expandedFillColor: Colors.white,
                closedBorder: Border.all(
                  color: const Color(0xffF4F7FD),
                  width: 1,
                ),
                closedBorderRadius: BorderRadius.circular(12),
                expandedBorder: Border.all(
                  color: const Color(0xffF4F7FD),
                  width: 1,
                ),
                expandedBorderRadius: BorderRadius.circular(12),
              ),
              listItemBuilder: (context, item, isSelected, onItemSelect) {
                return Text(
                  '${item.name ?? ''} ${item.lastname ?? ''}',
                  style: const TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                  ),
                );
              },
              headerBuilder: (context, selectedItem, enabled) {
                if (state is GetAllAuthorLoading) {
                  return Text(
                    AppLocalizations.of(context)!.translate('select_author'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  );
                }
                return Text(
                  selectedItem != null
                      ? '${selectedItem.name ?? ''} ${selectedItem.lastname ?? ''}'
                      : AppLocalizations.of(context)!.translate('select_author'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                );
              },
              hintBuilder: (context, hint, enabled) => Text(
                AppLocalizations.of(context)!.translate('select_author'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              excludeSelected: false,
              initialItem: authorsList.contains(selectedAuthorData)
                  ? selectedAuthorData
                  : null,
              validator: (value) {
                if (value == null) {
                  return AppLocalizations.of(context)!.translate('field_required_project');
                }
                return null;
              },
              onChanged: (value) {
                if (value != null) {
                  widget.onSelectAuthor(value);
                  setState(() {
                    selectedAuthorData = value;
                  });
                  FocusScope.of(context).unfocus();
                }
              },
            );
          },
        ),
      ],
    );
  }
}