import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/filter/event/event_status_list.dart';
import 'package:crm_task_manager/custom_widget/filter/event/multi_manager_list.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class EventManagerFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onManagersSelected;
  final List? initialManagers;
  final int? initialStatuses;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final DateTime? initialNoticeFromDate;
  final DateTime? initialNoticeToDate;
  final VoidCallback? onResetFilters;

  const EventManagerFilterScreen({
    super.key,
    this.onManagersSelected,
    this.initialManagers,
    this.initialStatuses,
    this.initialFromDate,
    this.initialToDate,
    this.initialNoticeFromDate,
    this.initialNoticeToDate,
    this.onResetFilters,
  });

  @override
  State<EventManagerFilterScreen> createState() =>
      _EventManagerFilterScreenState();
}

class _EventManagerFilterScreenState extends State<EventManagerFilterScreen> {
  List _selectedManagers = [];
  int? _selectedStatuses;
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _noticeFromDate;
  DateTime? _noticeToDate;

  @override
  void initState() {
    super.initState();
    _selectedManagers = widget.initialManagers ?? [];
    _selectedStatuses = widget.initialStatuses;
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _noticeFromDate = widget.initialNoticeFromDate;
    _noticeToDate = widget.initialNoticeToDate;
  }

  Future<void> _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (pickedRange != null) {
      setState(() {
        _fromDate = pickedRange.start;
        _toDate = pickedRange.end;
      });
    }
  }

  Future<void> _selectNoticeDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _noticeFromDate != null && _noticeToDate != null
          ? DateTimeRange(start: _noticeFromDate!, end: _noticeToDate!)
          : null,
    );
    if (pickedRange != null) {
      setState(() {
        _noticeFromDate = pickedRange.start;
        _noticeToDate = pickedRange.end;
      });
    }
  }

  Widget _buildFilterCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.appColors.surfacePrimary,
      shadowColor: context.appColors.shadowColor,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(8),
        child: child,
      ),
    );
  }

  Widget _buildDateRangeCard({
    required VoidCallback onTap,
    required String placeholder,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) {
    final hasRange = fromDate != null && toDate != null;
    final rangeLabel = hasRange
        ? (() {
            final start = fromDate;
            final end = toDate;
            return "${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year} - ${end.day.toString().padLeft(2, '0')}.${end.month.toString().padLeft(2, '0')}.${end.year}";
          })()
        : placeholder;

    return _buildFilterCard(
      padding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.appColors.surfacePrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                rangeLabel,
                style: context.appTextStyles.bodyMd.copyWith(
                  color: hasRange
                      ? context.appColors.textPrimary
                      : context.appColors.textSecondary,
                ),
              ),
              Icon(
                Icons.calendar_today,
                color: context.appColors.iconSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _buildActionButtonStyle() {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      backgroundColor:
          context.appColors.buttonSecondaryBg.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide(color: context.appColors.buttonPrimaryBg, width: 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.appColors.backgroundSecondary,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          localizations.translate('filter'),
          style: context.appTextStyles.titleLg.copyWith(
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
        backgroundColor: context.appColors.surfacePrimary,
        forceMaterialTransparency: true,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                widget.onResetFilters?.call();
                _selectedManagers.clear();
                _selectedStatuses = null;
                _fromDate = null;
                _toDate = null;
                _noticeFromDate = null;
                _noticeToDate = null;
              });
            },
            style: _buildActionButtonStyle(),
            child: Text(
              localizations.translate('reset'),
              style: context.appTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appColors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () {
              final isAnyFilterSelected = _selectedManagers.isNotEmpty ||
                  _selectedStatuses != null ||
                  _fromDate != null ||
                  _toDate != null ||
                  _noticeFromDate != null ||
                  _noticeToDate != null;

              if (isAnyFilterSelected) {
                widget.onManagersSelected?.call({
                  'managers': _selectedManagers,
                  'statuses': _selectedStatuses,
                  'fromDate': _fromDate,
                  'toDate': _toDate,
                  'noticefromDate': _noticeFromDate,
                  'noticetoDate': _noticeToDate,
                });
              }
              Navigator.pop(context);
            },
            style: _buildActionButtonStyle(),
            child: Text(
              localizations.translate('apply'),
              style: context.appTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appColors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
        child: Column(
          children: [
            _buildDateRangeCard(
              onTap: _selectDateRange,
              placeholder: localizations.translate('enter_date_range_create'),
              fromDate: _fromDate,
              toDate: _toDate,
            ),
            const SizedBox(height: 16),
            _buildDateRangeCard(
              onTap: _selectNoticeDateRange,
              placeholder: localizations.translate('enter_date_range_notice'),
              fromDate: _noticeFromDate,
              toDate: _noticeToDate,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildFilterCard(
                      child: EventManagerMultiSelectWidget(
                        selectedManagers: _selectedManagers
                            .map((manager) => manager.id.toString())
                            .toList(),
                        onSelectManagers:
                            (List<ManagerData> selectedUsersData) {
                          setState(() {
                            _selectedManagers = selectedUsersData;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFilterCard(
                      child: EventStatusRadioGroupWidget(
                        key: ValueKey(_selectedStatuses),
                        selectedStatus: _selectedStatuses?.toString(),
                        onSelectStatus: (int selectedStatusId) {
                          setState(() {
                            _selectedStatuses = selectedStatusId;
                          });
                        },
                      ),
                    ),
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
