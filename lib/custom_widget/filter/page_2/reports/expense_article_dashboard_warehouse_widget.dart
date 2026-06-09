import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/expense_article_dashboard_warehouse/expense_article_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/expense_article_dashboard_warehouse/expense_article_dashboard_warehouse_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/expense_article_dashboard_warehouse/expense_article_dashboard_warehouse_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/expense_article_dashboard_warehouse_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExpenseArticleDashboardWarehouseWidget extends StatefulWidget {
  final String? selectedExpenseArticleDashboardWarehouse;
  final ValueChanged<String?> onChanged;

  const ExpenseArticleDashboardWarehouseWidget({
    super.key,
    required this.selectedExpenseArticleDashboardWarehouse,
    required this.onChanged,
  });

  @override
  State<ExpenseArticleDashboardWarehouseWidget> createState() => _ExpenseArticleDashboardWarehouseWidgetState();
}

class _ExpenseArticleDashboardWarehouseWidgetState extends State<ExpenseArticleDashboardWarehouseWidget> {
  ExpenseArticleDashboardWarehouse? selectedExpenseArticleData;

  @override
  void initState() {
    super.initState();
    context.read<ExpenseArticleDashboardWarehouseBloc>().add(FetchExpenseArticleDashboardWarehouse());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseArticleDashboardWarehouseBloc, ExpenseArticleDashboardWarehouseState>(
      listener: (context, state) {
        if (state is ExpenseArticleDashboardWarehouseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),
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
      child: BlocBuilder<ExpenseArticleDashboardWarehouseBloc, ExpenseArticleDashboardWarehouseState>(
        builder: (context, state) {
          // Update data on successful load
          if (state is ExpenseArticleDashboardWarehouseLoaded) {
            final List<ExpenseArticleDashboardWarehouse> expenseArticlesList = state.expenseArticleDashboardWarehouse;

            if (widget.selectedExpenseArticleDashboardWarehouse != null && expenseArticlesList.isNotEmpty) {
              try {
                selectedExpenseArticleData = expenseArticlesList.firstWhere(
                      (expenseArticle) => expenseArticle.id.toString() == widget.selectedExpenseArticleDashboardWarehouse,
                );
              } catch (e) {
                selectedExpenseArticleData = null;
              }
            }
          }

          // Always display the field
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('expense_article'),
                style: context.appTextStyles.bodyLg.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              CustomDropdown<ExpenseArticleDashboardWarehouse>.search(
                key: widget.key,
                closeDropDownOnClearFilterSearch: true,
                items: state is ExpenseArticleDashboardWarehouseLoaded ? state.expenseArticleDashboardWarehouse : [],
                searchHintText: AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 400,
                enabled: true,
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
                  return Text(
                    item.name,
                    style: context.appTextStyles.bodyMd.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
                headerBuilder: (context, selectedItem, enabled) {
                  if (state is ExpenseArticleDashboardWarehouseLoading) {
                    return Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('select_expense_article'),
                          style: context.appTextStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.w500,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                      ],
                    );
                  }
                  return Text(
                    selectedItem.name,
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textPrimary,
                    ),
                  );
                },
                hintBuilder: (context, hint, enabled) => Text(
                  AppLocalizations.of(context)!.translate('select_expense_article'),
                  style: context.appTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                ),
                excludeSelected: false,
                initialItem: (state is ExpenseArticleDashboardWarehouseLoaded && state.expenseArticleDashboardWarehouse.contains(selectedExpenseArticleData))
                    ? selectedExpenseArticleData
                    : null,
                onChanged: (value) {
                  if (value != null) {
                    widget.onChanged(value.id.toString());
                    setState(() {
                      selectedExpenseArticleData = value;
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
