import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_for_edit.dart';
import 'package:crm_task_manager/models/leadById_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_create_field.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_add_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/region_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/source_lead_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:intl/intl.dart';

class LeadEditScreen extends StatefulWidget {
  final int leadId;
  final String leadName;
  final String? region;
  final String? manager;
  final String? sourceId;
  final String? birthday;
  final String? createAt;
  final String? instagram;
  final String? facebook;
  final String? telegram;
  final String? phone;
  final String? whatsApp;
  final String? email;
  final String? description;
  final int statusId;
  final List<LeadCustomFieldsById> leadCustomFields;

  LeadEditScreen(
      {required this.leadId,
      required this.leadName,
      required this.statusId,
      this.region,
      this.manager,
      this.sourceId,
      this.birthday,
      this.createAt,
      this.instagram,
      this.facebook,
      this.telegram,
      this.phone,
      this.whatsApp,
      this.email,
      this.description,
      required this.leadCustomFields});

  @override
  _LeadEditScreenState createState() => _LeadEditScreenState();
}

class _LeadEditScreenState extends State<LeadEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController whatsAppController = TextEditingController();
  final TextEditingController instaLoginController = TextEditingController();
  final TextEditingController facebookLoginController = TextEditingController();
  final TextEditingController telegramController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController createdAtController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedRegion;
  String? selectedSource;

  String? selectedManager;
  String selectedDialCode = '+992';
  String selectedWhatsAppDialCode = '+992'; // Новая переменная для WhatsApp

  List<String> countryCodes = ['+992', '+7', '+996', '+998', '+1'];
  bool _isPhoneEdited = false;
  bool _isWhatsAppEdited =
      false; // Новая переменная для отслеживания изменений WhatsApp

  List<CustomField> customFields = [];

  @override
  void initState() {
    super.initState();
    titleController.text = widget.leadName;
    if (widget.phone != null) {
      String phoneNumber = widget.phone!;
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
    if (widget.whatsApp != null) {
      String phoneNumber = widget.whatsApp!;
      for (var code in countryCodes) {
        if (phoneNumber.startsWith(code)) {
          setState(() {
            selectedDialCode = code;
            whatsAppController.text = phoneNumber.substring(code.length);
          });
          break;
        }
      }
      if (whatsAppController.text.isEmpty) {
        whatsAppController.text = phoneNumber;
      }

      _isPhoneEdited = false;
    }
    print(widget.sourceId);
    print('jkdbfjkwehfkjbwejnffvknfklewnr------------------------');
    if (widget.whatsApp != null) {
      String whatsAppNumber = widget.whatsApp!;
      for (var code in countryCodes) {
        if (whatsAppNumber.startsWith(code)) {
          setState(() {
            selectedWhatsAppDialCode = code;
            whatsAppController.text = whatsAppNumber.substring(code.length);
          });
          break;
        }
      }
      if (whatsAppController.text.isEmpty) {
        whatsAppController.text = whatsAppNumber;
      }
      _isWhatsAppEdited = false;
    }

    instaLoginController.text = widget.instagram ?? '';
    facebookLoginController.text = widget.facebook ?? '';
    telegramController.text = widget.telegram ?? '';
    birthdayController.text = widget.birthday ?? '';
    emailController.text = widget.email ?? '';
    descriptionController.text = widget.description ?? '';
    selectedRegion = widget.region;
    selectedSource = widget.sourceId;
    selectedManager = widget.manager;
    for (var customField in widget.leadCustomFields) {
      customFields.add(CustomField(fieldName: customField.key)
        ..controller.text = customField.value);
    }
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetAllRegionBloc>().add(GetAllRegionEv());
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
        centerTitle: false,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: const Text(
          'Редактирование лида',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      body: BlocListener<LeadBloc, LeadState>(
        listener: (context, state) {
          if (state is LeadError) {
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
            Navigator.pop(context, true);
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
                        validator: (value) => value!.isEmpty
                            ? 'Поле обязательно для заполнения'
                            : null,
                      ),
                      CustomPhoneNumberInput(
                        controller: phoneController,
                        selectedDialCode: selectedDialCode,
                        onInputChanged: (String number) {
                          setState(() {
                            _isPhoneEdited = true;
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
                        selectedSourceLead: selectedSource,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedSource = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: instaLoginController,
                        hintText: 'Введите логин Instagram',
                        label: 'Instagram',
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: facebookLoginController,
                        hintText: 'Введите логин Facebook',
                        label: 'Facebook',
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: telegramController,
                        hintText: 'Введите логин Telegram',
                        label: 'Telegram',
                      ),
                      const SizedBox(height: 8),
                      CustomPhoneNumberInput(
                        controller: whatsAppController,
                        selectedDialCode:
                            selectedWhatsAppDialCode, // Используем отдельный код страны для WhatsApp
                        onInputChanged: (String number) {
                          setState(() {
                            _isWhatsAppEdited = true;
                            selectedWhatsAppDialCode = number;
                          });
                        },
                        label: 'WhatsApp',
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
                      const SizedBox(height: 20),
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
                        buttonColor: const Color(0xffF4F7FD),
                        textColor: Colors.black,
                        onPressed: () => Navigator.pop(context, null),
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
                              buttonText: 'Сохранить',
                              buttonColor: const Color(0xff4759FF),
                              textColor: Colors.white,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  String phoneToSend;
                                  String whatsAppToSend;

                                  if (_isPhoneEdited) {
                                    phoneToSend = selectedDialCode;
                                  } else {
                                    phoneToSend =
                                        '$selectedDialCode${phoneController.text}';
                                  }
                                  if (_isWhatsAppEdited) {
                                    whatsAppToSend = selectedWhatsAppDialCode;
                                  } else {
                                    whatsAppToSend = whatsAppController
                                            .text.isNotEmpty
                                        ? '$selectedWhatsAppDialCode${whatsAppController.text}'
                                        : ''; // Если поле пустое, отправляем пустую строку
                                  }
                                  DateTime? parsedBirthday;

                                  if (birthdayController.text.isNotEmpty) {
                                    try {
                                      parsedBirthday = DateFormat('dd/MM/yyyy')
                                          .parseStrict(birthdayController.text);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                              'Ошибка ввода даты роджения. Пожалуйста, используйте формат DD/MM/YYYY.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                  List<Map<String, String>> customFieldList =
                                      [];
                                  for (var field in customFields) {
                                    String fieldName = field.fieldName.trim();

                                    String fieldValue =
                                        field.controller.text.trim();
                                    if (fieldName.isNotEmpty &&
                                        fieldValue.isNotEmpty) {
                                      customFieldList
                                          .add({fieldName: fieldValue});
                                    }
                                  }
                                  final leadBloc = context.read<LeadBloc>();
                                  context
                                      .read<LeadBloc>()
                                      .add(FetchLeadStatuses());
                                  leadBloc.add(UpdateLead(
                                    leadId: widget.leadId,
                                    name: titleController.text,
                                    phone: phoneToSend,
                                    waPhone:
                                        whatsAppToSend, // Теперь передаем отдельный номер для WhatsApp
                                    regionId: selectedRegion != null
                                        ? int.parse(selectedRegion!)
                                        : null,
                                    managerId: selectedManager != null
                                        ? int.parse(selectedManager!)
                                        : null,
                                    sourseId: selectedSource != null
                                        ? int.parse(selectedSource!)
                                        : null,
                                    instaLogin: instaLoginController.text,
                                    facebookLogin: facebookLoginController.text,
                                    tgNick: telegramController.text,
                                    birthday: parsedBirthday,
                                    email: emailController.text,
                                    description: descriptionController.text,
                                    leadStatusId: widget.statusId,
                                    customFields: customFieldList,
                                  ));
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
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Colors.red,
                                      elevation: 3,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      duration: Duration(seconds: 3),
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
