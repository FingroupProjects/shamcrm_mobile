import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_bloc.dart';
import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_event.dart';
import 'package:crm_task_manager/bloc/notice_subject_list/notice_subject_list_state.dart';
import 'package:crm_task_manager/models/notice_subject_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TematikaListWidget extends StatefulWidget {
  final String? selectedSubject;
  final Function(String) onSelectSubject;
  final bool hasError; // Новая переменная для индикации ошибки

  TematikaListWidget({
    Key? key,
    this.selectedSubject,
    required this.onSelectSubject,
    this.hasError = false, // По умолчанию нет ошибки
  }) : super(key: key);

  @override
  State<TematikaListWidget> createState() => _TematikaListWidgetState();
}

class _TematikaListWidgetState extends State<TematikaListWidget> {
  List<SubjectData> subjectList = [];
  List<SubjectData> filteredList = [];
  SubjectData? selectedSubjectData;
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
      widget.onSelectSubject(_textController.text);
    });
  }

  void filterSearchResults(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredList = List.from(subjectList);
      } else {
        filteredList = subjectList
            .where((item) =>
                item.title.toLowerCase().contains(query.toLowerCase().trim()))
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
        Text(
          AppLocalizations.of(context)!.translate('subject'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        BlocBuilder<GetAllSubjectBloc, GetAllSubjectState>(
          builder: (context, state) {
            if (state is GetAllSubjectLoading) {
              return Column(
                children: [
                  _buildTextField(),
                ],
              );
            }

            if (state is GetAllSubjectError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.translate(state.message),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.red,
                  elevation: 3,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  duration: Duration(seconds: 3),
                ),
              );
            }

            if (state is GetAllSubjectSuccess) {
              subjectList = state.dataSubject.result ?? [];
              if (filteredList.isEmpty && !_isDropdownVisible) {
                filteredList = List.from(subjectList);
              }

              if (widget.selectedSubject != null && subjectList.isNotEmpty) {
                try {
                  selectedSubjectData = subjectList.firstWhere(
                    (subject) => subject.title == widget.selectedSubject,
                  );
                } catch (e) {
                  selectedSubjectData = null;
                }
              }
            }
            return _buildTextField();
          },
        ),
      ],
    );
  }

  Widget _buildTextField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        decoration: BoxDecoration(
          color: Color(0xffF4F7FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.hasError ? Colors.red : Color(0xffF4F7FD),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.translate('select_subject'),
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  widget.onSelectSubject(value);
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_drop_down),
              onPressed: () {
                setState(() {
                  _isDropdownVisible = !_isDropdownVisible;
                  if (!_isDropdownVisible) {
                    _searchController.clear();
                    filteredList = [];
                  }
                });
              },
            ),
          ],
        ),
      ),
      if (widget.hasError) 
        Padding(
          padding: const EdgeInsets.only(top: 0, left: 12),
          child: Text(
            AppLocalizations.of(context)!.translate('field_required'),
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        ),
      if (_isDropdownVisible)
        Container(
          margin: EdgeInsets.only(top: 4),
          constraints: BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xffF4F7FD),
              width: 1,
            ),
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
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xffF4F7FD)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xffF4F7FD)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    filterSearchResults(value);
                  },
                ),
              ),
              Expanded(
                child: filteredList.isEmpty && _searchController.text.isNotEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!
                              .translate('no_data_to_display'),
                          style: TextStyle(
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
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xff1E2E52),
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _textController.text = filteredList[index].title;
                                selectedSubjectData = filteredList[index];
                                _isDropdownVisible = false;
                                _searchController.clear();
                                filteredList = [];
                              });
                              widget.onSelectSubject(filteredList[index].title);
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