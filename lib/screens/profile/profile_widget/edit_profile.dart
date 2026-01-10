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
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math' as math; // Импортируем math для математических вычислений

import 'package:shared_preferences/shared_preferences.dart';

import '../../../custom_widget/country_data_list.dart';

// Новый виджет для интерактивного аватара
class InteractiveAvatar extends StatefulWidget {
  final File? localImage; // Локальное изображение если есть
  final String userImage; // URL изображения пользователя
  final VoidCallback onTap; // Callback для нажатия на аватар
  final ScrollController scrollController; // Контроллер скролла для анимации

  const InteractiveAvatar({
    Key? key,
    this.localImage,
    required this.userImage,
    required this.onTap,
    required this.scrollController,
  }) : super(key: key);

  @override
  _InteractiveAvatarState createState() => _InteractiveAvatarState();
}

class _InteractiveAvatarState extends State<InteractiveAvatar>
    with TickerProviderStateMixin {
  late AnimationController _scaleController; // Контроллер анимации масштабирования
  late Animation<double> _scaleAnimation; // Анимация масштаба
  late AnimationController _tapController; // Контроллер анимации нажатия
  late Animation<double> _tapAnimation; // Анимация при нажатии
  
  double _scrollOffset = 0.0; // Текущий offset скролла
  bool _isExpanded = false; // Флаг развернутого состояния

  @override
  void initState() {
    super.initState();
    
    // Инициализация контроллера масштабирования
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Создание анимации масштабирования с плавной кривой
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.8,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutCubic,
    ));
    
    // Инициализация контроллера анимации нажатия
    _tapController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    
    // Создание анимации нажатия
    _tapAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeInOut,
    ));
    
    // Добавляем слушатель к контроллеру скролла
    widget.scrollController.addListener(_onScroll);
  }

  // Обработчик скролла для анимации масштабирования
  void _onScroll() {
    final double offset = widget.scrollController.offset; // Получаем текущий offset
    setState(() {
      _scrollOffset = offset; // Обновляем offset состояния
    });
    
    // Вычисляем прогресс анимации на основе скролла
    double progress = math.min(offset / 200.0, 1.0); // Максимум на 200 пикселях скролла
    _scaleController.value = progress; // Устанавливаем значение анимации
    
    // Определяем когда аватар считается развернутым
    bool shouldBeExpanded = progress > 0.7;
    if (_isExpanded != shouldBeExpanded) {
      setState(() {
        _isExpanded = shouldBeExpanded; // Обновляем состояние развернутости
      });
    }
  }

  // Обработчик нажатия с анимацией
