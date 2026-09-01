import 'package:crm_task_manager/app/app_keys.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void openReportClientCard(
  BuildContext context, {
  required int clientId,
  required String clientName,
  String? phone,
}) {
  if (clientId <= 0) return;
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => LeadDetailsScreen(
        leadId: clientId.toString(),
        leadName: clientName,
        leadStatus: '',
        statusId: 0,
        phone: phone,
      ),
    ),
  );
}

Future<void> openReportClientPhone(String phone) async {
  final normalized = phone.replaceAll(RegExp(r'\s+'), '');
  if (normalized.isEmpty) return;
  final uri = Uri(scheme: 'tel', path: normalized);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class ReportClientNameText extends StatelessWidget {
  const ReportClientNameText({
    super.key,
    required this.name,
    required this.onTap,
  });

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return GestureDetector(
      onTap: onTap,
      child: Text(
        '${localizations.translate('client')} $name',
        style: textStyles.bodyMd.copyWith(
          fontWeight: FontWeight.w400,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}

class ReportClientPhoneText extends StatelessWidget {
  const ReportClientPhoneText({
    super.key,
    required this.phone,
  });

  final String phone;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final trimmed = phone.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${localizations.translate('phone')}: ',
          style: textStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w400,
            color: colors.textPrimary,
          ),
        ),
        Expanded(
          child: SelectableText(
            trimmed,
            onTap: () => openReportClientPhone(trimmed),
            style: textStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w400,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
