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
  String _lastLoadedImage = '';

  static String _cachedUserImage = '';

  @override
  void initState() {
    _searchController = widget.textEditingController;
    focusNode = widget.focusNode;

    if (_cachedUserImage.isNotEmpty) {
      _userImage = _cachedUserImage;
    } else {
      _loadUserProfile();
    }
    super.initState();
  }

  Future<void> _loadUserProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String UUID = prefs.getString('userID') ?? 'Не найдено';

      UserByIdProfile userProfile = await ApiService().getUserById(int.parse(UUID));
      
      if (userProfile.image != null && userProfile.image != _lastLoadedImage) {
        setState(() {
          _userImage = userProfile.image!;
          _lastLoadedImage = userProfile.image!;
          _cachedUserImage = userProfile.image!;
        });

        await prefs.setString('userProfileImage_$UUID', _userImage);
      } else if (_userImage.isEmpty && _cachedUserImage.isNotEmpty) {
        setState(() {
          _userImage = _cachedUserImage;
        });
      }
    } catch (e) {
      print('Ошибка при загрузке изображения: $e');
      if (_userImage.isEmpty && _cachedUserImage.isNotEmpty) {
        setState(() {
          _userImage = _cachedUserImage;
        });
      }
    }
  }

  Future<void> refreshUserImage() async {
    _lastLoadedImage = '';
    await _loadUserProfile();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.delayed(Duration(seconds: 30), () {
      if (mounted) {
        _loadUserProfile();
      }
    });
  }

  String? extractImageUrlFromSvg(String svg) {
    if (svg.contains('href="')) {
      final start = svg.indexOf('href="') + 6;
      final end = svg.indexOf('"', start);
      return svg.substring(start, end);
    }
    return null;
  }

  Widget _buildAvatarImage(String imageSource) {
    if (imageSource.isEmpty) {
      return Image.asset(
        'assets/icons/playstore.png',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    }

    if (imageSource.startsWith('<svg')) {
      final imageUrl = extractImageUrlFromSvg(imageSource);
      
      if (imageUrl != null) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        return SvgPicture.string(
          imageSource,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        );
      }
    }

    return Image.network(
      imageSource,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center();
      },
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/icons/playstore.png',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        );
      },
    );
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
              icon: _buildAvatarImage(_userImage),
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
                  color: Color(0xfff1E2E52),
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
                      builder: (context) => NotificationsScreen(),
                    ),
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