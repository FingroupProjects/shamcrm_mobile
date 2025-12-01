import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/supplier_list/supplier_list_bloc.dart';
import 'package:crm_task_manager/bloc/supplier_list/supplier_list_event.dart';
import 'package:crm_task_manager/bloc/supplier_list/supplier_list_state.dart';
import 'package:crm_task_manager/models/supplier_list_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SupplierGroupWidget extends StatefulWidget {
  final String? selectedSupplierId;
  final Function(SupplierData) onSelectSupplier;

  const SupplierGroupWidget({
    super.key,
    required this.onSelectSupplier,
    this.selectedSupplierId,
  });

  @override
  State<SupplierGroupWidget> createState() => _SupplierGroupWidgetState();
}

class _SupplierGroupWidgetState extends State<SupplierGroupWidget> {
  List<SupplierData> suppliersList = [];
  SupplierData? selectedSupplierData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<GetAllSupplierBloc>().state;
        if (state is GetAllSupplierSuccess) {
          suppliersList = state.dataSuppliers.result ?? [];
          _updateSelectedSupplierData();
        }
        if (state is! GetAllSupplierSuccess) {
          context.read<GetAllSupplierBloc>().add(GetAllSupplierEv());
        }
      }
    });
  }

  void _updateSelectedSupplierData() {
    if (widget.selectedSupplierId != null && suppliersList.isNotEmpty) {
      try {
        selectedSupplierData = suppliersList.firstWhere(
              (supplier) => supplier.id.toString() == widget.selectedSupplierId,
        );
        if (selectedSupplierData?.id != null) {
          widget.onSelectSupplier(selectedSupplierData!);
        }
      } catch (e) {
        // selectedSupplierData = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('supplier'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        BlocBuilder<GetAllSupplierBloc, GetAllSupplierState>(
          builder: (context, state) {
            if (state is GetAllSupplierSuccess) {
              suppliersList = state.dataSuppliers.result ?? [];
              _updateSelectedSupplierData();
            }

            return CustomDropdown<SupplierData>.search(
              closeDropDownOnClearFilterSearch: true,
              items: suppliersList,
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
                if (state is GetAllSupplierLoading) {
                  return Text(
                    AppLocalizations.of(context)!.translate('select_supplier'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  );
                }
                return Text(
                  selectedItem?.name ??
                      AppLocalizations.of(context)!.translate('select_supplier'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                );
              },
              hintBuilder: (context, hint, enabled) => Text(
                AppLocalizations.of(context)!.translate('select_supplier'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              excludeSelected: false,
              initialItem: suppliersList.contains(selectedSupplierData)
                  ? selectedSupplierData
                  : null,
              validator: (value) {
                if (value == null) {
                  return AppLocalizations.of(context)!
                      .translate('field_required_project');
                }
                return null;
              },
              onChanged: (value) {
                if (value != null) {
                  widget.onSelectSupplier(value);
                  setState(() {
                    selectedSupplierData = value;
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