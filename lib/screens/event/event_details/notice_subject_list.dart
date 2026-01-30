import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_bloc.dart';
import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_event.dart';
import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_state.dart';
import 'package:crm_task_manager/models/notice_subject_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SubjectSelectionWidget extends StatefulWidget {
  final String? selectedSubject;
  final Function(String) onSelectSubject;
  final bool hasError;

  const SubjectSelectionWidget({
    Key? key,
    this.selectedSubject,
    required this.onSelectSubject,
    this.hasError = false,
  }) : super(key: key);

  @override
  State<SubjectSelectionWidget> createState() => _SubjectSelectionWidgetState();
}

class _SubjectSelectionWidgetState extends State<SubjectSelectionWidget> {
  List<SubjectData> subjectList = [];
  List<SubjectData> filteredList = [];
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isDropdownVisible = false;

  @override
  void initState() {
    super.initState();
    context.read<GetAllSubjectBloc>().add(GetAllSubjectEv());
    _textController.text = widget.selectedSubject ?? '';

    _textController.addListener(() {
      widget.onSelectSubject(_textController.text.trim());
    });
  }

  void filterSearchResults(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredList = List.from(subjectList);
      } else {
        filteredList = subjectList
            .where((item) => item.title.toLowerCase().contains(query.toLowerCase().trim()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок поля + звёздочка
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: AppLocalizations.of(context)!.translate('subject'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        BlocBuilder<GetAllSubjectBloc, GetAllSubjectState>(
          builder: (context, state) {
            if (state is GetAllSubjectLoading) {
              return _buildTextFieldSkeleton();
            }
            if (state is GetAllSubjectSuccess) {
              subjectList = state.dataSubject.result ?? [];
              if (filteredList.isEmpty && !_isDropdownVisible) {
                filteredList = List.from(subjectList);
              }
            }
            return _buildTextField();
          },
        ),

        // Текст ошибки под полем (как в CustomTextField)
        if (widget.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              AppLocalizations.of(context)!.translate('field_required'),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextFieldSkeleton() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xffF4F7FD),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildTextField() {
    final borderColor = widget.hasError ? Colors.red : const Color(0xffF4F7FD);
    final borderWidth = widget.hasError ? 2.0 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xffF4F7FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.translate('select_subject'),
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff99A4BA),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    widget.onSelectSubject(value.trim());
                  },
                ),
              ),
              IconButton(
                icon: Transform.rotate(
                  angle: 90 * 3.1415926535 / 180,
                  child: Image.asset('assets/icons/arrow_down.png', width: 12, height: 12),
                ),
                onPressed: () {
                  setState(() {
                    _isDropdownVisible = !_isDropdownVisible;
                    if (!_isDropdownVisible) {
                      _searchController.clear();
                    }
                  });
                },
              ),
            ],
          ),
        ),

        if (_isDropdownVisible)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffF4F7FD), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.translate('search'),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffF4F7FD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffF4F7FD)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: filterSearchResults,
                  ),
                ),
                Expanded(
                  child: filteredList.isEmpty && _searchController.text.isNotEmpty
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context)!.translate('no_data_to_display'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                filteredList[index].title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Gilroy',
                                  color: Color(0xff1E2E52),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _textController.text = filteredList[index].title;
                                  _isDropdownVisible = false;
                                  _searchController.clear();
                                });
                                widget.onSelectSubject(filteredList[index].title.trim());
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}