import 'package:crm_task_manager/bloc/contact_person/contact_person_bloc.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_event.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_state.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContactPersonAddScreen extends StatefulWidget {
  final int leadId;

  ContactPersonAddScreen({required this.leadId});

  @override
  _ContactPersonAddScreenState createState() => _ContactPersonAddScreenState();
}

class _ContactPersonAddScreenState extends State<ContactPersonAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController positionController = TextEditingController();

  String selectedDialCode = '';

  Color _screenPrimaryText(BuildContext context) =>
      context.appColors.textInverse.withValues(alpha: 0.96);
  Color _screenSecondaryText(BuildContext context) =>
      context.appColors.textInverse.withValues(alpha: 0.82);
  Color _screenHintText(BuildContext context) =>
      context.appColors.textInverse.withValues(alpha: 0.58);
  Color _screenBorder(BuildContext context) =>
      context.appColors.textInverse.withValues(alpha: 0.16);
  Color _screenFieldBackground(BuildContext context) =>
      context.appColors.surfaceElevated.withValues(alpha: 0.96);
  Color _screenSurfaceBackground(BuildContext context) =>
      context.appColors.surfacePrimary.withValues(alpha: 0.84);

  void _showErrorSnackBar(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.appColors.textInverse,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: context.appColors.error,
          elevation: 3,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBarGradient = [
      _screenFieldBackground(context),
      _screenSurfaceBackground(context),
    ];
    final primaryText = _screenPrimaryText(context);
    final subtleBorder = _screenBorder(context);

    return Scaffold(
      backgroundColor: context.appColors.overlay.withValues(alpha: 0),
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        forceMaterialTransparency: true,
        backgroundColor: context.appColors.overlay.withValues(alpha: 0),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 74,
        titleSpacing: 16,
        title: AppBarShell(
          leading: AppBarShell.capsule(
            context,
            width: AppBarShell.orbSize,
            padding: EdgeInsets.zero,
            gradientColors: appBarGradient,
            borderColor: subtleBorder,
            child: IconButton(
              onPressed: () => Navigator.pop(context, widget.leadId),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: primaryText,
              ),
            ),
          ),
          center: AppBarShell.capsule(
            context,
            gradientColors: appBarGradient,
            borderColor: subtleBorder,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.translate('add_contact'),
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
            ),
          ),
        ),
      ),
      body: BlocListener<ContactPersonBloc, ContactPersonState>(
        listener: (context, state) {
          if (state is ContactPersonError) {
            _showErrorSnackBar(
              context,
              AppLocalizations.of(context)!
                  .translate(state.message), // Локализация сообщения
            );
          } else if (state is ContactPersonSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!
                      .translate('contact_created_successfully'),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textInverse,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: context.appColors.success,
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.pop(context, widget.leadId);
          }
        },
        child: Stack(
          children: [
            const AppBackgroundOverlay(
              preset: AppBackgroundPreset.aurora,
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                      },
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                          decoration: BoxDecoration(
                            color: _screenSurfaceBackground(context),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: subtleBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                controller: nameController,
                                backgroundColor:
                                    _screenFieldBackground(context),
                                textColor: primaryText,
                                labelColor: _screenPrimaryText(context),
                                hintColor: _screenHintText(context),
                                borderColor: subtleBorder,
                                focusedBorderColor:
                                    context.appColors.buttonPrimaryBg,
                                hintText: AppLocalizations.of(context)!
                                    .translate('enter_full_name'),
                                label: AppLocalizations.of(context)!
                                    .translate('full_name'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(context)!
                                        .translate('field_required');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              CustomPhoneNumberInput(
                                controller: phoneController,
                                onInputChanged: (String number) {
                                  setState(() {
                                    selectedDialCode = number;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(context)!
                                        .translate('field_required');
                                  }
                                  return null;
                                },
                                label: AppLocalizations.of(context)!
                                    .translate('phone'),
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: positionController,
                                backgroundColor:
                                    _screenFieldBackground(context),
                                textColor: primaryText,
                                labelColor: _screenPrimaryText(context),
                                hintColor: _screenHintText(context),
                                borderColor: subtleBorder,
                                focusedBorderColor:
                                    context.appColors.buttonPrimaryBg,
                                hintText: AppLocalizations.of(context)!
                                    .translate('enter_position'),
                                label: AppLocalizations.of(context)!
                                    .translate('position'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _screenSurfaceBackground(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: subtleBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            buttonText: AppLocalizations.of(context)!
                                .translate('cancel'),
                            buttonColor: _screenFieldBackground(context),
                            textColor: primaryText,
                            onPressed: () {
                              Navigator.pop(context, widget.leadId);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: BlocBuilder<ContactPersonBloc,
                              ContactPersonState>(
                            builder: (context, state) {
                              if (state is ContactPersonLoading) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: primaryText,
                                  ),
                                );
                              } else {
                                return CustomButton(
                                  buttonText: AppLocalizations.of(context)!
                                      .translate('save'),
                                  buttonColor:
                                      context.appColors.buttonPrimaryBg,
                                  textColor: context.appColors.buttonPrimaryFg,
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      final String phone = selectedDialCode;

                                      context.read<ContactPersonBloc>().add(
                                            CreateContactPerson(
                                              leadId: widget.leadId,
                                              name: nameController.text,
                                              phone: phone,
                                              position: positionController.text,
                                            ),
                                          );
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
          ],
        ),
      ),
    );
  }
}
