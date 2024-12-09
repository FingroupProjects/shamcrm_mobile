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
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
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
  final TextEditingController userController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  
  File? _profileImage;
  String selectedDialCode = '';
  String? _selectedOrganization;
  String _userImage = '';
  File? _localImage;
  final ImagePicker _picker = ImagePicker();

  // Функция для выбора изображения с улучшенной обработкой
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выборе изображения: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Объединенный метод загрузки данных
    context.read<OrganizationBloc>().add(FetchOrganizations());
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userID') ?? 'Не найдено';

    // Загрузка данных из SharedPreferences
    String ULogin = prefs.getString('userLogin') ?? 'Не найдено';
    String UName = prefs.getString('userName') ?? 'Не найдено';
    String UPhone = prefs.getString('userPhone') ?? 'Не найдено';
    String UEmail = prefs.getString('userEmail') ?? 'Не найдено';
    String URoleName = prefs.getString('userRoleName') ?? 'Не найдено';
    String UImage = prefs.getString('userImage') ?? 'Не найдено';

    // Загрузка данных через API
    try {
      UserByIdProfile userProfile = await ApiService().getUserById(userId as int);
      
      setState(() {
        // Приоритет данным из API
        loginController.text = ULogin;
        userController.text = userId;
        phoneController.text = userProfile.phone.isNotEmpty ? userProfile.phone : UPhone;
        fullNameController.text = userProfile.name.isNotEmpty ? userProfile.name : UName;
        emailController.text = userProfile.email.isNotEmpty ? userProfile.email : UEmail;
        roleController.text = URoleName;
        _userImage = userProfile.image?.isNotEmpty == true ? userProfile.image! : UImage;

        print('ImageSVG: $_userImage');
        print('UUUID: $userId');
      });
    } catch (e) {
      // Если API не сработал, используем данные из SharedPreferences
      setState(() {
        loginController.text = ULogin;
        userController.text = userId;
        phoneController.text = UPhone;
        fullNameController.text = UName;
        emailController.text = UEmail;
        roleController.text = URoleName;
        _userImage = UImage;

        print('ImageSVG: $_userImage');
        print('UUUID: $userId');
      });
      print('Ошибка загрузки профиля: $e');
    }

    // Загрузка организации
    await _loadSelectedOrganization();
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


  // Выбор изображения из галереи или камеры
  Future<void> _showImagePickerDialog() async {
    final XFile? pickedFile = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Галерея'),
              onTap: () async {
                final file =
                    await _picker.pickImage(source: ImageSource.gallery);
                Navigator.of(context).pop(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Камера'),
              onTap: () async {
                final file =
                    await _picker.pickImage(source: ImageSource.camera);
                Navigator.of(context).pop(file);
              },
            ),
          ],
        ),
      ),
    );

    if (pickedFile != null) {
      setState(() {
        _localImage = File(pickedFile.path);
        _userImage = ''; // Очищаем строку SVG или URL
      });
    }
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
                      _localImage != null
                          ? CircleAvatar(
                              radius: 70,
                              backgroundImage: FileImage(_localImage!),
                            )
                          : _userImage != 'Не найдено' && _userImage.isNotEmpty
                              ? _userImage.trim().startsWith('<svg')
                                  ? Container(
                                      width: 140,
                                      height: 140,
                                      child: SvgPicture.string(
                                        _userImage,
                                        placeholderBuilder:
                                            (BuildContext context) => Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    )
                                  : _userImage.endsWith('.png') ||
                                          _userImage.endsWith('.jpg') ||
                                          _userImage.endsWith('.jpeg')
                                      ? Container(
                                          width: 140,
                                          height: 140,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(70),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                  _userImage), // Замените на `FileImage` для локальных файлов
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      : CircleAvatar(
                                          radius: 70,
                                          backgroundColor: Colors.grey[300],
                                          child: Icon(
                                            Icons.person,
                                            size: 100,
                                            color: const Color.fromARGB(
                                                255, 255, 255, 255),
                                          ),
                                        )
                              : CircleAvatar(
                                  radius: 70,
                                  backgroundColor: Colors.grey[300],
                                  child: Icon(
                                    Icons.person,
                                    size: 100,
                                    color: const Color.fromARGB(
                                        255, 255, 255, 255),
                                  ),
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
                          _userImage == 'Не найдено' || _userImage.isEmpty
                              ? 'Сменить фото'
                              : 'Сменить фото',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
                readOnly: true,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: loginController,
                hintText: 'Введите логин',
                label: 'Логин',
                readOnly: true,
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
                onPressed: () async {
                  // Извлечение UUID из SharedPreferences
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  String UUID = prefs.getString('userID') ?? '';

                  // Проверка, если UUID не найден
                  if (UUID.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Ошибка: UUID не найден в SharedPreferences')),
                    );
                    return;
                  }

                  try {
                    // Преобразование UUID в int
                    int userId = int.parse(UUID);
                    // Получение данных из контроллеров
                    final name = fullNameController.text;
                    final phone = phoneController.text;
                    final email = emailController.text;
                    // final login = loginController.text;
                    // final role = roleController.text;
                    final image = _userImage;

                    // Передача userId как int
                    context.read<ProfileBloc>().add(UpdateProfile(
                        userId: userId, // Передаем преобразованный userId
                        name: name,
                        phone: phone,
                        email: email,
                        // login: login,
                        // role: role,
                        image: image));
                  } catch (e) {
                    // Если UUID не удалось преобразовать в int
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Ошибка: UUID имеет некорректный формат')),
                    );
                  }
                },
                child: Text('Сохранить', style: TextStyle(color: Colors.white)),
              ),

              BlocListener<ProfileBloc, ProfileState>(
                listener: (context, state) {
                  if (state is ProfileSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    ); // Закрываем окно
                    Navigator.pop(context);
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
