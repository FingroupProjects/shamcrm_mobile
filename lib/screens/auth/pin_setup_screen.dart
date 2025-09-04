import 'dart:convert';

import 'package:background_location_tracker/background_location_tracker.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/permission/permession_bloc.dart';
import 'package:crm_task_manager/bloc/permission/permession_event.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/screens/home_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({Key? key}) : super(key: key);

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _pinsDoNotMatch = false;
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  int? userRoleId;
  bool isPermissionsLoaded = false;
  Map<String, dynamic>? tutorialProgress;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();

    context.read<PermissionsBloc>().add(FetchPermissionsEvent());
    _loadUserRoleId();
    _fetchTutorialProgress();
    _fetchSettings();
    _fetchMiniAppSettings(); // Добавляем вызов
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_animationController);
  }

Future<void> _fetchMiniAppSettings() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final organizationId = await _apiService.getSelectedOrganization();
    print('Fetching MiniAppSettings for organizationId: $organizationId');
    
    final settingsList = await _apiService.getMiniAppSettings(organizationId);
    
    if (settingsList.isNotEmpty) {
      final settings = settingsList.first;
      print('Saving currency_id: ${settings.currencyId}');
      await prefs.setInt('currency_id', settings.currencyId);
    } else {
      print('No settings found for organizationId: $organizationId');
    }
  } catch (e) {
    print('Error fetching mini-app settings: $e');
    final prefs = await SharedPreferences.getInstance();
    final savedCurrencyId = prefs.getInt('currency_id');
    print('Using cached currency_id: $savedCurrencyId');
  }
}

  Future<void> _fetchTutorialProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool isNewUser = prefs.getString('user_pin') == null;

      if (isNewUser) {
        final progress = await _apiService.getTutorialProgress();
        setState(() {
          tutorialProgress = progress['result'];
        });
        await prefs.setString(
            'tutorial_progress', json.encode(progress['result']));
      } else {
        final savedProgress = prefs.getString('tutorial_progress');
        if (savedProgress != null) {
          setState(() {
            tutorialProgress = json.decode(savedProgress);
          });
        }
      }
    } catch (e) {
      //print('Error fetching tutorial progress: $e');
    }
  }

  Future<void> _fetchSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final organizationId = await _apiService.getSelectedOrganization();

      final response = await _apiService.getSettings(organizationId);

      if (response['result'] != null) {
        await prefs.setBool('department_enabled', response['result']['department'] ?? false);
        await prefs.setBool('integration_with_1C', response['result']['integration_with_1C'] ?? false);
        if (kDebugMode) {
          //print('PinScreen: Настройки сохранены: integration_with_1C = ${response['result']['integration_with_1C']}');
        }
      }
    } catch (e) {
      //print('Error fetching settings: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('integration_with_1C', false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_pinsDoNotMatch) {
        _pinsDoNotMatch = false;
        _confirmPin = '';
      }

      if (_isConfirming) {
        if (_confirmPin.length < 4) {
          _confirmPin += number;
        }
        if (_confirmPin.length == 4) {
          _validatePins();
        }
      } else {
        if (_pin.length < 4) {
          _pin += number;
        }
        if (_pin.length == 4 && !_isConfirming) {
          _isConfirming = true;
        }
      }
    });
  }

  void _onClear() {
    setState(() {
      _pin = '';
      _confirmPin = '';
      _pinsDoNotMatch = false;
      _isConfirming = false;
    });
  }

  void _onDelete() {
    setState(() {
      if (_isConfirming && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (!_isConfirming && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

Future<void> _loadUserRoleId() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userID') ?? '';
    print('PinSetupScreen: Loaded userID: $userId');
    if (userId.isEmpty || userId == '1') {
      print('PinSetupScreen: Invalid userID ($userId), setting userRoleId to 0');
      setState(() {
        userRoleId = 0;
      });
      return;
    }

    UserByIdProfile userProfile = await ApiService().getUserById(int.parse(userId));
    print('PinSetupScreen: Fetched user profile: id=$userId, roleId=${userProfile.role!.first.id}');
    setState(() {
      userRoleId = userProfile.role!.first.id;
    });

    await prefs.setInt('userRoleId', userRoleId!);
    await prefs.setString('userRoleName', userProfile.role![0].name);

    // Запрос разрешений на геолокацию
    final locationStatus = await Permission.location.status;
    print('PinSetupScreen: Location permission status: $locationStatus');
    
    if (!locationStatus.isGranted) {
      await Permission.location.request();
      print('PinSetupScreen: Requested location permission');
    }

    final locationAlwaysStatus = await Permission.locationAlways.status;
    print('PinSetupScreen: Location always permission status: $locationAlwaysStatus');
    print('GPS: Location permissions - location: $locationStatus, always: $locationAlwaysStatus');

    if (!locationAlwaysStatus.isGranted) {
      await Permission.locationAlways.request();
      print('PinSetupScreen: Requested location always permission');
    }

    BlocProvider.of<LeadBloc>(context).add(FetchLeadStatuses());
    BlocProvider.of<DealBloc>(context).add(FetchDealStatuses());
    BlocProvider.of<TaskBloc>(context).add(FetchTaskStatuses());
    BlocProvider.of<MyTaskBloc>(context).add(FetchMyTaskStatuses());

    setState(() {
      isPermissionsLoaded = true;
    });
  } catch (e) {
    print('PinSetupScreen: Error loading user role: $e');
    setState(() {
      userRoleId = 0;
    });
  }
}

 Future<void> _validatePins() async {
  if (_pin == _confirmPin) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pin', _pin);
    print('PinSetupScreen: PIN set successfully');

    // Инициализация трекинга
    if (userRoleId != null && userRoleId != 0) {
      try {
        await BackgroundLocationTrackerManager.startTracking();
        print('PinSetupScreen: GPS tracking started');
      } catch (e) {
        print('PinSetupScreen: Failed to start GPS tracking: $e');
      }
    }

    if (isPermissionsLoaded) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (Route<dynamic> route) => false,
      );
    }
  } else {
    _triggerErrorEffect();
  }
}

  void _triggerErrorEffect() async {
    setState(() {
      _pinsDoNotMatch = true;
    });
    _animationController.forward(from: 0);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _pinsDoNotMatch = false;
      _confirmPin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Image.asset(
                'assets/icons/playstore.png',
                height: 160,
              ),
              const SizedBox(height: 16),
              Text(
                _isConfirming
                    ? (_pinsDoNotMatch
                        ? AppLocalizations.of(context)!
                            .translate('pins_do_not_match_error')
                        : AppLocalizations.of(context)!
                            .translate('confirm_pin_title'))
                    : AppLocalizations.of(context)!.translate('set_pin_title'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _pinsDoNotMatch ? Colors.red : Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset:
                        Offset(_pinsDoNotMatch ? _shakeAnimation.value : 0, 0),
                    child: Column(
                      children: [
                        _buildPinRow(_pin),
                        if (_isConfirming) const SizedBox(height: 16),
                        if (_isConfirming) _buildPinRow(_confirmPin),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                childAspectRatio: 1.5,
                children: [
                  for (var i = 1; i <= 9; i++)
                    TextButton(
                      onPressed: () => _onNumberPressed(i.toString()),
                      child: Text(
                        i.toString(),
                        style:
                            const TextStyle(fontSize: 24, color: Colors.black),
                      ),
                    ),
                  TextButton(
                    onPressed: _onDelete,
                    child: const Icon(Icons.backspace_outlined),
                  ),
                  TextButton(
                    onPressed: () => _onNumberPressed('0'),
                    child: const Text(
                      '0',
                      style: TextStyle(fontSize: 24, color: Colors.black),
                    ),
                  ),
                  const SizedBox(),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _onClear,
                child: Text(
                  AppLocalizations.of(context)!.translate('clear'),
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff1E2E52),
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 20.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinRow(String pin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: _pinsDoNotMatch
                ? Colors.red
                : (index < pin.length
                    ? const Color.fromARGB(255, 33, 41, 188)
                    : Colors.grey.shade300),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}