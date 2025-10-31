import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/good_dashboard_warehouse/good_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/good_dashboard_warehouse/good_dashboard_warehouse_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/good_dashboard_warehouse/good_dashboard_warehouse_state.dart';
import 'package:crm_task_manager/models/page_2/good_dashboard_warehouse_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoodDashboardWarehouseWidget extends StatefulWidget {
  final String? selectedGoodDashboardWarehouse;
  final ValueChanged<String?> onChanged;
  final Key? key;

  const GoodDashboardWarehouseWidget({
    required this.selectedGoodDashboardWarehouse,
    required this.onChanged,
    this.key,
  });

  @override
  State<GoodDashboardWarehouseWidget> createState() => _GoodDashboardWarehouseWidgetState();
}

class _GoodDashboardWarehouseWidgetState extends State<GoodDashboardWarehouseWidget> {
  GoodDashboardWarehouse? selectedGoodData;

  @override
  void initState() {
    super.initState();
    context.read<GoodDashboardWarehouseBloc>().add(FetchGoodDashboardWarehouse());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GoodDashboardWarehouseBloc, GoodDashboardWarehouseState>(
      listener: (context, state) {
        if (state is GoodDashboardWarehouseError) {
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
      child: BlocBuilder<GoodDashboardWarehouseBloc, GoodDashboardWarehouseState>(
        builder: (context, state) {
          // Update data on successful load
          if (state is GoodDashboardWarehouseLoaded) {
            final List<GoodDashboardWarehouse> goodsList = state.goodDashboardWarehouse;

            if (widget.selectedGoodDashboardWarehouse != null && goodsList.isNotEmpty) {
              try {
                selectedGoodData = goodsList.firstWhere(
                      (good) => good.id.toString() == widget.selectedGoodDashboardWarehouse,
                );
              } catch (e) {
                selectedGoodData = null;
              }
            }
          }

          // Always display the field
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('good'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 4),
              CustomDropdown<GoodDashboardWarehouse>.search(
                key: widget.key,
                closeDropDownOnClearFilterSearch: true,
                items: state is GoodDashboardWarehouseLoaded ? state.goodDashboardWarehouse : [],
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
                  // Display price with proper formatting
                  return Text(
                    item.name,
                    style: const TextStyle(
                      color: Color(0xff1E2E52),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
                headerBuilder: (context, selectedItem, enabled) {
                  if (state is GoodDashboardWarehouseLoading) {
                    return Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('select_good'),
                          style: const TextStyle(
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
                  AppLocalizations.of(context)!.translate('select_good'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                excludeSelected: false,
                initialItem: (state is GoodDashboardWarehouseLoaded &&
                    selectedGoodData != null &&
                    state.goodDashboardWarehouse.contains(selectedGoodData))
                    ? selectedGoodData
                    : null,
                onChanged: (value) {
                  if (value != null) {
                    widget.onChanged(value.id.toString());
                    setState(() {
                      selectedGoodData = value;
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