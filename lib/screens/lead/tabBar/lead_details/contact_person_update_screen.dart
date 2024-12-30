import 'package:crm_task_manager/bloc/contact_person/contact_person_bloc.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_event.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_for_edit.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/contact_person_model.dart';
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


  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.contactPerson.name);
    phoneController = TextEditingController(text: widget.contactPerson.phone);
    positionController = TextEditingController(text: widget.contactPerson.position);
    
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
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Редактировать контакт',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      body: BlocListener<ContactPersonBloc, ContactPersonState>(
        listener: (context, state) {
          if (state is ContactPersonError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${state.message}',
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
                backgroundColor: Colors.red,
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: Duration(seconds: 3),
              ),
            );
          } else if (state is ContactPersonSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text(
                       'Контактное лицо успешно обновлено!',
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
            Navigator.pop(context);
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
                              ? 'Поле обязательно для заполнения'
                              : null,
                          label: 'Телефон',
                        ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: positionController,
                        hintText: 'Введите позицию',
                        label: 'Позиция',
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
                        buttonColor: const Color(0xffF4F7FD),
                        textColor: Colors.black,
                        onPressed: () {
                          Navigator.pop(context);
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
                              buttonText: 'Сохранить',
                              buttonColor: const Color(0xff4759FF),
                              textColor: Colors.white,
                              onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                String phoneToSend;

                                if (_isPhoneEdited) {
                                  phoneToSend = selectedDialCode;
                                } else {
                                  phoneToSend = '$selectedDialCode${phoneController.text}'; 
                                }

                                context.read<ContactPersonBloc>().add(
                                  UpdateContactPerson(
                                    contactpersonId: widget.contactPerson.id,
                                    leadId: widget.leadId,
                                    name: nameController.text,
                                    phone: phoneToSend,
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
