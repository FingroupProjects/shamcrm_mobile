import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth_domain/domain_bloc.dart';
import '../../bloc/auth_domain/domain_event.dart';
import '../../bloc/auth_domain/domain_state.dart';
import 'qr_scanner_screen.dart';
import 'dart:ui' as ui;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final TextEditingController subdomainController = TextEditingController();
  final TextEditingController domainController = TextEditingController();
  bool _isDomainChecked = false;
  bool _showManualInput = false;


  @override
  void initState() {
    super.initState();
      //  main();
    // _checkDomain();
  }

  Future<void> _checkDomain() async {
    final isChecked = await context.read<ApiService>().isDomainChecked();
    if (isChecked) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthScreen()),
      );
    } else {
      setState(() {
        _isDomainChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xff1E2E52)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              width: screenWidth * 0.9,
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.15),
                  Image.asset('assets/icons/shamCRM.jpg', height: 80),
                  SizedBox(height: 30),
                  Visibility(
                    visible: !_showManualInput,
                    child: Column(
                      children: [
                        Text(
                          localizations!.translate('Сканировать QR-код'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        ),
                        SizedBox(height: 10),
                        Icon(
                          Icons.arrow_downward,
                          size: 60,
                          color: Color(0xff1E2E52),
                        ),
                        SizedBox(height: 10),
                        IconButton(
                          icon: Icon(Icons.qr_code_scanner, size: 120, color: Color(0xff1E2E52)),
                          onPressed: () async {
                            final scanResult = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => QrScannerScreen()),
                            );
                          },
                        ),
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showManualInput = true;
                            });
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: Color(0xff4F40EC), width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                localizations.translate('Ручной ввод'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff4F40EC),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: _showManualInput ? null : 0,
                    child: Visibility(
                      visible: _showManualInput,
                      child: Column(
                        children: [
                          SizedBox(height: 24),
                          CustomTextField(
                            controller: domainController,
                            hintText: localizations.translate('Введите Домен'),
                            label: localizations.translate('Домен'),
                          ),
                          SizedBox(height: 24),
                          CustomTextField(
                            controller: subdomainController,
                            hintText: localizations.translate('subdomain_hint'),
                            label: localizations.translate('subdomain_label'),
                          ),
                          SizedBox(height: 24),
                          BlocConsumer<DomainBloc, DomainState>(
                            listener: (context, state) async {
                              if (state is DomainError) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(state.message)),
                                );
                              } else if (state is DomainLoaded) {
                                if (state.domainCheck.result) {
                                  await context.read<ApiService>().saveDomainChecked(true);
                                  await context.read<ApiService>().initialize();
                                  // Добавляем задержку перед переходом
                                  await Future.delayed(Duration(seconds: 2));
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => LoginScreen()),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        localizations.translate('invalid_subdomain'),
                                        style: TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                            builder: (context, state) {
                              // Показываем анимацию для состояний DomainLoading и успешного DomainLoaded
                              if (state is DomainLoading || 
                                  (state is DomainLoaded && state.domainCheck.result)) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                                  ),
                                );
                              }
                              // Показываем кнопку для всех остальных состояний
                              return CustomButton(
                                buttonText: localizations.translate('login_button'),
                                buttonColor: Color(0xff4F40EC),
                                textColor: Colors.white,
                                onPressed: () async {
                                  final subdomain = subdomainController.text.trim();
                                  final domain = domainController.text.trim();
                                  if (subdomain.isNotEmpty) {
                                    await context.read<ApiService>().saveDomain(subdomain, domain);
                                    context.read<DomainBloc>().add(CheckDomain(subdomain));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(localizations.translate('enter_subdomain_error')),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                          SizedBox(height: 24),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showManualInput = false;
                              });
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(color: Color(0xff4F40EC), width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  localizations.translate('QR-CODE'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff4F40EC),
                                  ),
                                ),
                              ),
                            ),
                          ),
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
}
