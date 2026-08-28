import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/page_2/dashboard/act_of_reconciliation_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../utils/global_fun.dart';

class ReconciliationActDetailsScreen extends StatefulWidget {
  final ReconciliationItem reconciliationItem;

  const ReconciliationActDetailsScreen({
    required this.reconciliationItem,
    super.key,
  });

  @override
  _ReconciliationActDetailsScreenState createState() =>
      _ReconciliationActDetailsScreenState();
}

class _ReconciliationActDetailsScreenState
    extends State<ReconciliationActDetailsScreen> {
  late ReconciliationItem currentItem;
  List<Map<String, dynamic>> details = [];

  @override
  void initState() {
    super.initState();
    currentItem = widget.reconciliationItem;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDetails();
  }

  String _formatDate(DateTime? date, AppLocalizations localizations) {
    if (date == null) return localizations.translate('not_updated');
    return DateFormat('dd.MM.yyyy HH:mm', 'ru_RU').format(date);
  }

  String _getMovementTypeText(String? movementType, AppLocalizations localizations) {
    switch (movementType?.toLowerCase()) {
      case 'income':
        return localizations.translate('income');
      case 'outcome':
        return localizations.translate('outcome');
      default:
        return movementType ?? localizations.translate('not_specified');
    }
  }

  String _getCounterpartyTypeText(String? type, AppLocalizations localizations) {
    switch (type?.toLowerCase()) {
      case 'lead':
        return localizations.translate('client');
      case 'supplier':
        return localizations.translate('supplier');
      default:
        return type ?? localizations.translate('not_specified');
    }
  }

  String _getModelTypeText(String? type, AppLocalizations localizations) {
    // Можно добавить разные типы моделей
    return type ?? localizations.translate('not_specified');
  }

  void _updateDetails() {
    final localizations = AppLocalizations.of(context)!;

    details = [

      {
        'label': '${localizations.translate('document_type')}:',
        'value': _getMovementTypeText(currentItem.movementType, localizations),
      },
      if (currentItem.counterparty != null) ...[
        {
          'label': '${localizations.translate('counterparty')}:',
          'value': currentItem.counterparty!.name ?? localizations.translate('not_specified'),
        },
        if (currentItem.counterparty!.phone != null) {
          'label': '${localizations.translate('phone')}:',
          'value': currentItem.counterparty!.phone!,
        },
        if (currentItem.counterparty!.email != null) {
          'label': '${localizations.translate('email')}:',
          'value': currentItem.counterparty!.email!,
        },
      ],
      {
        'label': '${localizations.translate('sum')}:',
        'value': parseNumberToString(currentItem.sum, nullValue: '0'),
      },
      if (currentItem.saleSum != null) {
        'label': '${localizations.translate('sale_sum')}:',
        'value': parseNumberToString(currentItem.saleSum, nullValue: '0'),
      },
      // if (currentItem.model != null) ...[
      //   {
      //     'label': '${localizations.translate('our_duty')}:',
      //     'value': parseNumberToString(currentItem.model!.ourDuty, nullValue: '0'),
      //   },
      //   {
      //     'label': '${localizations.translate('debt_to_us')}:',
      //     'value': parseNumberToString(currentItem.model!.debtToUs, nullValue: '0'),
      //   },
      // ],
      {
        'label': '${localizations.translate('created_at')}:',
        'value': _formatDate(currentItem.createdAt, localizations),
      },
      {
        'label': '${localizations.translate('updated_at')}:',
        'value': _formatDate(currentItem.updatedAt, localizations),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: context.appColors.backgroundPrimary,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ListView(
          children: [
            _buildDetailsList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final colors = context.appColors;

    return AppBar(
      backgroundColor: colors.backgroundPrimary,
      forceMaterialTransparency: true,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: Transform.translate(
          offset: const Offset(0, -2),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: colors.iconPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: Transform.translate(
        offset: const Offset(-10, 0),
        child: Text(
          "${localizations.translate('reconciliation_act_details')} №${currentItem.id ?? ''}",
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: details.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildDetailItem(
            details[index]['label']!,
            details[index]['value']!,
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(width: 8),
        Expanded(child: _buildValue(value)),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: context.appColors.textSecondary,
      ),
    );
  }

  Widget _buildValue(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: context.appColors.textPrimary,
      ),
      overflow: TextOverflow.visible,
    );
  }
}

