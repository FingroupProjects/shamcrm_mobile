import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/good_dashboard_warehouse/good_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/good_dashboard_warehouse/good_dashboard_warehouse_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/good_dashboard_warehouse/good_dashboard_warehouse_state.dart';
import 'package:crm_task_manager/models/page_2/good_dashboard_warehouse_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

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
  List<GoodDashboardWarehouse> goodsList = [];
  GoodDashboardWarehouse? selectedGoodData;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('🟢 GoodWidget: initState');
    }

    // ✅ Force fresh data load using RefreshGoodDashboardWarehouse
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (kDebugMode) {
          debugPrint('🔥 GoodWidget: Forcing fresh data load (ignoring cache)');
        }
        context.read<GoodDashboardWarehouseBloc>().add(RefreshGoodDashboardWarehouse());
      }
    });
  }

  @override
  void didUpdateWidget(GoodDashboardWarehouseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update selected good if changed externally
    if (oldWidget.selectedGoodDashboardWarehouse != widget.selectedGoodDashboardWarehouse &&
        goodsList.isNotEmpty) {
      _updateSelectedGoodData();
    }
  }

  void _updateSelectedGoodData() {
    if (kDebugMode) {
      debugPrint('🔄 GoodWidget: _updateSelectedGoodData started');
    }

    if (widget.selectedGoodDashboardWarehouse != null && goodsList.isNotEmpty) {
      try {
        selectedGoodData = goodsList.firstWhere(
              (good) => good.id.toString() == widget.selectedGoodDashboardWarehouse,
        );
        if (kDebugMode) {
          debugPrint('🟢 GoodWidget: Selected good found - ${selectedGoodData?.name}');
        }
      } catch (e) {
        selectedGoodData = null;
        if (kDebugMode) {
          debugPrint('🔴 GoodWidget: Selected good NOT found - searching for ${widget.selectedGoodDashboardWarehouse}');
        }
      }
    } else {
      selectedGoodData = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('🟡 GoodWidget: build() called');
    }

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
      child: Column(
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
          BlocBuilder<GoodDashboardWarehouseBloc, GoodDashboardWarehouseState>(
            builder: (context, state) {
              if (kDebugMode) {
                debugPrint('🔵 GoodWidget BlocBuilder: state=${state.runtimeType}');
              }

              final isLoading = state is GoodDashboardWarehouseLoading;

              // ✅ Update list only on Success
              if (state is GoodDashboardWarehouseLoaded) {
                goodsList = state.goodDashboardWarehouse;
                if (kDebugMode) {
                  debugPrint('🔵 GoodWidget BlocBuilder: SUCCESS - ${goodsList.length} goods loaded');
                  if (goodsList.isNotEmpty) {
                    debugPrint('🔵 GoodWidget BlocBuilder: First good = ${goodsList.first.name}');
                  }
                }
                _updateSelectedGoodData();
              }

              if (state is GoodDashboardWarehouseError) {
                if (kDebugMode) {
                  debugPrint('🔴 GoodWidget BlocBuilder: ERROR - ${state.message}');
                }
              }

              // ✅ If loading, don't show initialItem to prevent errors
              final actualInitialItem = isLoading
                  ? null
                  : (selectedGoodData != null &&
                  goodsList.isNotEmpty &&
                  goodsList.contains(selectedGoodData))
                  ? selectedGoodData
                  : null;

              if (kDebugMode) {
                debugPrint('🔵 GoodWidget: Rendering dropdown - items=${goodsList.length}, isLoading=$isLoading');
                debugPrint('🔵 GoodWidget: actualInitialItem=${actualInitialItem?.name}');
              }

              return CustomDropdown<GoodDashboardWarehouse>.search(
                key: widget.key,
                closeDropDownOnClearFilterSearch: true,
                items: goodsList,
                searchHintText: AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 400,
                enabled: !isLoading,
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
                  if (isLoading) {
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                        ),
                      ),
                    );
                  }

                  return Text(
                    selectedItem?.name ?? AppLocalizations.of(context)!.translate('select_good'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  );
                },
                hintBuilder: (context, hint, enabled) {
                  if (isLoading) {
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                        ),
                      ),
                    );
                  }

                  return Text(
                    AppLocalizations.of(context)!.translate('select_good'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  );
                },
                noResultFoundBuilder: (context, text) {
                  if (isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                        ),
                      ),
                    );
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        AppLocalizations.of(context)!.translate('no_results'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ),
                  );
                },
                excludeSelected: false,
                initialItem: actualInitialItem,
                onChanged: (value) {
                  if (kDebugMode) {
                    debugPrint('🟢 GoodWidget: onChanged - selected ${value?.name}');
                  }

                  if (value != null) {
                    widget.onChanged(value.id.toString());
                    setState(() {
                      selectedGoodData = value;
                    });
                    FocusScope.of(context).unfocus();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}