import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/notifications_screen.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
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

class _CustomAppBarState extends State<CustomAppBar> with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  late TextEditingController _searchController;
  late FocusNode focusNode;
  String _userImage = '';
  String _lastLoadedImage = '';
  static String _cachedUserImage = '';

  bool _hasNewNotification = false;
  late PusherChannelsClient socketClient;
  late StreamSubscription<ChannelReadEvent> notificationSubscription;

  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();

    _searchController = widget.textEditingController;
    focusNode = widget.focusNode;

    if (_cachedUserImage.isNotEmpty) {
      _userImage = _cachedUserImage;
    } else {
      _loadUserProfile();
    }

    _loadNotificationState();
    _setUpSocketForNotifications();

    _blinkController = AnimationController(
      vsync: this, 
      duration: Duration(milliseconds: 700),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _blinkAnimation = CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

Future<void> _loadNotificationState() async {
  final prefs = await SharedPreferences.getInstance();
  bool hasNewNotification = prefs.getBool('hasNewNotification') ?? false;
  setState(() {
    _hasNewNotification = hasNewNotification;
  });
}


  Future<void> _setUpSocketForNotifications() async {
  debugPrint('--------------------------- start socket CUSTOM APPBAR:::::::----------------');
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  final baseUrlSocket = await ApiService().getSocketBaseUrl();
  final enteredDomain = await ApiService().getEnteredDomain();

  final customOptions = PusherChannelsOptions.custom(
    uriResolver: (metadata) => Uri.parse('wss://soketi.shamcrm.com/app/app-key'),
    metadata: PusherChannelsOptionsMetadata.byDefault(),
  );

  socketClient = PusherChannelsClient.websocket(
    options: customOptions,
    connectionErrorHandler: (exception, trace, refresh) {},
    minimumReconnectDelayDuration: const Duration(seconds: 1),
  );

  String userId = prefs.getString('userID') ?? '';

  final myPresenceChannel = socketClient.presenceChannel(
    'presence-user.$userId',
    authorizationDelegate:
        EndpointAuthorizableChannelTokenAuthorizationDelegate
            .forPresenceChannel(
      authorizationEndpoint: Uri.parse(baseUrlSocket),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Tenant': '$enteredDomain-back'
      },
      onAuthFailed: (exception, trace) {
        debugPrint(exception);
      },
    ),
  );

  socketClient.onConnectionEstablished.listen((_) {
    myPresenceChannel.subscribeIfNotUnsubscribed();
    notificationSubscription =
        myPresenceChannel.bind('notification.created').listen((event) {
      debugPrint('Received notification: ${event.data}');
      setState(() {
        _hasNewNotification = true;
      });
      prefs.setBool('hasNewNotification', true);  
    });
  });

  try {
    await socketClient.connect();
    print('Socket connection SUCCESSS');
  } catch (e) {
    if (kDebugMode) {
      print('Socket connection error!');
    }
  }
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
      print('Ошибка при загрузке изображения!');
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
              Row(
                children: [
                  IconButton(
                    icon: Stack(
                      children: [
                        Image.asset(
                          'assets/icons/AppBar/notification.png',
                          width: 24,
                          height: 24,
                        ),
                        if (_hasNewNotification)
                          Positioned(
                            right: 0,
                            child: FadeTransition(
                              opacity: _blinkAnimation, 
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      setState(() {
                        _hasNewNotification = false; 
                      });
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setBool('hasNewNotification', false);
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsScreen(),
                        ),
                      );
                    },
                  )
                ],
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