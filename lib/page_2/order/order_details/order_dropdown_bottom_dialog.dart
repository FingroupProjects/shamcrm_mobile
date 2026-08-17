import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/screens/common/reason_for_refusal_modal.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/undo_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    backgroundColor: context.appColors.surfacePrimary,
    shape: RoundedRectangleBorder(
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
              final colors = context.appColors;
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
                        color: colors.borderSubtle,
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
                              context: context,
                              text: status.name,
                              isSelected: selectedValue == status.name,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    isSubmittingSave
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: colors.buttonPrimaryBg,
                              ),
                            ),
                          )
                        : CustomButton(
                            buttonText:
                                AppLocalizations.of(context)!.translate('save'),
                            buttonColor: colors.buttonPrimaryBg,
                            textColor: colors.textInverse,
                            onPressed: () async {
                              if (isSubmittingSave ||
                                  selectedStatusId == null) {
                                return;
                              }

                              final selectedStatus = orderStatuses
                                  .where(
                                      (status) => status.id == selectedStatusId)
                                  .cast<dynamic>()
                                  .firstWhere(
                                    (_) => true,
                                    orElse: () => null,
                                  );

                              ReasonForRefusalSubmitData? refusalData;
                              if (selectedStatusId != order.orderStatus.id &&
                                  selectedStatus != null &&
                                  selectedStatus.isFailed == true) {
                                refusalData = await showReasonForRefusalDialog(
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
                                        style: TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: colors.textInverse,
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: colors.error,
                                      elevation: 3,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  return;
                                }

                                final previousStatusId = order.orderStatus.id;
                                final previousTitle = defaultValue;
                                final nextStatusId = selectedStatusId!;
                                final nextTitle = selectedValue;
                                final l10n = AppLocalizations.of(context)!;
                                final previousTabIndex =
                                    orderStatuses.indexWhere(
                                  (status) => status.id == previousStatusId,
                                );

                                onSelect(nextTitle, nextStatusId);

                                context.read<OrderBloc>().add(
                                      FetchOrderStatuses(forceRefresh: true),
                                    );
                                context.read<OrderBloc>().add(
                                      FetchOrderDetails(order.id),
                                    );

                                Navigator.pop(context);

                                final newTabIndex = orderStatuses.indexWhere(
                                  (status) => status.id == nextStatusId,
                                );
                                if (newTabIndex != -1) {
                                  onTabChange(newTabIndex);
                                }

                                if (nextStatusId != previousStatusId) {
                                  UndoActions.showRevert(
                                    message:
                                        l10n.translate('undo_status_changed'),
                                    actionLabel: l10n.translate('undo'),
                                    onUndo: () async {
                                      await ApiService().changeOrderStatus(
                                        orderId: order.id,
                                        statusId: previousStatusId,
                                        organizationId: order.organizationId,
                                      );
                                      onSelect(previousTitle, previousStatusId);
                                      if (previousTabIndex != -1) {
                                        onTabChange(previousTabIndex);
                                      }
                                    },
                                  );
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
                                      style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: colors.textInverse,
                                      ),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: colors.error,
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
