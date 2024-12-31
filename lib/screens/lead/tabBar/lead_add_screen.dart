import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_bloc.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_create_field.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/region_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/source_lead_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:intl/intl.dart';

class LeadAddScreen extends StatefulWidget {
  final int statusId;

  LeadAddScreen({required this.statusId});

  @override
  _LeadAddScreenState createState() => _LeadAddScreenState();
}

class _LeadAddScreenState extends State<LeadAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController instaLoginController = TextEditingController();
  final TextEditingController facebookLoginController = TextEditingController();
  final TextEditingController tgNickController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController createDateController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedRegion;
  String? selectedManager;
  String? selectedSourceLead;
  String selectedDialCode = '';
  String selectedDialCodeWhatsapp = '';
  List<CustomField> customFields = [];
  bool isEndDateInvalid = false;

  @override
  void initState() {
    super.initState();

    context.read<SourceLeadBloc>().add(FetchSourceLead());
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetAllRegionBloc>().add(GetAllRegionEv());
    _fetchAndAddCustomFields();
  }

  void _fetchAndAddCustomFields() async {
    try {
      final data = await ApiService().getCustomFieldslead();
      if (data['result'] != null) {
        data['result'].forEach((value) {
          setState(() {
            customFields.add(CustomField(fieldName: value));
          });
        });
      }
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  void _addCustomField(String fieldName) {
    setState(() {
      customFields.add(CustomField(fieldName: fieldName));
    });
  }

  void _showAddFieldDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddCustomFieldDialog(
          onAddField: (fieldName) {
            _addCustomField(fieldName);
          },
        );
      },
    );
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
            Navigator.pop(context, widget.statusId);
            context.read<LeadBloc>().add(FetchLeadStatuses());
          },
        ),
        title: const Row(
          children: [
            Text(
              'Новый лид',
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
      body: BlocListener<LeadBloc, LeadState>(
        listener: (context, state) {
          if (state is LeadError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${state.message}',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                backgroundColor: Colors.red,
                elevation: 0,
                duration: Duration(seconds: 3),
              ),
            );
          } else if (state is LeadSuccess) {
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
                backgroundColor: Colors.green,
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.pop(context, widget.statusId);
            context.read<LeadBloc>().add(FetchLeadStatuses());
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
                        controller: titleController,
                        hintText: 'Введите название',
                        label: 'Название',
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
                      const SizedBox(height: 8),
                      RegionRadioGroupWidget(
                        selectedRegion: selectedRegion,
                        onSelectRegion: (RegionData selectedRegionData) {
                          setState(() {
                            selectedRegion = selectedRegionData.id.toString();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      ManagerRadioGroupWidget(
                        selectedManager: selectedManager,
                        onSelectManager: (ManagerData selectedManagerData) {
                          setState(() {
                            selectedManager = selectedManagerData.id.toString();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      SourceLeadWidget(
                        selectedSourceLead: selectedSourceLead,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedSourceLead = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: instaLoginController,
                        hintText: 'Введите логин instagram',
                        label: 'Instagram',
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: facebookLoginController,
                        hintText: 'Введите логин facebook',
                        label: 'Facebook',
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: tgNickController,
                        hintText: 'Введите логин telegram',
                        label: 'Telegram',
                      ),
                      const SizedBox(height: 8),
                      CustomPhoneNumberInput(
                        controller: whatsappController,
                        onInputChanged: (String number) {
                          setState(() {
                            selectedDialCodeWhatsapp = number;
                          });
                        },
                        label: 'Whatsapp',
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: emailController,
                        hintText: 'Введите электронную почту',
                        label: 'Электронная почта',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      CustomTextFieldDate(
                        controller: birthdayController,
                        label: 'Дата рождения',
                        withTime: false,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: descriptionController,
                        hintText: 'Введите описание',
                        label: 'Описание',
                        maxLines: 5,
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: customFields.length,
                        itemBuilder: (context, index) {
                          return CustomFieldWidget(
                            fieldName: customFields[index].fieldName,
                            valueController: customFields[index].controller,
                            onRemove: () {
                              setState(() {
                                customFields.removeAt(index);
                              });
                            },
                          );
                        },
                      ),
                      CustomButton(
                        buttonText: 'Добавить поле',
                        buttonColor: Color(0xff1E2E52),
                        textColor: Colors.white,
                        onPressed: _showAddFieldDialog,
                      ),
                      const SizedBox(height: 20),
                    ],
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
                        buttonText: 'Отмена',
                        buttonColor: Color(0xffF4F7FD),
                        textColor: Colors.black,
                        onPressed: () {
                          Navigator.pop(context, widget.statusId);
                          context.read<LeadBloc>().add(FetchLeadStatuses());
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BlocBuilder<LeadBloc, LeadState>(
                        builder: (context, state) {
                          if (state is LeadLoading) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: Color(0xff1E2E52),
                              ),
                            );
                          } else {
                            return CustomButton(
                              buttonText: 'Добавить',
                              buttonColor: Color(0xff4759FF),
                              textColor: Colors.white,
                              onPressed: _submitForm,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _createLead();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Пожалуйста, заполните все обязательные поля!',
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
    }
  }

  void _createLead() {
    final String name = titleController.text;
    final String phone = selectedDialCode;
    final String? instaLogin =
        instaLoginController.text.isEmpty ? null : instaLoginController.text;
    final String? facebookLogin = facebookLoginController.text.isEmpty
        ? null
        : facebookLoginController.text;
    final String? tgNick =
        tgNickController.text.isEmpty ? null : tgNickController.text;
    final String? whatsapp =
        whatsappController.text.isEmpty || selectedDialCodeWhatsapp.isEmpty
            ? null
            : selectedDialCodeWhatsapp;
    final String? birthdayString =
        birthdayController.text.isEmpty ? null : birthdayController.text;
    final String? email =
        emailController.text.isEmpty ? null : emailController.text;
    final String? description =
        descriptionController.text.isEmpty ? null : descriptionController.text;

    DateTime? birthday;
    if (birthdayString != null && birthdayString.isNotEmpty) {
      try {
        birthday = DateFormat('dd/MM/yyyy').parse(birthdayString);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Введите корректную дату рождения в формате ДД/ММ/ГГГГ'),
          ),
        );
        return;
      }
    }

    List<Map<String, String>> customFieldMap = [];
    for (var field in customFields) {
      String fieldName = field.fieldName.trim();
      String fieldValue = field.controller.text.trim();
      if (fieldName.isNotEmpty && fieldValue.isNotEmpty) {
        customFieldMap.add({fieldName: fieldValue});
      }
    }

    context.read<LeadBloc>().add(CreateLead(
          name: name,
          leadStatusId: widget.statusId,
          phone: phone,
          regionId: selectedRegion != null ? int.parse(selectedRegion!) : null,
          managerId:
              selectedManager != null ? int.parse(selectedManager!) : null,
          sourceId: selectedSourceLead != null
              ? int.parse(selectedSourceLead!)
              : null,
          instaLogin: instaLogin,
          facebookLogin: facebookLogin,
          tgNick: tgNick,
          waPhone: whatsapp,
          birthday: birthday,
          email: email,
          description: description,
          customFields: customFieldMap,
        ));
  }
}

class CustomField {
  final String fieldName;
  final TextEditingController controller = TextEditingController();

  CustomField({required this.fieldName});
}
