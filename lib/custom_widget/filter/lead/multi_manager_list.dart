import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManagerMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedManagers;
  final Function(List<ManagerData>) onSelectManagers;

  ManagerMultiSelectWidget({
    super.key,
    required this.onSelectManagers,
    this.selectedManagers,
  });

  @override
  State<ManagerMultiSelectWidget> createState() =>
      _ManagersMultiSelectWidgetState();
}

class _ManagersMultiSelectWidgetState extends State<ManagerMultiSelectWidget> {
  List<ManagerData> managersList = [];
  List<ManagerData> selectedManagersData = [];
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadManagers();
  }

  void _loadManagers() {
    final bloc = context.read<GetAllManagerBloc>();
    if (bloc.state is! GetAllManagerSuccess) {
      bloc.add(GetAllManagerEv());
    }
  }

  void _initializeSelectedManagers(List<ManagerData> allManagers) {
    if (isInitialized) return;

    if (widget.selectedManagers != null &&
        widget.selectedManagers!.isNotEmpty) {
      selectedManagersData = allManagers
          .where((manager) =>
              widget.selectedManagers!.contains(manager.id.toString()))
          .toList();
    } else {
      selectedManagersData = [];
    }

    isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<GetAllManagerBloc, GetAllManagerState>(
          builder: (context, state) {
            if (state is GetAllManagerLoading) {
              return _buildLoadingWidget(context);
            }

            if (state is GetAllManagerError) {
              return _buildErrorWidget(context, state.message);
            }

            if (state is GetAllManagerSuccess) {
              final systemManager = ManagerData(
                id: 0,
                name: "Система",
                lastname: "",
              );

              managersList = [
                systemManager,
                ...state.dataManager.result ?? [],
              ];

              _initializeSelectedManagers(managersList);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('managers'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  CustomDropdown<ManagerData>.multiSelectSearch(
                    items: managersList,
                    initialItems: selectedManagersData,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration:  CustomDropdownDecoration(
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
                    listItemBuilder:
                        (context, item, isSelected, onItemSelect) {
                      return ListTile(
                        minTileHeight: 1,
                        minVerticalPadding: 2,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Color(0xff1E2E52), width: 1),
                                color: isSelected
                                    ? Color(0xff1E2E52)
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.id == 0
                                    ? item.name
                                    : '${item.name} ${item.lastname}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Gilroy',
                                  color: Color(0xff1E2E52),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          onItemSelect();
                          FocusScope.of(context).unfocus();
                        },
                      );
                    },
                    headerListBuilder: (context, hint, enabled) {
                      int selectedManagersCount = selectedManagersData.length;
                      return Text(
                        selectedManagersCount == 0
                            ? AppLocalizations.of(context)!
                                .translate('selected_manager')
                            : '${AppLocalizations.of(context)!.translate('selected_manager')} $selectedManagersCount',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!.translate('select_manager'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onListChanged: (values) {
                      setState(() {
                        selectedManagersData = values;
                      });
                      widget.onSelectManagers(selectedManagersData);
                    },
                  ),
                ],
              );
            }

            return _buildFallbackWidget(context);
          },
        ),
      ],
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('managers'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Color(0xffF4F7FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xffF4F7FD)),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Загрузка...',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('managers'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Color(0xffF4F7FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ошибка загрузки: $message',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Colors.red,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh,
                    color: Color(0xff1E2E52), size: 16),
                onPressed: _loadManagers,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('managers'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Color(0xffF4F7FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xffF4F7FD)),
          ),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)!.translate('select_manager'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff99A4BA),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh,
                    color: Color(0xff1E2E52), size: 16),
                onPressed: _loadManagers,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
        ),
      ],
    );
  }
}