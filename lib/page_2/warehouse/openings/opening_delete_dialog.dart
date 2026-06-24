import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

enum OpeningType {
  cashRegister,
  client,
  supplier,
  goods,
}

class OpeningDeleteDialog extends StatelessWidget {
  final int openingId;
  final OpeningType openingType;
  final VoidCallback onConfirmDelete;

  const OpeningDeleteDialog({
    super.key,
    required this.openingId,
    required this.openingType,
    required this.onConfirmDelete,
  });

  String _getTitle(AppLocalizations localizations) {
    switch (openingType) {
      case OpeningType.cashRegister:
        return localizations.translate('delete_cash_register_opening') ??
            'Удалить остаток кассы';
      case OpeningType.client:
        return localizations.translate('delete_client_opening') ??
            'Удалить остаток клиента';
      case OpeningType.supplier:
        return localizations.translate('delete_supplier_opening') ??
            'Удалить остаток поставщика';
      case OpeningType.goods:
        return localizations.translate('delete_goods_opening') ??
            'Удалить остаток товара';
    }
  }

  String _getConfirmationMessage(AppLocalizations localizations) {
    switch (openingType) {
      case OpeningType.cashRegister:
        return localizations
                .translate('delete_cash_register_opening_confirm') ??
            'Вы уверены, что хотите удалить этот первоначальный остаток кассы?';
      case OpeningType.client:
        return localizations.translate('delete_client_opening_confirm') ??
            'Вы уверены, что хотите удалить этот первоначальный остаток клиента?';
      case OpeningType.supplier:
        return localizations.translate('delete_supplier_opening_confirm') ??
            'Вы уверены, что хотите удалить этот первоначальный остаток поставщика?';
      case OpeningType.goods:
        return localizations.translate('delete_goods_opening_confirm') ??
            'Вы уверены, что хотите удалить этот первоначальный остаток товара?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return AlertDialog(
      backgroundColor: colors.surfacePrimary,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.borderSubtle),
      ),
      title: Center(
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.buttonDangerBg.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: colors.buttonDangerBg,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getTitle(localizations),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      content: Text(
        _getConfirmationMessage(localizations),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: colors.textSecondary,
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                buttonText: localizations.translate('close') ?? 'Отмена',
                onPressed: () {
                  Navigator.of(context).pop();
                },
                buttonColor: colors.buttonSecondaryBg,
                textColor: colors.buttonSecondaryFg,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomButton(
                buttonText: localizations.translate('delete') ?? 'Удалить',
                onPressed: () {
                  onConfirmDelete();
                  Navigator.of(context).pop();
                },
                buttonColor: colors.buttonDangerBg,
                textColor: colors.buttonDangerFg,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
