import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth_domain/domain_bloc.dart';
import '../../bloc/auth_domain/domain_event.dart';
import '../../bloc/auth_domain/domain_state.dart';
import 'qr_scanner_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController subdomainController = TextEditingController();
  bool _isDomainChecked = false;

  @override
  void initState() {
    super.initState();
    _checkDomain();
  }

  Future<void> _checkDomain() async {
    final isChecked = await context.read<ApiService>().isDomainChecked();
    if (isChecked) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
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
    if (!_isDomainChecked) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xff1E2E52))),
      );
    }

    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xff1E2E52)),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, size: 40),
            onPressed: () async {
              final scanResult = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QrScannerScreen()),
              );
            },
          ),
        ],
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
                  Text(
                    localizations!.translate('enter_subdomain'), // Локализованный текст
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Gilroy'),
                  ),
                  SizedBox(height: 24),
                  CustomTextField(
                    controller: subdomainController,
                    hintText: localizations.translate('subdomain_hint'), // Локализованный текст
                    label: localizations.translate('subdomain_label'), // Локализованный текст
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
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations.translate('invalid_subdomain'), // Локализованный текст
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
                      if (state is DomainLoading) {
                        return CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                        );
                      }
                      return CustomButton(
                        buttonText: localizations.translate('login_button'), 
                        buttonColor: Color(0xff4F40EC),
                        textColor: Colors.white,
                        onPressed: () async {
                          final subdomain = subdomainController.text.trim();
                          if (subdomain.isNotEmpty) {
                            await context.read<ApiService>().saveDomain(subdomain);
                            context.read<DomainBloc>().add(CheckDomain(subdomain));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(localizations.translate('enter_subdomain_error')),),
                            );
                          }
                        },
                      );
                    },
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