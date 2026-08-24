import 'package:crm_task_manager/bloc/page_2_BLOC/employee_bloc/employee_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/employee_bloc/employee_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/employee_bloc/employee_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/warehouse/employee/add_employee_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/employee/employee_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/helpful_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late EmployeeBloc _employeeBloc;
  bool _isSearching = false;
  String? _currentQuery;

  static const bool _hasCreatePermission = true;
  static const bool _hasUpdatePermission = true;
  static const bool _hasDeletePermission = true;

  @override
  void initState() {
    super.initState();
    _employeeBloc = context.read<EmployeeBloc>()..add(FetchEmployees());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      _currentQuery = query.isNotEmpty ? query : null;
    });
    _employeeBloc.add(FetchEmployees(query: _currentQuery));
  }

  Future<void> _openAdd() async {
    final wasAdded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddEmployeeScreen()),
    );
    if (wasAdded == true) {
      _employeeBloc.add(FetchEmployees(query: _currentQuery));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: colors.surfacePrimary,
        title: CustomAppBarPage2(
          title: localizations.translate('employees'),
          showSearchIcon: true,
          showFilterIcon: false,
          showFilterOrderIcon: false,
          onChangedSearchInput: _onSearch,
          textEditingController: _searchController,
          focusNode: _focusNode,
          clearButtonClick: (value) {
            if (!value) {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _currentQuery = null;
              });
              _employeeBloc.add(FetchEmployees());
            }
          },
          onClickProfileAvatar: () {},
          clearButtonClickFiltr: (_) {},
          currentFilters: const {},
        ),
      ),
      floatingActionButton: _hasCreatePermission
          ? FloatingActionButton(
              onPressed: _openAdd,
              backgroundColor: colors.buttonPrimaryBg,
              child: Icon(Icons.add, color: colors.buttonPrimaryFg),
            )
          : null,
      body: BlocBuilder<EmployeeBloc, EmployeeState>(
        builder: (context, state) {
          if (state is EmployeeLoading) {
            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          }

          if (state is EmployeeLoaded) {
            final employees = state.employees;
            if (employees.isEmpty) {
              return _isSearching
                  ? HelpfulEmptyState.search(localizations)
                  : HelpfulEmptyState.section(
                      l10n: localizations,
                      icon: Icons.badge_outlined,
                      titleKey: 'empty_employees_title',
                      subtitleKey: 'empty_employees_subtitle',
                      actionKey:
                          _hasCreatePermission ? 'empty_employees_action' : null,
                      onAction: _hasCreatePermission ? _openAdd : null,
                    );
            }

            return RefreshIndicator(
              color: colors.buttonPrimaryBg,
              backgroundColor: colors.backgroundPrimary,
              onRefresh: () async {
                _employeeBloc.add(FetchEmployees(query: _currentQuery));
              },
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  return EmployeeCard(
                    employee: employees[index],
                    hasUpdatePermission: _hasUpdatePermission,
                    hasDeletePermission: _hasDeletePermission,
                    onUpdate: () {
                      _employeeBloc.add(FetchEmployees(query: _currentQuery));
                    },
                  );
                },
              ),
            );
          }

          if (state is EmployeeError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizations.translate(state.message),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        _employeeBloc.add(FetchEmployees(query: _currentQuery));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.buttonPrimaryBg,
                        foregroundColor: colors.buttonPrimaryFg,
                      ),
                      child: Text(localizations.translate('retry')),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: Text(
              localizations.translate('no_data'),
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }
}
