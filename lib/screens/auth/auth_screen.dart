import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/auth_domain/domain_bloc.dart';
import '../../bloc/auth_domain/domain_event.dart';
import '../../bloc/auth_domain/domain_state.dart';
import '../../bloc/login/login_bloc.dart';
import '../../bloc/login/login_event.dart';
import '../../bloc/login/login_state.dart';
import 'qr_scanner_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static final Uri _demoUri = Uri.parse('https://shamcrm.com/');
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _showManualInput = false;
  bool _showPasswordField = false;
  String _verifiedLogin = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Запускаем проверку домена асинхронно
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDomainAsync();
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Function to validate email
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  // Асинхронная проверка домена
  Future<void> _checkDomainAsync() async {
    try {
      await context.read<ApiService>().isDomainChecked();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      //print('AuthScreen: Error checking domain: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openDemoRequest() async {
    final launched = await launchUrl(
      _demoUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.translate('site_open_failed') ??
                'Не удалось открыть сайт',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return Scaffold(
        body: Center(child: Text('Localization not available')),
      );
    }

    // Показываем индикатор загрузки пока проверяется домен
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
              ),
              SizedBox(height: 20),
              Text(
                localizations.translate('configuration_check'),
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
            ],
          ),
        ),
      );
    }

    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xff1E2E52)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              width: screenWidth * 0.9,
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.15),
                  Image.asset('assets/images/new_icon_shamCRM.jpg', height: 80),
                  const SizedBox(height: 30),
                  Visibility(
                    visible: !_showManualInput,
                    child: Column(
                      children: [
                        Text(
                          localizations.translate('scan_qr_prompt'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Icon(
                          Icons.arrow_downward,
                          size: 60,
                          color: Color(0xff1E2E52),
                        ),
                        const SizedBox(height: 10),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner,
                              size: 120, color: Color(0xff1E2E52)),
                          onPressed: () async {
                            try {
                              final scanResult = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => QrScannerScreen()),
                              );
                              if (scanResult != null &&
                                  scanResult is String &&
                                  mounted) {
                                if (_isValidEmail(scanResult)) {
                                  setState(() {
                                    _showManualInput = true;
                                    emailController.text = scanResult;
                                    _showPasswordField = false;
                                    _verifiedLogin = '';
                                  });
                                  context
                                      .read<DomainBloc>()
                                      .add(CheckEmail(scanResult));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        localizations
                                            .translate('invalid_email_in_qr'),
                                      ),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              //print('AuthScreen: Error with QR scan: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations.translate('qr_scan_error'),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showManualInput = true;
                            });
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                    color: const Color(0xff4F40EC), width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                localizations.translate('manual_input'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Gilroy',
                                  color: Color(0xff4F40EC),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildDemoCard(localizations),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: _showManualInput ? null : 0,
                    child: Visibility(
                      visible: _showManualInput,
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          CustomTextField(
                            controller: emailController,
                            hintText: 'example@company.com',
                            label: localizations.translate('email'),
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_showPasswordField,
                            showEditButton: _showPasswordField,
                            onEditPressed: () {
                              setState(() {
                                _showPasswordField = false;
                                passwordController.clear();
                                _verifiedLogin = '';
                              });
                            },
                            backgroundColor: _showPasswordField
                                ? const Color(0xffE8F2FF)
                                : const Color(0xffF4F7FD),
                          ),
                          const SizedBox(height: 16),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: _showPasswordField ? null : 0,
                            child: _showPasswordField
                                ? Column(
                                    children: [
                                      CustomTextField(
                                        controller: passwordController,
                                        hintText: localizations
                                            .translate('login_password_hint'),
                                        label: localizations
                                            .translate('login_password_label'),
                                        isPassword: true,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                          BlocConsumer<DomainBloc, DomainState>(
                            listener: (context, state) async {
                              try {
                                if (state is DomainError) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context)!
                                            .translate(state.message),
                                        style: TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
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
                                } else if (state is EmailVerified) {
                                  setState(() {
                                    _showPasswordField = true;
                                    _verifiedLogin = state.login;
                                  });
                                  await context
                                      .read<ApiService>()
                                      .initializeWithEmailFlow();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle,
                                                color: Colors.white, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              localizations.translate(
                                                'email_verified_success',
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                //print('AuthScreen: Error in domain listener: $e');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        localizations.translate(
                                          'email_verification_error',
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            builder: (context, domainState) {
                              if (!_showPasswordField) {
                                if (domainState is DomainLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xff1E2E52)),
                                    ),
                                  );
                                }
                                return CustomButton(
                                  buttonText: localizations
                                      .translate('continue_button'),
                                  buttonColor: const Color(0xff4F40EC),
                                  textColor: Colors.white,
                                  onPressed: () {
                                    final email = emailController.text.trim();
                                    if (email.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(localizations
                                                .translate('enter_email'))),
                                      );
                                    } else if (!_isValidEmail(email)) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(localizations
                                                .translate('invalid_email'))),
                                      );
                                    } else {
                                      context
                                          .read<DomainBloc>()
                                          .add(CheckEmail(email));
                                    }
                                  },
                                );
                              }
                              return BlocConsumer<LoginBloc, LoginState>(
                                listener: (context, loginState) async {
                                  try {
                                    if (loginState is LoginLoaded) {
                                      SharedPreferences prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.setString('userName',
                                          loginState.user.name.toString());
                                      await prefs.setString('userID',
                                          loginState.user.id.toString());
                                      await prefs.setString('userLogin',
                                          loginState.user.login.toString());

                                      // НОВОЕ: Сохраняем информацию о hasMiniApp из ответа сервера
                                      bool hasMiniApp = loginState
                                          .hasMiniApp; // Теперь это поле есть в LoginLoaded

                                      await prefs.setBool(
                                          'hasMiniApp', hasMiniApp);
                                      //print('AuthScreen: Saved hasMiniApp: $hasMiniApp');

                                      await context
                                          .read<ApiService>()
                                          .getSelectedOrganization();
                                      //print('AuthScreen: Login successful, organization_id: $organizationId');
                                      await Future.delayed(
                                          const Duration(seconds: 2));
                                      if (mounted) {
                                        await _checkPinSetupStatus(context);
                                      }
                                    } else if (loginState is LoginError) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(context)!
                                                .translate(loginState.message),
                                            style: TextStyle(
                                              fontFamily: 'Gilroy',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          backgroundColor: Colors.red,
                                          elevation: 3,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 16),
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    //print('AuthScreen: Error in login listener: $e');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            localizations.translate(
                                              'login_error_system',
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                builder: (context, loginState) {
                                  if (loginState is LoginLoading ||
                                      loginState is LoginLoaded) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Color(0xff1E2E52)),
                                      ),
                                    );
                                  }
                                  return CustomButton(
                                    buttonText:
                                        localizations.translate('login_button'),
                                    buttonColor: const Color(0xff4F40EC),
                                    textColor: Colors.white,
                                    onPressed: () {
                                      final password =
                                          passwordController.text.trim();
                                      if (password.isNotEmpty) {
                                        context.read<LoginBloc>().add(
                                              CheckLogin(
                                                  _verifiedLogin, password),
                                            );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  localizations.translate(
                                                      'login_password_hint'))),
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showManualInput = false;
                                _showPasswordField = false;
                                emailController.clear();
                                passwordController.clear();
                                _verifiedLogin = '';
                              });
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(
                                      color: const Color(0xff4F40EC), width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  localizations.translate('qr_code_label'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Gilroy',
                                    color: Color(0xff4F40EC),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _buildDemoCard(localizations),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkPinSetupStatus(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPinSetupComplete = prefs.getBool('isPinSetupComplete') ?? false;

      if (!isPinSetupComplete) {
        await prefs.setBool('isPinSetupComplete', true);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/pin_setup');
        }
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/pin_screen');
        }
      }
    } catch (e) {
      //print('AuthScreen: Error checking PIN setup status: $e');
      if (mounted) {
        // Fallback - идем на pin_setup
        Navigator.pushReplacementNamed(context, '/pin_setup');
      }
    }
  }

  Widget _buildDemoCard(AppLocalizations localizations) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(
          localizations.translate('auth_signup_prompt'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff6E7B96),
          ),
        ),
        InkWell(
          onTap: _openDemoRequest,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Text(
              localizations.translate('auth_signup_cta'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'Gilroy',
                color: Color(0xff4F40EC),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
