import 'package:crm_task_manager/bloc/contact_person/contact_person_bloc.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_event.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_state.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_for_edit.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/contact_person_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContactPersonUpdateScreen extends StatefulWidget {
  final int leadId;
  final ContactPerson contactPerson;

  ContactPersonUpdateScreen({
    required this.leadId,
    required this.contactPerson,
  });

  @override
  _ContactPersonUpdateScreenState createState() =>
      _ContactPersonUpdateScreenState();
}

class _ContactPersonUpdateScreenState extends State<ContactPersonUpdateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController positionController;

  String selectedDialCode = '+7';
  List<String> countryCodes = ['+992', '+7', '+996', '+998', '+1'];
  bool _isPhoneEdited = false;

  Color _screenPrimaryText(BuildContext context) =>
      context.appColors.textInverse.withValues(alpha: 0.96);
  Color _screenHintText(BuildContext context) =>
      context.appColors.textInverse.withValues(alpha: 0.58);
  Color _screenBorder(BuildContext context) =>
      context.appColors.textInverse.withValues(alpha: 0.16);
  Color _screenFieldBackground(BuildContext context) =>
      context.appColors.surfaceElevated.withValues(alpha: 0.96);
  Color _screenSurfaceBackground(BuildContext context) =>
      context.appColors.surfacePrimary.withValues(alpha: 0.84);

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.contactPerson.name);
    phoneController = TextEditingController(text: widget.contactPerson.phone);
    positionController =
        TextEditingController(text: widget.contactPerson.position);

    String phoneNumber = widget.contactPerson.phone;
    for (var code in countryCodes) {
      if (phoneNumber.startsWith(code)) {
        setState(() {
          selectedDialCode = code;
          phoneController.text = phoneNumber.substring(code.length);
        });
        break;
      }
    }

    if (phoneController.text.isEmpty) {
      phoneController.text = phoneNumber;
    }

    _isPhoneEdited = false;
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
              onPressed: () => Navigator.pop(context),
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
                AppLocalizations.of(context)!.translate('edit_contact'),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.translate(state.message),
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
                backgroundColor: context.appColors.error,
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: Duration(seconds: 3),
              ),
            );
          } else if (state is ContactPersonSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!
                      .translate('contact_add_successfully'),
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
            Navigator.pop(context);
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
                                labelColor: primaryText,
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
                              const SizedBox(height: 8),
                              CustomPhoneNumberInput(
                                controller: phoneController,
                                selectedDialCode: selectedDialCode,
                                onInputChanged: (String number) {
                                  setState(() {
                                    _isPhoneEdited = true;
                                    selectedDialCode = number;
                                  });
                                },
                                validator: (value) => value!.isEmpty
                                    ? AppLocalizations.of(context)!
                                        .translate('field_required')
                                    : null,
                                label: AppLocalizations.of(context)!
                                    .translate('phone'),
                              ),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: positionController,
                                backgroundColor:
                                    _screenFieldBackground(context),
                                textColor: primaryText,
                                labelColor: primaryText,
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
                              Navigator.pop(context);
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
                              }

                              return CustomButton(
                                buttonText: AppLocalizations.of(context)!
                                    .translate('save'),
                                buttonColor: context.appColors.buttonPrimaryBg,
                                textColor: context.appColors.buttonPrimaryFg,
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    final phoneToSend = _isPhoneEdited
                                        ? selectedDialCode
                                        : '$selectedDialCode${phoneController.text}';

                                    context.read<ContactPersonBloc>().add(
                                          UpdateContactPerson(
                                            contactpersonId:
                                                widget.contactPerson.id,
                                            leadId: widget.leadId,
                                            name: nameController.text,
                                            phone: phoneToSend,
                                            position: positionController.text,
                                          ),
                                        );
                                  }
                                },
                              );
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
