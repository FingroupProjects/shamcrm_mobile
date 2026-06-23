import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/storage_bloc/storage_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/storage_bloc/storage_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/storage_bloc/storage_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StorageWidget extends StatefulWidget {
  final String? selectedStorage;
  final ValueChanged<String?> onChanged;

  const StorageWidget({
    required this.selectedStorage,
    required this.onChanged,
    super.key,
  });

  @override
  _StorageWidgetState createState() => _StorageWidgetState();
}

class _StorageWidgetState extends State<StorageWidget> {
  WareHouse? selectedStorageData;
  bool _isInitialLoad = true; // ✅ Track if this is the first load
  String? _autoSelectedStorageId;

  @override
  void initState() {
    super.initState();
    context.read<StorageBloc>().add(FetchStorage());
  }

  @override
  void didUpdateWidget(StorageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedStorage != widget.selectedStorage) {
      final currentState = context.read<StorageBloc>().state;
      if (currentState is StorageLoaded) {
        if (widget.selectedStorage != null) {
          try {
            selectedStorageData = currentState.storageList.firstWhere(
              (storage) => storage.id.toString() == widget.selectedStorage,
            );
          } catch (e) {
            selectedStorageData = null;
          }
        } else {
          selectedStorageData = null;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocListener<StorageBloc, StorageState>(
      listener: (context, state) {
        // ✅ Mark as loaded when data arrives
        if (state is StorageLoaded && _isInitialLoad) {
          setState(() {
            _isInitialLoad = false;
          });
        }

        if (state is StorageError) {
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
              backgroundColor: const Color(0xffDC2626),
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: BlocBuilder<StorageBloc, StorageState>(
        builder: (context, state) {
          final isLoading = state is StorageLoading;

          if (state is StorageLoaded) {
            List<WareHouse> storageList = state.storageList;

            if (widget.selectedStorage != null && storageList.isNotEmpty) {
              try {
                selectedStorageData = storageList.firstWhere(
                  (storage) => storage.id.toString() == widget.selectedStorage,
                );
              } catch (e) {
                selectedStorageData = null;
              }
            }

            if (storageList.length == 1 &&
                (widget.selectedStorage == null ||
                    selectedStorageData == null) &&
                _autoSelectedStorageId != storageList.first.id.toString()) {
              final singleStorage = storageList.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                widget.onChanged(singleStorage.id.toString());
                setState(() {
                  selectedStorageData = singleStorage;
                  _autoSelectedStorageId = singleStorage.id.toString();
                });
              });
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('storage'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              CustomDropdown<WareHouse>.search(
                closeDropDownOnClearFilterSearch: true,
                items: state is StorageLoaded ? state.storageList : [],
                searchHintText:
                    AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 400,
                enabled: !isLoading,
                decoration: CustomDropdownDecoration(
                  closedFillColor: colors.surfaceElevated,
                  expandedFillColor: colors.surfaceElevated,
                  closedBorder: Border.all(
                    color: colors.borderSubtle,
                    width: 1,
                  ),
                  closedBorderRadius: BorderRadius.circular(12),
                  expandedBorder: Border.all(
                    color: colors.borderSubtle,
                    width: 1,
                  ),
                  expandedBorderRadius: BorderRadius.circular(12),
                  listItemDecoration: ListItemDecoration(
                    splashColor: colors.buttonPrimaryBg.withValues(alpha: 0.10),
                    highlightColor:
                        colors.buttonPrimaryBg.withValues(alpha: 0.12),
                    selectedColor: colors.surfaceElevated,
                  ),
                  searchFieldDecoration: SearchFieldDecoration(
                    fillColor: colors.surfaceElevated,
                    textStyle: TextStyle(
                      color: colors.textPrimary,
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    hintStyle: TextStyle(
                      color: colors.textSecondary,
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colors.buttonPrimaryBg),
                    ),
                    prefixIcon: Icon(Icons.search,
                        size: 22, color: colors.textSecondary),
                    suffixIcon: (onClear) => IconButton(
                      onPressed: onClear,
                      icon: Icon(Icons.close,
                          size: 20, color: colors.textSecondary),
                    ),
                  ),
                ),
                listItemBuilder: (context, item, isSelected, onItemSelect) {
                  return Text(
                    item.name,
                    style: TextStyle(
                      color: colors.textPrimary,
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
                    return Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colors.buttonPrimaryBg),
                        ),
                      ),
                    );
                  }

                  return Text(
                    selectedItem.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: colors.textPrimary,
                    ),
                  );
                },
                hintBuilder: (context, hint, enabled) {
                  if (isLoading) {
                    return Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colors.buttonPrimaryBg),
                        ),
                      ),
                    );
                  }

                  return Text(
                    AppLocalizations.of(context)!.translate('select_storage'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: colors.textPrimary,
                    ),
                  );
                },
                noResultFoundBuilder: (context, text) {
                  if (isLoading) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colors.buttonPrimaryBg),
                        ),
                      ),
                    );
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        AppLocalizations.of(context)!.translate('no_results'),
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
                excludeSelected: false,
                initialItem: (state is StorageLoaded &&
                        state.storageList.contains(selectedStorageData))
                    ? selectedStorageData
                    : null,
                // ✅ FIX: Don't validate while data is loading or on initial load
                validator: (value) {
                  if (_isInitialLoad || isLoading) {
                    return null; // Skip validation during initial load
                  }
                  if (value == null) {
                    return AppLocalizations.of(context)!
                        .translate('field_required_project');
                  }
                  return null;
                },
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
