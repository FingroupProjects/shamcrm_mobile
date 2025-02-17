import 'package:crm_task_manager/bloc/contact_person/contact_person_bloc.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_event.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_state.dart';
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
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.red,
        elevation: 3,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        duration: Duration(seconds: 3),
      ),
    );
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Navigator.pop(context, widget.leadId);
          },
        ),
        title: Row(
          children: [
            Text(
              AppLocalizations.of(context)!.translate('add_contact'), 
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ],
        ),
      ),
      body: BlocListener<ContactPersonBloc, ContactPersonState>(
  listener: (context, state) {
    if (state is ContactPersonError) {
      _showErrorSnackBar(context,AppLocalizations.of(context)!.translate(state.message), // Локализация сообщения
      );
    } else if (state is ContactPersonSuccess) {
       ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text(
                       AppLocalizations.of(context)!.translate('contact_created_successfully'), 
                       style: TextStyle(
                         fontFamily: 'Gilroy',
                         fontSize: 16, 
                         fontWeight: FontWeight.w500, 
                         color: Colors.white, 
                       ),
                     ),
                     behavior: SnackBarBehavior.floating,
                     margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(12),
                     ),
                     backgroundColor: Colors.green,
                     elevation: 3,
                     padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), 
                     duration: Duration(seconds: 3),
                   ),
                );
      Navigator.pop(context, widget.leadId);
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: nameController,
                        hintText: AppLocalizations.of(context)!.translate('enter_full_name'),
                        label: AppLocalizations.of(context)!.translate('full_name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.translate('field_required');
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
                            return AppLocalizations.of(context)!.translate('field_required');
                          }
                          return null;
                        },
                        label: AppLocalizations.of(context)!.translate('phone'),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: positionController,
                        hintText: AppLocalizations.of(context)!.translate('enter_position'),
                        label: AppLocalizations.of(context)!.translate('position'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.translate('field_required');
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        buttonText: AppLocalizations.of(context)!.translate('cancel'),
                        buttonColor: Color(0xffF4F7FD),
                        textColor: Colors.black,
                        onPressed: () {
                          Navigator.pop(context, widget.leadId);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BlocBuilder<ContactPersonBloc, ContactPersonState>(
                        builder: (context, state) {
                          if (state is ContactPersonLoading) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: Color(0xff1E2E52),
                              ),
                            );
                          } else {
                            return CustomButton(
                              buttonText: AppLocalizations.of(context)!.translate('save'),
                              buttonColor: Color(0xff4759FF),
                              textColor: Colors.white,
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
      ),
    );
  }
}
