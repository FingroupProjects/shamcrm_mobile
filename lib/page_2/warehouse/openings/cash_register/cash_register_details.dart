import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../custom_widget/animation.dart';
import '../../../../models/page_2/openings/cash_register_openings_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../bloc/page_2_BLOC/openings/cash_register/cash_register_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/cash_register/cash_register_openings_event.dart';
import '../opening_delete_dialog.dart';
import 'edit_cash_register_opening_screen.dart';

class CashRegisterOpeningDetailsScreen extends StatefulWidget {
  final CashRegisterOpening opening;
  final VoidCallback? onOpeningUpdated;

  const CashRegisterOpeningDetailsScreen({
    required this.opening,
    this.onOpeningUpdated,
    super.key,
  });

  @override
  _CashRegisterOpeningDetailsScreenState createState() =>
      _CashRegisterOpeningDetailsScreenState();
}

class _CashRegisterOpeningDetailsScreenState
    extends State<CashRegisterOpeningDetailsScreen> {
  late CashRegisterOpening currentOpening;
  List<Map<String, dynamic>> details = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    currentOpening = widget.opening;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDetails();
  }

  void _updateDetails() {
    final localizations = AppLocalizations.of(context)!;
    
    final cashRegisterName = currentOpening.cashRegister?.name;
    final displayName = (cashRegisterName == null || cashRegisterName.isEmpty) ? 'N/A' : cashRegisterName;
    
    details = [
      {
        'label': '${localizations.translate('name') ?? 'Название'}:',
        'value': displayName,
      },
      {
        'label': '${localizations.translate('balance') ?? 'Баланс'}:',
        'value': _formatAmount(currentOpening.sum ?? '0'),
      },
    ];
  }

  String _formatAmount(String amount) {
    double amountValue = double.tryParse(amount.replaceAll(' ', '')) ?? 0.0;
    return NumberFormat('#,##0.00', 'ru_RU').format(amountValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: const Duration(milliseconds: 1000),
              ),
            )
          : Padding(
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
    
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: Transform.translate(
          offset: const Offset(0, -2),
          child: IconButton(
            icon: Image.asset(
              'assets/icons/arrow-left.png',
              width: 24,
              height: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: Transform.translate(
        offset: const Offset(-10, 0),
        child: Text(
          localizations.translate('cash_register_opening_details') ?? 'Остаток кассы',
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Image.asset(
                'assets/icons/edit.png',
                width: 24,
                height: 24,
              ),
              onPressed: () async {
                if (_isLoading) return;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditCashRegisterOpeningScreen(
                      cashRegisterOpening: currentOpening,
                    ),
                  ),
                );
                if (result == true) {
                  Navigator.pop(context, true);
                  if (widget.onOpeningUpdated != null) {
                    widget.onOpeningUpdated!();
                  }
                }
              },
            ),
            IconButton(
              padding: const EdgeInsets.only(right: 8),
              constraints: const BoxConstraints(),
              icon: Image.asset(
                'assets/icons/delete.png',
                width: 24,
                height: 24,
              ),
              onPressed: () {
                if (_isLoading) return;
                final bloc = context.read<CashRegisterOpeningsBloc>();
                showDialog(
                  context: context,
                  builder: (dialogContext) => OpeningDeleteDialog(
                    openingId: currentOpening.id ?? 0,
                    openingType: OpeningType.cashRegister,
                    onConfirmDelete: () {
                      bloc.add(DeleteCashRegisterOpening(id: currentOpening.id ?? 0));
                      Navigator.pop(context, true);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ],
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
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: Color(0xff99A4BA),
      ),
    );
  }

  Widget _buildValue(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xff1E2E52),
      ),
      overflow: TextOverflow.visible,
    );
  }
}

