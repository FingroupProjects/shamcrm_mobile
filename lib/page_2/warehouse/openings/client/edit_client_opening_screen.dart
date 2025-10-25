import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/client/client_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/client/client_openings_event.dart';
import '../../../../bloc/page_2_BLOC/openings/client/client_openings_state.dart';
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

    debugPrint("Editing Client Opening: ${widget.clientOpening.id}");

    return BlocListener<ClientOpeningsBloc, ClientOpeningsState>(
      listener: (context, state) {
        if (state is ClientOpeningUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('successfully_updated'),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.green,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: const Duration(seconds: 2),
            ),
          );
          // Небольшая задержка перед закрытием экрана, чтобы SnackBar успел отобразиться
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        } else if (state is ClientOpeningUpdateError) {
          // Показываем ошибку обновления
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.red,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Scaffold(
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
            AppLocalizations.of(context)!.translate('edit_client_opening'),
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
              BlocBuilder<ClientOpeningsBloc, ClientOpeningsState>(
                builder: (context, state) {
                  final isUpdating = state is ClientOpeningUpdating;
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            buttonText:
                                AppLocalizations.of(context)!.translate('close'),
                            buttonColor: const Color(0xffF4F7FD),
                            textColor: Colors.black,
                            onPressed: isUpdating ? null : () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            buttonText:
                                AppLocalizations.of(context)!.translate('save'),
                            buttonColor: const Color(0xff4759FF),
                            textColor: Colors.white,
                            isLoading: isUpdating,
                            onPressed: isUpdating ? null : () {
                              if (_formKey.currentState!.validate()) {
                                if (_selectedLead == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context)!.translate('select_client'),
                                        style: const TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Colors.red,
                                      elevation: 3,
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                final ourDuty = double.tryParse(
                                        ourDebtController.text.replaceAll(' ', '')) ??
                                    0.0;
                                final debtToUs = double.tryParse(
                                        theirDebtController.text.replaceAll(' ', '')) ??
                                    0.0;

                                context.read<ClientOpeningsBloc>().add(
                                      UpdateClientOpening(
                                        id: widget.clientOpening.id!,
                                        leadId: _selectedLead!.id,
                                        ourDuty: ourDuty,
                                        debtToUs: debtToUs,
                                      ),
                                    );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
