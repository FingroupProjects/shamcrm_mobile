import 'package:crm_task_manager/bloc/page_2_BLOC/document/measure_units/measure_units_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/measure_units/measure_units_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/measure_units/measure_units_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/page_2/measure_unit_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddMeasureUnitScreen extends StatefulWidget {
  const AddMeasureUnitScreen({Key? key}) : super(key: key);

  @override
  _AddMeasureUnitScreenState createState() => _AddMeasureUnitScreenState();
}

class _AddMeasureUnitScreenState extends State<AddMeasureUnitScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController shortNameController = TextEditingController();

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
          AppLocalizations.of(context)!.translate('add_measure_unit') ??
              'Добавить единицу измерения',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: BlocListener<MeasureUnitsBloc, MeasureUnitsState>(
        listener: (context, state) {
          if (state is MeasureUnitsError) {
            _showErrorSnackBar(
                context,
                AppLocalizations.of(context)!.translate(state.message) ??
                    state.message);
          } else if (state is MeasureUnitsLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!
                          .translate('measure_unit_created_successfully') ??
                      'Единица измерения успешно создана',
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
            Navigator.pop(context, true);
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
                                  .translate('enter_measure_unit_name') ??
                              'Введите название единицы измерения',
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
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: shortNameController,
                          hintText: AppLocalizations.of(context)!
                                  .translate('enter_short_name') ??
                              'Введите краткое название',
                          label: AppLocalizations.of(context)!
                                  .translate('short_name') ??
                              'Краткое название',
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
                      child: BlocBuilder<MeasureUnitsBloc, MeasureUnitsState>(
                        builder: (context, state) {
                          if (state is MeasureUnitsLoading) {
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
                                  final measureUnit = MeasureUnitModel(
                                    id: 0, // ID will be set by the backend
                                    name: nameController.text,
                                    shortName:
                                        shortNameController.text.isNotEmpty
                                            ? shortNameController.text
                                            : null,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );
                                  context
                                      .read<MeasureUnitsBloc>()
                                      .add(AddMeasureUnitEvent(measureUnit));
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
