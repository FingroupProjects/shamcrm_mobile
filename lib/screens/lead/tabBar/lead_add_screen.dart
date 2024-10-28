import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/region/region_bloc.dart';
import 'package:crm_task_manager/bloc/region/region_event.dart';
import 'package:crm_task_manager/bloc/region/region_state.dart';
import 'package:crm_task_manager/models/region_model.dart';
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
  final TextEditingController descriptionController = TextEditingController();

  String? selectedRegion;
  String selectedDialCode = ''; // Для хранения кода страны
  String selectedDialCodeWhatsapp = ''; 

  @override
  void initState() {
    super.initState();
    context.read<RegionBloc>().add(FetchRegions());
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
              'Создание Лида',
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
            // Show a SnackBar with the error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is LeadSuccess) {
            // Show a SnackBar with the success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.green,
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
                      BlocBuilder<RegionBloc, RegionState>(
                        builder: (context, state) {
                          List<DropdownMenuItem<String>> dropdownItems = [];

                          if (state is RegionLoading) {
                            dropdownItems = [
                              DropdownMenuItem(
                                value: null,
                                child: Text(
                                  'Загрузка...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Gilroy',
                                    color: Color(0xff1E2E52),
                                  ),
                                ),
                              ),
                            ];
                          } else if (state is RegionLoaded) {
                            dropdownItems = state.regions
                                .map<DropdownMenuItem<String>>((Region region) {
                              return DropdownMenuItem<String>(
                                value: region.id.toString(),
                                child: Text(region.name),
                              );
                            }).toList();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Регион',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Gilroy',
                                  color: Color(0xff1E2E52),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFF4F7FD),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: selectedRegion,
                                  hint: const Text(
                                    'Выберите регион',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Gilroy',
                                      color: Color(0xff1E2E52),
                                    ),
                                  ),
                                  items: dropdownItems,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedRegion = newValue;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Поле обязательно для заполнения';
                                    }
                                    return null; // Поле заполнено корректно
                                  },
                                  decoration: InputDecoration(
                                    labelStyle: TextStyle(color: Colors.grey),
                                    border: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFFF4F7FD)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFFF4F7FD)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFFF4F7FD)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  dropdownColor: Colors.white,
                                  icon: Image.asset(
                                    'assets/icons/tabBar/dropdown.png',
                                    width: 16,
                                    height: 16,
                                  ),
                                ),
                              ),
                            ],
                          );
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
                            selectedDialCodeWhatsapp =
                                number; // Сохраняем код страны
                          });
                        },
                        label: 'Whatsapp',
                      ),
                      const SizedBox(height: 8),
                      CustomTextFieldDate(
                        controller: birthdayController,
                        label: 'Дата рождения',
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: descriptionController,
                        hintText: 'Введите описание',
                        label: 'Описание',
                        maxLines: 5,
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
                      child: CustomButton(
                        buttonText: 'Добавить',
                        buttonColor: Color(0xff4759FF),
                        textColor: Colors.white,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final String name = titleController.text;
                            final String phone =
                                selectedDialCode; // Объединяем код страны и номер
                            final String? instaLogin =
                                instaLoginController.text.isEmpty
                                    ? null
                                    : instaLoginController.text;
                            final String? facebookLogin =
                                facebookLoginController.text.isEmpty
                                    ? null
                                    : facebookLoginController.text;
                            final String? tgNick = tgNickController.text.isEmpty
                                ? null
                                : tgNickController.text;
                            final String? whatsapp =
                                whatsappController.text.isEmpty ||
                                        selectedDialCodeWhatsapp.isEmpty
                                    ? null
                                    : selectedDialCodeWhatsapp;
                            final String? birthdayString =
                                birthdayController.text.isEmpty
                                    ? null
                                    : birthdayController.text;
                            final String? description =
                                descriptionController.text.isEmpty
                                    ? null
                                    : descriptionController.text;

                            DateTime? birthday;
                            if (birthdayString != null &&
                                birthdayString.isNotEmpty) {
                              try {
                                // Изменяем формат на 'dd/MM/yyyy'
                                birthday = DateFormat('dd/MM/yyyy')
                                    .parse(birthdayString);
                              } catch (e) {
                                // Если произошла ошибка при парсинге, показываем сообщение об ошибке
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Введите корректную дату рождения в формате ДД/ММ/ГГГГ')),
                                );
                                return; // Выход из метода, чтобы предотвратить отправку запроса
                              }
                            }
                            context.read<LeadBloc>().add(CreateLead(
                                  name: name,
                                  leadStatusId: widget.statusId,
                                  phone: phone, // Используем полный номер
                                  regionId: selectedRegion != null
                                      ? int.parse(selectedRegion!)
                                      : null,
                                  organizationId: 1,
                                  instaLogin: instaLogin,
                                  facebookLogin: facebookLogin,
                                  tgNick: tgNick,
                                  waPhone: whatsapp,
                                  birthday: birthday,
                                  description: description,
                                ));
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
