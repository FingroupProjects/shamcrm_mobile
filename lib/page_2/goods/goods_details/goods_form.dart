import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/attributes_handler.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_utils.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/image_handler.dart';
import 'package:crm_task_manager/page_2/goods/category_list.dart';
import 'package:crm_task_manager/page_2/order/order_details/branch_method_dropdown.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

class GoodsForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final List<Branch> branches;
  final bool isLoading;
  final Function(bool) onLoadingChanged;
  final Future<bool> Function() onCreateProduct;

  const GoodsForm({
    required this.formKey,
    required this.branches,
    required this.isLoading,
    required this.onLoadingChanged,
    required this.onCreateProduct,
  });

  @override
  _GoodsFormState createState() => _GoodsFormState();
}

class _GoodsFormState extends State<GoodsForm> {
  final TextEditingController goodsNameController = TextEditingController();
  final TextEditingController goodsDescriptionController =
      TextEditingController();
  final TextEditingController discountPriceController = TextEditingController();
  final TextEditingController stockQuantityController = TextEditingController();
  final TextEditingController unitIdController = TextEditingController();
  SubCategoryAttributesData? selectedCategory;
  Branch? selectedBranch;
  bool isActive = true;
  List<SubCategoryAttributesData> subCategories = [];
  bool isCategoryValid = true;
  bool isImagesValid = true;
  bool isBranchValid = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    fetchSubCategories();
  }

  Future<void> fetchSubCategories() async {
    widget.onLoadingChanged(true);
    try {
      final categories = await _apiService.getSubCategoryAttributes();
      setState(() {
        subCategories = categories;
      });
    } catch (e) {
      print('Error fetching subcategories: $e');
    } finally {
      widget.onLoadingChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: Colors.white,
  bottomSheet: Container(
    padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 18),
    decoration: const BoxDecoration(color: Colors.white),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: CustomButton(
            buttonText: AppLocalizations.of(context)!.translate('cancel'),
            buttonColor: const Color(0xffF4F7FD),
            textColor: Colors.black,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: widget.isLoading
              ? SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      color: const Color(0xff4759FF),
                    ),
                  ),
                )
              : CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('add'),
                  buttonColor: const Color(0xff4759FF),
                  textColor: Colors.white,
                  onPressed: () async {
                    validateForm(
                      formKey: widget.formKey,
                      selectedCategory: selectedCategory,
                      selectedBranch: selectedBranch,
                      isImagesValid: isImagesValid,
                      onCategoryValid: (valid) =>
                          setState(() => isCategoryValid = valid),
                      onImagesValid: (valid) =>
                          setState(() => isImagesValid = valid),
                      onBranchValid: (valid) =>
                          setState(() => isBranchValid = valid),
                    );
                    if (widget.formKey.currentState!.validate() &&
                        isCategoryValid &&
                        isImagesValid &&
                        isBranchValid) {
                      final success = await widget.onCreateProduct();
                      if (success) {
                        context.read<GoodsBloc>().add(FetchGoods());
                      }
                    } else {
                      showCustomSnackBar(
                        context: context,
                        message: AppLocalizations.of(context)!
                            .translate('fill_all_required_fields'),
                        isSuccess: false,
                      );
                    }
                  },
                ),
        ),
      ],
    ),
  ),
  body: Padding(
    padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
    child: GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        child: Form(
          key: widget.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: goodsNameController,
                hintText: AppLocalizations.of(context)!
                    .translate('enter_goods_name'),
                label:
                    AppLocalizations.of(context)!.translate('goods_name'),
                validator: (value) => value == null || value.isEmpty
                    ? AppLocalizations.of(context)!.translate('field_required')
                    : null,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: goodsDescriptionController,
                hintText: AppLocalizations.of(context)!
                    .translate('enter_goods_description'),
                label: AppLocalizations.of(context)!
                    .translate('goods_description'),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
              ),
              if (selectedCategory != null &&
                  !selectedCategory!.hasPriceCharacteristics)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: discountPriceController,
                      label:
                          AppLocalizations.of(context)!.translate('price'),
                      hintText: AppLocalizations.of(context)!
                          .translate('enter_price'),
                      keyboardType: TextInputType.number,
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
              const SizedBox(height: 8),
              BranchesDropdown(
                label: AppLocalizations.of(context)!.translate('branch'),
                selectedBranch: selectedBranch,
                branches: widget.branches,
                onSelectBranch: (Branch branch) {
                  setState(() {
                    selectedBranch = branch;
                    isBranchValid = true;
                  });
                },
              ),
              const SizedBox(height: 8),
              CategoryDropdownWidget(
                selectedCategory: selectedCategory?.name,
                onSelectCategory: (category) {
                  setState(() {
                    selectedCategory = category;
                    isCategoryValid = category != null;
                  });
                },
                subCategories: subCategories,
                isValid: isCategoryValid,
              ),
              AttributesHandler(
                selectedCategory: selectedCategory,
                onCategoryValid: (valid) =>
                    setState(() => isCategoryValid = valid),
              ),
              ImageHandler(
                isImagesValid: isImagesValid,
                onImagesValid: (valid) =>
                    setState(() => isImagesValid = valid),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .translate('status_goods'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isActive = !isActive;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7FD),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Switch(
                                  value: isActive,
                                  onChanged: (value) {
                                    setState(() {
                                      isActive = value;
                                    });
                                  },
                                  activeColor: const Color.fromARGB(
                                      255, 255, 255, 255),
                                  inactiveTrackColor:
                                      const Color.fromARGB(255, 179, 179, 179)
                                          .withOpacity(0.5),
                                  activeTrackColor: const Color(0xff4759FF),
                                  inactiveThumbColor:
                                      const Color.fromARGB(255, 255, 255, 255),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isActive
                                      ? AppLocalizations.of(context)!
                                          .translate('active')
                                      : AppLocalizations.of(context)!
                                          .translate('inactive'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Gilroy',
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  ),
);

  }

  @override
  void dispose() {
    goodsNameController.dispose();
    goodsDescriptionController.dispose();
    discountPriceController.dispose();
    stockQuantityController.dispose();
    unitIdController.dispose();
    super.dispose();
  }
}