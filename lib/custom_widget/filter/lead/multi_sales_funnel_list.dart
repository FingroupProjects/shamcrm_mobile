import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_event.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_state.dart';
import 'package:crm_task_manager/models/sales_funnel_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesFunnelMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedFunnels;
  final Function(List<SalesFunnel>) onSelectFunnels;

  const SalesFunnelMultiSelectWidget({
    super.key,
    required this.onSelectFunnels,
    this.selectedFunnels,
  });

  @override
  State<SalesFunnelMultiSelectWidget> createState() =>
      _SalesFunnelMultiSelectWidgetState();
}

class _SalesFunnelMultiSelectWidgetState
    extends State<SalesFunnelMultiSelectWidget> {
  List<SalesFunnel> funnelsList = [];
  List<SalesFunnel> selectedFunnelsData = [];
  bool allSelected = false;

  final TextStyle funnelTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    context.read<SalesFunnelBloc>().add(FetchSalesFunnels());
  }

  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      if (allSelected) {
        selectedFunnelsData = List.from(funnelsList);
      } else {
        selectedFunnelsData = [];
      }
      widget.onSelectFunnels(selectedFunnelsData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<SalesFunnel>>(
      validator: (value) {
        if (selectedFunnelsData.isEmpty) {
          return AppLocalizations.of(context)!.translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<SalesFunnel>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('sales_funnel'),
              style: funnelTextStyle.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError ? Colors.red : const Color(0xFFE5E7EB),
                ),
              ),
              child: BlocBuilder<SalesFunnelBloc, SalesFunnelState>(
                builder: (context, state) {
                  if (state is SalesFunnelLoaded) {
                    funnelsList = state.funnels;
                    if (widget.selectedFunnels != null &&
                        funnelsList.isNotEmpty) {
                      selectedFunnelsData = funnelsList
                          .where((funnel) =>
                              widget.selectedFunnels!.contains(funnel.id.toString()))
                          .toList();
                      allSelected =
                          selectedFunnelsData.length == funnelsList.length;
                    }
                  }

                  return CustomDropdown<SalesFunnel>.multiSelectSearch(
                    items: funnelsList,
                    initialItems: selectedFunnelsData,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: const Color(0xffF4F7FD),
                      expandedFillColor: Colors.white,
                      closedBorder: Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      if (funnelsList.indexOf(item) == 0) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: GestureDetector(
                                onTap: _toggleSelectAll,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xff1E2E52),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        color: allSelected
                                            ? const Color(0xff1E2E52)
                                            : Colors.transparent,
                                      ),
                                      child: allSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 14,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.translate('select_all'),
                                        style: funnelTextStyle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                              height: 20,
                              color: const Color(0xFFE5E7EB),
                            ),
                            _buildListItem(item, isSelected, onItemSelect),
                          ],
                        );
                      }
                      return _buildListItem(item, isSelected, onItemSelect);
                    },
                    headerListBuilder: (context, hint, enabled) {
                      final selectedNames = selectedFunnelsData.isEmpty
                          ? AppLocalizations.of(context)!.translate('select_sales_funnel')
                          : selectedFunnelsData.map((e) => e.name).join(', ');
                      return Text(
                        selectedNames,
                        style: funnelTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!.translate('select_sales_funnel'),
                      style: funnelTextStyle.copyWith(fontSize: 14),
                    ),
                    onListChanged: (values) {
                      widget.onSelectFunnels(values);
                      setState(() {
                        selectedFunnelsData = values;
                        allSelected = values.length == funnelsList.length;
                      });
                      field.didChange(values);
                    },
                  );
                },
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 0),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildListItem(
    SalesFunnel item,
    bool isSelected,
    Function() onItemSelect,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onItemSelect,
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xff1E2E52),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                style: funnelTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
