import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/helpers/theme_context_extension.dart';
import '../../../../models/page_2/openings/goods_openings_model.dart';
import '../../../../models/page_2/good_variants_model.dart';
import '../../../../bloc/cash_register_list/cash_register_list_bloc.dart';
import '../../../../bloc/cash_register_list/cash_register_list_event.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_openings_event.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_openings_state.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_list_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_list_event.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../custom_widget/custom_textfield.dart';
import '../../../../custom_widget/price_input_formatter.dart';
import '../../incoming/supplier_widget.dart';
import '../../incoming/storage_widget.dart';
import '../../../../utils/global_fun.dart';
import 'goods_list.dart';
import 'goods_units_dropdown.dart';

class EditGoodsOpeningScreen extends StatefulWidget {
  final GoodsOpeningDocument goodsOpening;

  const EditGoodsOpeningScreen({super.key, required this.goodsOpening});

  @override
  State<EditGoodsOpeningScreen> createState() => _EditGoodsOpeningScreenState();
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

  GoodVariantItem? _selectedGoods;

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

    // Initialize selected goods from existing data - use goodVariantId as the ID
    if (documentGood?.goodVariant != null) {
      _selectedGoods = GoodVariantItem(
        id: documentGood!.goodVariantId,
        goodId: documentGood.goodVariant?.goodId,
        fullName: documentGood.goodVariant?.fullName,
        good: documentGood.goodVariant?.good != null
            ? VariantGood(
                id: documentGood.goodVariant!.good!.id,
                name: documentGood.goodVariant!.good!.name,
              )
            : null,
      );
    }

    // Load required data
    context.read<GetAllGoodsListBloc>().add(GetAllGoodsListEv());
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
    final colors = context.appColors;
    debugPrint(
        "EditGoodsOpeningScreen: Building edit screen for Goods Opening ID: ${widget.goodsOpening.id}");

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
          // Небольшая задержка перед закрытием экрана, чтобы SnackBar успел отобразиться
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        } else if (state is GoodsOpeningUpdateError) {
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
        backgroundColor: colors.backgroundPrimary,
        appBar: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: colors.backgroundPrimary,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colors.iconPrimary,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppLocalizations.of(context)!.translate('edit_goods_opening'),
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
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
                        // _buildStatusBanner(context),
                        // const SizedBox(height: 16),
                        GoodsRadioGroupWidget(
                          selectedGood: _selectedGoods?.id.toString(),
                          showPrice: false,
                          onSelectGood: (GoodVariantItem goods) {
                            setState(() {
                              _selectedGoods = goods;
                              // Сбрасываем выбранную единицу измерения при смене товара
                              _selectedUnitId = null;
                            });
                          },
                        ),
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
                          selectedGood: _selectedGoods,
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
                          label: AppLocalizations.of(context)!
                              .translate('quantity'),
                          hintText: AppLocalizations.of(context)!
                              .translate('enter_quantity'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            PriceInputFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .translate('field_required');
                            }
                            if (double.tryParse(value) == null) {
                              return AppLocalizations.of(context)!
                                  .translate('enter_correct_number');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: priceController,
                          label:
                              AppLocalizations.of(context)!.translate('price'),
                          hintText: AppLocalizations.of(context)!
                              .translate('enter_price'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            PriceInputFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .translate('field_required');
                            }
                            if (double.tryParse(value) == null) {
                              return AppLocalizations.of(context)!
                                  .translate('enter_correct_number');
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
                            buttonText: AppLocalizations.of(context)!
                                .translate('close'),
                            buttonColor: colors.surfacePrimary,
                            textColor: colors.textPrimary,
                            onPressed: isUpdating
                                ? null
                                : () {
                                    Navigator.pop(context);
                                  },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            buttonText:
                                AppLocalizations.of(context)!.translate('save'),
                            buttonColor: colors.buttonPrimaryBg,
                            textColor: colors.buttonPrimaryFg,
                            isLoading: isUpdating,
                            onPressed: isUpdating
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      if (_selectedGoods == null ||
                                          _selectedSupplierId == null ||
                                          _selectedWarehouseId == null ||
                                          _selectedUnitId == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppLocalizations.of(context)!
                                                  .translate('fill_all_fields'),
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            backgroundColor: Colors.orange,
                                            elevation: 3,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 16),
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                        return;
                                      }

                                      if (widget.goodsOpening.id == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
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
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            backgroundColor: Colors.red,
                                            elevation: 3,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 16),
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                        return;
                                      }

                                      context.read<GoodsOpeningsBloc>().add(
                                            UpdateGoodsOpening(
                                              id: widget.goodsOpening.id!,
                                              goodVariantId:
                                                  _selectedGoods!.id!,
                                              supplierId: int.parse(
                                                  _selectedSupplierId!),
                                              price: double.parse(
                                                  priceController.text),
                                              quantity: double.parse(
                                                  quantityController.text),
                                              unitId:
                                                  int.parse(_selectedUnitId!),
                                              storageId: int.parse(
                                                  _selectedWarehouseId!),
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

  Widget _buildStatusBanner(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.buttonPrimaryBg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.buttonPrimaryBg.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.buttonPrimaryBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_note_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.translate('edit_goods_opening'),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!
                      .translate('update_initial_balance'),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
