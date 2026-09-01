import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_bloc.dart';
import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_event.dart';
import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/event/notice_subject_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SubjectSelectionWidget extends StatefulWidget {
  final String? selectedSubject;
  final Function(String) onSelectSubject;
  final bool hasError;

  const SubjectSelectionWidget({
    super.key,
    this.selectedSubject,
    required this.onSelectSubject,
    this.hasError = false,
  });

  @override
  State<SubjectSelectionWidget> createState() => _SubjectSelectionWidgetState();
}

class _SubjectSelectionWidgetState extends State<SubjectSelectionWidget> {
  static const int _pageSize = 20;
  final ApiService _apiService = ApiService();
  late final TextEditingController _textController;
  List<SubjectData> subjectList = [];

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.selectedSubject ?? '');
    context.read<GetAllSubjectBloc>().add(GetAllSubjectEv());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SubjectSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSubject != widget.selectedSubject) {
      final nextValue = widget.selectedSubject ?? '';
      if (_textController.text != nextValue) {
        _textController.value = _textController.value.copyWith(
          text: nextValue,
          selection: TextSelection.collapsed(offset: nextValue.length),
          composing: TextRange.empty,
        );
      }
    }
  }

  Future<List<SubjectData>> _searchSubjects(String query) async {
    final response = await _apiService.getAllSubjects(
      search: query,
      page: 1,
      perPage: _pageSize,
    );
    return response.result ?? <SubjectData>[];
  }

  Future<void> _openSubjectPicker() async {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final searchController = TextEditingController();
    List<SubjectData> items = List<SubjectData>.from(subjectList);
    bool isLoading = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> handleSearch(String query) async {
              setModalState(() {
                isLoading = true;
              });

              try {
                final results = await _searchSubjects(query);
                if (!mounted) return;
                setModalState(() {
                  items = results;
                });
              } finally {
                if (mounted) {
                  setModalState(() {
                    isLoading = false;
                  });
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.borderPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.translate('subject'),
                        style: textStyles.titleMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        onChanged: handleSearch,
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context)!.translate('search'),
                          prefixIcon:
                              Icon(Icons.search, color: colors.textSecondary),
                          filled: true,
                          fillColor: colors.fieldBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: textStyles.bodyLg.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: colors.buttonPrimaryBg,
                                ),
                              )
                            : items.isEmpty
                                ? Center(
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .translate('no_data_to_display'),
                                      style: textStyles.bodyMd.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: items.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      final isSelected =
                                          item.title == _textController.text;
                                      return Material(
                                        color: colors.fieldBackground,
                                        borderRadius: BorderRadius.circular(12),
                                        child: ListTile(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          title: Text(
                                            item.title,
                                            style: textStyles.bodyMd.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                          trailing: isSelected
                                              ? Icon(
                                                  Icons.check,
                                                  color: colors.buttonPrimaryBg,
                                                )
                                              : null,
                                          onTap: () {
                                            _textController.text = item.title;
                                            widget.onSelectSubject(item.title);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('subject'),
          style: context.appTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w500,
            color: context.appColors.textPrimary,
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
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
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
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _textController,
                  onChanged: (value) {
                    widget.onSelectSubject(value);
                  },
                  style: context.appTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!
                        .translate('select_subject'),
                    hintStyle: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: context.appColors.fieldBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.appColors.borderSubtle,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.hasError
                            ? context.appColors.error
                            : context.appColors.borderSubtle,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.hasError
                            ? context.appColors.error
                            : context.appColors.buttonPrimaryBg,
                        width: 1,
                      ),
                    ),
                    suffixIcon: IconButton(
                      onPressed: _openSubjectPicker,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.appColors.iconPrimary,
                      ),
                    ),
                  ),
                ),
                if (widget.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 12),
                    child: Text(
                      AppLocalizations.of(context)!.translate('field_required'),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appColors.error,
                        fontWeight: FontWeight.w400,
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
