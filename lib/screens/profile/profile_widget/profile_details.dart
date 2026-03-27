import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_event.dart';
import 'package:crm_task_manager/bloc/organization/organization_state.dart';
import 'package:crm_task_manager/bloc/profile/profile_bloc.dart';
import 'package:crm_task_manager/bloc/profile/profile_state.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_edit_profile.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/edit_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../custom_widget/country_data_list.dart';

class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({Key? key}) : super(key: key);

  @override
  _ProfileDetailsPageState createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isButtonDisabled = false;
  bool readOnly = false;
  final TextEditingController phoneController = TextEditingController();
  String selectedDialCode = '+992'; // Default country code

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
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('file_too_large'),
              ),
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .translate('image_selected_successfully'),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('image_selection_error'),
          ),
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
      //print('Error loading initial data: $e');
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
      String detectedDialCode = '+992';
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
      //print('Ошибка при загрузке данных из API: $e');
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
              title: Text(
                AppLocalizations.of(context)!.translate('gallery'),
              ),
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
                            Text(
                              AppLocalizations.of(context)!
                                  .translate('checking_image'),
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
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!
                                .translate('file_size_limit'),
                          ),
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
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!
                              .translate('image_selected_successfully'),
                        ),
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
                        content: Text(
                          AppLocalizations.of(context)!
                              .translate('image_selection_error'),
                        ),
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
              title: Text(
                AppLocalizations.of(context)!.translate('camera'),
              ),
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
                            Text(
                              AppLocalizations.of(context)!
                                  .translate('checking_image'),
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
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!
                                .translate('file_size_limit'),
                          ),
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
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!
                              .translate('image_selected_successfully'),
                        ),
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
                        content: Text(
                          AppLocalizations.of(context)!
                              .translate('image_selection_error'),
                        ),
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
    Color? extractBackgroundColorFromSvg(String svg) {
      final fillMatch = RegExp(r'fill="(#[A-Fa-f0-9]+)"').firstMatch(svg);
      if (fillMatch != null) {
        final colorHex = fillMatch.group(1);
        if (colorHex != null) {
          final hex = colorHex.replaceAll('#', '');
          return Color(int.parse('FF$hex', radix: 16));
        }
      }
      return null;
    }

    Widget buildSvgAvatar(String svg) {
      if (svg.contains('image href=')) {
        // Извлекаем URL изображения
        final start = svg.indexOf('href="') + 6;
        final end = svg.indexOf('"', start);
        final imageUrl = svg.substring(start, end);

        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        // Извлекаем текст из SVG и цвет фона
        final text = RegExp(r'>([^<]+)</text>').firstMatch(svg)?.group(1) ?? '';
        final backgroundColor =
            extractBackgroundColorFromSvg(svg) ?? Color(0xFF2C2C2C);

        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor, // Теперь используем извлеченный цвет
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 120,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      key: _formKey,
      appBar: AppBar(
        title: Transform.translate(
          offset: const Offset(-10, 0), // Двигаем заголовок ближе к стрелке
          child: Text(
            AppLocalizations.of(context)!.translate('profile_editor'),
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        centerTitle: false, // Заголовок остаётся слева
        leading: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Transform.translate(
            offset:
                const Offset(0, -2), // Поднимаем иконку стрелки немного вверх
            child: IconButton(
              icon: Image.asset(
                'assets/icons/arrow-left.png',
                width: 24,
                height: 24,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        leadingWidth: 40, // Уменьшаем ширину области для стрелки
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/icons/edit.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProfileEditPage()),
              );
            },
          ),
        ],
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: const Color(0xff1E2E52),
              ),
            )
          : Column(children: [
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
                                    : _userImage !=
                                                AppLocalizations.of(context)!
                                                    .translate('not_found') &&
                                            _userImage.isNotEmpty
                                        ? _userImage.contains('<svg')
                                            ? buildSvgAvatar(_userImage)
                                            : Container(
                                                width: 140,
                                                height: 140,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(70),
                                                  image: DecorationImage(
                                                    image: NetworkImage(
                                                        _userImage),
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
                                          ),
                                // const SizedBox(height: 10),
                                // ElevatedButton(
                                //   onPressed: _showImagePickerDialog,
                                //   style: ElevatedButton.styleFrom(
                                //     padding: const EdgeInsets.symmetric(
                                //         horizontal: 16, vertical: 8),
                                //     backgroundColor: const Color(0xff1E2E52),
                                //   ),
                                //   child: Text(
                                //     _userImage ==
                                //                 AppLocalizations.of(context)!
                                //                     .translate('not_found') ||
                                //             _userImage.isEmpty
                                //         ? AppLocalizations.of(context)!
                                //             .translate('change_photo')
                                //         : AppLocalizations.of(context)!
                                //             .translate('change_photo'),
                                //     style: const TextStyle(
                                //       color: Colors.white,
                                //       fontSize: 16,
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: 0.8, // Прозрачность для всего виджета
                          child: CustomTextField(
                            controller: NameController,
                            hintText:
                                AppLocalizations.of(context)!.translate('name'),
                            label:
                                AppLocalizations.of(context)!.translate('name'),
                            readOnly: true,
                            onChanged: (value) {
                              setState(() {
                                _nameError = null;
                              });
                            },
                          ),
                        ),
                        if (_nameError != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4, left: 12),
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
                        Opacity(
                          opacity: 0.8, // Прозрачность для всего виджета
                          child: CustomTextField(
                            controller: SurnameController,
                            hintText: AppLocalizations.of(context)!
                                .translate('surname'),
                            label: AppLocalizations.of(context)!
                                .translate('surname'),
                            readOnly: true,
                            onChanged: (value) {
                              setState(() {
                                _surnameError = null;
                              });
                            },
                          ),
                        ),
                        if (_surnameError != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4, left: 12),
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
                        Opacity(
                          opacity: 0.8, // Прозрачность для всего виджета
                          child: CustomTextField(
                            controller: phoneController,
                            hintText: AppLocalizations.of(context)!
                                .translate('phone'),
                            label: AppLocalizations.of(context)!
                                .translate('phone'),
                            readOnly: true,
                            onChanged: (value) {
                              setState(() {
                                _surnameError = null;
                              });
                            },
                          ),
                        ),
                        if (_surnameError != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4, left: 12),
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
                        Opacity(
                          opacity: 0.8, // Прозрачность для всего виджета
                          child: CustomTextField(
                            controller: roleController,
                            hintText:
                                AppLocalizations.of(context)!.translate('role'),
                            label:
                                AppLocalizations.of(context)!.translate('role'),
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: 0.8, // Прозрачность для всего виджета
                          child: CustomTextField(
                            controller: loginController,
                            hintText: AppLocalizations.of(context)!
                                .translate('login'),
                            label: AppLocalizations.of(context)!
                                .translate('login'),
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: 0.8, // Прозрачность для всего виджета
                          child: CustomTextField(
                            controller: emailController,
                            hintText: AppLocalizations.of(context)!
                                .translate('email'),
                            label: AppLocalizations.of(context)!
                                .translate('email'),
                            readOnly: true,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) {
                              setState(() {
                                _emailError = null;
                              });
                            },
                          ),
                        ),
                        if (_emailError != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4, left: 12),
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
                                    AppLocalizations.of(context)!.translate(
                                        'profile_updated_successfully'),
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
                                message = AppLocalizations.of(context)!
                                    .translate('server_error');
                              } else if (state.message.contains('422')) {
                                message = AppLocalizations.of(context)!
                                    .translate('validation_error');
                              } else if (state.message.contains('404')) {
                                message = AppLocalizations.of(context)!
                                    .translate('resource_not_found');
                              } else {
                                message = AppLocalizations.of(context)!
                                    .translate('invalid_phone_number');
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
                // padding: const EdgeInsets.all(16.0),
                // child: BlocBuilder<ProfileBloc, ProfileState>(
                //   builder: (context, state) {
                //     return ElevatedButton(
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: const Color(0xff1E2E52),
                //         padding: const EdgeInsets.symmetric(
                //             horizontal: 16, vertical: 8),
                //         minimumSize: Size(double.infinity, 48),
                //       ),
                //       onPressed: () async {
                //         // Сбрасываем состояние ошибок
                //         setState(() {
                //           _nameError = null;
                //           _surnameError = null;
                //           _phoneError = null;
                //           _emailError = null;
                //         });

                //         // Проверяем валидацию
                //         bool isValid = true;

                //         if (NameController.text.trim().isEmpty) {
                //           setState(() {
                //             _nameError = AppLocalizations.of(context)!
                //                 .translate('name_required');
                //           });
                //           isValid = false;
                //         }

                //         if (SurnameController.text.trim().isEmpty) {
                //           setState(() {
                //             _surnameError = AppLocalizations.of(context)!
                //                 .translate('surname_required');
                //           });
                //           isValid = false;
                //         }

                //         if (emailController.text.trim().isNotEmpty &&
                //             !isValidEmail(emailController.text.trim())) {
                //           setState(() {
                //             _emailError = AppLocalizations.of(context)!
                //                 .translate('invalid_email');
                //           });
                //           isValid = false;
                //         }

                //         if (!isValid) return;

                //         try {
                //           SharedPreferences prefs =
                //               await SharedPreferences.getInstance();
                //           String UUID = prefs.getString('userID') ?? '';

                //           if (UUID.isEmpty) {
                //             _showErrorMessage('Ошибка: UUID не найден');
                //             return;
                //           }

                //           String UserNameProfile = NameController.text;
                //           await prefs.setString(
                //               'userNameProfile', UserNameProfile);

                //           int userId = int.parse(UUID);
                //           final image = _getImageToUpload();
                //           context.read<ProfileBloc>().add(UpdateProfile(
                //               userId: userId,
                //               name: NameController.text.trim(),
                //               sname: SurnameController.text.trim(),
                //               phone: selectedDialCode + phoneController.text,
                //               email: emailController.text.trim(),
                //               image: image,
                //               pname: ''));
                //         } catch (e) {
                //           _showErrorMessage(AppLocalizations.of(context)!
                //               .translate('profile_update_error'));
                //         }
                //       },
                //       child: Text(
                //         AppLocalizations.of(context)!.translate('save'),
                //         style: TextStyle(
                //           color: Colors.white,
                //           fontFamily: 'Gilroy',
                //           fontWeight: FontWeight.w600,
                //           fontSize: 16,
                //         ),
                //       ),
                //     );
                //   },
                // )
              )
            ]),
    );
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
