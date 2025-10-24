import 'package:crm_task_manager/bloc/page_2_BLOC/openings/cash_register/cash_register_openings_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/openings/cash_register/cash_register_openings_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/openings/cash_register/cash_register_openings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import '../../../../models/page_2/openings/cash_register_openings_model.dart';
import '../../../../models/cash_register_list_model.dart';
import '../../../../bloc/cash_register_list/cash_register_list_bloc.dart';
import '../../../../bloc/cash_register_list/cash_register_list_event.dart';
import '../../../../bloc/cash_register_list/cash_register_list_state.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../custom_widget/custom_textfield.dart';
import '../../../../custom_widget/price_input_formatter.dart';
import '../../../../utils/global_fun.dart';

class EditCashRegisterOpeningScreen extends StatefulWidget {
  final CashRegisterOpening cashRegisterOpening;

  const EditCashRegisterOpeningScreen({Key? key, required this.cashRegisterOpening})
      : super(key: key);

  @override
  _EditCashRegisterOpeningScreenState createState() =>
      _EditCashRegisterOpeningScreenState();
}

class _EditCashRegisterOpeningScreenState
    extends State<EditCashRegisterOpeningScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controller for balance field
  late TextEditingController balanceController;
  
  // Cash register selection
  String? _selectedCashRegisterId;
  CashRegisterData? _selectedCashRegisterData;

  @override
  void initState() {
    super.initState();
    
    // Initialize controller with existing value
    balanceController = TextEditingController(
      text: parseNumberToString(widget.cashRegisterOpening.sum, nullValue: '0'),
    );
    
    // Initialize selected cash register
    _selectedCashRegisterId = widget.cashRegisterOpening.cashRegisterId?.toString();
    
    // Load cash registers
    context.read<GetAllCashRegisterBloc>().add(GetAllCashRegisterEv());
  }

  @override
  void dispose() {
    balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CashRegisterOpeningsBloc, CashRegisterOpeningsState>(
      listener: (context, state) {
        if (state is CashRegisterOpeningUpdateSuccess) {
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
        } else if (state is CashRegisterOpeningUpdateError) {
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
          AppLocalizations.of(context)!.translate('edit_cash_register_opening'),
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
                      _buildCashRegisterDropdown(),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: balanceController,
                        label: AppLocalizations.of(context)!.translate('balance'),
                        hintText: AppLocalizations.of(context)!.translate('enter_balance'),
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
            BlocBuilder<CashRegisterOpeningsBloc, CashRegisterOpeningsState>(
              builder: (context, state) {
                final isUpdating = state is CashRegisterOpeningUpdating;
                
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
                              context.read<CashRegisterOpeningsBloc>().add(
                                UpdateCashRegisterOpening(
                                  id: widget.cashRegisterOpening.id!,
                                  cashRegisterId: int.parse(_selectedCashRegisterId!),
                                  sum: balanceController.text,
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

  Widget _buildCashRegisterDropdown() {
    return BlocListener<GetAllCashRegisterBloc, GetAllCashRegisterState>(
      listener: (context, state) {
        if (state is GetAllCashRegisterError) {
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
      child: BlocBuilder<GetAllCashRegisterBloc, GetAllCashRegisterState>(
        builder: (context, state) {
          final isLoading = state is GetAllCashRegisterLoading;
          
          // Update selected cash register data when loaded
          if (state is GetAllCashRegisterSuccess) {
            List<CashRegisterData> cashRegisterList = state.dataCashRegisters.result ?? [];

            if (_selectedCashRegisterId != null && cashRegisterList.isNotEmpty) {
              try {
                _selectedCashRegisterData = cashRegisterList.firstWhere(
                  (cashRegister) => cashRegister.id.toString() == _selectedCashRegisterId,
                );
              } catch (e) {
                _selectedCashRegisterData = null;
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('cash_register'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                child: CustomDropdown<CashRegisterData>.search(
                  closeDropDownOnClearFilterSearch: true,
                  items: state is GetAllCashRegisterSuccess 
                      ? (state.dataCashRegisters.result ?? []) 
                      : [],
                  searchHintText: AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
                  enabled: !isLoading,
                  decoration: CustomDropdownDecoration(
                    closedFillColor: const Color(0xffF4F7FD),
                    expandedFillColor: Colors.white,
                    closedBorder: Border.all(
                      color: const Color(0xffF4F7FD),
                      width: 1,
                    ),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(
                      color: const Color(0xffF4F7FD),
                      width: 1,
                    ),
                    expandedBorderRadius: BorderRadius.circular(12),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Text(
                      item.name,
                      style: const TextStyle(
                        color: Color(0xff1E2E52),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    if (isLoading) {
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                          ),
                        ),
                      );
                    }
                    
                    return Text(
                      selectedItem.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) {
                    if (isLoading) {
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                          ),
                        ),
                      );
                    }
                    
                    return Text(
                      AppLocalizations.of(context)!.translate('select_cash_register'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    );
                  },
                  noResultFoundBuilder: (context, text) {
                    if (isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                          ),
                        ),
                      );
                    }
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          AppLocalizations.of(context)!.translate('no_results'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ),
                    );
                  },
                  excludeSelected: false,
                  initialItem: (state is GetAllCashRegisterSuccess &&
                          (state.dataCashRegisters.result ?? []).contains(_selectedCashRegisterData))
                      ? _selectedCashRegisterData
                      : null,
                  validator: (value) {
                    if (value == null) {
                      return AppLocalizations.of(context)!.translate('field_required');
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCashRegisterId = value.id.toString();
                        _selectedCashRegisterData = value;
                      });
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

