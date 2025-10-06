import 'package:animated_custom_dropdown/custom_dropdown.dart';

import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/order_status_warehouse/order_status_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/order_status_warehouse/order_status_warehouse_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/order_status_warehouse/order_status_warehouse_state.dart';
import 'package:crm_task_manager/models/page_2/order_status_warehouse_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderStatusWarehouseWidget extends StatefulWidget {
  final String? selectedOrderStatusWarehouse;
  final ValueChanged<String?> onChanged;

  const OrderStatusWarehouseWidget({
    required this.selectedOrderStatusWarehouse,
    required this.onChanged,
  });

  @override
  State<OrderStatusWarehouseWidget> createState() => _OrderStatusWarehouseWidgetState();
}

class _OrderStatusWarehouseWidgetState extends State<OrderStatusWarehouseWidget> {
  OrderStatusWarehouse? selectedOrderStatusData;

  @override
  void initState() {
    super.initState();
    context.read<OrderStatusWarehouseBloc>().add(FetchOrderStatusWarehouse());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderStatusWarehouseBloc, OrderStatusWarehouseState>(
      listener: (context, state) {
        if (state is OrderStatusWarehouseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),  // Адаптировать ключ, если message не локализован
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
      child: BlocBuilder<OrderStatusWarehouseBloc, OrderStatusWarehouseState>(
        builder: (context, state) {
          // Обновляем данные при успешной загрузке
          if (state is OrderStatusWarehouseLoaded) {
            final List<OrderStatusWarehouse> orderStatusList = state.orderStatusWarehouse;
            
            if (widget.selectedOrderStatusWarehouse != null && orderStatusList.isNotEmpty) {
              try {
                selectedOrderStatusData = orderStatusList.firstWhere(
                  (orderStatus) => orderStatus.id.toString() == widget.selectedOrderStatusWarehouse,
                );
              } catch (e) {
                selectedOrderStatusData = null;
              }
            }
          }

          // Всегда отображаем поле
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('order_status'),  // Ключ для "Статус заказа"
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 4),
              CustomDropdown<OrderStatusWarehouse>.search(
                closeDropDownOnClearFilterSearch: true,
                items: state is OrderStatusWarehouseLoaded ? state.orderStatusWarehouse : [],
                searchHintText: AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 400,
                enabled: true,  // Всегда enabled
                decoration:  CustomDropdownDecoration(
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
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(int.parse('0xFF${item.color}')),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: Color(0xff1E2E52),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Gilroy',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${item.ordersCount}',
                          style: const TextStyle(
                            color: Color(0xff1E2E52),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ],
                    ),
                  );
                },
                headerBuilder: (context, selectedItem, enabled) {
                  if (state is OrderStatusWarehouseLoading) {
                    return Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('select_order_status'),  // Ключ для "Выберите статус заказа"
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
                  return Row(
                    children: [
                      if (selectedItem != null) ...[
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(int.parse('0xFF${selectedItem.color}')),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        selectedItem.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ],
                  );
                },
                hintBuilder: (context, hint, enabled) => Text(
                  AppLocalizations.of(context)!.translate('select_order_status'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                excludeSelected: false,
                initialItem: (state is OrderStatusWarehouseLoaded && state.orderStatusWarehouse.contains(selectedOrderStatusData))
                    ? selectedOrderStatusData
                    : null,
                onChanged: (value) {
                  if (value != null) {
                    widget.onChanged(value.id.toString());
                    setState(() {
                      selectedOrderStatusData = value;
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
