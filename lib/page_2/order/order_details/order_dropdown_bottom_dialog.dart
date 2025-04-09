import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void OrderDropdownBottomSheet(
  BuildContext context,
  String defaultValue,
  Function(String, int) onSelect,
  Order order, {
  required Function(int) onTabChange, // Новый коллбэк для переключения таба
}) {
  String selectedValue = defaultValue;
  int? selectedStatusId = order.orderStatus.id;

  final currentState = context.read<OrderBloc>().state;
  print('Состояние перед открытием BottomSheet: $currentState');
  if (currentState is! OrderLoaded || currentState.statuses.isEmpty) {
    context.read<OrderBloc>().add(FetchOrderStatuses());
    print('Отправлено событие FetchOrderStatuses');
  } else {
    print('Статусы уже загружены: ${currentState.statuses.length}');
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          print('Текущее состояние в BlocBuilder: $state');

          if (currentState is OrderLoaded && currentState.statuses.isNotEmpty) {
            final orderStatuses = currentState.statuses;
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Container(
                  height: 700,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xffDFE3EC),
                          borderRadius: BorderRadius.circular(1200),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: orderStatuses.map((status) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedValue = status.name;
                                  selectedStatusId = status.id;
                                });
                              },
                              child: buildDropDownStyles(
                                text: status.name,
                                isSelected: selectedValue == status.name,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      CustomButton(
                        buttonText: AppLocalizations.of(context)!.translate('save'),
                        buttonColor: const Color(0xff4F40EC),
                        textColor: Colors.white,
                        onPressed: () {
                          if (selectedStatusId != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!
                                      .translate('status_changed_successfully'),
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
                                backgroundColor: Colors.green,
                                elevation: 3,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                duration: const Duration(seconds: 3),
                              ),
                            );

                            onSelect(selectedValue, selectedStatusId!);

                            context.read<OrderBloc>().add(ChangeOrderStatus(
                              orderId: order.id,
                              statusId: selectedStatusId!,
                              organizationId: order.organizationId,
                            ));

                            Navigator.pop(context);

                            final newTabIndex = orderStatuses.indexWhere((status) => status.id == selectedStatusId);
                            if (newTabIndex != -1) {
                              onTabChange(newTabIndex); // Передаем индекс таба через коллбэк
                              context.read<OrderBloc>().add(FetchOrders(statusId: selectedStatusId!));
                            }
                          } else {
                            print('Статус не выбран');
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          } else if (state is OrderLoading) {
            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          } else if (state is OrderError) {
            return Center(child: Text(state.message));
          }
          return const Center(
            child: PlayStoreImageLoading(
              size: 80.0,
              duration: Duration(milliseconds: 1000),
            ),
          );
        },
      );
    },
  );
}