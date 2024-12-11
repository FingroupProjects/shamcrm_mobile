import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAppBar extends StatefulWidget {
  String title;
  Function() onClickProfileAvatar;
  FocusNode focusNode;
  TextEditingController textEditingController;
  ValueChanged<String>? onChangedSearchInput;
  Function(bool) clearButtonClick;
  bool showSearchIcon;

  CustomAppBar({
    super.key,
    required this.title,
    required this.onClickProfileAvatar,
    required this.onChangedSearchInput,
    required this.textEditingController,
    required this.focusNode,
    required this.clearButtonClick,
    this.showSearchIcon = true,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool _isSearching = false;
  late TextEditingController _searchController;
  late FocusNode focusNode;
  String _userImage = '';
  
  // Добавляем статическую переменную для кэширования
  static String _cachedUserImage = '';

  @override
  void initState() {
    _searchController = widget.textEditingController;
    focusNode = widget.focusNode;
    
    // Используем кэшированное изображение, если оно есть
    if (_cachedUserImage.isNotEmpty) {
      _userImage = _cachedUserImage;
    } else {
      _loadUserProfile(); // Загрузка изображения только если нет кэша
    }
    
    super.initState();
  }

  Future<void> _loadUserProfile() async {
    // Проверяем, было ли изображение уже загружено ранее
    if (_cachedUserImage.isNotEmpty) {
      setState(() {
        _userImage = _cachedUserImage;
      });
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String UUID = prefs.getString('userID') ?? 'Не найдено';

      // Проверяем, есть ли кэшированное изображение в ShajredPreferences
      String? cachedImage = prefs.getString('userProfileImage_$UUID');
      
      if (cachedImage != null && cachedImage.isNotEmpty) {
        setState(() {
          _userImage = cachedImage;
          _cachedUserImage = cachedImage; // Кэшируем статически
          print('Изображение загружено из кэша: $_userImage');
        });
        return;
      }

      // Если нет кэшированного изображения, загружаем с сервера
      UserByIdProfile userProfile =
          await ApiService().getUserById(int.parse(UUID));

      if (userProfile.image != null && userProfile.image!.isNotEmpty) {
        setState(() {
          _userImage = userProfile.image!;
          _cachedUserImage = userProfile.image!; // Кэшируем статически
        });

        // Кэшируем изображение в SharedPreferences
        await prefs.setString('userProfileImage_$UUID', _userImage);
        print('Изображение пользователя загружено: $_userImage');
      }
    } catch (e) {
      print('Ошибка при загрузке изображения: $e');
      setState(() {
        _userImage = ''; // В случае ошибки использовать пустую строку или резервное изображение
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        FocusScope.of(context).requestFocus(focusNode);
      } else {
        _searchController.clear();
        focusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: kToolbarHeight,
      color: Colors.white,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: _userImage.isNotEmpty
                  ? _userImage.startsWith('<svg') // Проверка, начинается ли строка с <svg
                      ? SvgPicture.string(
                          _userImage,
                          width: 40,
                          height: 40,
                        )
                      : Image.network(
                          _userImage,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              print('Изображение загружено успешно.');
                              return child;
                            } else {
                              print(
                                  'Загрузка изображения... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                              return Center();
                            }
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Ошибка при загрузке изображения: $error');
                            return Image.asset(
                              'assets/icons/playstore.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                  : Image.asset(
                      'assets/icons/playstore.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
              onPressed: widget.onClickProfileAvatar,
            ),
          ),
          SizedBox(width: 8),
          if (!_isSearching)
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_isSearching)
            Expanded(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _isSearching ? 200.0 : 0.0,
                child: TextField(
                  controller: _searchController,
                  focusNode: focusNode,
                  onChanged: widget.onChangedSearchInput,
                  decoration: InputDecoration(
                    hintText: 'Поиск...',
                    border: InputBorder.none,
                  ),
                  style: TextStyle(fontSize: 16),
                  autofocus: true,
                ),
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Image.asset(
                  'assets/icons/AppBar/notification.png',
                  width: 24,
                  height: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NotificationsScreen()),
                  );
                },
              ),
              if (widget.showSearchIcon)
                IconButton(
                  icon: _isSearching
                      ? Icon(Icons.close)
                      : Image.asset(
                          'assets/icons/AppBar/search.png',
                          width: 24,
                          height: 24,
                        ),
                  onPressed: () {
                    _toggleSearch();
                    widget.clearButtonClick(_isSearching);
                    if (_isSearching) {
                      FocusScope.of(context).requestFocus(focusNode);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}