import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_bloc.dart';
import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_event.dart';
import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_state.dart';
import 'package:crm_task_manager/models/event/notice_subject_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TematikaListWidget extends StatefulWidget {
  final String? selectedSubject;
  final Function(String) onSelectSubject;
  final bool hasError;

  const TematikaListWidget({
    super.key,
    this.selectedSubject,
    required this.onSelectSubject,
    this.hasError = false,
  });

  @override
  State<TematikaListWidget> createState() => _TematikaListWidgetState();
}

class _TematikaListWidgetState extends State<TematikaListWidget> {
  final ApiService _apiService = ApiService();
  List<SubjectData> subjectList = [];
  SubjectData? selectedSubjectData;

  @override
  void initState() {
    super.initState();
    context.read<GetAllSubjectBloc>().add(GetAllSubjectEv());
  }

  @override
  void didUpdateWidget(covariant TematikaListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSubject != widget.selectedSubject) {
      _updateSelectedSubjectData();
    }
  }

  void _updateSelectedSubjectData() {
    if (widget.selectedSubject == null || subjectList.isEmpty) {
      selectedSubjectData = null;
      return;
    }

    try {
      selectedSubjectData = subjectList.firstWhere(
        (subject) => subject.title == widget.selectedSubject,
      );
    } catch (_) {
      selectedSubjectData = null;
    }
  }

  Future<List<SubjectData>> _searchSubjects(String query) async {
    final response = await _apiService.getAllSubjects(search: query);
    return response.result ?? <SubjectData>[];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fieldBorder =
        widget.hasError ? colors.error : colors.borderSubtle.withValues(alpha: 0.7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('subject'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        BlocBuilder<GetAllSubjectBloc, GetAllSubjectState>(
          builder: (context, state) {
            if (state is GetAllSubjectError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.translate(state.message),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colors.textInverse,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.red,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
            }

            if (state is GetAllSubjectSuccess) {
              subjectList = state.dataSubject.result ?? [];
              _updateSelectedSubjectData();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomDropdown<SubjectData>.searchRequest(
                  futureRequest: _searchSubjects,
                  futureRequestDelay: const Duration(milliseconds: 350),
                  closeDropDownOnClearFilterSearch: true,
                  items: subjectList,
                  initialItem: selectedSubjectData,
                  searchHintText:
                      AppLocalizations.of(context)!.translate('search'),
                  hintText:
                      AppLocalizations.of(context)!.translate('select_subject'),
                  overlayHeight: 400,
                  enabled: true,
                  decoration: CustomDropdownDecoration(
                    closedFillColor:
                        colors.surfacePrimary.withValues(alpha: 0.72),
                    expandedFillColor: colors.surfacePrimary,
                    closedBorder: Border.all(
                      color: fieldBorder,
                      width: 1,
                    ),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(
                      color: fieldBorder,
                      width: 1,
                    ),
                    expandedBorderRadius: BorderRadius.circular(12),
                    closedSuffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colors.iconSecondary,
                      ),
                    ),
                    expandedSuffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: colors.iconSecondary,
                      ),
                    ),
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: colors.textSecondary,
                    ),
                    headerStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: colors.textPrimary,
                    ),
                    listItemStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: colors.textPrimary,
                    ),
                    searchFieldDecoration: SearchFieldDecoration(
                      fillColor: colors.surfacePrimary,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: colors.textSecondary,
                      ),
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: colors.textPrimary,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: colors.textSecondary,
                      ),
                      suffixIcon: (onClear) => IconButton(
                        onPressed: onClear,
                        icon: Icon(
                          Icons.close_rounded,
                          color: colors.textSecondary,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: fieldBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: colors.buttonPrimaryBg),
                      ),
                    ),
                    listItemDecoration: ListItemDecoration(
                      selectedColor:
                          colors.buttonPrimaryBg.withValues(alpha: 0.14),
                      highlightColor:
                          colors.buttonPrimaryBg.withValues(alpha: 0.08),
                      splashColor: Colors.transparent,
                    ),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: colors.textPrimary,
                      ),
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    return Text(
                      selectedItem.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: colors.textPrimary,
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_subject'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: colors.textPrimary,
                    ),
                  ),
                  noResultFoundBuilder: (context, text) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          AppLocalizations.of(context)!
                              .translate('no_data_to_display'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                  excludeSelected: false,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    widget.onSelectSubject(value.title);
                    setState(() {
                      selectedSubjectData = value;
                    });
                    FocusScope.of(context).unfocus();
                  },
                ),
                if (widget.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 0, left: 12),
                    child: Text(
                      AppLocalizations.of(context)!.translate('field_required'),
                      style: TextStyle(
                        color: colors.error,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
