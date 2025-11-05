import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_state.dart';
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SupplierWidget extends StatefulWidget {
  final String? selectedSupplier;
  final ValueChanged<String?> onChanged;

  SupplierWidget({required this.selectedSupplier, required this.onChanged});

  @override
  _SupplierWidgetState createState() => _SupplierWidgetState();
}

class _SupplierWidgetState extends State<SupplierWidget> {
  Supplier? selectedSupplierData;
  bool _isInitialLoad = true; // ✅ Track if this is the first load

  @override
  void initState() {
    super.initState();
    context.read<SupplierBloc>().add(FetchSupplier(query: null));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SupplierBloc, SupplierState>(
      listener: (context, state) {
        // ✅ Mark as loaded when data arrives
        if (state is SupplierLoaded && _isInitialLoad) {
          setState(() {
            _isInitialLoad = false;
          });
        }

        if (state is SupplierError) {
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
      child: BlocBuilder<SupplierBloc, SupplierState>(
        builder: (context, state) {
          final isLoading = state is SupplierLoading;

          if (state is SupplierLoaded) {
            List<Supplier> supplierList = state.supplierList;

            if (widget.selectedSupplier != null && supplierList.isNotEmpty) {
              try {
                selectedSupplierData = supplierList.firstWhere(
                      (supplier) =>
                  supplier.id.toString() == widget.selectedSupplier,
                );
              } catch (e) {
                selectedSupplierData = null;
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('supplier'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                child: CustomDropdown<Supplier>.search(
                  closeDropDownOnClearFilterSearch: true,
                  items: state is SupplierLoaded ? state.supplierList : [],
                  searchHintText:
                  AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
                  enabled: !isLoading,
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
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            color: Color(0xff1E2E52),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.phone ?? '',
                          style: TextStyle(
                            color: Color(0xff1E2E52).withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Gilroy',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
                      selectedItem?.name ??
                          AppLocalizations.of(context)!
                              .translate('select_supplier'),
                      style: TextStyle(
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
                      AppLocalizations.of(context)!.translate('select_supplier'),
                      style: TextStyle(
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
                  initialItem: (state is SupplierLoaded &&
                      state.supplierList.contains(selectedSupplierData))
                      ? selectedSupplierData
                      : null,
                  // ✅ FIX: Don't validate while data is loading or on initial load
                  validator: (value) {
                    if (_isInitialLoad || isLoading) {
                      return null; // Skip validation during initial load
                    }
                    if (value == null) {
                      return AppLocalizations.of(context)!.translate('field_required_project');
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value != null) {
                      widget.onChanged(value.id.toString());
                      setState(() {
                        selectedSupplierData = value;
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