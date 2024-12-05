import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileEditPage extends StatefulWidget {
  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController organizationController = TextEditingController();
  final TextEditingController loginController = TextEditingController();
  File? _profileImage; // Переменная для хранения изображения профиля

  final ImagePicker _picker = ImagePicker();

  // Функция для выбора изображения из камеры или галереи
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 100, // Устанавливаем качество изображения (0-100)
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выберите источник изображения'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Камера'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.image),
                title: Text('Галерея'),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Фото пользователя
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
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
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: ElevatedButton(
                        onPressed: _showImagePickerDialog,
                        child: Text('Сменить фото', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Поля для редактирования профиля
              const SizedBox(height: 8),
              CustomTextField(
                controller: fullNameController,
                hintText: 'Введите ФИО',
                label: 'ФИО',
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: phoneController,
                hintText: 'Введите телефон',
                label: 'Телефон',
                keyboardType: TextInputType.phone,
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
              SizedBox(height: 20),
              // Кнопка сохранения изменений
              ElevatedButton(
                onPressed: () {
                  // Действие для сохранения изменений
                },
                child: Text('Сохранить', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
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
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // Действие для перехода на страницу редактирования профиля
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => ProfileEditPage()));
      },
      icon: Icon(Icons.edit),
      label: Text('Редактировать профиль'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: TextStyle(fontSize: 16),
      ),
    );
  }
}
