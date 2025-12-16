import 'package:animated_custom_dropdown/custom_dropdown.dart';
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
  final bool hasError; // Флаг для отображения ошибки

  SubjectSelectionWidget({
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

    // Добавляем слушатель изменений текста
    _textController.addListener(() {
      // Вызываем callback при любом изменении текста
      widget.onSelectSubject(_textController.text);
    });
  }

  void filterSearchResults(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredList = List.from(subjectList); // Показываем все элементы
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
            color: Color(0xfff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        BlocBuilder<GetAllSubjectBloc, GetAllSubjectState>(
          builder: (context, state) {
            if (state is GetAllSubjectLoading) {
              // Показываем индикатор загрузки, если данные загружаются
              return Column(
                children: [
                  _buildTextField(),
                  // Center(child: CircularProgressIndicator()),
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
              width: widget.hasError ? 2 : 1,
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
                    hintText: AppLocalizations.of(context)!
                        .translate('select_subject'),
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
                icon: Transform.rotate(
                  angle: 90 * 3.1415926535 / 180,
                  child: Image.asset('assets/icons/arrow_down.png', width: 12, height: 12),
                ),
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
                      hintText: AppLocalizations.of(context)!
                          .translate('search'),
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide
                            .none, // Убираем фиолетовую обводку
                      ),
                      enabledBorder: OutlineInputBorder(
                        // Добавляем свою обводку
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Color(0xffF4F7FD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        // И для фокуса тоже
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Color(0xffF4F7FD)),
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
                  child: filteredList.isEmpty &&
                          _searchController.text.isNotEmpty
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
                                  _textController.text =
                                      filteredList[index].title;
                                  selectedSubjectData =
                                      filteredList[index];
                                  _isDropdownVisible = false;
                                  _searchController.clear();
                                  filteredList = [];
                                });
                                widget.onSelectSubject(
                                    filteredList[index].title);
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