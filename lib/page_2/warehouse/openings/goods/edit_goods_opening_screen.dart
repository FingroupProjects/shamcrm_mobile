import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import '../../../../models/page_2/openings/goods_openings_model.dart';
import '../../../../models/page_2/goods_model.dart';
import '../../../../models/cash_register_list_model.dart';
import '../../../../bloc/page_2_BLOC/goods/goods_bloc.dart';
import '../../../../bloc/page_2_BLOC/goods/goods_event.dart';
import '../../../../bloc/page_2_BLOC/goods/goods_state.dart';
import '../../../../bloc/cash_register_list/cash_register_list_bloc.dart';
import '../../../../bloc/cash_register_list/cash_register_list_event.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_openings_event.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_openings_state.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../custom_widget/custom_textfield.dart';
import '../../../../custom_widget/price_input_formatter.dart';
import '../../incoming/supplier_widget.dart';
import '../../incoming/storage_widget.dart';
import '../../incoming/units_widget.dart';
import '../../../money/widgets/cash_register_radio_group.dart';
import '../../../../utils/global_fun.dart';

class EditGoodsOpeningScreen extends StatefulWidget {
  final GoodsOpeningDocument goodsOpening;

  const EditGoodsOpeningScreen({Key? key, required this.goodsOpening})
      : super(key: key);

  @override
  _EditGoodsOpeningScreenState createState() => _EditGoodsOpeningScreenState();
}

class _EditGoodsOpeningScreenState extends State<EditGoodsOpeningScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controllers for numeric fields
  late TextEditingController quantityController;
  late TextEditingController priceController;
  
  // Selection variables
  String? _selectedSupplierId;
  String? _selectedWarehouseId;
  String? _selectedUnitId;
  
  Goods? _selectedGoods;
  CashRegisterData? _selectedCashRegister;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing values
    final documentGood = widget.goodsOpening.documentGoods?.isNotEmpty == true 
        ? widget.goodsOpening.documentGoods!.first 
        : null;
        
    quantityController = TextEditingController(
      text: parseNumberToString(documentGood?.quantity, nullValue: '0'),
    );
    priceController = TextEditingController(
      text: parseNumberToString(documentGood?.price, nullValue: '0'),
    );
    
    // Initialize selections from existing data
    _selectedSupplierId = widget.goodsOpening.model?.id?.toString();
    _selectedWarehouseId = widget.goodsOpening.storage?.id?.toString();
    _selectedUnitId = documentGood?.unit?.id?.toString();
    
    // Load required data
    context.read<GoodsBloc>().add(FetchGoods(page: 1));
    context.read<GetAllCashRegisterBloc>().add(GetAllCashRegisterEv());
  }

  @override
  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GoodsOpeningsBloc, GoodsOpeningsState>(
      listener: (context, state) {
        if (state is GoodsOpeningUpdateSuccess) {
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
        } else if (state is GoodsOpeningUpdateError) {
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
            AppLocalizations.of(context)!.translate('edit_goods_opening'),
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
                      _buildGoodsDropdown(),
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
                      CashRegisterGroupWidget(
                        selectedCashRegisterId: _selectedCashRegister?.id.toString(),
                        onSelectCashRegister: (CashRegisterData cashRegister) {
                          setState(() {
                            _selectedCashRegister = cashRegister;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      UnitsWidget(
                        selectedUnit: _selectedUnitId,
                        onChanged: (value) {
                          setState(() {
                            _selectedUnitId = value;
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
                final isUpdating = state is GoodsOpeningUpdating;
                
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
                          if (_selectedSupplierId == null ||
                              _selectedWarehouseId == null ||
                              _selectedUnitId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!.translate('fill_all_fields'),
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
                            return;
                          }

                          final documentGood = widget.goodsOpening.documentGoods?.isNotEmpty == true 
                              ? widget.goodsOpening.documentGoods!.first 
                              : null;

                          if (widget.goodsOpening.id == null || documentGood?.goodVariantId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Ошибка: неверные данные документа',
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

                          context.read<GoodsOpeningsBloc>().add(
                            UpdateGoodsOpening(
                              id: widget.goodsOpening.id!,
                              goodVariantId: documentGood!.goodVariantId!,
                              supplierId: int.parse(_selectedSupplierId!),
                              price: double.parse(priceController.text),
                              quantity: double.parse(quantityController.text),
                              unitId: int.parse(_selectedUnitId!),
                              storageId: int.parse(_selectedWarehouseId!),
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

  Widget _buildGoodsDropdown() {
    return BlocListener<GoodsBloc, GoodsState>(
      listener: (context, state) {
        if (state is GoodsError) {
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
      child: BlocBuilder<GoodsBloc, GoodsState>(
        builder: (context, state) {
          final isLoading = state is GoodsLoading;
          
          List<Goods> goodsList = [];
          if (state is GoodsDataLoaded) {
            goodsList = state.goods;
            
            // Инициализируем выбранный товар при загрузке данных
            if (_selectedGoods == null && 
                widget.goodsOpening.documentGoods?.isNotEmpty == true) {
              final documentGood = widget.goodsOpening.documentGoods!.first;
              if (documentGood.goodVariant != null) {
                try {
                  _selectedGoods = goodsList.firstWhere(
                    (good) => good.id == documentGood.goodVariantId,
                  );
                } catch (e) {
                  // Товар не найден в списке
                }
              }
            }
          }

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
              CustomDropdown<Goods>.search(
                closeDropDownOnClearFilterSearch: true,
                items: goodsList,
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
                    AppLocalizations.of(context)!.translate('select_goods'),
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
                initialItem: _selectedGoods,
                validator: (value) {
                  if (value == null) {
                    return AppLocalizations.of(context)!.translate('field_required');
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedGoods = value;
                    });
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

}
