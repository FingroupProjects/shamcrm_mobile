import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal_name_list_bloc/deal_name_list_bloc.dart';
import 'package:crm_task_manager/bloc/deal_name_list_bloc/deal_name_list_event.dart';
import 'package:crm_task_manager/bloc/deal_name_list_bloc/deal_name_lists_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/deal/deal_name_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealNameSelectionWidget extends StatefulWidget {
  final String? selectedDealName;
  final Function(String) onSelectDealName;
  final bool hasError;

  const DealNameSelectionWidget({
    super.key,
    this.selectedDealName,
    required this.onSelectDealName,
    this.hasError = false,
  });

  @override
  State<DealNameSelectionWidget> createState() =>
      _DealNameSelectionWidgetState();
}

class _DealNameSelectionWidgetState extends State<DealNameSelectionWidget> {
  static const int _pageSize = 20;
  final ApiService _apiService = ApiService();
  late final TextEditingController _textController;
  List<DealNameData> dealNameList = [];

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.selectedDealName ?? '');
    context.read<GetAllDealNameBloc>().add(GetAllDealNameEv());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DealNameSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDealName != widget.selectedDealName) {
      final nextValue = widget.selectedDealName ?? '';
      if (_textController.text != nextValue) {
        _textController.value = _textController.value.copyWith(
          text: nextValue,
          selection: TextSelection.collapsed(offset: nextValue.length),
          composing: TextRange.empty,
        );
      }
      _updateSelectedDealNameData();
    }
  }

  void _updateSelectedDealNameData() {
    if (widget.selectedDealName == null) return;
  }

  Future<List<DealNameData>> _searchDealNames(String query) async {
    final response = await _apiService.getAllDealNames(
      search: query,
      page: 1,
      perPage: _pageSize,
    );
    return response.result ?? <DealNameData>[];
  }

  Future<void> _openDealNamePicker() async {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final searchController = TextEditingController();
    List<DealNameData> items = List<DealNameData>.from(dealNameList);
    bool isLoading = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> handleSearch(String query) async {
              setModalState(() {
                isLoading = true;
              });

              try {
                final results = await _searchDealNames(query);
                if (!mounted) return;
                setModalState(() {
                  items = results;
                });
              } finally {
                if (mounted) {
                  setModalState(() {
                    isLoading = false;
                  });
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.borderPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.translate('deal_name'),
                        style: textStyles.titleMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        onChanged: handleSearch,
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context)!.translate('search'),
                          prefixIcon:
                              Icon(Icons.search, color: colors.textSecondary),
                          filled: true,
                          fillColor: colors.fieldBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: textStyles.bodyLg.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: colors.buttonPrimaryBg,
                                ),
                              )
                            : items.isEmpty
                                ? Center(
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .translate('no_data_to_display'),
                                      style: textStyles.bodyMd.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: items.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      final isSelected =
                                          item.title == _textController.text;
                                      return Material(
                                        color: colors.fieldBackground,
                                        borderRadius: BorderRadius.circular(12),
                                        child: ListTile(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          title: Text(
                                            item.title,
                                            style: textStyles.bodyMd.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                          trailing: isSelected
                                              ? Icon(
                                                  Icons.check,
                                                  color: colors.buttonPrimaryBg,
                                                )
                                              : null,
                                          onTap: () {
                                            _textController.text = item.title;
                                            widget.onSelectDealName(item.title);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('deal_name'),
          style: context.appTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w500,
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        BlocBuilder<GetAllDealNameBloc, GetAllDealNameState>(
          builder: (context, state) {
            if (state is GetAllDealNameError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
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
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.red,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
            }

            if (state is GetAllDealNameSuccess) {
              dealNameList = state.dataDealName.result ?? [];
              _updateSelectedDealNameData();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _textController,
                  onChanged: (value) {
                    widget.onSelectDealName(value);
                  },
                  style: context.appTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!
                        .translate('select_deal_name'),
                    hintStyle: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: context.appColors.fieldBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.appColors.borderSubtle,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.hasError
                            ? context.appColors.error
                            : context.appColors.borderSubtle,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.hasError
                            ? context.appColors.error
                            : context.appColors.buttonPrimaryBg,
                        width: 1,
                      ),
                    ),
                    suffixIcon: IconButton(
                      onPressed: _openDealNamePicker,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.appColors.iconPrimary,
                      ),
                    ),
                  ),
                ),
                if (widget.hasError)
                  Text(
                    ' ${AppLocalizations.of(context)!.translate('field_required_project')}',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 253, 38, 23),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
