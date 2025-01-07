import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth_domain/domain_bloc.dart';
import '../../bloc/auth_domain/domain_event.dart';
import '../../bloc/auth_domain/domain_state.dart';
import 'qr_scanner_screen.dart'; 

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController subdomainController = TextEditingController();
    double screenHeight = MediaQuery.of(context).size.height;

    return FutureBuilder(
      future: context.read<ApiService>().isDomainChecked(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
        }

        if (snapshot.data == true) {
          Future.microtask(() => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => LoginScreen())));
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Color.fromARGB(255, 255, 255, 255),
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xff1E2E52)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Icon(Icons.qr_code_scanner),
                  iconSize: 40,
                  onPressed: () async {
                    final scanResult = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => QrScannerScreen()),
                    );
                  },
                ),
              )
            ],
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start, 
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    SizedBox(height: screenHeight * 0.15), 
                  Padding(
                    padding: const EdgeInsets.only(right: 0),
                    child: Image.asset(
                      'assets/icons/11.png',
                      height: 80,
                    ),
                  ),
                  SizedBox(height: 30),
                  const Text(
                    'Введите ваш поддомен',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  SizedBox(height: 24),
                  CustomTextField(
                    controller: subdomainController,
                    hintText: 'Введите поддомен',
                    label: 'Поддомен',
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
                                'Неверный поддомен',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.red,
                              elevation: 3,
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                    builder: (context, state) {
                      if (state is DomainLoading) {
                        return CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xfff1E2E52)),
                        );
                      }
                      return CustomButton(
                        buttonText: 'Войти',
                        buttonColor: Color(0xfff4F40EC),
                        textColor: Colors.white,
                        onPressed: () async {
                          final subdomain = subdomainController.text.trim();
                          if (subdomain.isNotEmpty) {
                            await context.read<ApiService>().saveDomain(subdomain);
                            context.read<DomainBloc>().add(CheckDomain(subdomain));
                            String? savedDomain = await context.read<ApiService>().getEnteredDomain();
                            print('Сохранённый домен: $savedDomain');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Пожалуйста, введите поддомен'),
                              ),
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
        );
      },
    );
  }
}
