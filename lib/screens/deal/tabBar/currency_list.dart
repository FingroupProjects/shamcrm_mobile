import 'package:crm_task_manager/bloc/currency/currency_bloc.dart';
import 'package:crm_task_manager/bloc/currency/currency_state.dart';
import 'package:crm_task_manager/models/currency_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CurrencyWidget extends StatefulWidget {
  final String? selectedCurrency;
  final ValueChanged<String?> onChanged;

  CurrencyWidget({required this.selectedCurrency, required this.onChanged});

  @override
  _CurrencyWidgetState createState() => _CurrencyWidgetState();
}

class _CurrencyWidgetState extends State<CurrencyWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrencyBloc, CurrencyState>(
      builder: (context, state) {
        List<DropdownMenuItem<String>> dropdownItems = [];

        if (state is CurrencyLoading) {
          dropdownItems = [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Загрузка...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ];
        } else if (state is CurrencyLoaded) {
          if (state.currencies.isEmpty) {
            dropdownItems = [
              DropdownMenuItem(
                value: null,
                child: Text(
                  'Нет валюты',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
              ),
            ];
          } else {
            dropdownItems = state.currencies.map<DropdownMenuItem<String>>((Currency currency) {
              return DropdownMenuItem<String>(
                value: currency.id.toString(),
                child: Text(currency.name),
              );
            }).toList();
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Валюта',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonFormField<String>(
                value: dropdownItems.any((item) => item.value == widget.selectedCurrency)
                    ? widget.selectedCurrency
                    : null,
                hint: const Text(
                  'Выберите валюту',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                items: dropdownItems,
                onChanged: widget.onChanged,
                validator: (value) {
                  if (value == null) {
                    return 'Поле обязательно для заполнения';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: Colors.white,
                icon: Image.asset(
                  'assets/icons/tabBar/dropdown.png',
                  width: 16,
                  height: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
