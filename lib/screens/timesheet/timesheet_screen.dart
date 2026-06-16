import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/timesheet_models.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:crm_task_manager/screens/timesheet/timesheet_detail_screen.dart';
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
      setState(() => _isLoadingMore = true);
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
    if (_isLoading || _isLoadingMore || _page > _lastPage) {
      return;
    }
    _loadTimesheet(reset: false);
  }

  void _onUsersSelected(List<UserData> users) {
    setState(() {
      _selectedUserIds = users.map((u) => u.id.toString()).toList();
    });
  }

  Future<void> _applyFilter() => _loadTimesheet(reset: true);

  Future<void> _resetFilter() async {
    setState(() => _selectedUserIds = const []);
    await _loadTimesheet(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: context.appColors.backgroundPrimary,
        elevation: 0,
        surfaceTintColor: context.appColors.backgroundPrimary,
        foregroundColor: context.appColors.textPrimary,
        title: Text(
          'Табель',
          style: context.appTextStyles.titleLg.copyWith(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: context.appColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () => setState(() => _showFilter = !_showFilter),
              style: IconButton.styleFrom(
                backgroundColor: _showFilter
                    ? context.appColors.buttonPrimaryBg
                    : context.appColors.buttonPrimaryBg.withValues(alpha: 0.10),
              ),
              icon: Icon(
                _showFilter ? Icons.close_rounded : Icons.filter_alt_outlined,
                color: _showFilter
                    ? context.appColors.textInverse
                    : context.appColors.textPrimary,
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
              color: context.appColors.buttonPrimaryBg,
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
        color: context.appColors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Фильтр по пользователям',
            style: context.appTextStyles.bodyLg.copyWith(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          UserMultiSelectWidget(
            selectedUsers: _selectedUserIds,
            customLabelText: 'Пользователи',
            isRequired: false,
            hasError: false,
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
                    side: BorderSide(
                      color: context.appColors.borderSubtle,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Сбросить',
                    style: context.appTextStyles.bodyLg.copyWith(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: context.appColors.textPrimary,
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
                    backgroundColor: context.appColors.buttonPrimaryBg,
                    foregroundColor: context.appColors.textInverse,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Показать',
                    style: context.appTextStyles.bodyLg.copyWith(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: context.appColors.textInverse,
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
            color: context.appColors.surfacePrimary,
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
            color: context.appColors.textSecondary,
          ),
          const SizedBox(height: 14),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: context.appTextStyles.titleMd.copyWith(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: context.appColors.textPrimary,
            ),
          ),
        ],
      );
    }

    if (_entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.event_note_rounded,
            size: 54,
            color: context.appColors.textSecondary,
          ),
          const SizedBox(height: 14),
          Text(
            'Сотрудники не найдены',
            textAlign: TextAlign.center,
            style: context.appTextStyles.titleMd.copyWith(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: context.appColors.textPrimary,
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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(
                color: context.appColors.buttonPrimaryBg,
              ),
            ),
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

// ─────────────────────────────────────────────
// Card
// ─────────────────────────────────────────────

class _TimesheetListCard extends StatelessWidget {
  final TimesheetEntry entry;

  const _TimesheetListCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.surfacePrimary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TimesheetDetailScreen(entry: entry),
          ),
        ),
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
                    child: Text(
                      entry.user.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTextStyles.titleMd.copyWith(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: context.appColors.textPrimary,
                      ),
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

// ─────────────────────────────────────────────
// Compact info cell
// ─────────────────────────────────────────────

class _CompactInfo extends StatelessWidget {
  final String label;
  final String value;

  const _CompactInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.appColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.appTextStyles.bodySm.copyWith(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.appTextStyles.bodyMd.copyWith(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: context.appColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Status chip
// ─────────────────────────────────────────────

class _ListStatusChip extends StatelessWidget {
  final TimesheetEntry entry;

  const _ListStatusChip({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isNotStarted = !entry.hasStarted;

    final background = entry.isActive
        ? const Color(0xFFE0F7EA)
        : isNotStarted
            ? context.appColors.surfacePrimary
            : context.appColors.buttonPrimaryBg.withValues(alpha: 0.12);

    final foreground = entry.isActive
        ? const Color(0xFF1E9E5A)
        : isNotStarted
            ? context.appColors.textSecondary
            : context.appColors.buttonPrimaryBg;

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
