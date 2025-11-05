import 'package:crm_task_manager/page_2/warehouse/incoming/supplier_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import '../../../../models/page_2/openings/supplier_openings_model.dart';
import '../../../../models/page_2/supplier_model.dart';
import '../../../../bloc/page_2_BLOC/supplier_bloc/supplier_bloc.dart';
import '../../../../bloc/page_2_BLOC/supplier_bloc/supplier_event.dart';
import '../../../../bloc/page_2_BLOC/supplier_bloc/supplier_state.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_event.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_state.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../custom_widget/custom_textfield.dart';
import '../../../../custom_widget/price_input_formatter.dart';
import '../../../../utils/global_fun.dart';

class EditSupplierOpeningScreen extends StatefulWidget {
  final SupplierOpening supplierOpening;

  const EditSupplierOpeningScreen({Key? key, required this.supplierOpening})
      : super(key: key);

  @override
  _EditSupplierOpeningScreenState createState() =>
      _EditSupplierOpeningScreenState();
}

class _EditSupplierOpeningScreenState extends State<EditSupplierOpeningScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for debt fields
  late TextEditingController ourDebtController;
  late TextEditingController theirDebtController;

  // Supplier selection
  String? _selectedSupplierId;
  Supplier? _selectedSupplierData;

  // Флаги для отслеживания состояния полей
  bool isOurDebtEnabled = true;
  bool isTheirDebtEnabled = true;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing values
    ourDebtController = TextEditingController(
      text: parseNumberToString(widget.supplierOpening.ourDuty, nullValue: '0'),
    );
    theirDebtController = TextEditingController(
      text: parseNumberToString(widget.supplierOpening.debtToUs, nullValue: '0'),
    );

    // Initialize selected supplier
    _selectedSupplierId = widget.supplierOpening.counterpartyId?.toString();

    // Load suppliers
    context.read<SupplierBloc>().add(FetchSupplier(query: null));

    // Добавляем слушатели для отслеживания изменений в полях
    ourDebtController.addListener(_onOurDebtChanged);
    theirDebtController.addListener(_onTheirDebtChanged);

    // Устанавливаем начальное состояние на основе текущих значений
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFieldStates();
    });
  }

  void _updateFieldStates() {
    final ourDebtValue = ourDebtController.text.replaceAll(' ', '');
    final theirDebtValue = theirDebtController.text.replaceAll(' ', '');
    
    // Если значение не пустое и не равно 0, то второе поле должно быть отключено
    final ourDebtNotEmpty = ourDebtValue.isNotEmpty && 
                            double.tryParse(ourDebtValue) != null && 
                            double.parse(ourDebtValue) != 0;
    final theirDebtNotEmpty = theirDebtValue.isNotEmpty && 
                              double.tryParse(theirDebtValue) != null && 
                              double.parse(theirDebtValue) != 0;

    setState(() {
      isTheirDebtEnabled = !ourDebtNotEmpty;
      isOurDebtEnabled = !theirDebtNotEmpty;
    });
  }

  void _onOurDebtChanged() {
    final ourDebtValue = ourDebtController.text.replaceAll(' ', '');
    final hasValue = ourDebtValue.isNotEmpty && 
                     double.tryParse(ourDebtValue) != null && 
                     double.parse(ourDebtValue) != 0;
    
    setState(() {
      isTheirDebtEnabled = !hasValue;
    });
  }

  void _onTheirDebtChanged() {
    final theirDebtValue = theirDebtController.text.replaceAll(' ', '');
    final hasValue = theirDebtValue.isNotEmpty && 
                     double.tryParse(theirDebtValue) != null && 
                     double.parse(theirDebtValue) != 0;
    
    setState(() {
      isOurDebtEnabled = !hasValue;
    });
  }

  @override
  void dispose() {
    ourDebtController.dispose();
    theirDebtController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    if (!mounted || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
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
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        elevation: 3,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        duration: Duration(seconds: isSuccess ? 2 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SupplierOpeningsBloc, SupplierOpeningsState>(
      listener: (context, state) {
        if (!mounted || !context.mounted) return;

        if (state is SupplierOpeningUpdateSuccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.mounted) {
              // Just pop - the parent screen will show the success message
              Navigator.pop(context, true); // ✅ Return true to indicate success
            }
          });
        }

        if (state is SupplierOpeningUpdateError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.mounted) {
              _showSnackBar(state.message, isSuccess: false);
            }
          });
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
              AppLocalizations.of(context)!.translate('edit_supplier_opening'),
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
                          SupplierWidget(
                            selectedSupplier: _selectedSupplierId,
                            onChanged: (value) => setState(() => _selectedSupplierId = value),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              if (!isOurDebtEnabled) {
                                _showFieldLockedSnackBar('their_debt');
                              }
                            },
                            child: AbsorbPointer(
                              absorbing: !isOurDebtEnabled,
                              child: CustomTextField(
                                controller: ourDebtController,
                                label: AppLocalizations.of(context)!.translate('our_debt'),
                                hintText: AppLocalizations.of(context)!.translate('enter_debt'),
                                keyboardType: TextInputType.number,
                                enabled: isOurDebtEnabled,
                                inputFormatters: [
                                  PriceInputFormatter(),
                                ],
                                validator: (value) {
                                  // Валидация только если поле активно
                                  if (!isOurDebtEnabled) {
                                    return null;
                                  }
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(context)!.translate('field_required');
                                  }
                                  if (double.tryParse(value) == null) {
                                    return AppLocalizations.of(context)!.translate('enter_correct_number');
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              if (!isTheirDebtEnabled) {
                                _showFieldLockedSnackBar('our_debt');
                              }
                            },
                            child: AbsorbPointer(
                              absorbing: !isTheirDebtEnabled,
                              child: CustomTextField(
                                controller: theirDebtController,
                                label: AppLocalizations.of(context)!.translate('their_debt'),
                                hintText: AppLocalizations.of(context)!.translate('enter_debt'),
                                keyboardType: TextInputType.number,
                                enabled: isTheirDebtEnabled,
                                inputFormatters: [
                                  PriceInputFormatter(),
                                ],
                                validator: (value) {
                                  // Валидация только если поле активно
                                  if (!isTheirDebtEnabled) {
                                    return null;
                                  }
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(context)!.translate('field_required');
                                  }
                                  if (double.tryParse(value) == null) {
                                    return AppLocalizations.of(context)!.translate('enter_correct_number');
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                BlocBuilder<SupplierOpeningsBloc, SupplierOpeningsState>(
                  builder: (context, state) {
                    final isUpdating = state is SupplierOpeningUpdating;

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
                                  if (_selectedSupplierId == null) {
                                    _showSnackBar(
                                      AppLocalizations.of(context)!.translate('select_supplier'),
                                      isSuccess: false,
                                    );
                                    return;
                                  }

                                  final ourDuty = double.tryParse(
                                      ourDebtController.text.replaceAll(' ', '')) ??
                                      0.0;
                                  final debtToUs = double.tryParse(
                                      theirDebtController.text.replaceAll(' ', '')) ??
                                      0.0;

                                  context.read<SupplierOpeningsBloc>().add(
                                    EditSupplierOpening(
                                      id: widget.supplierOpening.id!,
                                      supplierId: int.parse(_selectedSupplierId!),
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

  void _showFieldLockedSnackBar(String fieldKey) {
    final fieldName = AppLocalizations.of(context)!.translate(fieldKey);
    
    // Закрываем текущий SnackBar перед показом нового
    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Сначала очистите поле "$fieldName"',
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
        backgroundColor: Colors.orange,
        elevation: 3,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}