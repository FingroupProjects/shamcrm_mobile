import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/timesheet_models.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:crm_task_manager/screens/timesheet/timesheet_detail_screen.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _showFilter = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  List<TimesheetEntry> _entries = const [];
  List<String> _selectedUserIds = const [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTimesheet();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTimesheet({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _page = 1;
        _error = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final response = await _apiService.getTimesheet(
        page: reset ? 1 : _page,
        userIds: _selectedUserIds,
      );

      if (!mounted) return;
      setState(() {
        _entries = reset ? response.items : [..._entries, ...response.items];
        _lastPage = response.lastPage < 1 ? 1 : response.lastPage;
        _page = (reset ? response.currentPage : _page) + 1;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить табель';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 240) {
      return;
    }
    if (_isLoading || _isLoadingMore || _page > _lastPage) return;
    _loadTimesheet(reset: false);
  }

  void _onUsersSelected(List<UserData> users) {
    setState(() {
      _selectedUserIds = users.map((user) => user.id.toString()).toList();
    });
  }

  Future<void> _applyFilter() async {
    await _loadTimesheet(reset: true);
  }

  Future<void> _resetFilter() async {
    setState(() {
      _selectedUserIds = const [];
    });
    await _loadTimesheet(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.primaryBlue,
        title: const Text(
          'Табель',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: AppColors.primaryBlue,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _showFilter = !_showFilter;
                });
              },
              style: IconButton.styleFrom(
                backgroundColor: _showFilter
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFFF1F5FE),
              ),
              icon: Icon(
                _showFilter ? Icons.close_rounded : Icons.filter_alt_outlined,
                color: _showFilter ? Colors.white : AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              heightFactor: _showFilter ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: _showFilter ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeInOut,
                child: _buildFilterPanel(),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadTimesheet(reset: true),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF4F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Фильтр по пользователям',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          UserMultiSelectWidget(
            selectedUsers: _selectedUserIds,
            customLabelText: 'Пользователи',
            customHintText: 'Выберите пользователей',
            isRequired: false,
            hasError: false,
            backgroundColor: Colors.white,
            onSelectUsers: _onUsersSelected,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _selectedUserIds.isEmpty ? null : _resetFilter,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: Color(0xff1E2E52), width: .2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Сбросить',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilter,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: const Color(0xff1E2E52),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Показать',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 108,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xffF4F7FD),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.badge_outlined,
            size: 54,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      );
    }

    if (_entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Icon(
            Icons.event_note_rounded,
            size: 54,
            color: Color(0xFFB7C1D1),
          ),
          SizedBox(height: 14),
          Text(
            'Сотрудники не найдены',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _entries.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _entries.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final entry = _entries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _TimesheetListCard(entry: entry),
        );
      },
    );
  }
}

class _TimesheetListCard extends StatelessWidget {
  final TimesheetEntry entry;

  const _TimesheetListCard({
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffF4F7FD),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TimesheetDetailScreen(entry: entry),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.user.fullName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ListStatusChip(entry: entry),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CompactInfo(
                      label: 'Время прихода',
                      value: _formatTime(entry.startedAt),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CompactInfo(
                      label: 'Время ухода',
                      value: _formatTime(entry.endedAt),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('dd.MM.yyyy HH:mm').format(value);
  }
}

class _CompactInfo extends StatelessWidget {
  final String label;
  final String value;

  const _CompactInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF7B8798),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListStatusChip extends StatelessWidget {
  final TimesheetEntry entry;

  const _ListStatusChip({
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final isNotStarted = !entry.hasStarted;
    final background = entry.isActive
        ? const Color(0xFFE0F7EA)
        : isNotStarted
            ? const Color(0xFFF1F3F7)
            : const Color(0xFFE9F0FF);
    final foreground = entry.isActive
        ? const Color(0xFF1E9E5A)
        : isNotStarted
            ? const Color(0xFF657389)
            : const Color(0xFF3755C5);

    return Container(
      constraints: const BoxConstraints(minWidth: 102),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        entry.statusLabel,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: foreground,
        ),
      ),
    );
  }
}
