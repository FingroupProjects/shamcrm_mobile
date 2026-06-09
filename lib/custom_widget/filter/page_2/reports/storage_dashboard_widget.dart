import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/storage_dashboard/storage_dashboard_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/storage_dashboard/storage_dashboard_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/storage_dashboard/storage_dashboard_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StorageDashboardWidget extends StatefulWidget {
  final String? selectedStorage;
  final ValueChanged<String?> onChanged;

  const StorageDashboardWidget({
    super.key,
    required this.selectedStorage,
    required this.onChanged,
  });

  @override
  State<StorageDashboardWidget> createState() => _StorageDashboardWidgetState();
}

class _StorageDashboardWidgetState extends State<StorageDashboardWidget> {
  WareHouse? selectedStorageData;

  @override
  void initState() {
    super.initState();
    context.read<StorageDashboardBloc>().add(FetchStorageDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StorageDashboardBloc, StorageDashboardState>(
      listener: (context, state) {
        if (state is StorageDashboardError) {
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
      child: BlocBuilder<StorageDashboardBloc, StorageDashboardState>(
        builder: (context, state) {
          // Update data on successful load
          if (state is StorageDashboardLoaded) {
            final List<WareHouse> storageList = state.storageList;

            if (widget.selectedStorage != null && storageList.isNotEmpty) {
              try {
                selectedStorageData = storageList.firstWhere(
                      (storage) => storage.id.toString() == widget.selectedStorage,
                );
              } catch (e) {
                selectedStorageData = null;
              }
            }
          }

          // Always display the field
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('storage'),
                style: context.appTextStyles.bodyLg.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              CustomDropdown<WareHouse>.search(
                key: widget.key,
                closeDropDownOnClearFilterSearch: true,
                items: state is StorageDashboardLoaded ? state.storageList : [],
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
                  if (state is StorageDashboardLoading) {
                    return Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('select_storage'),
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
                  AppLocalizations.of(context)!.translate('select_storage'),
                  style: context.appTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                ),
                excludeSelected: false,
                initialItem: (state is StorageDashboardLoaded &&
                    selectedStorageData != null &&
                    state.storageList.contains(selectedStorageData))
                    ? selectedStorageData
                    : null,
                onChanged: (value) {
                  if (value != null) {
                    widget.onChanged(value.id.toString());
                    setState(() {
                      selectedStorageData = value;
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
