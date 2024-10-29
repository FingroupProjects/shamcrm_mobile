import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/bloc/region/region_bloc.dart';
import 'package:crm_task_manager/bloc/region/region_event.dart';
import 'package:crm_task_manager/screens/lead/tabBar/region_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';

class LeadEditScreen extends StatefulWidget {
  final int leadId;
  final String leadName;
  final String leadStatus;
  final String? region;
  final String? birthday;
  final String? instagram;
  final String? facebook;
  final String? telegram;
  final String? phone;
  final String? description;

  LeadEditScreen({
    required this.leadId,
    required this.leadName,
    required this.leadStatus,
    this.region,
    this.birthday,
    this.instagram,
    this.facebook,
    this.telegram,
    this.phone,
    this.description,
  });

  @override
  _LeadEditScreenState createState() => _LeadEditScreenState();
}

class _LeadEditScreenState extends State<LeadEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController instaLoginController = TextEditingController();
  final TextEditingController facebookLoginController = TextEditingController();
  final TextEditingController telegramController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedRegion;
  String selectedDialCode = '';

  @override
  void initState() {
    super.initState();
    titleController.text = widget.leadName;
    phoneController.text = widget.phone ?? '';
    instaLoginController.text = widget.instagram ?? '';
    facebookLoginController.text = widget.facebook ?? '';
    telegramController.text = widget.telegram ?? '';
    birthdayController.text = widget.birthday ?? '';
    descriptionController.text = widget.description ?? '';

    selectedRegion = widget.region;

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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Редактирование Лида',
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
                content: Text(state.message),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          }
          // else if (state is LeadUpdated) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text('Лид успешно обновлен'),
          //       duration: Duration(seconds: 3),
          //       backgroundColor: Colors.green,
          //     ),
          //   );
          //   Navigator.pop(context);
          // }
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
                      const SizedBox(height: 8),
                      CustomPhoneNumberInput(
                        controller: phoneController,
                        onInputChanged: (String number) {
                          setState(() => selectedDialCode = number);
                        },
                        validator: (value) => value!.isEmpty
                            ? 'Поле обязательно для заполнения'
                            : null,
                        label: 'Телефон',
                      ),
                      const SizedBox(height: 8),
                      // Добавление RegionWidget для выбора региона
                      RegionWidget(
                        selectedRegion: selectedRegion,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedRegion = newValue; // Обновляем состояние
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        buttonText: 'Сохранить',
                        buttonColor: Color(0xff4759FF),
                        textColor: Colors.white,
                        onPressed: () {
                          // if (_formKey.currentState!.validate()) {
                          //   final leadBloc = context.read<LeadBloc>();
                          //   leadBloc.add(UpdateLead(
                          //     id: widget.leadId,
                          //     name: titleController.text,
                          //     phone: selectedDialCode,
                          //     regionId: selectedRegion != null ? int.parse(selectedRegion!) : null,
                          //     instaLogin: instaLoginController.text,
                          //     facebookLogin: facebookLoginController.text,
                          //     tgNick: telegramController.text,
                          //     birthday: birthdayController.text.isNotEmpty
                          //         ? DateFormat('dd/MM/yyyy').parse(birthdayController.text)
                          //         : null,
                          //     description: descriptionController.text,
                          //   ));
                          // }
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
