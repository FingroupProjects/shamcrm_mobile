import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_event.dart';
import 'package:crm_task_manager/custom_widget/manager_app_bar.dart';
import 'package:crm_task_manager/custom_widget/user_app_bar.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/notifications_screen.dart';
import 'package:crm_task_manager/screens/my-task/task_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAppBar extends StatefulWidget {
  String title;
  Function() onClickProfileAvatar;
  FocusNode focusNode;
  TextEditingController textEditingController;
  ValueChanged<String>? onChangedSearchInput;
  Function(bool) clearButtonClick;
  Function(bool) clearButtonClickFiltr;
  bool showSearchIcon;
  final bool showFilterIcon;
  final bool showFilterTaskIcon; // New field for task filter
  final Function(List<dynamic>)?
      onManagersSelected; // Изменено на List<dynamic>
  final Function(List<dynamic>)? onUsersSelected; // Изменено на List<dynamic>
  final bool showMyTaskIcon; // Новый параметр

  CustomAppBar({
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
    this.showFilterTaskIcon = true, // Default value for task filter
    this.onManagersSelected,
    this.onUsersSelected, // Add to constructor
    this.showMyTaskIcon = false, // По умолчанию выключено
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;

  late TextEditingController _searchController;
  late FocusNode focusNode;
  String _userImage = '';
  String _lastLoadedImage = '';
  static String _cachedUserImage = '';
  bool _isFiltering = false;
  bool _isTaskFiltering = false; // New state for task filter
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
    debugPrint(
        '--------------------------- start socket CUSTOM APPBAR:::::::----------------');
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final baseUrlSocket = await ApiService().getSocketBaseUrl();
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
        authorizationEndpoint: Uri.parse('https://$enteredDomain-back.$enteredMainDomain/broadcasting/auth'),
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

  void _toggleFilter() {
    setState(() {
      _isFiltering = !_isFiltering;
      if (_isFiltering) {
        FocusScope.of(context).requestFocus(focusNode);
      } else {
        focusNode.unfocus();
      }
    });
    widget.clearButtonClickFiltr(_isFiltering);
  }

  void _toggleTaskFilter() {
    setState(() {
      _isTaskFiltering = !_isTaskFiltering;
      if (_isTaskFiltering) {
        FocusScope.of(context).requestFocus(focusNode);
      } else {
        focusNode.unfocus();
      }
    });
    widget.clearButtonClick(_isTaskFiltering);
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
              width: 1,
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
                        hintText: AppLocalizations.of(context)!.translate('search_appbar'),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(fontSize: 16),
                      autofocus: true,
                    ),
                  ),
                ),
              Row(
                children: [
                  if (widget.showMyTaskIcon)
                    Tooltip(
                      message: AppLocalizations.of(context)!.translate('appbar_my_tasks'),
                      // Текст подсказки
                      preferBelow: false,
                      decoration: BoxDecoration(
                        color: Colors.white, // Белый фон
                        borderRadius:
                            BorderRadius.circular(8), // Слегка скругленные углы
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ], // Тень
                      ),
                      textStyle: TextStyle(
                        fontSize: 12, // Размер текста подсказки
                        color: Colors.black, // Цвет текста
                      ),
                      child: IconButton(
                        icon: Image.asset(
                          'assets/icons/AppBar/my-task.png',
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyTaskScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  if (widget.showFilterIcon)
                    Tooltip(
                      message: AppLocalizations.of(context)!.translate('filtr'),
                      preferBelow: false,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      textStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                      child: IconButton(
                        icon: _isFiltering
                            ? Icon(Icons.close)
                            : Image.asset(
                                'assets/icons/AppBar/filter.png',
                                width: 24,
                                height: 24,
                              ),
                        onPressed: () {
                          if (_isTaskFiltering || _isTaskFiltering) {
                            setState(() {
                              _isFiltering = !_isFiltering;
                            });
                          } else {
                            _toggleFilter();
                            if (_isFiltering) {
                              context
                                  .read<GetAllManagerBloc>()
                                  .add(GetAllManagerEv());
                              final RenderBox button =
                                  context.findRenderObject() as RenderBox;
                              final position =
                                  button.localToGlobal(Offset.zero);

                              showMenu(
                                context: context,
                                position: RelativeRect.fromLTRB(
                                  position.dx,
                                  position.dy + button.size.height,
                                  position.dx + button.size.width,
                                  position.dy + button.size.height,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                                color: Colors.white,
                                items: [
                                  PopupMenuItem(
                                    padding: EdgeInsets.zero,
                                    child: ManagerFilterPopup(
                                      onManagersSelected:
                                          widget.onManagersSelected,
                                    ),
                                  ),
                                ],
                              );
                            }
                          }
                        },
                      ),
                    ),
                  if (widget.showFilterTaskIcon)
                    Tooltip(
                      message: AppLocalizations.of(context)!.translate('filtr'),
                      preferBelow: false,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      textStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                      child: IconButton(
                        icon: _isTaskFiltering
                            ? Icon(Icons.close)
                            : Image.asset(
                                'assets/icons/AppBar/filter.png',
                                width: 24,
                                height: 24,
                              ),
                        onPressed: () {
                          if (_isFiltering || _isFiltering) {
                            setState(() {
                              _isTaskFiltering = !_isTaskFiltering;
                            });
                          } else {
                            _toggleTaskFilter();
                            if (_isTaskFiltering) {
                              context.read<UserTaskBloc>().add(FetchUsers());
                              final RenderBox button =
                                  context.findRenderObject() as RenderBox;
                              final position =
                                  button.localToGlobal(Offset.zero);

                              showMenu(
                                context: context,
                                position: RelativeRect.fromLTRB(
                                  position.dx,
                                  position.dy + button.size.height,
                                  position.dx + button.size.width,
                                  position.dy + button.size.height,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                                color: Colors.white,
                                items: [
                                  PopupMenuItem(
                                    padding: EdgeInsets.zero,
                                    child: UserFilterPopup(
                                      onUsersSelected: widget.onUsersSelected,
                                    ),
                                  ),
                                ],
                              );
                            }
                          }
                        },
                      ),
                    ),
                  Tooltip(
                    message:
                        AppLocalizations.of(context)!.translate('notification'),

                    preferBelow: false,
                    decoration: BoxDecoration(
                      color: Colors.white, // Белый фон
                      borderRadius:
                          BorderRadius.circular(8), // Слегка скругленные углы
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ], // Тень
                    ),
                    textStyle: TextStyle(
                      fontSize: 12, // Размер текста подсказки
                      color: Colors.black, // Цвет текста
                    ),
                    child: IconButton(
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
                    ),
                  ),
                  if (widget.showSearchIcon)
                    Tooltip(
                      message:
                          AppLocalizations.of(context)!.translate('search'),
                      preferBelow: false,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      textStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                      child: IconButton(
                        icon: _isSearching
                            ? Icon(Icons.close)
                            : Image.asset(
                                'assets/icons/AppBar/search.png',
                                width: 24,
                                height: 24,
                              ),
                        onPressed: () {
                          if (_isTaskFiltering || _isTaskFiltering) {
                            setState(() {
                              _isSearching = !_isSearching;
                            });
                          } else {
                            setState(() {
                              _isSearching = !_isSearching;
                            });
                            widget.clearButtonClick(_isSearching);

                            if (_isSearching) {
                              // Открытие поля поиска и клавиатуры
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                FocusScope.of(context).requestFocus(focusNode);
                              });
                            } else {
                              // Закрытие клавиатуры при выключении поиска
                              FocusScope.of(context).unfocus();
                            }
                          }
                        },
                      ),
                    ),
                ],
              )
            ]));
  }
}
