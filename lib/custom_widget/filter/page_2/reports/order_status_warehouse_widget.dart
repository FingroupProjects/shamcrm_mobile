import 'package:animated_custom_dropdown/custom_dropdown.dart';

import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/order_status_warehouse/order_status_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/order_status_warehouse/order_status_warehouse_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/order_status_warehouse/order_status_warehouse_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/order_status_warehouse_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderStatusWarehouseWidget extends StatefulWidget {
  final String? selectedOrderStatusWarehouse;
  final ValueChanged<String?> onChanged;

  const OrderStatusWarehouseWidget({
    super.key,
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

  /// Безопасно парсит цвет из строки
  /// Возвращает серый цвет по умолчанию в случае ошибки
  Color _parseColorSafely(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return const Color(0xFF9E9E9E); // Серый цвет по умолчанию
    }

    try {
      // Удаляем # если есть
      String cleanColor = colorString.replaceAll('#', '');
      
      // Если цвет уже содержит альфа-канал (8 символов), используем как есть
      if (cleanColor.length == 8) {
        return Color(int.parse('0x$cleanColor'));
      }
      
      // Если цвет без альфа-канала (6 символов), добавляем FF в начало
      if (cleanColor.length == 6) {
        return Color(int.parse('0xFF$cleanColor'));
      }
      
      // Если длина не 6 и не 8, возвращаем цвет по умолчанию
      return const Color(0xFF9E9E9E);
    } catch (e) {
      // В случае любой ошибки парсинга возвращаем цвет по умолчанию
      debugPrint('Ошибка парсинга цвета: $colorString, error: $e');
      return const Color(0xFF9E9E9E);
    }
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
                style: context.appTextStyles.bodyLg.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textInverse,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: context.appColors.error,
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
                style: context.appTextStyles.bodyLg.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              CustomDropdown<OrderStatusWarehouse>.search(
                key: widget.key,
                closeDropDownOnClearFilterSearch: true,
                items: state is OrderStatusWarehouseLoaded ? state.orderStatusWarehouse : [],
                searchHintText: AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 400,
                enabled: true,  // Всегда enabled
                decoration: CustomDropdownDecoration(
                  closedFillColor: context.appColors.fieldBg,
                  expandedFillColor: context.appColors.surfacePrimary,
                  closedBorder: Border.all(
                    color: context.appColors.fieldBg,
                    width: 1,
                  ),
                  closedBorderRadius: BorderRadius.circular(12),
                  expandedBorder: Border.all(
                    color: context.appColors.fieldBg,
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
                            color: _parseColorSafely(item.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            style: context.appTextStyles.bodyMd.copyWith(
                              color: context.appColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${item.ordersCount}',
                          style: context.appTextStyles.bodySm.copyWith(
                            color: context.appColors.textPrimary,
                            fontWeight: FontWeight.w400,
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
                          style: context.appTextStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.w500,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _parseColorSafely(selectedItem.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedItem.name,
                        style: context.appTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    ],
                  );
                },
                hintBuilder: (context, hint, enabled) => Text(
                  AppLocalizations.of(context)!.translate('select_order_status'),
                  style: context.appTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
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