void _handleTap() {
  _tapController.forward().then((_) => _tapController.reverse());
  //print('Avatar tapped, isExpanded: $_isExpanded'); // Логирование
  _openFullScreenGallery(); // Всегда открываем галерею
}

  // Открытие полноэкранной галереи
  void _openFullScreenGallery() {
  //print('Opening gallery with localImage: ${widget.localImage}, userImage: ${widget.userImage}');
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      barrierDismissible: true,
      pageBuilder: (context, animation, secondaryAnimation) {
        return FullScreenImageViewer(
          localImage: widget.localImage,
          userImage: widget.userImage,
          animation: animation,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _tapAnimation]), // Слушаем обе анимации
      builder: (context, child) {
        // Вычисляем финальный масштаб комбинируя обе анимации
        double finalScale = _scaleAnimation.value * _tapAnimation.value;
        
        return GestureDetector(
          onTap: _handleTap, // Обработчик нажатия
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 20), // Отступы сверху и снизу
            child: Transform.scale(
              scale: 1.0 + finalScale * 0.3, // Применяем масштабирование
              child: Container(
                width: 140 + (_scaleAnimation.value * 60), // Динамическая ширина
                height: 140 + (_scaleAnimation.value * 60), // Динамическая высота
                child: Stack(
                  children: [
                    // Основной контейнер аватара
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          // Динамическое изменение радиуса для овального эффекта внизу
                          _isExpanded ? 20 : 70,
                        ),
                        boxShadow: [
                          // Тень которая увеличивается при масштабировании
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1 + _scaleAnimation.value * 0.2),
                            blurRadius: 10 + _scaleAnimation.value * 20,
                            offset: Offset(0, 5 + _scaleAnimation.value * 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          _isExpanded ? 20 : 70, // Скругление углов
                        ),
                        child: _buildAvatarContent(), // Содержимое аватара
                      ),
                    ),
                    
                    // Индикатор что можно нажать (появляется при разворачивании)
                    if (_isExpanded)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6), // Полупрозрачный фон
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.fullscreen, // Иконка полноэкранного режима
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Построение содержимого аватара
  Widget _buildAvatarContent() {
  if (widget.localImage != null) {
    return Image.file(widget.localImage!, fit: BoxFit.cover);
  }
  if (widget.userImage.isNotEmpty && widget.userImage != AppLocalizations.of(context)!.translate('not_found')) {
    return Image.network(
      widget.userImage,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
    );
  }
  return _buildDefaultAvatar();
}

  // Построение SVG аватара
  Widget _buildSvgAvatar(String svg) {
    // Извлекаем URL изображения из SVG если есть
    if (svg.contains('image href=')) {
      final start = svg.indexOf('href="') + 6;
      final end = svg.indexOf('"', start);
      final imageUrl = svg.substring(start, end);

      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      // Извлекаем текст и цвет фона из SVG
      final text = RegExp(r'>([^<]+)</text>').firstMatch(svg)?.group(1) ?? '';
      final backgroundColor = _extractBackgroundColorFromSvg(svg) ?? Color(0xFF2C2C2C);

      return Container(
        width: double.infinity,
        height: double.infinity,
        color: backgroundColor,
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

  // Аватар по умолчанию
  Widget _buildDefaultAvatar() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: 100,
        color: Colors.white,
      ),
    );
  }

  // Извлечение цвета фона из SVG
  Color? _extractBackgroundColorFromSvg(String svg) {
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

  @override
  void dispose() {
    // Освобождаем ресурсы
    widget.scrollController.removeListener(_onScroll);
    _scaleController.dispose();
    _tapController.dispose();
    super.dispose();
  }
}

// Виджет для полноэкранного просмотра изображения
class FullScreenImageViewer extends StatefulWidget {
  final File? localImage; // Локальное изображение
  final String userImage; // URL изображения
  final Animation<double> animation; // Анимация появления

  const FullScreenImageViewer({
    Key? key,
    this.localImage,
    required this.userImage,
    required this.animation,
  }) : super(key: key);

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController; // Контроллер трансформации для зума
  late AnimationController _fadeController; // Контроллер анимации исчезновения UI
  late Animation<double> _fadeAnimation; // Анимация исчезновения UI

  bool _isUIVisible = true; // Флаг видимости UI элементов

  @override
  void initState() {
    super.initState();
    
    // Инициализация контроллера трансформации
    _transformationController = TransformationController();
    
    // Инициализация контроллера анимации исчезновения UI
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Создание анимации исчезновения
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Запускаем анимацию появления UI
    _fadeController.forward();
  }

  // Переключение видимости UI
  void _toggleUI() {
    setState(() {
      _isUIVisible = !_isUIVisible;
    });
    
    if (_isUIVisible) {
      _fadeController.forward(); // Показываем UI
    } else {
      _fadeController.reverse(); // Скрываем UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Черный фон галереи
      body: Stack(
        children: [
          // Основное изображение с возможностью зума
          Center(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5, // Минимальный зум
              maxScale: 4.0, // Максимальный зум
              onInteractionStart: (details) {
                // Скрываем UI при начале взаимодействия
                if (_isUIVisible) {
                  _toggleUI();
                }
              },
              child: GestureDetector(
                onTap: _toggleUI, // Переключаем UI по нажатию
                child: Hero(
  tag: 'avatar_hero_${widget.userImage.hashCode}', // ✅ Уникальный тег
  child: _buildFullScreenImage(),
),
              ),
            ),
          ),
          
          // Верхняя панель с кнопкой закрытия
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  height: MediaQuery.of(context).padding.top + 60, // Высота с учетом safe area
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7), // Градиент для лучшей видимости
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Кнопка закрытия
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(); // Закрываем галерею
                          },
                        ),
                        Spacer(), // Распорка
                        // Можно добавить дополнительные кнопки (поделиться, скачать и т.д.)
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Нижняя панель с информацией (опционально)
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 20,
                      top: 20,
                      left: 20,
                      right: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      'Фото профиля', // Подпись к изображению
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Построение полноэкранного изображения
  Widget _buildFullScreenImage() {
    // Если есть локальное изображение
    if (widget.localImage != null) {
      return Image.file(
        widget.localImage!,
        fit: BoxFit.contain, // Вписываем в экран сохраняя пропорции
      );
    }
    
    // Если есть URL изображения
    if (widget.userImage.isNotEmpty && 
        widget.userImage != 'Не найдено') {
      
      // Обработка SVG
      if (widget.userImage.contains('<svg')) {
        return _buildSvgFullScreen(widget.userImage);
      }
      
      // Обычное изображение
      return Image.network(
        widget.userImage,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                    loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultFullScreenAvatar();
        },
      );
    }
    
    return _buildDefaultFullScreenAvatar();
  }

  // SVG в полноэкранном режиме
  Widget _buildSvgFullScreen(String svg) {
    if (svg.contains('image href=')) {
      final start = svg.indexOf('href="') + 6;
      final end = svg.indexOf('"', start);
      final imageUrl = svg.substring(start, end);

      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
      );
    } else {
      final text = RegExp(r'>([^<]+)</text>').firstMatch(svg)?.group(1) ?? '';
      final backgroundColor = _extractBackgroundColorFromSvg(svg) ?? Color(0xFF2C2C2C);

      return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: backgroundColor,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 200,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  // Аватар по умолчанию в полноэкранном режиме
  Widget _buildDefaultFullScreenAvatar() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: Colors.grey[800],
      child: Icon(
        Icons.person,
        size: 200,
        color: Colors.white,
      ),
    );
  }

  // Извлечение цвета из SVG
  Color? _extractBackgroundColorFromSvg(String svg) {
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

  @override
  void dispose() {
    _transformationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}

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
  final ScrollController _scrollController = ScrollController(); // Контроллер скролла для интерактивного аватара
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
  // Используем новое поле для всех ролей
  String UAllRoles = prefs.getString('userAllRoles') ?? 'Не найдено';

  setState(() {
    userController.text = UUID;
    loginController.text = ULogin;
    roleController.text = UAllRoles; // Отображаем все роли
  });

  try {
    UserByIdProfile userProfile = await ApiService().getUserById(int.parse(UUID));
    
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

    // Обновляем роли из API, если они есть
    if (userProfile.role != null && userProfile.role!.isNotEmpty) {
      String allRoles = userProfile.role!.map((role) => role.name).join(', ');
      setState(() {
        roleController.text = allRoles;
      });
      // Обновляем SharedPreferences
      await prefs.setString('userAllRoles', allRoles);
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
            title: Text(AppLocalizations.of(context)!.translate('gallery')),
            onTap: () async {
              final XFile? pickedFile = await _picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 80,
                maxWidth: 1080,
                maxHeight: 1080,
              );
              if (pickedFile != null) {
                final file = File(pickedFile.path);
                final int fileSize = await file.length();
                if (fileSize > 2 * 1024 * 1024) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.translate('file_size_limit'))),
                  );
                  Navigator.pop(context);
                  return;
                }
                setState(() {
                  _localImage = file;
                  _userImage = ''; // Сбрасываем URL
                  //print('Local image selected: ${_localImage?.path}'); // Логирование
                });
                Navigator.pop(context);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(AppLocalizations.of(context)!.translate('camera')),
            onTap: () async {
              final XFile? pickedFile = await _picker.pickImage(
                source: ImageSource.camera,
                imageQuality: 80,
                maxWidth: 1080,
                maxHeight: 1080,
              );
              if (pickedFile != null) {
                final file = File(pickedFile.path);
                final int fileSize = await file.length();
                if (fileSize > 2 * 1024 * 1024) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.translate('file_size_limit'))),
                  );
                  Navigator.pop(context);
                  return;
                }
                setState(() {
                  _localImage = file;
                  _userImage = ''; // Сбрасываем URL
                  //print('Local image selected: ${_localImage?.path}'); // Логирование
                });
                Navigator.pop(context);
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
        // actions: [
        //   IconButton(
        //     icon: Image.asset(
        //       'assets/icons/edit.png',
        //       width: 24,
        //       height: 24,
        //     ),
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //             builder: (context) => const ProfileEditPage()),
        //       );
        //     },
        //   ),
        // ],
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
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: _showImagePickerDialog,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    backgroundColor: const Color(0xff1E2E52),
                                  ),
                                  child: Text(
                                    _userImage ==
                                                AppLocalizations.of(context)!
                                                    .translate('not_found') ||
                                            _userImage.isEmpty
                                        ? AppLocalizations.of(context)!
                                            .translate('change_photo')
                                        : AppLocalizations.of(context)!
                                            .translate('change_photo'),
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
                          hintText: AppLocalizations.of(context)!
                              .translate('enter_name'),
                          label:
                              AppLocalizations.of(context)!.translate('name'),
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
                        CustomTextField(
                          controller: SurnameController,
                          hintText: AppLocalizations.of(context)!
                              .translate('enter_surname'),
                          label: AppLocalizations.of(context)!
                              .translate('surname'),
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
                        CustomPhoneNumberInput(
                          controller: phoneController,
                          selectedDialCode: selectedDialCode,
                          phoneNumberLengths:
                              phoneNumberLengths, // Передача длины номеров
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
                          label:
                              AppLocalizations.of(context)!.translate('phone'),
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: 0.6, // Прозрачность для всего виджета
                          child: CustomTextField(
                            controller: roleController,
                            hintText: AppLocalizations.of(context)!
                                .translate('enter_role'),
                            label:
                                AppLocalizations.of(context)!.translate('role'),
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: 0.6, // Прозрачность для всего виджета
                          child: CustomTextField(
                            controller: loginController,
                            hintText: AppLocalizations.of(context)!
                                .translate('enter_login'),
                            label: AppLocalizations.of(context)!
                                .translate('login'),
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: emailController,
                          hintText: AppLocalizations.of(context)!
                              .translate('enter_email'),
                          label:
                              AppLocalizations.of(context)!.translate('email'),
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
                        onPressed: () async {
                          // Сбрасываем состояние ошибок
                          setState(() {
                            _nameError = null;
                            _surnameError = null;
                            _phoneError = null;
                            _emailError = null;
                          });

                          // Проверяем валидацию
                          bool isValid = true;

                          if (NameController.text.trim().isEmpty) {
                            setState(() {
                              _nameError = AppLocalizations.of(context)!
                                  .translate('name_required');
                            });
                            isValid = false;
                          }

                          if (SurnameController.text.trim().isEmpty) {
                            setState(() {
                              _surnameError = AppLocalizations.of(context)!
                                  .translate('surname_required');
                            });
                            isValid = false;
                          }

                          if (emailController.text.trim().isNotEmpty &&
                              !isValidEmail(emailController.text.trim())) {
                            setState(() {
                              _emailError = AppLocalizations.of(context)!
                                  .translate('invalid_email');
                            });
                            isValid = false;
                          }

                          if (!isValid) return;

                          try {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            String UUID = prefs.getString('userID') ?? '';

                            if (UUID.isEmpty) {
                              _showErrorMessage('Ошибка: UUID не найден');
                              return;
                            }

                            String UserNameProfile = NameController.text;
                            await prefs.setString(
                                'userNameProfile', UserNameProfile);

                            int userId = int.parse(UUID);
                            final image = _getImageToUpload();
                            context.read<ProfileBloc>().add(UpdateProfile(
                                userId: userId,
                                name: NameController.text.trim(),
                                sname: SurnameController.text.trim(),
                                phone: selectedDialCode + phoneController.text,
                                email: emailController.text.trim(),
                                image: image,
                                pname: ''));
                          } catch (e) {
                            _showErrorMessage(AppLocalizations.of(context)!
                                .translate('profile_update_error'));
                          }
                        },
                        child: Text(
                          AppLocalizations.of(context)!.translate('save'),
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ))
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