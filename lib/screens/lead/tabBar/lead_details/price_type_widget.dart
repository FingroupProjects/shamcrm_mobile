import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/pricce_type/price_type_bloc.dart';
import 'package:crm_task_manager/bloc/pricce_type/price_type_event.dart';
import 'package:crm_task_manager/bloc/pricce_type/price_type_state.dart';
import 'package:crm_task_manager/models/price_type_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PriceTypeWidget extends StatefulWidget {
  final String? selectedPriceType;
  final ValueChanged<String?> onChanged;

  const PriceTypeWidget({
    Key? key,
    required this.selectedPriceType,
    required this.onChanged,
  }) : super(key: key);

  @override
  _PriceTypeWidgetState createState() => _PriceTypeWidgetState();
}

class _PriceTypeWidgetState extends State<PriceTypeWidget> {
  PriceType? selectedPriceTypeData;

  @override
  void initState() {
    super.initState();
    context.read<PriceTypeBloc>().add(FetchPriceType());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PriceTypeBloc, PriceTypeState>(
      listener: (context, state) {
        if (state is PriceTypeError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.red,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: BlocBuilder<PriceTypeBloc, PriceTypeState>(
        builder: (context, state) {
          if (state is PriceTypeLoaded) {
            List<PriceType> priceTypesList = state.priceTypes;

            if (widget.selectedPriceType != null && priceTypesList.isNotEmpty) {
              try {
                selectedPriceTypeData = priceTypesList.firstWhere(
                  (priceType) => priceType.id.toString() == widget.selectedPriceType,
                );
              } catch (e) {
                selectedPriceTypeData = null;
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('price_type'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 4),
              CustomDropdown<PriceType>.search(
                closeDropDownOnClearFilterSearch: true,
                items: state is PriceTypeLoaded ? state.priceTypes : [],
                searchHintText: AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 400,
                enabled: true,
                decoration: CustomDropdownDecoration(
                  closedFillColor: Color(0xffF4F7FD),
                  expandedFillColor: Colors.white,
                  closedBorder: Border.all(
                    color: Color(0xffF4F7FD),
                    width: 1,
                  ),
                  closedBorderRadius: BorderRadius.circular(12),
                  expandedBorder: Border.all(
                    color: Color(0xffF4F7FD),
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
                  if (state is PriceTypeLoading) {
                    return Text(
                      AppLocalizations.of(context)!.translate('select_price_type'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    );
                  }
                  return Text(
                    selectedItem?.name ?? AppLocalizations.of(context)!.translate('select_price_type'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  );
                },
                hintBuilder: (context, hint, enabled) => Text(
                  AppLocalizations.of(context)!.translate('select_price_type'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                excludeSelected: false,
                initialItem: (state is PriceTypeLoaded && state.priceTypes.contains(selectedPriceTypeData))
                    ? selectedPriceTypeData
                    : null,
                onChanged: (value) {
                  if (value != null) {
                    widget.onChanged(value.id.toString());
                    setState(() {
                      selectedPriceTypeData = value;
                    });
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}