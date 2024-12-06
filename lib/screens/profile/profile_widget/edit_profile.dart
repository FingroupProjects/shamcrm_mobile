import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({Key? key}) : super(key: key);

  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController organizationController = TextEditingController();
  final TextEditingController loginController = TextEditingController();
  File? _profileImage;
  String selectedDialCode = '';

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

  // Диалоговое окно для выбора источника изображения
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
        icon: Icon(Icons.arrow_back), // Иконка стрелки назад
        onPressed: () {
          Navigator.pop(context); // Возвращает пользователя на предыдущий экран
        },
      ),
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
                            : null,
                        child: _profileImage == null
                            ? Icon(
                                Icons.person,
                                size: 100,
                                color: Colors.grey[600],
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
              // Поля для редактирования профиля
              const SizedBox(height: 8),
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
                controller: organizationController,
                hintText: 'Введите организацию',
                label: 'Организация',
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: loginController,
                hintText: 'Введите логин',
                label: 'Логин',
              ),
              const SizedBox(height: 20),
              // Кнопка сохранения изменений
              ElevatedButton(
                onPressed: () {
                  // Действие для сохранения изменений
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric( horizontal: 16, vertical: 8),
                  backgroundColor: Color(0xff1E2E52), // Цвет фона кнопки
                  foregroundColor: Colors.white, // Цвет текста
                ),
                child: const Text(
                  'Сохранить',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileButton extends StatelessWidget {
  const ProfileButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // Действие для перехода на страницу редактирования профиля
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ProfileEditPage()));
      },
      icon: const Icon(Icons.edit),
      label: const Text('Редактировать профиль'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }
}
