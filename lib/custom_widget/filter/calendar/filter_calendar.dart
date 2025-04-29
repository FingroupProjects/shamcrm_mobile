import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/filter/calendar/user_calendar_multi_list.dart';
import 'package:crm_task_manager/models/author_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class CalendarFilterScreen extends StatefulWidget {
  final Function(List<String>, List<String>)? onTypesSelected;
  final List<String>? initialTypes;
  final List<String>? initialUsers; 

  const CalendarFilterScreen({
    Key? key,
    this.onTypesSelected,
    this.initialTypes,
    this.initialUsers, 
  }) : super(key: key);

  @override
  _CalendarFilterScreenState createState() => _CalendarFilterScreenState();
}

class _CalendarFilterScreenState extends State<CalendarFilterScreen> {
  bool _hasTask = false;
  bool _hasMyTask = false;
  bool _hasNotice = false;
  List<String> _selectedUsers = [];
  final ApiService _apiService = ApiService();
  bool _canReadUserList = false;



    Future<void> _checkPermissions() async {
    // final canReadUserList = await _apiService.hasPermission('notice.read');
    final canReadUserList = await _apiService.hasPermission('calendar.another');

    setState(() {
      _canReadUserList = canReadUserList;
    });
  }


  @override
  void initState() {
    super.initState();
     _checkPermissions();
    if (widget.initialTypes != null) {
      _hasTask = widget.initialTypes!.contains('task');
      _hasMyTask = widget.initialTypes!.contains('my_task');
      _hasNotice = widget.initialTypes!.contains('notice');
    }
    if (widget.initialUsers != null) {
      _selectedUsers = List.from(widget.initialUsers!); 
    }
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black54,
          fontFamily: 'Gilroy',
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      inactiveTrackColor: Colors.grey.withOpacity(0.5),
      activeTrackColor: ChatSmsStyles.messageBubbleSenderColor,
      inactiveThumbColor: Colors.white,
    );
  }

  List<String> _getSelectedTypes() {
    List<String> types = [];
    if (_hasTask) types.add('task');
    if (_hasMyTask) types.add('my_task');
    if (_hasNotice) types.add('notice');
    return types;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FD),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('filter'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
            fontFamily: 'Gilroy',
          ),
        ),
        backgroundColor: Colors.white,
        forceMaterialTransparency: true,
        leadingWidth: 50,
        leading: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Transform.translate(
            offset: const Offset(0, -2),
            child: IconButton(
              icon: Image.asset(
                'assets/icons/arrow-left.png',
                width: 24,
                height: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _hasTask = false;
                _hasMyTask = false;
                _hasNotice = false;
                _selectedUsers = []; 
              });
              widget.onTypesSelected?.call([], []); 
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('reset'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () {
              final selectedTypes = _getSelectedTypes();
              widget.onTypesSelected?.call(selectedTypes, _selectedUsers);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('apply'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      elevation: 0,
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('Задача'),
                            _hasTask,
                            (value) => setState(() => _hasTask = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('Моя задача'),
                            _hasMyTask,
                            (value) => setState(() => _hasMyTask = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('События'),
                            _hasNotice,
                            (value) => setState(() => _hasNotice = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if(_canReadUserList)
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: UserListCalendarWidget(
                          selectedAuthors: _selectedUsers,
                          onSelectAuthors: (List<AuthorData> selectedAuthorsData) {
                            setState(() {
                              _selectedUsers = selectedAuthorsData
                                  .map((author) => author.id.toString())
                                  .toList();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}