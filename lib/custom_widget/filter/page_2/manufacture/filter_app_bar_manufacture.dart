import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/author/get_all_author_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_wh.dart';
import 'package:crm_task_manager/custom_widget/dropdown_loading_state.dart';
import 'package:crm_task_manager/models/user/author_data_response.dart';
import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManufactureFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final String? initialStatus;
  final String? initialAuthorId;
  final String? initialStorageId;
  final String? initialRecipientStorageId;
  final bool? initialIsDeleted;

  const ManufactureFilterScreen({
    super.key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialFromDate,
    this.initialToDate,
    this.initialStatus,
    this.initialAuthorId,
    this.initialStorageId,
    this.initialRecipientStorageId,
    this.initialIsDeleted,
  });

  @override
  State<ManufactureFilterScreen> createState() =>
      _ManufactureFilterScreenState();
}

class _ManufactureFilterScreenState extends State<ManufactureFilterScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedStatus;
  bool? _isDeleted;
  AuthorData? _selectedAuthor;
  WareHouse? _selectedSenderStorage;
  WareHouse? _selectedRecipientStorage;

  List<AuthorData> _authors = [];
  List<WareHouse> _storages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _selectedStatus = widget.initialStatus;
    _isDeleted = widget.initialIsDeleted;
    _syncDateControllers();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authorState = context.read<GetAllAuthorBloc>().state;
      if (authorState is! GetAllAuthorSuccess) {
        context.read<GetAllAuthorBloc>().add(GetAllAuthorEv());
      }
    });
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  void _syncDateControllers() {
    _fromDateController.text = _fromDate == null
        ? ''
        : '${_fromDate!.day.toString().padLeft(2, '0')}/${_fromDate!.month.toString().padLeft(2, '0')}/${_fromDate!.year}';
    _toDateController.text = _toDate == null
        ? ''
        : '${_toDate!.day.toString().padLeft(2, '0')}/${_toDate!.month.toString().padLeft(2, '0')}/${_toDate!.year}';
  }

  Future<void> _loadData() async {
    List<WareHouse> storages = [];

    try {
      storages = await _apiService.getWareHouses();
    } catch (_) {}

    final authorId = int.tryParse(widget.initialAuthorId ?? '');
    final storageId = int.tryParse(widget.initialStorageId ?? '');
    final recipientStorageId =
        int.tryParse(widget.initialRecipientStorageId ?? '');

    if (!mounted) return;

    setState(() {
      _storages = storages;
      _selectedAuthor = authorId == null
          ? null
          : _authors.cast<AuthorData?>().firstWhere(
                (item) => item?.id == authorId,
                orElse: () => null,
              );
      _selectedSenderStorage = storageId == null
          ? null
          : _storages.cast<WareHouse?>().firstWhere(
                (item) => item?.id == storageId,
                orElse: () => null,
              );
      _selectedRecipientStorage = recipientStorageId == null
          ? null
          : _storages.cast<WareHouse?>().firstWhere(
                (item) => item?.id == recipientStorageId,
                orElse: () => null,
              );
      _isLoading = false;
    });
  }

  bool _hasAnyFilters() {
    return _fromDate != null ||
        _toDate != null ||
        _selectedSenderStorage != null ||
        _selectedRecipientStorage != null ||
        _selectedStatus != null ||
        _selectedAuthor != null ||
        _isDeleted != null;
  }

  Future<void> _resetFilters() async {
    if (!mounted) return;
    setState(() {
      _fromDate = null;
      _toDate = null;
      _selectedSenderStorage = null;
      _selectedRecipientStorage = null;
      _selectedStatus = null;
      _selectedAuthor = null;
      _isDeleted = null;
      _syncDateControllers();
    });
    widget.onResetFilters?.call();
    Navigator.pop(context);
  }

  Future<void> _applyFilters() async {
    if (!_hasAnyFilters()) {
      widget.onResetFilters?.call();
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    final fromDate = _fromDate == null
        ? null
        : DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day, 0, 0, 0);
    final toDate = _toDate == null
        ? null
        : DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);

    widget.onSelectedDataFilter?.call({
      'date_from': fromDate,
      'date_to': toDate,
      'storage_id': _selectedSenderStorage?.id.toString(),
      'recipient_storage_id': _selectedRecipientStorage?.id.toString(),
      'status': _selectedStatus,
      'author_id': _selectedAuthor?.id.toString(),
      'deleted': _isDeleted == null ? null : (_isDeleted! ? '1' : '0'),
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  ButtonStyle _buildActionButtonStyle() {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      backgroundColor:
          context.appColors.buttonSecondaryBg.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide(color: context.appColors.buttonPrimaryBg, width: 0.5),
    );
  }

  CustomDropdownDecoration _buildDropdownDecoration() {
    return CustomDropdownDecoration(
      closedFillColor: context.appColors.fieldBg,
      expandedFillColor: context.appColors.surfacePrimary,
      closedBorder: Border.all(color: context.appColors.fieldBg, width: 1),
      expandedBorder: Border.all(color: context.appColors.fieldBg, width: 1),
      closedBorderRadius: BorderRadius.circular(12),
      expandedBorderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.appColors.surfacePrimary,
      shadowColor: context.appColors.shadowColor,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.appTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStorageDropdown({
    required String title,
    required String hint,
    required WareHouse? selectedValue,
    required ValueChanged<WareHouse> onChanged,
  }) {
    return _buildSectionCard(
      title: title,
      child: _isLoading
          ? const DropdownLoadingState()
          : _storages.isEmpty
              ? Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.appColors.fieldBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hint,
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                )
              : CustomDropdown<WareHouse>.search(
                  items: _storages,
                  searchHintText:
                      AppLocalizations.of(context)!.translate('search') ??
                          'Поиск',
                  overlayHeight: 300,
                  enabled: true,
                  decoration: _buildDropdownDecoration(),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Text(
                      item.name,
                      style: context.appTextStyles.bodyMd.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    return Text(
                      selectedItem?.name ?? hint,
                      style: context.appTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textPrimary,
                      ),
                    );
                  },
                  hintBuilder: (context, hintText, enabled) => Text(
                    hint,
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  initialItem: selectedValue != null &&
                          _storages
                              .any((storage) => storage.id == selectedValue.id)
                      ? _storages.firstWhere(
                          (storage) => storage.id == selectedValue.id,
                        )
                      : null,
                  onChanged: (value) {
                    if (value != null && mounted) {
                      onChanged(value);
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
    );
  }

  Widget _buildAuthorWidget() {
    final localizations = AppLocalizations.of(context)!;

    return _buildSectionCard(
      title: localizations.translate('author'),
      child: BlocConsumer<GetAllAuthorBloc, GetAllAuthorState>(
        listener: (context, state) {
          if (state is GetAllAuthorSuccess) {
            final authors = state.dataAuthor.result ?? [];
            setState(() {
              _authors = authors;
              final authorId = int.tryParse(widget.initialAuthorId ?? '');
              if (_selectedAuthor == null && authorId != null) {
                _selectedAuthor = authors.cast<AuthorData?>().firstWhere(
                      (item) => item?.id == authorId,
                      orElse: () => null,
                    );
              }
            });
          }
        },
        builder: (context, state) {
          final authors = state is GetAllAuthorSuccess
              ? (state.dataAuthor.result ?? [])
              : _authors;

          if (state is GetAllAuthorSuccess &&
              _selectedAuthor == null &&
              widget.initialAuthorId != null) {
            final authorId = int.tryParse(widget.initialAuthorId ?? '');
            if (authorId != null) {
              _selectedAuthor = authors.cast<AuthorData?>().firstWhere(
                    (item) => item?.id == authorId,
                    orElse: () => null,
                  );
            }
          }

          if (state is GetAllAuthorInitial ||
              state is GetAllAuthorLoading) {
            return const DropdownLoadingState();
          }

          if (state is GetAllAuthorError) {
            return Container(
              height: 50,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Ошибка загрузки',
                    style: TextStyle(fontSize: 12),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<GetAllAuthorBloc>().add(GetAllAuthorEv());
                    },
                    child: const Text(
                      'Повторить',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomDropdown<AuthorData>.search(
            items: authors,
            searchHintText: localizations.translate('search') ?? 'Поиск',
            overlayHeight: 300,
            enabled: true,
            decoration: _buildDropdownDecoration(),
            listItemBuilder: (context, item, isSelected, onItemSelect) {
              return Text(
                '${item.name} ${item.lastname}'.trim(),
                style: context.appTextStyles.bodyMd.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
            headerBuilder: (context, selectedItem, enabled) {
              return Text(
                selectedItem != null
                    ? '${selectedItem.name} ${selectedItem.lastname}'.trim()
                    : (localizations.translate('select_author') ??
                        'Выберите автора'),
                style: context.appTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textPrimary,
                ),
              );
            },
            hintBuilder: (context, hint, enabled) => Text(
              localizations.translate('select_author') ?? 'Выберите автора',
              style: context.appTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
            ),
            initialItem: _selectedAuthor != null &&
                    authors.any((author) => author.id == _selectedAuthor!.id)
                ? authors.firstWhere(
                    (author) => author.id == _selectedAuthor!.id,
                  )
                : null,
            onChanged: (value) {
              if (value != null && mounted) {
                setState(() {
                  _selectedAuthor = value;
                });
                FocusScope.of(context).unfocus();
              }
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.appColors.backgroundSecondary,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          localizations.translate('filter'),
          style: context.appTextStyles.titleLg.copyWith(
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
        backgroundColor: context.appColors.surfacePrimary,
        forceMaterialTransparency: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            style: _buildActionButtonStyle(),
            child: Text(
              localizations.translate('clear'),
              style: context.appTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appColors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _applyFilters,
            style: _buildActionButtonStyle(),
            child: Text(
              localizations.translate('apply'),
              style: context.appTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appColors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSectionCard(
                      title: localizations.translate('date'),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: DateFieldWithFromTo(
                          isFrom: true,
                          controller: _fromDateController,
                          label: localizations.translate('date'),
                          withTime: false,
                          onDateSelected: (date) {
                            if (mounted) {
                              setState(() {
                                _fromDateController.text = date;
                                final parts = date.split('/');
                                if (parts.length == 3) {
                                  _fromDate = DateTime(
                                    int.parse(parts[2]),
                                    int.parse(parts[1]),
                                    int.parse(parts[0]),
                                  );
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSectionCard(
                      title: localizations.translate('date'),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: DateFieldWithFromTo(
                          isFrom: false,
                          controller: _toDateController,
                          label: localizations.translate('date'),
                          withTime: false,
                          onDateSelected: (date) {
                            if (mounted) {
                              setState(() {
                                _toDateController.text = date;
                                final parts = date.split('/');
                                if (parts.length == 3) {
                                  _toDate = DateTime(
                                    int.parse(parts[2]),
                                    int.parse(parts[1]),
                                    int.parse(parts[0]),
                                  );
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStorageDropdown(
                      title: localizations
                          .translate('manufacture_writeoff_storage'),
                      hint: localizations.translate(
                              'select_manufacture_writeoff_storage') ??
                          'Выберите склад списания',
                      selectedValue: _selectedSenderStorage,
                      onChanged: (value) {
                        setState(() {
                          _selectedSenderStorage = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildStorageDropdown(
                      title:
                          localizations.translate('manufacture_income_storage'),
                      hint: localizations
                              .translate('select_manufacture_income_storage') ??
                          'Выберите склад прихода',
                      selectedValue: _selectedRecipientStorage,
                      onChanged: (value) {
                        setState(() {
                          _selectedRecipientStorage = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildSectionCard(
                      title: localizations.translate('status'),
                      child: _StatusMethodDropdown(
                        title: localizations.translate('status'),
                        statusMethodsList: [
                          localizations.translate('approved'),
                          localizations.translate('not_approved'),
                        ],
                        selectedstatusMethod: _selectedStatus != null
                            ? (_selectedStatus == '1'
                                ? localizations.translate('approved')
                                : localizations.translate('not_approved'))
                            : null,
                        onSelectstatusMethod: (String value) {
                          if (mounted) {
                            setState(() {
                              _selectedStatus =
                                  value == localizations.translate('approved')
                                      ? '1'
                                      : '0';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildAuthorWidget(),
                    const SizedBox(height: 8),
                    _buildSectionCard(
                      title:
                          localizations.translate('status_delete') ?? 'Удален',
                      child: _StatusMethodDropdown(
                        title: localizations.translate('status_delete') ??
                            'Удален',
                        statusMethodsList: [
                          localizations.translate('yes'),
                          localizations.translate('no'),
                        ],
                        selectedstatusMethod: _isDeleted == null
                            ? null
                            : (_isDeleted!
                                ? localizations.translate('yes')
                                : localizations.translate('no')),
                        onSelectstatusMethod: (String value) {
                          if (mounted) {
                            setState(() {
                              _isDeleted =
                                  value == localizations.translate('yes');
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMethodDropdown extends StatefulWidget {
  final String? selectedstatusMethod;
  final Function(String) onSelectstatusMethod;
  final List<String> statusMethodsList;
  final String title;

  const _StatusMethodDropdown({
    required this.onSelectstatusMethod,
    this.selectedstatusMethod,
    required this.statusMethodsList,
    required this.title,
  });

  @override
  State<_StatusMethodDropdown> createState() => _StatusMethodDropdownState();
}

class _StatusMethodDropdownState extends State<_StatusMethodDropdown> {
  String? selectedstatusMethod;

  @override
  void initState() {
    super.initState();
    selectedstatusMethod = widget.selectedstatusMethod;
  }

  @override
  void didUpdateWidget(covariant _StatusMethodDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedstatusMethod != oldWidget.selectedstatusMethod) {
      selectedstatusMethod = widget.selectedstatusMethod;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        CustomDropdown<String>(
          items: widget.statusMethodsList,
          overlayHeight: 150,
          enabled: true,
          hintText:
              AppLocalizations.of(context)!.translate('select_status_method') ??
                  'Выберите статус',
          decoration: CustomDropdownDecoration(
            closedFillColor: context.appColors.fieldBg,
            expandedFillColor: context.appColors.surfacePrimary,
            closedBorder:
                Border.all(color: context.appColors.fieldBg, width: 1),
            expandedBorder:
                Border.all(color: context.appColors.fieldBg, width: 1),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorderRadius: BorderRadius.circular(12),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Text(
              item,
              style: context.appTextStyles.bodyMd.copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            );
          },
          headerBuilder: (context, selectedItem, enabled) {
            return Text(
              selectedItem ?? widget.title,
              style: context.appTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            widget.title,
            style: context.appTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w500,
              color: context.appColors.textPrimary,
            ),
          ),
          initialItem: selectedstatusMethod,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedstatusMethod = value;
              });
              widget.onSelectstatusMethod(value);
            }
          },
        ),
      ],
    );
  }
}
