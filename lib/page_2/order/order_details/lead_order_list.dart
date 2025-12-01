import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/lead_order.dart/lead_order_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/lead_order.dart/lead_order_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/lead_order.dart/lead_order_state.dart';
import 'package:crm_task_manager/models/page_2/lead_order_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadOrderRadioGroupWidget extends StatefulWidget {
  final String? selectedLeadOrder;
  final Function(LeadOrderData) onSelectLeadOrder;
  final Function(String) onManualLeadOrderName;

  LeadOrderRadioGroupWidget({
    super.key,
    required this.onSelectLeadOrder,
    required this.onManualLeadOrderName,
    this.selectedLeadOrder,
  });

  @override
  State<LeadOrderRadioGroupWidget> createState() => _LeadOrderRadioGroupWidgetState();
}

class _LeadOrderRadioGroupWidgetState extends State<LeadOrderRadioGroupWidget> {
  List<LeadOrderData> leadOrdersList = [];
  LeadOrderData? selectedLeadOrderData;
  bool isManualEntry = false;
  final TextEditingController manualEntryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<LeadOrderBloc>().add(FetchLeadOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('lead_order'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isManualEntry = !isManualEntry;
                  if (!isManualEntry) {
                    manualEntryController.clear();
                    widget.onManualLeadOrderName('');
                  }
                });
              },
              child: Text(
                isManualEntry
                    ? AppLocalizations.of(context)!.translate('select_from_list')
                    : AppLocalizations.of(context)!.translate('enter_manually'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff4759FF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        isManualEntry
            ? _buildManualEntryField()
            : _buildDropdownField(),
      ],
    );
  }

  Widget _buildManualEntryField() {
    return TextField(
      controller: manualEntryController,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.translate('enter_lead_order_name'),
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Gilroy',
          color: Color(0xff99A4BA),
        ),
        filled: true,
        fillColor: Color(0xffF4F7FD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xffF4F7FD), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xffF4F7FD), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xffF4F7FD), width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gilroy',
        color: Color(0xff1E2E52),
      ),
      onChanged: (value) {
        widget.onManualLeadOrderName(value);
      },
    );
  }

  Widget _buildDropdownField() {
    return BlocConsumer<LeadOrderBloc, LeadOrderState>(
      listener: (context, state) {
        if (state is LeadOrderLoaded) {
          setState(() {
            leadOrdersList = state.leadOrders;
            if (widget.selectedLeadOrder != null && leadOrdersList.isNotEmpty) {
              try {
                selectedLeadOrderData = leadOrdersList.firstWhere(
                  (leadOrder) => leadOrder.id.toString() == widget.selectedLeadOrder,
                );
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onSelectLeadOrder(selectedLeadOrderData!);
                });
              } catch (e) {
                selectedLeadOrderData = null;
              }
            }
          });
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              child: CustomDropdown<LeadOrderData>.search(
                closeDropDownOnClearFilterSearch: true,
                items: leadOrdersList,
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
                    style: TextStyle(
                      color: Color(0xff1E2E52),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                    ),
                  );
                },
                headerBuilder: (context, selectedItem, enabled) {
                  if (state is LeadOrderLoading && leadOrdersList.isEmpty) {
                    return Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('select_lead_orders'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ],
                    );
                  }
                  return Text(
                    selectedItem?.name ??
                        AppLocalizations.of(context)!.translate('select_lead_orders'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  );
                },
                hintBuilder: (context, hint, enabled) => Text(
                  AppLocalizations.of(context)!.translate('select_lead_order'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                excludeSelected: false,
                initialItem: selectedLeadOrderData,
                validator: (value) {
                  if (value == null && manualEntryController.text.isEmpty) {
                    return AppLocalizations.of(context)!.translate('field_required_lead_order');
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value != null) {
                    widget.onSelectLeadOrder(value);
                    setState(() {
                      selectedLeadOrderData = value;
                    });
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    manualEntryController.dispose();
    super.dispose();
  }
}