import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';

import 'package:crm_task_manager/models/user_byId_model..dart';

import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAppBarPage2 extends StatefulWidget {
  String title;
  Function() onClickProfileAvatar;
  FocusNode focusNode;
  TextEditingController textEditingController;
  ValueChanged<String>? onChangedSearchInput;
  Function(bool) clearButtonClick;
  Function(bool) clearButtonClickFiltr;
  final bool showSearchIcon;
  final bool showFilterIcon;

  CustomAppBarPage2({
    super.key,
    required this.title,
    required this.onClickProfileAvatar,
    required this.onChangedSearchInput,
    required this.textEditingController,
    required this.focusNode,
    required this.clearButtonClick,
    required this.clearButtonClickFiltr,
    this.showSearchIcon = true,
    this.showFilterIcon = true,
  });

  @override
  State<CustomAppBarPage2> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBarPage2>
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  final ApiService _apiService = ApiService();
  late TextEditingController _searchController;
  late FocusNode focusNode;
  String _userImage = '';
  String _lastLoadedImage = '';
  static String _cachedUserImage = '';
  bool _hasNewNotification = false;
  late PusherChannelsClient socketClient;
  late StreamSubscription<ChannelReadEvent> notificationSubscription;
  Timer? _checkOverdueTimer;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  bool _hasOverdueTasks = false;

  bool _canReadNotice = true;
  Color _iconColor = Colors.red;
  late Timer _timer;

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
    _checkOverdueTasks();
    _checkOverdueTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkOverdueTasks(),
    );

    _timer = Timer.periodic(Duration(milliseconds: 700), (timer) {
      setState(() {
        _iconColor = (_iconColor == Colors.blue) ? Colors.black : Colors.blue;
      });
    });
  }

  Future<void> _checkOverdueTasks() async {
    try {
      final apiService = ApiService();
      final hasOverdue = await apiService.checkOverdueTasks();

      if (mounted) {
        setState(() {
          _hasOverdueTasks = hasOverdue;
        });
      }
    } catch (e) {
      print('Error checking overdue tasks: $e');
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _checkOverdueTimer?.cancel();
    _timer.cancel();

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
    debugPrint(
        '--------------------------- start socket CUSTOM APPBAR:::::::----------------');
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final enteredDomainMap = await ApiService().getEnteredDomain();
    String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
    String? enteredDomain = enteredDomainMap['enteredDomain'];

    final customOptions = PusherChannelsOptions.custom(
      uriResolver: (metadata) =>
          Uri.parse('wss://soketi.$enteredMainDomain/app/app-key'),
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
        authorizationEndpoint: Uri.parse(
            'https://$enteredDomain-back.$enteredMainDomain/broadcasting/auth'),
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

  // Метод для проверки разрешений
  Future<void> _checkPermissions() async {
    final canReadNotice = await _apiService.hasPermission('notice.read');

    setState(() {
      _canReadNotice = canReadNotice;
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String UUID = prefs.getString('userID') ??
          AppLocalizations.of(context)!.translate('not_found');

      UserByIdProfile userProfile =
          await ApiService().getUserById(int.parse(UUID));

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.delayed(Duration(milliseconds: 1), () {
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

  Color? extractBackgroundColorFromSvg(String svg) {
    final fillMatch = RegExp(r'fill="(#[A-Fa-f0-9]+)"').firstMatch(svg);
    if (fillMatch != null) {
      final colorHex = fillMatch.group(1);
      if (colorHex != null) {
        // Конвертируем hex в Color
        final hex = colorHex.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      }
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
        final text =
            RegExp(r'>([^<]+)</text>').firstMatch(imageSource)?.group(1) ?? '';
        final backgroundColor =
            extractBackgroundColorFromSvg(imageSource) ?? Color(0xFF2C2C2C);

        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            border: Border.all(
              color: Colors.white,
              width: 0,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
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
      child: Row(children: [
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
                  hintText: AppLocalizations.of(context)!.translate('search_appbar'),
                  border: InputBorder.none,
                ),
                style: TextStyle(fontSize: 16),
                autofocus: true,
              ),
            ),
          ),
        if (widget.showSearchIcon)
          Transform.translate(
            offset: const Offset(10, 0),
            child: Tooltip(
              message: AppLocalizations.of(context)!.translate('search'),
              preferBelow: false,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              textStyle: TextStyle(
                fontSize: 12,
                color: Colors.black,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                icon: _isSearching
                    ? Icon(Icons.close)
                    : Image.asset(
                        'assets/icons/AppBar/search.png',
                        width: 24,
                        height: 24,
                      ),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                    }
                  });

                  widget.clearButtonClick(_isSearching);

                  if (_isSearching) {
                    Future.delayed(Duration(milliseconds: 100), () {
                      FocusScope.of(context).requestFocus(focusNode);
                    });
                  }
                },
              ),
            ),
          )
      ]),
    );
  }
}
