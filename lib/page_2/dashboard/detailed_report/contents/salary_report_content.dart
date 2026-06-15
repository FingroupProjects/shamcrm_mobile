import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/salary_report/sales_dashboard_salary_report_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/dashboard/salary_report_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalaryReportContent extends StatefulWidget {
  final int? selectedYear;
  final ValueChanged<int> onYearChanged;

  const SalaryReportContent({
    super.key,
    required this.selectedYear,
    required this.onYearChanged,
  });

  @override
  State<SalaryReportContent> createState() => _SalaryReportContentState();
}

class _SalaryReportContentState extends State<SalaryReportContent>
    with TickerProviderStateMixin {
  final Set<int> _expandedEmployeeIds = <int>{};

  int get _displayYear => widget.selectedYear ?? DateTime.now().year;

  String _monthKey(int month) {
    const monthKeys = <String>[
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];

    return monthKeys[month - 1];
  }

  String _monthLabel(AppLocalizations localizations, String monthValue) {
    final parts = monthValue.split('-');
    if (parts.length < 2) {
      return monthValue;
    }

    final monthNumber = int.tryParse(parts[1]);
    if (monthNumber == null || monthNumber < 1 || monthNumber > 12) {
      return monthValue;
    }

    return localizations.translate(_monthKey(monthNumber));
  }

  SalaryMonthReport? _currentMonthReport(SalaryEmployeeReport employee) {
    final currentMonth = DateTime.now().month;
    final expectedMonth =
        '${_displayYear.toString()}-${currentMonth.toString().padLeft(2, '0')}';

    for (final month in employee.months) {
      if (month.month == expectedMonth) {
        return month;
      }
    }

    return employee.months.isNotEmpty ? employee.months.first : null;
  }

  Future<void> _showYearPickerDialog() async {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final initialYear = _displayYear;
    int startYear = initialYear - (initialYear % 10);

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.16),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final years = List<int>.generate(10, (index) => startYear + index);

            return Dialog(
              backgroundColor: colors.surfacePrimary,
              surfaceTintColor: colors.surfacePrimary,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surfacePrimary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: context.appShadows.floating,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _YearPickerNavButton(
                          icon: Icons.chevron_left,
                          onTap: () {
                            setDialogState(() {
                              startYear -= 10;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            '$startYear - ${startYear + 9}',
                            textAlign: TextAlign.center,
                            style: textStyles.titleLg.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        _YearPickerNavButton(
                          icon: Icons.chevron_right,
                          onTap: () {
                            setDialogState(() {
                              startYear += 10;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        localizations.translate('select_year'),
                        style: textStyles.bodySm.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      itemCount: years.length,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.6,
                      ),
                      itemBuilder: (context, index) {
                        final year = years[index];
                        final isSelected = year == _displayYear;

                        return GestureDetector(
                          onTap: () {
                            widget.onYearChanged(year);
                            Navigator.of(dialogContext).pop();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.buttonPrimaryBg
                                  : colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? colors.buttonPrimaryBg
                                    : colors.borderSubtle,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              year.toString(),
                              style: textStyles.bodyMd.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? colors.buttonPrimaryFg
                                    : colors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(AppLocalizations localizations) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfacePrimary.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('salary_debt'),
                    style: textStyles.titleMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  // const SizedBox(height: 6),
                  // Text(
                  //   localizations.translate('salary_debt_report_hint'),
                  //   style: const TextStyle(
                  //     fontFamily: 'Gilroy',
                  //     fontSize: 13,
                  //     fontWeight: FontWeight.w500,
                  //     color: Color(0xff64748B),
                  //   ),
                  // ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: _showYearPickerDialog,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: colors.textPrimary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _displayYear.toString(),
                      style: textStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.textSecondary,
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

  Widget _buildLoadingState(AppLocalizations localizations) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colors.textPrimary),
          const SizedBox(height: 16),
          Text(
            localizations.translate('loading_data'),
            style: textStyles.bodyMd.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations localizations, String message) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surfacePrimary.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.error.withValues(alpha: 0.34)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 44,
                color: colors.error,
              ),
              const SizedBox(height: 14),
              Text(
                localizations.translate('error_loading_dialog'),
                style: textStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textStyles.bodySm.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<SalesDashboardSalaryReportBloc>().add(
                        LoadSalaryReport(
                          filter: {'year': _displayYear.toString()},
                        ),
                      );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.buttonPrimaryBg,
                  foregroundColor: colors.buttonPrimaryFg,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  localizations.translate('retry'),
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: colors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('no_salary_debts'),
              style: textStyles.titleMd.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('salary_debt_empty_hint'),
              textAlign: TextAlign.center,
              style: textStyles.bodySm.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthMetric(
    AppLocalizations localizations, {
    required String label,
    required double value,
    required Color color,
  }) {
    final themeColors = context.appColors;
    final textStyles = context.appTextStyles;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: themeColors.surfaceElevated.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.26),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textStyles.bodySm.copyWith(
                fontWeight: FontWeight.w500,
                color: themeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              parseNumberToString(value, nullValue: '0'),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedMonthRow(
    AppLocalizations localizations,
    SalaryMonthReport month,
  ) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final isDebt = month.remaining > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDebt
              ? colors.error.withValues(alpha: 0.24)
              : colors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDebt
                      ? colors.error.withValues(alpha: 0.12)
                      : colors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _monthLabel(localizations, month.month),
                  style: textStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDebt ? colors.error : colors.success,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                month.month,
                style: textStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMonthMetric(
                localizations,
                label: localizations.translate('accrued'),
                value: month.accrued,
                color: colors.textPrimary,
              ),
              const SizedBox(width: 10),
              _buildMonthMetric(
                localizations,
                label: localizations.translate('paid'),
                value: month.paid,
                color: colors.success,
              ),
              const SizedBox(width: 10),
              _buildMonthMetric(
                localizations,
                label: localizations.translate('remaining'),
                value: month.remaining,
                color:
                    month.remaining > 0 ? colors.error : colors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(
    AppLocalizations localizations,
    SalaryEmployeeReport employee,
  ) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final isExpanded = _expandedEmployeeIds.contains(employee.employeeId);
    final currentMonth = _currentMonthReport(employee);
    final currentRemaining = currentMonth?.remaining ?? 0;
    final previewMonth = currentMonth != null
        ? _monthLabel(localizations, currentMonth.month)
        : localizations.translate('current_month');

    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedEmployeeIds.remove(employee.employeeId);
            } else {
              _expandedEmployeeIds.add(employee.employeeId);
            }
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfacePrimary.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isExpanded ? colors.borderPrimary : colors.borderSubtle,
            ),
            boxShadow: context.appShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surfaceElevated,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      employee.employeeName.isNotEmpty
                          ? employee.employeeName.trim()[0].toUpperCase()
                          : '?',
                      style: textStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.employeeName,
                          style: textStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${localizations.translate('current_month')}: $previewMonth',
                          style: textStyles.bodySm.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: currentRemaining > 0
                          ? colors.error.withValues(alpha: 0.12)
                          : colors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: currentRemaining > 0
                            ? colors.error.withValues(alpha: 0.2)
                            : colors.success.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          localizations.translate('remaining'),
                          style: textStyles.caption.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          parseNumberToString(currentRemaining, nullValue: '0'),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: currentRemaining > 0
                                ? colors.error
                                : colors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isExpanded
                          ? localizations.translate('hide_months')
                          : localizations.translate('show_all_months'),
                      style: textStyles.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 14),
                ...employee.months.map(
                  (month) => _buildExpandedMonthRow(localizations, month),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedState(
    AppLocalizations localizations,
    SalaryReportResponse data,
  ) {
    if (data.result.isEmpty) {
      return _buildEmptyState(localizations);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: data.result
          .map((employee) => _buildEmployeeCard(localizations, employee))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      children: [
        _buildHeader(localizations),
        Expanded(
          child: BlocBuilder<SalesDashboardSalaryReportBloc,
              SalesDashboardSalaryReportState>(
            builder: (context, state) {
              if (state is SalesDashboardSalaryReportLoading) {
                return _buildLoadingState(localizations);
              }
              if (state is SalesDashboardSalaryReportError) {
                return _buildErrorState(localizations, state.message);
              }
              if (state is SalesDashboardSalaryReportLoaded) {
                return _buildLoadedState(localizations, state.result);
              }

              return _buildEmptyState(localizations);
            },
          ),
        ),
      ],
    );
  }
}

class _YearPickerNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _YearPickerNavButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Icon(
          icon,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}
