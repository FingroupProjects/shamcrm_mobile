import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/storage_bloc/storage_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/storage_bloc/storage_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/storage_bloc/storage_state.dart';
import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DualStorageWidget extends StatefulWidget {
  final String? selectedSenderStorage;
  final String? selectedRecipientStorage;
  final Function(String?) onSenderChanged;
  final Function(String?) onRecipientChanged;
  final bool hasSenderError;
  final bool hasRecipientError;
  final String? senderLabel;
  final String? senderHint;
  final String? recipientLabel;
  final String? recipientHint;

  const DualStorageWidget({
    Key? key,
    this.selectedSenderStorage,
    this.selectedRecipientStorage,
    required this.onSenderChanged,
    required this.onRecipientChanged,
    this.hasSenderError = false,
    this.hasRecipientError = false,
    this.senderLabel,
    this.senderHint,
    this.recipientLabel,
    this.recipientHint,
  }) : super(key: key);

  @override
  _DualStorageWidgetState createState() => _DualStorageWidgetState();
}

class _DualStorageWidgetState extends State<DualStorageWidget> {
  WareHouse? selectedSenderStorageData;
  WareHouse? selectedRecipientStorageData;
  String? _autoSelectedSenderId;
  String? _autoSelectedRecipientId;

  @override
  void initState() {
    super.initState();
    context.read<StorageBloc>().add(FetchStorage());
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return BlocListener<StorageBloc, StorageState>(
      listener: (context, state) {
        if (state is StorageError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate(state.message) ?? state.message,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.buttonPrimaryFg,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: colors.error,
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

          // Обновляем данные при успешной загрузке
          if (state is StorageLoaded) {
            List<WareHouse> storageList = state.storageList;

            // Обновляем данные для склада отправителя
            if (widget.selectedSenderStorage != null &&
                storageList.isNotEmpty) {
              try {
                selectedSenderStorageData = storageList.firstWhere(
                  (storage) =>
                      storage.id.toString() == widget.selectedSenderStorage,
                );
              } catch (e) {
                selectedSenderStorageData = null;
              }
            }

            // Обновляем данные для склада получателя
            if (widget.selectedRecipientStorage != null &&
                storageList.isNotEmpty) {
              try {
                selectedRecipientStorageData = storageList.firstWhere(
                  (storage) =>
                      storage.id.toString() == widget.selectedRecipientStorage,
                );
              } catch (e) {
                selectedRecipientStorageData = null;
              }
            }

            if (storageList.length == 1) {
              final singleStorage = storageList.first;
              if ((widget.selectedSenderStorage == null ||
                      selectedSenderStorageData == null) &&
                  _autoSelectedSenderId != singleStorage.id.toString()) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  widget.onSenderChanged(singleStorage.id.toString());
                  setState(() {
                    selectedSenderStorageData = singleStorage;
                    _autoSelectedSenderId = singleStorage.id.toString();
                  });
                });
              }

              if ((widget.selectedRecipientStorage == null ||
                      selectedRecipientStorageData == null) &&
                  _autoSelectedRecipientId != singleStorage.id.toString()) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  widget.onRecipientChanged(singleStorage.id.toString());
                  setState(() {
                    selectedRecipientStorageData = singleStorage;
                    _autoSelectedRecipientId = singleStorage.id.toString();
                  });
                });
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Склад отправитель
              _buildStorageField(
                label: widget.senderLabel ??
                    localizations.translate('sender_storage') ??
                    'Склад отправитель',
                hint: widget.senderHint ??
                    localizations.translate('select_sender_storage') ??
                    'Выберите склад отправитель',
                selectedStorage: selectedSenderStorageData,
                state: state,
                isLoading: isLoading,
                hasError: widget.hasSenderError,
                onChanged: (value) {
                  if (value != null) {
                    widget.onSenderChanged(value.id.toString());
                    setState(() {
                      selectedSenderStorageData = value;
                    });
                    FocusScope.of(context).unfocus();
                  }
                },
              ),

              const SizedBox(height: 16),

              // Склад получатель
              _buildStorageField(
                label: widget.recipientLabel ??
                    localizations.translate('recipient_storage') ??
                    'Склад получатель',
                hint: widget.recipientHint ??
                    localizations.translate('select_recipient_storage') ??
                    'Выберите склад получатель',
                selectedStorage: selectedRecipientStorageData,
                state: state,
                isLoading: isLoading,
                hasError: widget.hasRecipientError,
                onChanged: (value) {
                  if (value != null) {
                    widget.onRecipientChanged(value.id.toString());
                    setState(() {
                      selectedRecipientStorageData = value;
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

  Widget _buildStorageField({
    required String label,
    required String hint,
    required WareHouse? selectedStorage,
    required StorageState state,
    required bool isLoading,
    required bool hasError,
    required Function(WareHouse?) onChanged,
  }) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
          searchHintText: localizations.translate('search') ?? 'Поиск',
          overlayHeight: 400,
          enabled: !isLoading,
          decoration: CustomDropdownDecoration(
            closedFillColor: colors.surfaceElevated,
            expandedFillColor: colors.surfacePrimary,
            closedBorder: Border.all(
              color: hasError ? colors.error : colors.borderSubtle,
              width: hasError ? 2 : 1,
            ),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(
              color: colors.borderSubtle,
              width: 1,
            ),
            expandedBorderRadius: BorderRadius.circular(12),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Text(
              item.name ?? '',
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
              return const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              );
            }

            return Text(
              selectedItem?.name ?? hint,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
            );
          },
          hintBuilder: (context, hintText, enabled) {
            if (isLoading) {
              return const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              );
            }

            return Text(
              hint,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textSecondary,
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  localizations.translate('no_results') ?? 'Нет результатов',
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
                  state.storageList.contains(selectedStorage))
              ? selectedStorage
              : null,
          validator: (value) {
            if (hasError && value == null) {
              return localizations.translate('field_required') ??
                  'Поле обязательно для заполнения';
            }
            return null;
          },
          onChanged: onChanged,
        ),
      ],
    );
  }
}
