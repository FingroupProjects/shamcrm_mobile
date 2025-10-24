import 'package:flutter/material.dart';
import '../../../../models/page_2/openings/cash_register_openings_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../custom_widget/custom_button.dart';

class EditCashRegisterOpeningScreen extends StatefulWidget {
  final CashRegisterOpening cashRegisterOpening;

  const EditCashRegisterOpeningScreen({Key? key, required this.cashRegisterOpening})
      : super(key: key);

  @override
  _EditCashRegisterOpeningScreenState createState() =>
      _EditCashRegisterOpeningScreenState();
}

class _EditCashRegisterOpeningScreenState
    extends State<EditCashRegisterOpeningScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.translate('edit_cash_register_opening') ??
              'Редактировать остаток кассы',
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TODO: Add form fields here
                      const Center(
                        child: Text(
                          'Содержимое формы будет добавлено позже',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w400,
                            color: Color(0xff99A4BA),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      buttonText:
                          AppLocalizations.of(context)!.translate('close') ??
                              'Отмена',
                      buttonColor: const Color(0xffF4F7FD),
                      textColor: Colors.black,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      buttonText:
                          AppLocalizations.of(context)!.translate('save') ??
                              'Сохранить',
                      buttonColor: const Color(0xff4759FF),
                      textColor: Colors.white,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // TODO: Implement save logic
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

