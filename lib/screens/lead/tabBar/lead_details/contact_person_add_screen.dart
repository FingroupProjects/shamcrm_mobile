import 'package:crm_task_manager/bloc/contact_person/contact_person_bloc.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_event.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
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
        title: const Row(
          children: [
            Text(
              'Добавить контакт',
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is ContactPersonSuccess) {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text(state.message),
            //     duration: Duration(seconds: 3),
            //     backgroundColor: Colors.green,
            //   ),
            // );
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
                        hintText: 'Введите ФИО',
                        label: 'ФИО',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Поле обязательно для заполнения';
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
                            return 'Поле обязательно для заполнения';
                          }
                          return null;
                        },
                        label: 'Телефон',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: positionController,
                        hintText: 'Введите должность',
                        label: 'Должность',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Поле обязательно для заполнения';
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
                        buttonText: 'Отмена',
                        buttonColor: Color(0xffF4F7FD),
                        textColor: Colors.black,
                        onPressed: () {
                          Navigator.pop(context, widget.leadId);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        buttonText: 'Сохранить',
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
