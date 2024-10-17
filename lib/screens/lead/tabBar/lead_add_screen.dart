import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';

class LeadAddScreen extends StatelessWidget {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final int statusId; // Добавляем параметр для получения статус ID
  final TextEditingController instaLoginController = TextEditingController();
  final TextEditingController facebookLoginController = TextEditingController();
  final TextEditingController tgNickController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Добавляем переменную для выбранного значения списка
  String? selectedOption;

  LeadAddScreen({required this.statusId}); // Конструктор принимает statusId

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Row(
          children: [
            Text(
              'Создание Лида',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ],
        ),
      ),
      body: Column(
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
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: phoneController,
                    hintText: 'Введите номер телефона',
                    label: 'Телефон',
                    keyboardType: TextInputType.phone, // Устанавливаем тип клавиатуры
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ], // Позволяем вводить только цифры
                  ),
                  const SizedBox(height: 8),
                  // Dropdown для выбора опции
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Для выравнивания по левому краю
                    children: [
                      const Text(
                        'Регион', // Ваше название или лейбл
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xfff1E2E52),
                        ),
                      ),
                      const SizedBox(height: 4), // Отступ между лейблом и выпадающим списком
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF4F7FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedOption,
                          hint: const Text(
                            'Выберите опцию',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Gilroy',
                              color: Color(0xfff1E2E52),
                            ),
                          ),
                          items: <String>['Опция 1', 'Опция 2', 'Опция 3']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            // setState(() {
                            //   selectedOption = newValue; // Сохраняем выбранное значение
                            // });
                          },
                          decoration: InputDecoration(
                            labelStyle: TextStyle(
                              color: Colors.grey, // Цвет текста заголовка
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFF4F7FD), // Цвет рамки
                              ),
                              borderRadius: BorderRadius.circular(8), // Скругление углов рамки
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFF4F7FD), // Цвет рамки при активном состоянии
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFF4F7FD), // Цвет рамки при фокусе
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          dropdownColor: Colors.white,
                          icon: Image.asset(
                            'assets/icons/tabBar/dropdown.png', // Путь к вашему значку
                            width: 16, // Укажите нужную ширину
                            height: 16, // Укажите нужную высоту
                          ),
                        ),
                      ),
                    ],
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
                  CustomTextField(
                    controller: birthdayController,
                    hintText: 'Введите дату рождения',
                    label: 'Дата рождения',
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: descriptionController,
                    hintText: 'Введите описание',
                    label: 'Описание',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Контейнер для кнопок "Отмена" и "Добавить"
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
                      Navigator.pop(context);
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
                      final String name = titleController.text;
                      final String phone = phoneController.text;

                      // Используем переданный statusId и выбранную опцию
                      context.read<LeadBloc>().add(CreateLead(
                            name: name,
                            leadStatusId: statusId, // Передаем statusId
                            phone: phone,
                            // selectedOption: selectedOption, // Передаем выбранное значение
                          ));

                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
