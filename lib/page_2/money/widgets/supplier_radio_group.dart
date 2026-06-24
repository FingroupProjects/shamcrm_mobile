import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
  static const int _pageSize = 20;
  final ApiService _apiService = ApiService();
  List<SupplierData> suppliersList = [];
  SupplierData? selectedSupplierData;
  String? _autoSelectedSupplierId;

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

  Future<CustomDropdownPaginatedResponse<SupplierData>> _searchSuppliers(
    String query,
    int page,
  ) async {
    final response = await _apiService.getAllSuppliers(
      search: query,
      page: page,
      perPage: _pageSize,
    );
    final items = response.result ?? <SupplierData>[];

    return CustomDropdownPaginatedResponse<SupplierData>(
      items: items,
      hasMore: items.length >= _pageSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('supplier'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        BlocBuilder<GetAllSupplierBloc, GetAllSupplierState>(
          builder: (context, state) {
            if (state is GetAllSupplierSuccess) {
              suppliersList = state.dataSuppliers.result ?? [];
              _updateSelectedSupplierData();

              if (suppliersList.length == 1 &&
                  (widget.selectedSupplierId == null ||
                      selectedSupplierData == null) &&
                  _autoSelectedSupplierId !=
                      suppliersList.first.id.toString()) {
                final singleSupplier = suppliersList.first;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  widget.onSelectSupplier(singleSupplier);
                  setState(() {
                    selectedSupplierData = singleSupplier;
                    _autoSelectedSupplierId = singleSupplier.id.toString();
                  });
                });
              }
            }

            return CustomDropdown<SupplierData>.searchRequestPaginated(
              paginatedRequest: _searchSuppliers,
              futureRequestDelay: const Duration(milliseconds: 350),
              closeDropDownOnClearFilterSearch: true,
              items: suppliersList,
              searchHintText: AppLocalizations.of(context)!.translate('search'),
              overlayHeight: 400,
              enabled: true,
              decoration: CustomDropdownDecoration(
                closedFillColor: colors.surfaceElevated,
                expandedFillColor: colors.surfaceElevated,
                closedBorder: Border.all(
                  color: colors.borderSubtle,
                  width: 1,
                ),
                closedBorderRadius: BorderRadius.circular(12),
                expandedBorder: Border.all(
                  color: colors.borderSubtle,
                  width: 1,
                ),
                expandedBorderRadius: BorderRadius.circular(12),
                listItemDecoration: ListItemDecoration(
                  splashColor: colors.buttonPrimaryBg.withValues(alpha: 0.10),
                  highlightColor:
                      colors.buttonPrimaryBg.withValues(alpha: 0.12),
                  selectedColor: colors.surfaceElevated,
                ),
              ),
              listItemBuilder: (context, item, isSelected, onItemSelect) {
                return Text(
                  item.name,
                  style: TextStyle(
                    color: colors.textPrimary,
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: colors.textPrimary,
                    ),
                  );
                }
                return Text(
                  selectedItem.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: colors.textPrimary,
                  ),
                );
              },
              hintBuilder: (context, hint, enabled) => Text(
                AppLocalizations.of(context)!.translate('select_supplier'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
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
