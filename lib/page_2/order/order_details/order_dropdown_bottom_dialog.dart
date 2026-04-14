import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/screens/common/reason_for_refusal_modal.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> OrderDropdownBottomSheet(
  BuildContext context,
  String defaultValue,
  Function(String, int) onSelect,
  Order order, {
  required Function(int) onTabChange,
}) async {
  String selectedValue = defaultValue;
  int? selectedStatusId = order.orderStatus.id;

  final initialState = context.read<OrderBloc>().state;
  if (initialState is! OrderLoaded || initialState.statuses.isEmpty) {
    context.read<OrderBloc>().add(FetchOrderStatuses());
  }

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          final OrderLoaded? loadedState = state is OrderLoaded
              ? state
              : initialState is OrderLoaded
                  ? initialState
                  : null;

          if (loadedState == null || loadedState.statuses.isEmpty) {
            if (state is OrderError) {
              return Center(child: Text(state.message));
            }
            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          }

          final orderStatuses = loadedState.statuses;
          bool isSubmittingSave = false;

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
                      margin: const EdgeInsets.only(top: 7),
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
                    isSubmittingSave
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xff1E2E52),
                              ),
                            ),
                          )
                        : CustomButton(
                            buttonText: AppLocalizations.of(context)!
                                .translate('save'),
                            buttonColor: const Color(0xff4F40EC),
                            textColor: Colors.white,
                            onPressed: () async {
                              if (isSubmittingSave || selectedStatusId == null) {
                                return;
                              }

                              final prefs =
                                  await SharedPreferences.getInstance();
                              final askReasonForRefusal =
                                  prefs.getBool('ask_reason_for_refusal') ??
                                      false;
                              final selectedStatus = orderStatuses
                                  .where((status) => status.id == selectedStatusId)
                                  .cast<dynamic>()
                                  .firstWhere(
                                    (_) => true,
                                    orElse: () => null,
                                  );

                              ReasonForRefusalSubmitData? refusalData;
                              if (selectedStatusId != order.orderStatus.id &&
                                  askReasonForRefusal &&
                                  selectedStatus != null &&
                                  selectedStatus.isFailed == true) {
                                refusalData =
                                    await showReasonForRefusalDialog(
                                  context: context,
                                  type: 'order',
                                );
                                if (refusalData == null) {
                                  return;
                                }
                              }

                              setState(() {
                                isSubmittingSave = true;
                              });

                              try {
                                final success =
                                    await ApiService().changeOrderStatus(
                                  orderId: order.id,
                                  statusId: selectedStatusId!,
                                  organizationId: order.organizationId,
                                  reasonForRefusalId: refusalData?.reasonId,
                                  reasonForRefusal: refusalData?.comment,
                                );

                                if (!context.mounted) {
                                  return;
                                }

                                if (!success) {
                                  setState(() {
                                    isSubmittingSave = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context)!
                                            .translate('error_text'),
                                        style: const TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Colors.red,
                                      elevation: 3,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  return;
                                }

                                onSelect(selectedValue, selectedStatusId!);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(context)!.translate(
                                          'status_changed_successfully'),
                                      style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.green,
                                    elevation: 3,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );

                                context.read<OrderBloc>().add(
                                      FetchOrderStatuses(forceRefresh: true),
                                    );
                                context.read<OrderBloc>().add(
                                      FetchOrderDetails(order.id),
                                    );

                                Navigator.pop(context);

                                final newTabIndex = orderStatuses.indexWhere(
                                  (status) => status.id == selectedStatusId,
                                );
                                if (newTabIndex != -1) {
                                  onTabChange(newTabIndex);
                                }
                              } catch (error) {
                                if (!context.mounted) {
                                  return;
                                }

                                setState(() {
                                  isSubmittingSave = false;
                                });

                                final errorMessage =
                                    error is OrderStatusUpdateException
                                        ? error.message
                                        : error
                                            .toString()
                                            .replaceFirst('Exception: ', '');

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      errorMessage,
                                      style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.red,
                                    elevation: 3,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                          ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
