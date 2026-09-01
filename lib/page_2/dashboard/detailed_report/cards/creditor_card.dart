import 'package:crm_task_manager/models/page_2/dashboard/creditors_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';

import '../widgets/report_client_contact.dart';

class CreditorCard extends StatelessWidget {
  final Creditor creditor;

  const CreditorCard({
    Key? key,
    required this.creditor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.borderSubtle,
          width: 1,
        ),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportClientNameText(
            name: creditor.name,
            onTap: () => openReportClientCard(
              context,
              clientId: creditor.id,
              clientName: creditor.name,
              phone: creditor.phone,
            ),
          ),
          if ((creditor.phone ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            ReportClientPhoneText(phone: creditor.phone!),
          ],
          const SizedBox(height: 8),
          Text(
            '${localizations.translate('debt_amount')}: ${parseNumberToString(creditor.debtAmount)}',
            style: textStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
