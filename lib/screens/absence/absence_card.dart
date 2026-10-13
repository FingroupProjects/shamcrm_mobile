import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/absence/absence_models.dart';
import 'package:crm_task_manager/screens/absence/absence_logic.dart';
import 'package:crm_task_manager/screens/absence/absence_widgets.dart';
import 'package:flutter/material.dart';

class AbsenceRequestCard extends StatelessWidget {
  const AbsenceRequestCard({
    super.key,
    required this.request,
    required this.showEmployee,
    required this.showActions,
    required this.busy,
    required this.onOpen,
    required this.onApprove,
    required this.onReject,
  });

  final AbsenceRequest request;
  final bool showEmployee;
  final bool showActions;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final period = formatAbsencePeriod(request.dateFrom, request.dateTo);
    final clock = formatAbsenceClock(request.timeFrom, request.timeTo);
    final when = clock.isEmpty
        ? '$period · ${absenceTr(context, 'absence_all_day')}'
        : '$period · $clock';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: context.appColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpen,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showEmployee && request.userName.isNotEmpty) ...[
                          Text(
                            request.userName,
                            style: absenceStyle(
                              context,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          when,
                          style: absenceStyle(
                            context,
                            weight: FontWeight.w700,
                          ),
                        ),
                        if (request.reason.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            request.reason.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: absenceStyle(
                              context,
                              size: 13,
                              color: context.appColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!showActions) ...[
                    const SizedBox(width: 8),
                    AbsenceStatusBadge(
                      status: request.status,
                      label: absenceStatusText(context, request),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (request.limitWarning != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: AbsenceWarningBanner(message: request.limitWarning!.message),
            ),
          if (showActions)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  Expanded(child: _actionButton(context, approve: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _actionButton(context, approve: false)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, {required bool approve}) {
    final colors = context.appColors;
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: busy ? null : (approve ? onApprove : onReject),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: approve ? colors.buttonPrimaryBg : Colors.transparent,
          foregroundColor: approve ? colors.textInverse : colors.error,
          side: approve ? null : BorderSide(color: colors.error),
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          absenceTr(context, approve ? 'absence_approve' : 'absence_reject'),
          style: absenceStyle(
            context,
            size: 14,
            weight: FontWeight.w600,
            color: approve ? colors.textInverse : colors.error,
          ),
        ),
      ),
    );
  }
}
