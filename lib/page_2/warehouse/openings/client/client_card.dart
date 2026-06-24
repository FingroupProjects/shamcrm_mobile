import 'package:flutter/material.dart';

import '../../../../core/theme/helpers/theme_context_extension.dart';
import '../../../../models/page_2/openings/client_openings_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../utils/global_fun.dart';

class ClientCard extends StatelessWidget {
  final ClientOpening client;
  final Function(ClientOpening) onClick;
  final Function(ClientOpening) onLongPress;
  final Function(ClientOpening)? onDelete;
  final bool isSelectionMode;
  final bool isSelected;

  const ClientCard({
    Key? key,
    required this.client,
    required this.onClick,
    required this.onLongPress,
    this.onDelete,
    this.isSelectionMode = false,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return GestureDetector(
      onTap: () => onClick(client),
      onLongPress: () => onLongPress(client),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colors.fieldBg : colors.surfacePrimary,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${localizations.translate('title_with_two_dots')}${client.counterparty?.name ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Наш долг: ${parseNumberToString(client.ourDuty ?? '0')}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Долг клиента: ${parseNumberToString(client.debtToUs ?? '0')}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            if (onDelete != null)
              GestureDetector(
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 24,
                  color: colors.buttonDangerBg,
                ),
                onTap: () => onDelete!(client),
              ),
            if (isSelectionMode) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: colors.buttonPrimaryBg,
                  size: 24,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
