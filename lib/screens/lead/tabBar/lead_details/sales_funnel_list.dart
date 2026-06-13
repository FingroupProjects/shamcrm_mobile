import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_event.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/sales_funnel_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesFunnelWidget extends StatefulWidget {
  final String? selectedSalesFunnel;
  final ValueChanged<String?> onChanged;

  const SalesFunnelWidget({
    super.key,
    required this.selectedSalesFunnel,
    required this.onChanged,
  });

  @override
  State<SalesFunnelWidget> createState() => _SalesFunnelWidgetState();
}

class _SalesFunnelWidgetState extends State<SalesFunnelWidget> {
  SalesFunnel? selectedFunnelData;

  @override
  void initState() {
    super.initState();
    context.read<SalesFunnelBloc>().add(FetchSalesFunnels());
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = context.appTextStyles.bodyMd.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );
    final hintStyle = titleStyle.copyWith(
      fontSize: 14,
      color: context.appColors.textSecondary,
    );
    final surfaceColor = context.appColors.surfacePrimary.withValues(alpha: 0.78);
    final borderColor = context.appColors.borderSubtle.withValues(alpha: 0.36);

    return BlocListener<SalesFunnelBloc, SalesFunnelState>(
      listener: (context, state) {
        if (state is SalesFunnelError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.red,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      child: BlocBuilder<SalesFunnelBloc, SalesFunnelState>(
        builder: (context, state) {
          // Обновляем данные при успешной загрузке
          if (state is SalesFunnelLoaded) {
            List<SalesFunnel> funnelsList = state.funnels;
            
            if (widget.selectedSalesFunnel != null && funnelsList.isNotEmpty) {
              try {
                selectedFunnelData = funnelsList.firstWhere(
                  (funnel) => funnel.id.toString() == widget.selectedSalesFunnel,
                );
              } catch (e) {
                selectedFunnelData = null;
              }
            }
          }

          // Всегда отображаем поле
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('sales_funnel'),
                style: titleStyle,
              ),
              const SizedBox(height: 8),
              CustomDropdown<SalesFunnel>.search(
                  closeDropDownOnClearFilterSearch: true,
                  items: state is SalesFunnelLoaded ? state.funnels : [],
                  searchHintText: AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
                  enabled: true, // Всегда enabled
                  decoration: CustomDropdownDecoration(
                    closedFillColor: surfaceColor,
                    expandedFillColor: context.appColors.surfacePrimary,
                    closedBorder: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                    closedBorderRadius: BorderRadius.circular(18),
                    expandedBorder: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                    expandedBorderRadius: BorderRadius.circular(18),
                    hintStyle: hintStyle,
                    headerStyle: titleStyle.copyWith(fontSize: 14),
                    listItemStyle: titleStyle.copyWith(fontSize: 14),
                    listItemDecoration: ListItemDecoration(
                      selectedColor:
                          context.appColors.buttonPrimaryBg.withValues(alpha: 0.14),
                      highlightColor:
                          context.appColors.buttonPrimaryBg.withValues(alpha: 0.08),
                      splashColor: Colors.transparent,
                    ),
                    searchFieldDecoration: SearchFieldDecoration(
                      fillColor: context.appColors.backgroundPrimary,
                      textStyle: titleStyle.copyWith(fontSize: 14),
                      hintStyle: hintStyle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Text(
                      item.name,
                      style: titleStyle.copyWith(fontSize: 14),
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    if (state is SalesFunnelLoading) {
                      return Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.translate('select_sales_funnel'),
                            style: hintStyle,
                          ),
                        ],
                      );
                    }
                    return Text(
                      selectedItem.name,
                      style: titleStyle.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_sales_funnel'),
                    style: hintStyle,
                  ),
                  excludeSelected: false,
                  initialItem: (state is SalesFunnelLoaded && state.funnels.contains(selectedFunnelData))
                      ? selectedFunnelData
                      : null,
                  // validator: (value) {
                  //   if (value == null) {
                  //     return AppLocalizations.of(context)!.translate('field_required_sales_funnel');
                  //   }
                  //   return null;
                  // },
                  onChanged: (value) {
                    if (value != null) {
                      widget.onChanged(value.id.toString());
                      setState(() {
                        selectedFunnelData = value;
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
