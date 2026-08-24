import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/employee_model.dart';
import 'package:crm_task_manager/page_2/warehouse/employee/edit_employee_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/employee/employee_deletion.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class EmployeeDetailsScreen extends StatelessWidget {
  final EmployeeModel employee;
  final bool hasUpdatePermission;
  final bool hasDeletePermission;

  const EmployeeDetailsScreen({
    super.key,
    required this.employee,
    this.hasUpdatePermission = true,
    this.hasDeletePermission = true,
  });

  Future<void> _openEdit(BuildContext context) async {
    final wasUpdated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditEmployeeScreen(employee: employee),
      ),
    );
    if (wasUpdated == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    final rows = <({String label, String value})>[
      (label: l10n.translate('full_name'), value: employee.fullName),
      (label: l10n.translate('phone'), value: employee.phone ?? ''),
      (label: l10n.translate('birth_date'), value: employee.displayBirthDate),
      (label: l10n.translate('position'), value: employee.position ?? ''),
      (
        label: l10n.translate('employee_address'),
        value: employee.address ?? '',
      ),
      (label: l10n.translate('salary'), value: employee.displaySalary),
    ];

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: colors.surfacePrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.iconPrimary, size: 24),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          l10n.translate('employee_details'),
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          if (hasUpdatePermission)
            IconButton(
              tooltip: l10n.translate('edit'),
              icon: Icon(Icons.edit_outlined, color: colors.iconPrimary),
              onPressed: () => _openEdit(context),
            ),
          if (hasDeletePermission)
            IconButton(
              tooltip: l10n.translate('delete'),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: colors.buttonDangerBg,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => EmployeeDeleteDialog(
                    employeeId: employee.id,
                  ),
                ).then((deleted) {
                  if (deleted == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                });
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  _DetailRow(
                    label: rows[i].label,
                    value: rows[i].value.isEmpty ? '—' : rows[i].value,
                  ),
                  if (i != rows.length - 1)
                    Divider(height: 24, color: colors.borderSubtle),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
