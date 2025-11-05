import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/storage_bloc/storage_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/storage_bloc/storage_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/storage_bloc/storage_state.dart';
import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StorageWidget extends StatefulWidget {
  final String? selectedStorage;
  final ValueChanged<String?> onChanged;
  final Key? key;

  const StorageWidget({
    required this.selectedStorage,
    required this.onChanged,
    this.key,
  }) : super(key: key);

  @override
  _StorageWidgetState createState() => _StorageWidgetState();
}

class _StorageWidgetState extends State<StorageWidget> {
  WareHouse? selectedStorageData;
  bool _isInitialLoad = true; // ✅ Track if this is the first load

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
              backgroundColor: Colors.red,
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
                      (storage) =>
                  storage.id.toString() == widget.selectedStorage,
                );
              } catch (e) {
                selectedStorageData = null;
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('storage'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
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
                    item.name ?? '',
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xff1E2E52)),
                        ),
                      ),
                    );
                  }

                  return Text(
                    selectedItem?.name ??
                        AppLocalizations.of(context)!
                            .translate('select_storage'),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xff1E2E52)),
                        ),
                      ),
                    );
                  }

                  return Text(
                    AppLocalizations.of(context)!.translate('select_storage'),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xff1E2E52)),
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