import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/deliviry_adress/delivery_address_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/deliviry_adress/delivery_address_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/deliviry_adress/delivery_address_state.dart';
import 'package:crm_task_manager/models/page_2/delivery_address_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeliveryAddressDropdown extends StatefulWidget {
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
  State<DeliveryAddressDropdown> createState() => _DeliveryAddressDropdownState();
}

class _DeliveryAddressDropdownState extends State<DeliveryAddressDropdown> {
  int? _autoSelectedAddressId;

  @override
  void initState() {
    super.initState();
    // Fetch addresses on initialization
    _fetchAddresses();
  }

  @override
  void didUpdateWidget(DeliveryAddressDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fetch addresses when leadId changes
    if (oldWidget.leadId != widget.leadId) {
      _fetchAddresses();
    }
  }

  void _fetchAddresses() {
    context.read<DeliveryAddressBloc>().add(
      FetchDeliveryAddresses(leadId: widget.leadId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeliveryAddressBloc, DeliveryAddressState>(
      builder: (context, state) {
        List<DeliveryAddress> addresses = [];
        DeliveryAddress? initialAddress;

        if (state is DeliveryAddressLoading) {
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
              Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xffF4F7FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                  ),
                ),
              ),
            ],
          );
        } else if (state is DeliveryAddressLoaded) {
          addresses = state.addresses;
          // Check if selectedAddress exists in the addresses list
          if (widget.selectedAddress != null) {
            try {
              initialAddress = addresses.firstWhere(
                    (address) => address.id == widget.selectedAddress!.id,
              );
            } catch (e) {
              // If selectedAddress is not found, set initialAddress to null
              initialAddress = null;
            }
          }

          if (addresses.length == 1 &&
              widget.selectedAddress == null &&
              _autoSelectedAddressId != addresses.first.id) {
            final singleAddress = addresses.first;
            _autoSelectedAddressId = singleAddress.id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              widget.onSelectAddress(singleAddress);
            });
            initialAddress = singleAddress;
          }
        } else if (state is DeliveryAddressError) {
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
              Text(
                state.message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontFamily: 'Gilroy',
                ),
              ),
            ],
          );
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
              key: ValueKey(widget.leadId), // Force rebuild when leadId changes
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
                  widget.onSelectAddress(value);
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
