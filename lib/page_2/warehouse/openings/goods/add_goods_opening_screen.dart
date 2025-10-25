import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../bloc/cash_register_list/cash_register_list_bloc.dart';
import '../../../../bloc/cash_register_list/cash_register_list_event.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_openings_event.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_openings_state.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_list_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_list_event.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_list_state.dart';
import '../../../../models/page_2/good_variants_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../custom_widget/custom_textfield.dart';
import '../../../../custom_widget/price_input_formatter.dart';
import '../../incoming/supplier_widget.dart';
import '../../incoming/storage_widget.dart';
import 'goods_units_dropdown.dart';

class AddGoodsOpeningScreen extends StatefulWidget {
  final String goodName;
  final int goodVariantId;

  const AddGoodsOpeningScreen({
    Key? key,
    required this.goodName,
    required this.goodVariantId,
  }) : super(key: key);

  @override
  _AddGoodsOpeningScreenState createState() => _AddGoodsOpeningScreenState();
}

class _AddGoodsOpeningScreenState extends State<AddGoodsOpeningScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for numeric fields
  late TextEditingController quantityController;
  late TextEditingController priceController;

  // Selection variables
  String? _selectedSupplierId;
  String? _selectedWarehouseId;
  String? _selectedUnitId;
  
  // Selected good data
  GoodVariantItem? _selectedGood;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with empty values
    quantityController = TextEditingController();
    priceController = TextEditingController();

    // Load required data
    context.read<GetAllCashRegisterBloc>().add(GetAllCashRegisterEv());
    
    // Load goods list to get the selected good data with units
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<GetAllGoodsListBloc>().state;
        
        if (state is GetAllGoodsListSuccess) {
          _loadSelectedGood(state.goodsList);
        } else {
          context.read<GetAllGoodsListBloc>().add(GetAllGoodsListEv());
        }
      }
    });
  }
  
  void _loadSelectedGood(List<GoodVariantItem> goodsList) {
    try {
      _selectedGood = goodsList.firstWhere(
        (good) => good.id == widget.goodVariantId,
      );
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('AddGoodsOpeningScreen: Selected good not found in list');
    }
  }

  @override
  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GoodsOpeningsBloc, GoodsOpeningsState>(
          listener: (context, state) {
            if (state is GoodsOpeningCreateSuccess) {
              Navigator.pop(context, true);
            } else if (state is GoodsOpeningCreateError) {
              // Показываем ошибку создания
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
        ),
        BlocListener<GetAllGoodsListBloc, GetAllGoodsListState>(
          listener: (context, state) {
            if (state is GetAllGoodsListSuccess) {
              _loadSelectedGood(state.goodsList);
            }
          },
        ),
      ],
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
            AppLocalizations.of(context)!.translate('add_goods_opening'),
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
                        _buildGoodsNameField(),
                        const SizedBox(height: 16),
                        SupplierWidget(
                          selectedSupplier: _selectedSupplierId,
                          onChanged: (value) {
                            setState(() {
                              _selectedSupplierId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        StorageWidget(
                          selectedStorage: _selectedWarehouseId,
                          onChanged: (value) {
                            setState(() {
                              _selectedWarehouseId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        GoodUnitsDropdown(
                          selectedGood: _selectedGood,
                          selectedUnitId: _selectedUnitId,
                          onUnitSelected: (unitId) {
                            setState(() {
                              _selectedUnitId = unitId;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: quantityController,
                          label: AppLocalizations.of(context)!.translate('quantity'),
                          hintText: AppLocalizations.of(context)!.translate('enter_quantity'),
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
                          controller: priceController,
                          label: AppLocalizations.of(context)!.translate('price'),
                          hintText: AppLocalizations.of(context)!.translate('enter_price'),
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
              BlocBuilder<GoodsOpeningsBloc, GoodsOpeningsState>(
                builder: (context, state) {
                  final isCreating = state is GoodsOpeningCreating;
                  
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
                            onPressed: isCreating ? null : () {
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
                            isLoading: isCreating,
                            onPressed: isCreating ? null : () {
                          if (_formKey.currentState!.validate()) {
                            // Проверяем, что все обязательные поля заполнены
                            if (_selectedSupplierId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!.translate('select_supplier'),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (_selectedWarehouseId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!.translate('select_warehouse'),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (_selectedUnitId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!.translate('select_unit'),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Создаем событие для добавления товара
                            context.read<GoodsOpeningsBloc>().add(
                              CreateGoodsOpening(
                                goodVariantId: widget.goodVariantId,
                                supplierId: int.parse(_selectedSupplierId!),
                                price: double.parse(priceController.text),
                                quantity: double.parse(quantityController.text),
                                unitId: int.parse(_selectedUnitId!),
                                storageId: int.parse(_selectedWarehouseId!),
                              ),
                            );

                              // BlocListener автоматически обработает успешное создание
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

  Widget _buildGoodsNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('goods'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xffF4F7FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xffF4F7FD),
              width: 1,
            ),
          ),
          child: Text(
            widget.goodName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
        ),
      ],
    );
  }

}

