import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/money_outcome/money_outcome_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/price_input_formatter.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/money/cash_register_list_model.dart';
import 'package:crm_task_manager/models/money/employee_remaining_model.dart';
import 'package:crm_task_manager/models/money/money_outcome_document_model.dart';
import 'package:crm_task_manager/page_2/money/money_outcome/money_outcome_operation_type.dart';
import 'package:crm_task_manager/page_2/money/widgets/cash_register_radio_group.dart';
import 'package:crm_task_manager/page_2/money/widgets/error_dialog.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/styled_action_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class SalaryPaymentForm extends StatefulWidget {
  final Document? document;

  const SalaryPaymentForm({
    super.key,
    this.document,
  });

  @override
  State<SalaryPaymentForm> createState() => _SalaryPaymentFormState();
}

class _SalaryPaymentFormState extends State<SalaryPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final SingleSelectController<EmployeeRemainingModel?> _employeeController =
      SingleSelectController<EmployeeRemainingModel?>(null);
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  CashRegisterData? _selectedCashRegister;
  EmployeeRemainingModel? _selectedEmployee;
  List<EmployeeRemainingModel> _employees = [];

  bool _isLoading = false;
  bool _isApproveLoading = false;
  bool _isEmployeesLoading = false;
  bool _hasApprovePermission = false;
  bool _employeeTouched = false;
  late bool _isApproved;
  String? _selectedMonthValue;
  String? _employeesError;
  int _employeesRequestId = 0;

  bool get _isEdit => widget.document != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _checkApprovePermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEmployees();
    });
  }

  @override
  void dispose() {
    _employeeController.dispose();
    _dateController.dispose();
    _monthController.dispose();
    _commentController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_employees.isEmpty &&
        !_isEmployeesLoading &&
        _selectedMonthValue != null &&
        _selectedMonthValue!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _employees.isEmpty && !_isEmployeesLoading) {
          _loadEmployees();
        }
      });
    }
  }

  void _initializeFields() {
    final document = widget.document;
    _isApproved = document?.approved ?? false;

    final parsedDate = _parseDocumentDate(document?.date) ?? DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy HH:mm').format(parsedDate);

    final monthValue =
        document?.month ?? DateFormat('yyyy-MM').format(DateTime.now());
    _setMonth(monthValue, notify: false);

    _amountController.text = document?.amount ?? '';
    _commentController.text = document?.comment ?? '';

    if (document?.cashRegister != null) {
      _selectedCashRegister = CashRegisterData(
        id: document!.cashRegister!.id!,
        name: document.cashRegister!.name ?? '',
      );
    }

    final employeeId = document?.employeeId ?? document?.employee?.id;
    final employeeName = document?.employee?.fullName ?? document?.model?.name;
    final employeePhone = document?.employee?.phone ?? document?.model?.phone;

    if (employeeId != null) {
      final documentAmount = document?.amount ?? '';
      _selectedEmployee = EmployeeRemainingModel(
        id: employeeId,
        fullName: employeeName ?? '',
        phone: employeePhone,
        remaining: double.tryParse(documentAmount) ?? 0,
      );
    }
  }

  DateTime? _parseDocumentDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _checkApprovePermission() async {
    try {
      final hasPermission =
          await _apiService.hasPermission('checking_account_rko.approve');
      if (!mounted) return;
      setState(() {
        _hasApprovePermission = hasPermission;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasApprovePermission = false;
      });
    }
  }

  void _setMonth(String monthValue, {bool notify = true}) {
    _selectedMonthValue = monthValue;
    final parsedMonth = DateTime.tryParse('$monthValue-01');
    _monthController.text = parsedMonth != null
        ? DateFormat('MM/yyyy').format(parsedMonth)
        : monthValue;

    if (notify) {
      _selectedEmployee = null;
      _employeeController.value = null;
      _employeesError = null;
      _employees = [];
      _employeeTouched = false;
      if (!_isEdit) {
        _amountController.clear();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadEmployees(monthOverride: monthValue, forceRefresh: true);
      });
    }
  }

  Future<void> _selectMonth() async {
    final initialDate = DateTime.tryParse(
          '${_selectedMonthValue ?? DateFormat('yyyy-MM').format(DateTime.now())}-01',
        ) ??
        DateTime.now();

    final pickedMonth = await showDialog<DateTime>(
      context: context,
      barrierColor: const Color(0x661E2E52),
      builder: (dialogContext) {
        final colors = context.appColors;
        int selectedYear = initialDate.year;
        final locale = Localizations.localeOf(context).languageCode;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final months = List<DateTime>.generate(
              12,
              (index) => DateTime(selectedYear, index + 1, 1),
            );

            return Dialog(
              backgroundColor: colors.surfacePrimary,
              surfaceTintColor: colors.surfacePrimary,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfacePrimary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!
                                .translate('select_month'),
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colors.fieldBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: Icon(
                                Icons.close,
                                color: colors.textPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.fieldBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors.surfacePrimary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setDialogState(() {
                                    selectedYear--;
                                  });
                                },
                                icon: Icon(
                                  Icons.chevron_left,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                selectedYear.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors.surfacePrimary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setDialogState(() {
                                    selectedYear++;
                                  });
                                },
                                icon: Icon(
                                  Icons.chevron_right,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        itemCount: months.length,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.2,
                        ),
                        itemBuilder: (context, index) {
                          final monthDate = months[index];
                          final isSelected = _selectedMonthValue ==
                              DateFormat('yyyy-MM').format(monthDate);
                          final monthLabel = _capitalizeMonth(
                            DateFormat.MMM(locale).format(monthDate),
                          );

                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                Navigator.pop(dialogContext, monthDate),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.buttonPrimaryBg
                                    : colors.fieldBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? colors.buttonPrimaryBg
                                      : colors.borderSubtle,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                monthLabel,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : colors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
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

    if (pickedMonth == null) return;

    final monthValue = DateFormat('yyyy-MM').format(pickedMonth);
    setState(() {
      _setMonth(monthValue);
    });
  }

  String _capitalizeMonth(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<void> _loadEmployees({
    String? monthOverride,
    bool forceRefresh = false,
  }) async {
    final month = monthOverride ?? _selectedMonthValue;
    if (month == null || month.isEmpty) return;

    if (!forceRefresh && _isEmployeesLoading && month == _selectedMonthValue) {
      return;
    }

    final requestId = ++_employeesRequestId;
    debugPrint('SalaryPaymentForm: loading employees for month=$month');
    setState(() {
      _isEmployeesLoading = true;
      _employeesError = null;
      if (forceRefresh) {
        _employees = [];
      }
    });

    try {
      final employees = await _apiService.getEmployeesByRemaining(month: month);
      if (!mounted ||
          requestId != _employeesRequestId ||
          month != _selectedMonthValue) {
        return;
      }

      EmployeeRemainingModel? selectedEmployee = _selectedEmployee;
      if (selectedEmployee != null) {
        final selectedEmployeeId = selectedEmployee.id;
        for (final employee in employees) {
          if (employee.id == selectedEmployeeId) {
            selectedEmployee = employee;
            break;
          }
        }
      }

      setState(() {
        _employees = employees;
        _selectedEmployee = selectedEmployee;
        _employeeController.value = selectedEmployee;
        _isEmployeesLoading = false;
      });
      debugPrint(
        'SalaryPaymentForm: employees loaded count=${employees.length}',
      );
    } catch (e) {
      debugPrint('SalaryPaymentForm: employees load error=$e');
      if (!mounted ||
          requestId != _employeesRequestId ||
          month != _selectedMonthValue) {
        return;
      }
      setState(() {
        _isEmployeesLoading = false;
        _employeesError = e.toString();
      });
    }
  }

  void _handleEmployeeSelected(EmployeeRemainingModel employee) {
    setState(() {
      _selectedEmployee = employee;
      _employeeController.value = employee;
      _employeeTouched = false;
      _amountController.text = _formatEditableAmount(employee.remaining);
    });
  }

  String _formatEditableAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  void _toggleApproval() {
    if (widget.document?.id == null) return;
    setState(() => _isApproveLoading = true);
    context.read<MoneyOutcomeBloc>().add(
          ToggleApproveOneMoneyOutcomeDocument(
            widget.document!.id!,
            !_isApproved,
          ),
        );
  }

  void _saveDocument() {
    _submit(approve: false);
  }

  void _saveAndApproveDocument() {
    _submit(approve: true);
  }

  void _submit({required bool approve}) {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    final isEmployeeMissing = _selectedEmployee == null;

    if (isEmployeeMissing) {
      setState(() {
        _employeeTouched = true;
      });
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_employee') ??
            'Выберите сотрудника',
        false,
      );
      return;
    }

    if (!isFormValid) return;

    DateTime parsedDate;
    try {
      parsedDate = DateFormat('dd/MM/yyyy HH:mm').parse(_dateController.text);
    } catch (_) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('enter_valid_datetime') ??
            'Введите корректную дату и время',
        false,
      );
      return;
    }

    if (_selectedCashRegister == null) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_cash_register') ??
            'Пожалуйста, выберите кассу',
        false,
      );
      return;
    }

    final month = _selectedMonthValue;
    if (month == null || month.isEmpty) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_month') ??
            'Выберите месяц',
        false,
      );
      return;
    }

    final isoDate = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(parsedDate);
    final amount =
        double.parse(_amountController.text.trim().replaceAll(',', '.'));

    setState(() {
      _isLoading = true;
    });

    final bloc = context.read<MoneyOutcomeBloc>();

    if (_isEdit) {
      final document = widget.document!;
      final dataChanged = !areDatesEqual(document.date ?? '', isoDate) ||
          (document.amount ?? '') != _amountController.text.trim() ||
          (document.comment ?? '') != _commentController.text.trim() ||
          document.cashRegister?.id != _selectedCashRegister?.id ||
          (document.employeeId ??
                  document.employee?.id ??
                  document.model?.id) !=
              _selectedEmployee?.id ||
          (document.month ?? '') != month;

      if (!dataChanged) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pop(context, false);
        return;
      }

      bloc.add(
        UpdateMoneyOutcome(
          id: document.id,
          date: isoDate,
          amount: amount,
          operationType: MoneyOutcomeOperationType.salary_payment.name,
          comment: _commentController.text.trim(),
          cashRegisterId: _selectedCashRegister?.id,
          employeeId: _selectedEmployee?.id,
          month: month,
        ),
      );
      return;
    }

    bloc.add(
      CreateMoneyOutcome(
        date: isoDate,
        amount: amount,
        operationType: MoneyOutcomeOperationType.salary_payment.name,
        comment: _commentController.text.trim(),
        cashRegisterId: _selectedCashRegister?.id,
        employeeId: _selectedEmployee?.id,
        month: month,
        approve: approve,
      ),
    );
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSalaryNoticeDialog(AppLocalizations localizations, String message) {
    showSimpleErrorDialog(
      context,
      localizations.translate('warning'),
      message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surfacePrimary,
      appBar: AppBar(
        backgroundColor: colors.surfacePrimary,
        forceMaterialTransparency: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit
              ? (localizations.translate('edit_outcoming_document') ??
                  'Редактировать расход')
              : (localizations.translate('create_outcoming_document') ??
                  'Создать расход'),
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<MoneyOutcomeBloc, MoneyOutcomeState>(
        listener: (context, state) {
          if (state is MoneyOutcomeCreateSuccess) {
            setState(() {
              _isLoading = false;
            });
            Navigator.pop(context, true);
          } else if (state is MoneyOutcomeUpdateSuccess) {
            setState(() {
              _isLoading = false;
            });
            Navigator.pop(context, true);
          } else if (state is MoneyOutcomeCreateError) {
            setState(() {
              _isLoading = false;
            });
            if (state.statusCode == 409) {
              _showSalaryNoticeDialog(localizations, state.message);
            }
          } else if (state is MoneyOutcomeUpdateError) {
            setState(() {
              _isLoading = false;
            });
            if (state.statusCode == 409) {
              _showSalaryNoticeDialog(localizations, state.message);
            }
          } else if (state is MoneyOutcomeToggleOneApproveSuccess) {
            setState(() {
              _isApproveLoading = false;
              _isApproved = !_isApproved;
            });
          } else if (state is MoneyOutcomeToggleOneApproveError) {
            setState(() {
              _isApproveLoading = false;
            });
            if (state.statusCode == 409) {
              _showSalaryNoticeDialog(localizations, state.message);
            }
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEdit) ...[
                        Center(
                          child: _buildApproveButton(localizations),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildDateField(localizations),
                      const SizedBox(height: 16),
                      _buildMonthField(localizations),
                      const SizedBox(height: 16),
                      _buildEmployeeField(localizations),
                      const SizedBox(height: 16),
                      CashRegisterGroupWidget(
                        selectedCashRegisterId:
                            _selectedCashRegister?.id.toString(),
                        onSelectCashRegister: (cashRegister) {
                          setState(() {
                            _selectedCashRegister = cashRegister;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildAmountField(localizations),
                      const SizedBox(height: 16),
                      _buildCommentField(localizations),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(localizations),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApproveButton(AppLocalizations localizations) {
    final colors = context.appColors;
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: _isApproveLoading ? 0.6 : 1.0,
          child: StyledActionButton(
            text: !_isApproved
                ? localizations.translate('approve_document')
                : localizations.translate('unapprove_document'),
            icon: !_isApproved
                ? Icons.check_circle_outline
                : Icons.close_outlined,
            color: !_isApproved
                ? const Color(0xFF4CAF50)
                : const Color(0xFFFFA500),
            onPressed: _isApproveLoading ? () {} : _toggleApproval,
          ),
        ),
        if (_isApproveLoading)
          Positioned(
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.surfacePrimary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateField(AppLocalizations localizations) {
    return CustomTextFieldDate(
      controller: _dateController,
      label: localizations.translate('date') ?? 'Дата',
      withTime: true,
      onDateSelected: (value) {
        _dateController.text = value;
      },
    );
  }

  Widget _buildMonthField(AppLocalizations localizations) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('month') ?? 'Месяц',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectMonth,
          child: AbsorbPointer(
            child: TextFormField(
              controller: _monthController,
              decoration: InputDecoration(
                hintText: 'MM/YYYY',
                prefixIcon: Icon(Icons.calendar_month_outlined,
                    color: colors.textPrimary),
                suffixIcon: _isEmployeesLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colors.fieldBg,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeField(AppLocalizations localizations) {
    final colors = context.appColors;
    final borderColor = _employeeTouched && _selectedEmployee == null
        ? Colors.red
        : colors.borderSubtle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('employee') ?? 'Сотрудник',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (_employeesError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _employeesError!,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loadEmployees,
                  child: Text(localizations.translate('retry') ?? 'Повторить'),
                ),
              ],
            ),
          )
        else
          CustomDropdown<EmployeeRemainingModel>.search(
            key: ValueKey(
              'employee_dropdown_${_selectedMonthValue ?? ''}_${_selectedEmployee?.id ?? 'none'}_${_employees.length}',
            ),
            items: _employees,
            controller: _employeeController,
            hintText: localizations.translate('select_employee') ??
                'Выберите сотрудника',
            searchHintText: localizations.translate('search') ?? 'Поиск',
            decoration: CustomDropdownDecoration(
              closedFillColor: colors.fieldBg,
              expandedFillColor: colors.surfacePrimary,
              closedBorder: Border.all(
                  color: borderColor, width: _employeeTouched ? 1.5 : 1),
              expandedBorder: Border.all(color: colors.borderSubtle),
              closedBorderRadius: BorderRadius.circular(12),
              expandedBorderRadius: BorderRadius.circular(12),
              listItemStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
              headerStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textSecondary,
              ),
            ),
            onChanged: (value) {
              if (value != null) {
                _handleEmployeeSelected(value);
              }
            },
            listItemBuilder: (context, item, isSelected, onItemSelect) {
              return Row(
                children: [
                  Expanded(
                    child: Text(item.fullName),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    parseNumberToString(item.remaining),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                      color: Color(0xff16A34A),
                    ),
                  ),
                ],
              );
            },
            headerBuilder: (context, selectedItem, enabled) {
              return Text(
                selectedItem.fullName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
                ),
              );
            },
          ),
        if (_selectedEmployee != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: colors.fieldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.translate('remaining') ?? 'Остаток',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                Text(
                  parseNumberToString(_selectedEmployee!.remaining),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Gilroy',
                    color: Color(0xff16A34A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAmountField(AppLocalizations localizations) {
    return CustomTextField(
      controller: _amountController,
      inputFormatters: [PriceInputFormatter()],
      label: localizations.translate('amount') ?? 'Сумма',
      hintText: localizations.translate('enter_amount') ?? 'Введите сумму',
      maxLines: 1,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return localizations.translate('field_required') ?? 'Введите сумму';
        }

        final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
        if (parsed == null) {
          return localizations.translate('enter_valid_amount') ??
              'Введите корректную сумму';
        }

        if (parsed <= 0) {
          return localizations.translate('amount_must_be_greater_than_zero') ??
              'Сумма должна быть больше нуля';
        }

        return null;
      },
    );
  }

  Widget _buildCommentField(AppLocalizations localizations) {
    return CustomTextField(
      controller: _commentController,
      label: localizations.translate('comment') ?? 'Комментарий',
      hintText: localizations.translate('comment_hint') ?? 'Комментарий...',
      maxLines: 4,
    );
  }

  Widget _buildActionButtons(AppLocalizations localizations) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!_isEdit && _hasApprovePermission) ...[
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xff4CAF50), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _isLoading ? null : _saveAndApproveDocument,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: _isLoading
                            ? colors.textSecondary
                            : const Color(0xff4CAF50),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        localizations.translate('save_and_approve') ??
                            'Сохранить и провести',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: _isLoading
                              ? colors.textSecondary
                              : const Color(0xff4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.fieldBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: Text(
                    localizations.translate('close') ?? 'Отмена',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDocument,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.buttonPrimaryBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                colors.surfacePrimary),
                          ),
                        )
                      : Text(
                          localizations.translate('save') ?? 'Сохранить',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: colors.surfacePrimary,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
