import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_manager_list.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/page_2/order/order_details/payment_method_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/status_method_dropdown.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class OrdersFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;

  const OrdersFilterScreen({
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters,
  }) : super(key: key);

  @override
  _OrdersFilterScreenState createState() => _OrdersFilterScreenState();
}

class _OrdersFilterScreenState extends State<OrdersFilterScreen> {
  final TextEditingController _clientController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedStatus;
  String? _selectedPaymentMethod;
  String? _paymentMethod;
  String? _statusMethod;
    List _selectedManagers = [];


  String? selectedLead;
  // Список статусов заказов
  final List<String> _orderStatuses = [
    'Новый',
    'Ожидает оплаты',
    'Оплачен',
    'В обработке',
    'Отправлен',
    'Завершен',
    'Отменен',
  ];

  // Список способов оплаты
  final List<String> _paymentMethods = [
    'Наличные',
    'Онлайн',
    'Карта',
  ];

  @override
  void initState() {
    super.initState();
  }

  void _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (pickedRange != null) {
      setState(() {
        _fromDate = pickedRange.start;
        _toDate = pickedRange.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FD),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('filter'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52), // Исправлен цвет с 0xfff1E2E52
            fontFamily: 'Gilroy',
          ),
        ),
        backgroundColor: Colors.white,
        forceMaterialTransparency: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                widget.onResetFilters?.call();
                _fromDate = null;
                _toDate = null;
                _clientController.clear();
                _selectedStatus = null;
                _selectedPaymentMethod = null;
              });
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('reset'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
  onPressed: () {
    bool isAnyFilterSelected = _fromDate != null ||
        _toDate != null ||
        _clientController.text.isNotEmpty ||
        _selectedStatus != null ||
        _selectedPaymentMethod != null ||
        _selectedManagers.isNotEmpty; // Добавляем проверку на _selectedManagers
    if (isAnyFilterSelected) {
      widget.onSelectedDataFilter?.call({
        'fromDate': _fromDate,
        'toDate': _toDate,
        'client': _clientController.text,
        'status': _selectedStatus,
        'paymentMethod': _selectedPaymentMethod,
        'managers': _selectedManagers.map((manager) => manager.id.toString()).toList(), // Преобразуем в список ID
      });
    }
    Navigator.pop(context);
  },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('apply'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
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
                    // Фильтр по дате
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: GestureDetector(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fromDate != null && _toDate != null
                                    ? "${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year} - ${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}"
                                    : AppLocalizations.of(context)!
                                        .translate('select_date_range'),
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: _fromDate != null && _toDate != null
                                      ? Colors.black
                                      : const Color(0xff99A4BA),
                                  fontSize: 14,
                                ),
                              ),
                              const Icon(Icons.calendar_today,
                                  color: Color(0xff99A4BA)),
                            ],
                          ),
                        ),
                      ),
                    ),
                                        const SizedBox(height: 8),

                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: ManagerMultiSelectWidget(
                          selectedManagers: _selectedManagers.map((manager) => manager.id.toString()).toList(),
                          onSelectManagers: (List<ManagerData> selectedUsersData) {
                            setState(() {
                              _selectedManagers = selectedUsersData;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: LeadRadioGroupWidget(
                          selectedLead: selectedLead,
                          onSelectLead: (LeadData selectedRegionData) {
                            setState(() {
                              selectedLead = selectedRegionData.id.toString();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: PaymentMethodDropdown(
                          selectedPaymentMethod: _paymentMethod,
                          onSelectPaymentMethod: (value) {
                            setState(() {
                              _paymentMethod = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: StatusMethodDropdown(
                          selectedstatusMethod: _statusMethod,
                          onSelectstatusMethod: (value) {
                            setState(() {
                              _statusMethod = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text(
              hint,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                color: Color(0xff99A4BA),
                fontSize: 14,
              ),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}


