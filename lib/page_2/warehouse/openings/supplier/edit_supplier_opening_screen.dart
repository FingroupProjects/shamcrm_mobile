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
  }

  @override
  void dispose() {
    ourDebtController.dispose();
    theirDebtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SupplierOpeningsBloc, SupplierOpeningsState>(
      listener: (context, state) {
        if (state is SupplierOpeningUpdateSuccess) {
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
          Navigator.pop(context, true);
        } else if (state is SupplierOpeningUpdateError) {
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
                      _buildSupplierDropdown(),
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(context)!
                                          .translate('select_supplier'),
                                      style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.red,
                                    elevation: 3,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
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

  Widget _buildSupplierDropdown() {
    return BlocListener<SupplierBloc, SupplierState>(
      listener: (context, state) {
        if (state is SupplierError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),
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
      child: BlocBuilder<SupplierBloc, SupplierState>(
        builder: (context, state) {
          final isLoading = state is SupplierLoading;
          
          // Update selected supplier data when loaded
          if (state is SupplierLoaded) {
            List<Supplier> supplierList = state.supplierList;

            if (_selectedSupplierId != null && supplierList.isNotEmpty) {
              try {
                _selectedSupplierData = supplierList.firstWhere(
                  (supplier) => supplier.id.toString() == _selectedSupplierId,
                );
              } catch (e) {
                _selectedSupplierData = null;
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('supplier'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                child: CustomDropdown<Supplier>.search(
                  closeDropDownOnClearFilterSearch: true,
                  items: state is SupplierLoaded ? state.supplierList : [],
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
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: Color(0xff1E2E52),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.phone ?? '',
                          style: TextStyle(
                            color: const Color(0xff1E2E52).withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Gilroy',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
                      AppLocalizations.of(context)!.translate('select_supplier'),
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
                  initialItem: (state is SupplierLoaded &&
                          state.supplierList.contains(_selectedSupplierData))
                      ? _selectedSupplierData
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
                        _selectedSupplierId = value.id.toString();
                        _selectedSupplierData = value;
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

