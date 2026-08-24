import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/employee_model.dart';
import 'package:crm_task_manager/page_2/warehouse/employee/employee_deletion.dart';
import 'package:crm_task_manager/page_2/warehouse/employee/employee_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class EmployeeCard extends StatelessWidget {
  final EmployeeModel employee;
  final bool hasUpdatePermission;
  final bool hasDeletePermission;
  final VoidCallback? onUpdate;

  const EmployeeCard({
    super.key,
    required this.employee,
    this.hasUpdatePermission = true,
    this.hasDeletePermission = true,
    this.onUpdate,
  });

  Future<void> _openDetails(BuildContext context) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDetailsScreen(
          employee: employee,
          hasUpdatePermission: hasUpdatePermission,
          hasDeletePermission: hasDeletePermission,
        ),
      ),
    );
    if (changed == true) {
      onUpdate?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    employee.fullName.isNotEmpty ? employee.fullName : 'N/A',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasDeletePermission)
                  IconButton(
                    tooltip: localization.translate('delete'),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: colors.buttonDangerBg,
                      size: 24,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => EmployeeDeleteDialog(
                          employeeId: employee.id,
                        ),
                      ).then((_) => onUpdate?.call());
                    },
                  ),
              ],
            ),
            if (employee.phone != null && employee.phone!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${localization.translate('phone')}: ${employee.phone}',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w400,
                  color: colors.textSecondary,
                ),
              ),
            ],
            if (employee.position != null && employee.position!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${localization.translate('position')}: ${employee.position}',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w400,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
