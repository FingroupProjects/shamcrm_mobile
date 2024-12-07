import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_event.dart';
import 'package:crm_task_manager/bloc/organization/organization_state.dart';
import 'package:crm_task_manager/bloc/profile/profile_bloc.dart';
import 'package:crm_task_manager/bloc/profile/profile_event.dart';
import 'package:crm_task_manager/bloc/profile/profile_state.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({Key? key}) : super(key: key);

  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController loginController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController imageController =
      TextEditingController(); // Контроллер для изображения
  File? _profileImage;
  String selectedDialCode = '';
  String? _selectedOrganization;

  final ImagePicker _picker = ImagePicker();

  // Функция для выбора изображения с улучшенной обработкой
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Можно отрегулировать качество
        maxWidth: 1080, // Ограничение максимальной ширины
        maxHeight: 1080, // Ограничение максимальной высоты
      );
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Обработка возможных ошибок
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выборе изображения: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserPhone(); // Вызов асинхронного метода
    _loadSelectedOrganization();
    context.read<OrganizationBloc>().add(FetchOrganizations());
  }

  Future<void> _loadSelectedOrganization() async {
    final savedOrganization = await ApiService().getSelectedOrganization();
    if (savedOrganization == null) {
      final firstOrganization = await _getFirstOrganization();
      if (firstOrganization != null) {
        _onOrganizationChanged(firstOrganization);
      }
    } else {
      setState(() {
        _selectedOrganization = savedOrganization;
      });
    }
  }

  Future<String?> _getFirstOrganization() async {
    final state = context.read<OrganizationBloc>().state;
    if (state is OrganizationLoaded && state.organizations.isNotEmpty) {
      return state.organizations.first.id.toString();
    }
    return null;
  }

  void _onOrganizationChanged(String? newOrganization) {
    setState(() {
      _selectedOrganization = newOrganization;
    });

    if (newOrganization != null) {
      ApiService().saveSelectedOrganization(newOrganization);
    }
  }

  void _loadUserPhone() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String UUID = prefs.getString('userId') ?? 'Не найдено';
    String UPhone = prefs.getString('userPhone') ?? 'Не найдено';
    String UName = prefs.getString('userName') ?? 'Не найдено';
    String ULogin = prefs.getString('userLogin') ?? 'Не найдено';
    String UImage = prefs.getString('userImage') ?? 'Не найдено';
    String UEmail = prefs.getString('userEmail') ?? 'Не найдено';
    String URoleName = prefs.getString('userRoleName') ?? 'Не найдено';

    // Установка данных в контроллеры
    loginController.text = ULogin;
    phoneController.text = UPhone;
    fullNameController.text = UName;
    emailController.text = UEmail;
    roleController.text = URoleName;
    imageController.text =
        UImage; // Установка значения в контроллер для изображения

    print('ImageSVG: $UImage');
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите источник изображения'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Камера'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Галерея'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              
            ],
          ),
          backgroundColor: Color.fromARGB(255,255, 255, 255),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Редактирование профиля'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Фото пользователя
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (imageController.text != 'Не найдено'
                                ? NetworkImage(imageController.text)
                                : null),
                        child: _profileImage == null &&
                                (imageController.text == 'Не найдено' ||
                                    imageController.text.isEmpty)
                            ? Icon(
                                Icons.person,
                                size: 100,
                                color: const Color.fromARGB(255, 255, 255, 255),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _showImagePickerDialog,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          backgroundColor: const Color(0xff1E2E52),
                        ),
                        child: Text(
                          _profileImage == null
                              ? 'Установить фото'
                              : 'Сменить фото',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Остальной код интерфейса
              CustomTextField(
                controller: fullNameController,
                hintText: 'Введите ФИО',
                label: 'ФИО',
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
              CustomTextField(
                controller: roleController,
                hintText: 'Введите роль',
                label: 'Роль',
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: loginController,
                hintText: 'Введите логин',
                label: 'Логин',
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: emailController,
                hintText: 'Введите электронную почту',
                label: 'Электронная почта',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1E2E52), // Цвет фона кнопки
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8), // Отступы
                ),
                onPressed: () {
                  final name = fullNameController.text;
                  final phone = phoneController.text;
                  final email = emailController.text;
                  final login = loginController.text;
                  final role = roleController.text;

                  context.read<ProfileBloc>().add(UpdateProfile(
                        userId: 1,
                        name: name,
                        phone: phone,
                        email: email,
                        login: login,
                        role: role,
                      ));
                },
                child: Text('Сохранить', style: TextStyle(color: Colors.white)),
              ),

              BlocListener<ProfileBloc, ProfileState>(
                listener: (context, state) {
                  if (state is ProfileSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  } else if (state is ProfileError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                child: Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
