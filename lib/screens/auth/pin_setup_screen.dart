import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/permission/permession_bloc.dart';
import 'package:crm_task_manager/bloc/permission/permession_event.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/models/user_byId_model..dart';
import 'package:crm_task_manager/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  int? userRoleId ;
  bool isPermissionsLoaded = false; 




  @override
  void initState() {
    super.initState();
    _loadUserRoleId();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_animationController);
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
    if (userId.isEmpty) {
      setState(() {
        userRoleId = 0;
      });
      return;
    }

    // Получение ИД РОЛЯ через API
    UserByIdProfile userProfile = await ApiService().getUserById(int.parse(userId));
    setState(() {
      userRoleId = userProfile.role!.first.id;
    });

    await prefs.setInt('userRoleId', userRoleId!);
    await prefs.setString('userRoleName', userProfile.role![0].name);

    // Выводим данные в консоль
    context.read<PermissionsBloc>().add(FetchPermissionsEvent());
    BlocProvider.of<LeadBloc>(context).add(FetchLeadStatuses());
    BlocProvider.of<DealBloc>(context).add(FetchDealStatuses());
    BlocProvider.of<TaskBloc>(context).add(FetchTaskStatuses());

      
      setState(() {
        isPermissionsLoaded = true; 
      });

  } catch (e) {
    print('Error loading user role!');
    setState(() {
      userRoleId = 0;
    });
  }
}


  Future<void> _validatePins() async {
    if (_pin == _confirmPin) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_pin', _pin);
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
                        ? 'Пароли не совпадают'
                        : 'Повторите PIN-код')
                    : 'Установите PIN-код',
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
                    offset: Offset(_pinsDoNotMatch ? _shakeAnimation.value : 0,0), // Эффект "шатания".
                    child: Column(
                      children: [
                        _buildPinRow(_pin),
                        if (_isConfirming)
                          const SizedBox(height: 16), // Отступ между рядами.
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
                  const SizedBox(), // Пустое место для сетки.
                ],
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

