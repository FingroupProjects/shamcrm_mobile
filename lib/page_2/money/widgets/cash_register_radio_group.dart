import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/cash_register_list/cash_register_list_bloc.dart';
import 'package:crm_task_manager/bloc/cash_register_list/cash_register_list_event.dart';
import 'package:crm_task_manager/bloc/cash_register_list/cash_register_list_state.dart';
import 'package:crm_task_manager/models/cash_register_list_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashRegisterGroupWidget extends StatefulWidget {
  final String? selectedCashRegisterId;
  final Function(CashRegisterData) onSelectCashRegister;

  final String? title;

  const CashRegisterGroupWidget({
    super.key,
    required this.onSelectCashRegister,
    this.selectedCashRegisterId,
    this.title,
  });

  @override
  State<CashRegisterGroupWidget> createState() => _CashRegisterGroupWidgetState();
}

class _CashRegisterGroupWidgetState extends State<CashRegisterGroupWidget> {
  List<CashRegisterData> cashRegistersList = [];
  CashRegisterData? selectedCashRegisterData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<GetAllCashRegisterBloc>().state;
        if (state is GetAllCashRegisterSuccess) {
          cashRegistersList = state.dataCashRegisters.result ?? [];
          _updateSelectedCashRegisterData();
        }
        if (state is! GetAllCashRegisterSuccess) {
          context.read<GetAllCashRegisterBloc>().add(GetAllCashRegisterEv());
        }
      }
    });
  }

  void _updateSelectedCashRegisterData() {
    if (widget.selectedCashRegisterId != null && cashRegistersList.isNotEmpty) {
      try {
        selectedCashRegisterData = cashRegistersList.firstWhere(
              (register) => register.id.toString() == widget.selectedCashRegisterId,
        );
        if (selectedCashRegisterData?.id != null) {
          widget.onSelectCashRegister(selectedCashRegisterData!);
        }
      } catch (e) {
        // selectedCashRegisterData = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title ?? AppLocalizations.of(context)!.translate('cash_register'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        BlocBuilder<GetAllCashRegisterBloc, GetAllCashRegisterState>(
          builder: (context, state) {
            if (state is GetAllCashRegisterSuccess) {
              cashRegistersList = state.dataCashRegisters.result ?? [];
              _updateSelectedCashRegisterData();
            }

            return CustomDropdown<CashRegisterData>.search(
              closeDropDownOnClearFilterSearch: true,
              items: cashRegistersList,
              searchHintText: AppLocalizations.of(context)!.translate('search'),
              overlayHeight: 400,
              enabled: true,
              decoration: CustomDropdownDecoration(
                closedFillColor: const Color(0xffF4F7FD),
                expandedFillColor: Colors.white,
                closedBorder: Border.all(
                  color: const Color(0xffF4F7FD),
                  width: 1,
                ),
                closedBorderRadius: BorderRadius.circular(12),
                expandedBorder: Border.all(
                  color: const Color(0xffF4F7FD),
                  width: 1,
                ),
                expandedBorderRadius: BorderRadius.circular(12),
              ),
              listItemBuilder: (context, item, isSelected, onItemSelect) {
                return Text(
                  item.name,
                  style: const TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                  ),
                );
              },
              headerBuilder: (context, selectedItem, enabled) {
                if (state is GetAllCashRegisterLoading) {
                  return Text(
                    AppLocalizations.of(context)!.translate('select_cash_register'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  );
                }
                return Text(
                  selectedItem.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                );
              },
              hintBuilder: (context, hint, enabled) => Text(
                AppLocalizations.of(context)!.translate('select_cash_register'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              excludeSelected: false,
              initialItem: cashRegistersList.contains(selectedCashRegisterData)
                  ? selectedCashRegisterData
                  : null,
              validator: (value) {
                if (value == null) {
                  return AppLocalizations.of(context)!.translate('field_required_project');
                }
                return null;
              },
              onChanged: (value) {
                if (value != null) {
                  widget.onSelectCashRegister(value);
                  setState(() {
                    selectedCashRegisterData = value;
                  });
                  FocusScope.of(context).unfocus();
                }
              },
            );
          },
        ),
      ],
    );
  }
}
