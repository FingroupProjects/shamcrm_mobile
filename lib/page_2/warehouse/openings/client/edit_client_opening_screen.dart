import 'package:flutter/material.dart';
import '../../../../models/page_2/openings/client_openings_model.dart';
import '../../../../models/lead_list_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../screens/deal/tabBar/lead_list.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../custom_widget/custom_textfield.dart';
import '../../../../custom_widget/price_input_formatter.dart';

class EditClientOpeningScreen extends StatefulWidget {
  final ClientOpening clientOpening;

  const EditClientOpeningScreen({Key? key, required this.clientOpening})
      : super(key: key);

  @override
  _EditClientOpeningScreenState createState() =>
      _EditClientOpeningScreenState();
}

class _EditClientOpeningScreenState extends State<EditClientOpeningScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controllers for debt fields
  late TextEditingController ourDebtController;
  late TextEditingController theirDebtController;
  
  // Client selection
  LeadData? _selectedLead;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing values
    ourDebtController = TextEditingController(
      text: widget.clientOpening.ourDuty ?? '0',
    );
    theirDebtController = TextEditingController(
      text: widget.clientOpening.debtToUs ?? '0',
    );
    
    // Initialize selected client
    if (widget.clientOpening.counterpartyId != null) {
      _selectedLead = LeadData(
        id: widget.clientOpening.counterpartyId!,
        name: widget.clientOpening.counterparty?.name ?? '',
      );
    }
  }

  @override
  void dispose() {
    ourDebtController.dispose();
    theirDebtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.translate('edit_client_opening') ??
              'Редактировать остаток клиента',
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LeadRadioGroupWidget(
                        selectedLead: _selectedLead?.id.toString(),
                        onSelectLead: (lead) => setState(() => _selectedLead = lead),
                        showDebt: true,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: ourDebtController,
                        label: AppLocalizations.of(context)!.translate('our_debt'),
                        hintText: AppLocalizations.of(context)!.translate('enter_debt'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          PriceInputFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.translate('field_required');
                          }
                          if (double.tryParse(value) == null) {
                            return AppLocalizations.of(context)!.translate('enter_correct_number');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: theirDebtController,
                        label: AppLocalizations.of(context)!.translate('their_debt'),
                        hintText: AppLocalizations.of(context)!.translate('enter_debt'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          PriceInputFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.translate('field_required');
                          }
                          if (double.tryParse(value) == null) {
                            return AppLocalizations.of(context)!.translate('enter_correct_number');
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      buttonText:
                          AppLocalizations.of(context)!.translate('close') ??
                              'Отмена',
                      buttonColor: const Color(0xffF4F7FD),
                      textColor: Colors.black,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      buttonText:
                          AppLocalizations.of(context)!.translate('save') ??
                              'Сохранить',
                      buttonColor: const Color(0xff4759FF),
                      textColor: Colors.white,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // TODO: Implement save logic
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

