import 'package:crm_task_manager/bloc/page_2_BLOC/document/price_type/bloc/price_type_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/price_type/bloc/price_type_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/price_type/bloc/price_type_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/page_2/price_type_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditPriceTypeScreen extends StatefulWidget {
  final PriceTypeModel priceType;

  const EditPriceTypeScreen({Key? key, required this.priceType})
      : super(key: key);

  @override
  _EditPriceTypeScreenState createState() => _EditPriceTypeScreenState();
}

class _EditPriceTypeScreenState extends State<EditPriceTypeScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;

  String selectedDialCode = '';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.priceType.name);
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final colors = context.appColors;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colors.textInverse,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: colors.error,
          elevation: 3,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: colors.surfacePrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.iconPrimary, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.translate('edit_pricetype') ??
              'Редактировать тип цены',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: BlocListener<PriceTypeScreenBloc, PriceTypeState>(
        listener: (context, state) {
          if (state is PriceTypeError) {
            _showErrorSnackBar(
                context,
                AppLocalizations.of(context)!.translate(state.message) ??
                    state.message);
          } else if (state is PriceTypeSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!
                          .translate('pricetype_updated_successfully') ??
                      'Тип цены успешно обновлен',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colors.textInverse,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: colors.success,
                elevation: 3,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.pop(context);
          }
        },
        child: Form(
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
                        CustomTextField(
                          controller: nameController,
                          hintText: AppLocalizations.of(context)!
                                  .translate('enter_pricetype_name') ??
                              'Введите название типа цены',
                          label: AppLocalizations.of(context)!
                                  .translate('title_without_dots') ??
                              'Название',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                      .translate('field_required') ??
                                  'Поле обязательно';
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        buttonText:
                            AppLocalizations.of(context)!.translate('close') ??
                                'Отмена',
                        buttonColor: colors.backgroundSecondary,
                        textColor: colors.textPrimary,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BlocBuilder<PriceTypeScreenBloc, PriceTypeState>(
                        builder: (context, state) {
                          if (state is PriceTypeLoading) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: colors.buttonPrimaryBg,
                              ),
                            );
                          } else {
                            return CustomButton(
                              buttonText: AppLocalizations.of(context)!
                                      .translate('save') ??
                                  'Сохранить',
                              buttonColor: colors.buttonPrimaryBg,
                              textColor: colors.textInverse,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final priceType = PriceTypeModel(
                                    id: widget.priceType.id,
                                    name: nameController.text,
                                    createdAt: widget.priceType.createdAt,
                                    updatedAt: DateTime.now(),
                                    organizationId: 0,
                                    oneCId: null,
                                  );
                                  context.read<PriceTypeScreenBloc>().add(
                                      EditPriceTypeEvent(
                                          priceType, priceType.id));
                                }
                              },
                            );
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
      ),
    );
  }
}
