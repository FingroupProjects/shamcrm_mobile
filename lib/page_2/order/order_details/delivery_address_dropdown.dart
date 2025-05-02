import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/deliviry_adress/delivery_address_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/deliviry_adress/delivery_address_state.dart';
import 'package:crm_task_manager/models/page_2/delivery_address_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeliveryAddressDropdown extends StatelessWidget {
  final int leadId;
  final int organizationId;
  final DeliveryAddress? selectedAddress;
  final Function(DeliveryAddress) onSelectAddress;

  const DeliveryAddressDropdown({
    super.key,
    required this.leadId,
    required this.organizationId,
    this.selectedAddress,
    required this.onSelectAddress,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeliveryAddressBloc, DeliveryAddressState>(
      builder: (context, state) {
        List<DeliveryAddress> addresses = [];
        DeliveryAddress? initialAddress;

        if (state is DeliveryAddressLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is DeliveryAddressLoaded) {
          addresses = state.addresses;
          // Проверяем, есть ли selectedAddress в списке addresses
          if (selectedAddress != null) {
            initialAddress = addresses.firstWhere(
              (address) => address.id == selectedAddress!.id,
              orElse: () => selectedAddress!,
            );
          }
        } else if (state is DeliveryAddressError) {
          return Text(state.message);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('delivery_address'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 4),
            CustomDropdown<DeliveryAddress>.search(
              closeDropDownOnClearFilterSearch: true,
              items: addresses,
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
                  item.address,
                  style: const TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                  ),
                );
              },
              headerBuilder: (context, selectedItem, enabled) {
                if (state is DeliveryAddressLoading) {
                  return Text(
                    AppLocalizations.of(context)!.translate('select_delivery_address'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  );
                }
                return Text(
                  selectedItem?.address ??
                      AppLocalizations.of(context)!.translate('select_delivery_address'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                );
              },
              hintBuilder: (context, hint, enabled) => Text(
                AppLocalizations.of(context)!.translate('select_delivery_address'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              excludeSelected: false,
              initialItem: initialAddress,
              validator: (value) {
                if (value == null) {
                  return AppLocalizations.of(context)!
                      .translate('field_required_project');
                }
                return null;
              },
              onChanged: (value) {
                if (value != null) {
                  onSelectAddress(value);
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          ],
        );
      },
    );
  }
}