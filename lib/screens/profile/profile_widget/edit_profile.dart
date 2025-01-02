import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_event.dart';
import 'package:crm_task_manager/bloc/organization/organization_state.dart';
import 'package:crm_task_manager/bloc/profile/profile_bloc.dart';
import 'package:crm_task_manager/bloc/profile/profile_event.dart';
import 'package:crm_task_manager/bloc/profile/profile_state.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_edit_profile.dart';
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
  final TextEditingController NameController = TextEditingController();
  final TextEditingController SurnameController = TextEditingController();
  final TextEditingController PatronymicController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController loginController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  File? _profileImage;
  String? _selectedOrganization;
  String _userImage = '';
  File? _localImage;
  final ImagePicker _picker = ImagePicker();
  // Добавляем переменные для хранения ошибок
  String? _nameError;
  String? _surnameError;
  String? _phoneError;
  String? _emailError;
  bool _isLoading = true; // Add loading state
bool _isButtonLoading = false; // Добавляем состояние загрузки кнопки

  final TextEditingController phoneController = TextEditingController();
  String selectedDialCode = ''; // Default country code
  List<String> countryCodes = [
    '+992',
    '+7',
    '+996',
    '+998',
    '+1'
  ]; // Country codes list
  // Функция валидации email
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    // Extract country code from phone if necessary
  }

  bool isValidName(String name) {
    return name.trim().isNotEmpty && name.length >= 2;
  }

  String? _getImageToUpload() {
    // Если есть локально выбранное изображение
    if (_localImage != null) {
      return _localImage!.path;
    }
    // Если существующее изображение имеет расширения png, jpeg, jpg, img
    if (_userImage.endsWith('.png') ||
        _userImage.endsWith('.jpg') ||
        _userImage.endsWith('.jpeg') ||
        _userImage.endsWith('.img')) {
      return _userImage;
    }

    // Для SVG или других форматов возвращаем null
    return null;
  }

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
        final file = File(pickedFile.path);

        // Проверяем размер файла асинхронно
        final int fileSize = await file.length();

        if (fileSize > 2 * 1024 * 1024) {
          // Если размер больше 2 MB
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Выбранный файл слишком большой.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return; // Прекращаем выполнение, если файл слишком большой
        }

        // Если файл подходит по размеру
        setState(() {
          _profileImage = file;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Изображение успешно выбрано!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при выборе изображения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
    _loadInitialData();

    _loadSelectedOrganization();
    context.read<OrganizationBloc>().add(FetchOrganizations());
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadUserPhone(),
        _loadSelectedOrganization(),
      ]);
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserPhone() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String UUID = prefs.getString('userID') ?? 'Не найдено';
    String ULogin = prefs.getString('userLogin') ?? 'Не найдено';
    String URoleName = prefs.getString('userRoleName') ?? 'Не найдено';

    setState(() {
      userController.text = UUID;
      loginController.text = ULogin;
      roleController.text = URoleName;
    });

    try {
      UserByIdProfile userProfile =
          await ApiService().getUserById(int.parse(UUID));
      // Обработка телефона
      String phoneNumber = userProfile.phone ?? '';
      String detectedDialCode = '+7';
      String phoneWithoutCode = phoneNumber;

      // Проверяем код страны в полученном номере
      for (var country in countries) {
        if (phoneNumber.startsWith(country.dialCode)) {
          detectedDialCode = country.dialCode;
          phoneWithoutCode = phoneNumber.substring(country.dialCode.length);
          break;
        }
      }
      setState(() {
        NameController.text = userProfile.name;
        SurnameController.text = userProfile.lastname;
        PatronymicController.text = userProfile.Pname;
        emailController.text = userProfile.email;
        selectedDialCode = detectedDialCode;
        phoneController.text = phoneWithoutCode;
        _userImage = userProfile.image ?? '';
      });
    } catch (e) {
      print('Ошибка при загрузке данных из API: $e');
    }
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

  Future<void> _showImagePickerDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Галерея'),
              onTap: () async {
                // Показываем диалог загрузки
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return Dialog(
                      backgroundColor: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: Color(0xff1E2E52),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Проверка изображения...',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );

                final XFile? pickedFile = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                  maxWidth: 1080,
                  maxHeight: 1080,
                );

                if (pickedFile != null) {
                  try {
                    final file = File(pickedFile.path);
                    final int fileSize = await file.length();

                    // Закрываем диалог загрузки
                    Navigator.of(context).pop();

                    if (fileSize > 2 * 1024 * 1024) {
                      Navigator.pop(context); // Закрываем модальное окно выбора
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Файл слишком большой. Максимальный размер — 2 MB.'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          duration: Duration(seconds: 3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _localImage = file;
                      _userImage = '';
                    });

                    Navigator.pop(context); // Закрываем модальное окно выбора
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Изображение успешно выбрано!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        duration: Duration(seconds: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    );
                  } catch (e) {
                    // Закрываем диалог загрузки, если он еще открыт
                    Navigator.of(context).pop();
                    Navigator.pop(context); // Закрываем модальное окно выбора
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка при выборе изображения: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    );
                  }
                } else {
                  // Если пользователь отменил выбор, закрываем диалог загрузки
                  Navigator.of(context).pop();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Камера'),
              onTap: () async {
                // Показываем диалог загрузки
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return Dialog(
                      backgroundColor: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: Color(0xff1E2E52),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Проверка изображения...',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );

                final XFile? pickedFile = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                  maxWidth: 1080,
                  maxHeight: 1080,
                );

                if (pickedFile != null) {
                  try {
                    final file = File(pickedFile.path);
                    final int fileSize = await file.length();

                    // Закрываем диалог загрузки
                    Navigator.of(context).pop();

                    if (fileSize > 2 * 1024 * 1024) {
                      Navigator.pop(context); // Закрываем модальное окно выбора
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Файл слишком большой. Максимальный размер — 2 MB.'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          duration: Duration(seconds: 3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _localImage = file;
                      _userImage = '';
                    });

                    Navigator.pop(context); // Закрываем модальное окно выбора
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Изображение успешно выбрано!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        duration: Duration(seconds: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    );
                  } catch (e) {
                    // Закрываем диалог загрузки, если он еще открыт
                    Navigator.of(context).pop();
                    Navigator.pop(context); // Закрываем модальное окно выбора
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка при выборе изображения: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    );
                  }
                } else {
                  // Если пользователь отменил выбор, закрываем диалог загрузки
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Функция для извлечения URL из SVG
    String? extractImageUrlFromSvg(String svg) {
      if (svg.contains('href="')) {
        final start = svg.indexOf('href="') + 6;
        final end = svg.indexOf('"', start);
        return svg.substring(start, end);
      }
      return null;
    }

    return Scaffold(
        appBar: AppBar(
          title: Text('Редактирование профиля',
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              )),
          centerTitle: false,
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
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: const Color(0xff1E2E52),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    _localImage != null
                                        ? CircleAvatar(
                                            radius: 70,
                                            backgroundImage:
                                                FileImage(_localImage!),
                                          )
                                        : _userImage != 'Не найдено' &&
                                                _userImage.isNotEmpty
                                            ? _userImage.contains('<svg')
                                                ? Container(
                                                    width: 140,
                                                    height: 140,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      image: DecorationImage(
                                                        image: NetworkImage(
                                                          extractImageUrlFromSvg(
                                                                  _userImage) ??
                                                              '',
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    width: 140,
                                                    height: 140,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              70),
                                                      image: DecorationImage(
                                                        image: NetworkImage(
                                                            _userImage),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  )
                                            : CircleAvatar(
                                                radius: 70,
                                                backgroundColor:
                                                    Colors.grey[300],
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
                                        backgroundColor:
                                            const Color(0xff1E2E52),
                                      ),
                                      child: Text(
                                        _userImage == 'Не найдено' ||
                                                _userImage.isEmpty
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
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: NameController,
                              hintText: 'Введите Имя',
                              label: 'Имя',
                              onChanged: (value) {
                                setState(() {
                                  _nameError = null;
                                });
                              },
                            ),
                            if (_nameError != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4, left: 12),
                                  child: Text(
                                    _nameError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontFamily: 'Gilroy',
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: SurnameController,
                              hintText: 'Введите Фамилию',
                              label: 'Фамилия',
                              onChanged: (value) {
                                setState(() {
                                  _surnameError = null;
                                });
                              },
                            ),
                            if (_surnameError != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4, left: 12),
                                  child: Text(
                                    _surnameError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontFamily: 'Gilroy',
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            CustomPhoneNumberInput(
                              controller: phoneController,
                              selectedDialCode: selectedDialCode,
                              onInputChanged: (String number) {
                                for (var country in countries) {
                                  if (number.startsWith(country.dialCode)) {
                                    setState(() {
                                      selectedDialCode = country.dialCode;
                                    });
                                    break;
                                  }
                                }
                              },
                              validator: (value) => value!.isEmpty
                                  ? 'Поле обязательно для заполнения'
                                  : null,
                              label: 'Телефон',
                            ),
                            if (_phoneError != null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 4, right: 75),
                                child: Text(
                                  _phoneError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontFamily: 'Gilroy',
                                  ),
                                ),
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
                              onChanged: (value) {
                                setState(() {
                                  _emailError = null;
                                });
                              },
                            ),
                            if (_emailError != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4, left: 12),
                                  child: Text(
                                    _emailError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontFamily: 'Gilroy',
                                    ),
                                  ),
                                ),
                              ),
                            BlocListener<ProfileBloc, ProfileState>(
                              listener: (context, state) {
                                if (state is ProfileSuccess) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Профиль успешно обновлен!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Gilroy',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Colors.green,
                                      elevation: 3,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                  Navigator.pop(context);
                                } else if (state is ProfileError) {
                                  String message;

                                  if (state.message.contains('500')) {
                                    message =
                                        'Ошибка на сервере. Попробуйте позже.';
                                  } else if (state.message.contains('422')) {
                                    message = 'Проверьте введенные данные';
                                  } else if (state.message.contains('404')) {
                                    message = 'Ресурс не найден';
                                  } else {
                                    message =
                                        'Произошла ошибка при обновлении профиля';
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        message,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Gilroy',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
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
                              child: Container(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1E2E52),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            minimumSize: Size(double.infinity, 48),
                          ),
                          onPressed: _isButtonLoading
                              ? null
                              : () async {
                                  // Сбрасываем состояние ошибок
                                  setState(() {
                                    _isButtonLoading =
                                        true; // Устанавливаем состояние загрузки
                                    _nameError = null;
                                    _surnameError = null;
                                    _phoneError = null;
                                    _emailError = null;
                                  });

                                  // Проверяем валидацию
                                  bool isValid = true;

                                  if (NameController.text.trim().isEmpty) {
                                    setState(() {
                                      _nameError =
                                          'Поле имя обязательно для заполнения';
                                    });
                                    isValid = false;
                                  }

                                  if (SurnameController.text.trim().isEmpty) {
                                    setState(() {
                                      _surnameError =
                                          'Поле фамилия обязательно для заполнения';
                                    });
                                    isValid = false;
                                  }

                                  if (emailController.text.trim().isNotEmpty &&
                                      !isValidEmail(
                                          emailController.text.trim())) {
                                    setState(() {
                                      _emailError =
                                          'Введите корректный email адрес';
                                    });
                                    isValid = false;
                                  }

                                  if (!isValid) {
                                    setState(() {
                                      _isButtonLoading =
                                          false; // Снимаем состояние загрузки
                                    });
                                    return;
                                  }

                                  try {
                                    SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    String UUID =
                                        prefs.getString('userID') ?? '';

                                    if (UUID.isEmpty) {
                                      _showErrorMessage(
                                          'Ошибка: UUID не найден');
                                      setState(() {
                                        _isButtonLoading =
                                            false; // Снимаем состояние загрузки
                                      });
                                      return;
                                    }

                                    String UserNameProfile =
                                        NameController.text;
                                    await prefs.setString(
                                        'userNameProfile', UserNameProfile);

                                    int userId = int.parse(UUID);
                                    final image = _getImageToUpload();
                                    context.read<ProfileBloc>().add(
                                        UpdateProfile(
                                            userId: userId,
                                            name: NameController.text.trim(),
                                            sname:
                                                SurnameController.text.trim(),
                                            phone: selectedDialCode +
                                                phoneController.text,
                                            email: emailController.text.trim(),
                                            image: image,
                                            pname: ''));
                                  } catch (e) {
                                    _showErrorMessage(
                                        'Произошла ошибка при обновлении профиля');
                                    setState(() {
                                      _isButtonLoading =
                                          false; // Снимаем состояние загрузки
                                    });
                                  }
                                },
                          child: _isButtonLoading
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color:const Color(0xff1E2E52),

                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(
                                  'Сохранить',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ));
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            fontSize: 14,
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
