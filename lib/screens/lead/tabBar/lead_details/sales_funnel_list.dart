import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_event.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_state.dart';
import 'package:crm_task_manager/models/sales_funnel_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesFunnelWidget extends StatefulWidget {
  final String? selectedSalesFunnel;
  final ValueChanged<String?> onChanged;

  SalesFunnelWidget({required this.selectedSalesFunnel, required this.onChanged});

  @override
  _SalesFunnelWidgetState createState() => _SalesFunnelWidgetState();
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                child: CustomDropdown<SalesFunnel>.search(
                  closeDropDownOnClearFilterSearch: true,
                  items: state is SalesFunnelLoaded ? state.funnels : [],
                  searchHintText: AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
                  enabled: true, // Всегда enabled
                  decoration: CustomDropdownDecoration(
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
                    return Text(
                      item.name,
                      style: TextStyle(
                        color: Color(0xff1E2E52),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                      ),
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    if (state is SalesFunnelLoading) {
                      return Row(
                        children: [
                          // SizedBox(
                          //   width: 16,
                          //   height: 16,
                          //   child: CircularProgressIndicator(
                          //     strokeWidth: 2,
                          //     valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                          //   ),
                          // ),
                          Text(
                            AppLocalizations.of(context)!.translate('select_sales_funnel'),
                            style: TextStyle(
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
                      selectedItem?.name ?? AppLocalizations.of(context)!.translate('select_sales_funnel'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_sales_funnel'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
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
              ),
            ],
          );
        },
      ),
    );
  }
}