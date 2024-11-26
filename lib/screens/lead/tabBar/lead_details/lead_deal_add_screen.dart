import 'package:crm_task_manager/bloc/currency/currency_bloc.dart';
import 'package:crm_task_manager/bloc/currency/currency_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_bloc.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_event.dart';
import 'package:crm_task_manager/bloc/manager/manager_bloc.dart';
import 'package:crm_task_manager/bloc/manager/manager_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/screens/deal/tabBar/currency_list.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_create_field.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_deal_status_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';


class LeadDealAddScreen extends StatefulWidget {
  final int leadId;

  LeadDealAddScreen({required this.leadId});

  @override
  _LeadDealAddScreenState createState() => _LeadDealAddScreenState();
}


class _LeadDealAddScreenState extends State<LeadDealAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController sumController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedManager;
  String? selectedDealStatus; // Добавляем выбор статуса
  String? selectedCurrency;
  List<CustomField> customFields = [];

  @override
  void initState() {
    super.initState();
    context.read<ManagerBloc>().add(FetchManagers());
    context.read<DealBloc>().add(FetchDealStatuses()); // Загружаем статусы
    context.read<CurrencyBloc>().add(FetchCurrencies());
  }

  void _addCustomField(String fieldName) {
    setState(() {
      customFields.add(CustomField(fieldName: fieldName));
    });
  }

  void _showAddFieldDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddCustomFieldDialog(
          onAddField: (fieldName) {
            _addCustomField(fieldName);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            Navigator.pop(context, widget.leadId);
            context.read<DealBloc>().add(FetchDealStatuses());
          },
        ),
        title: const Row(
          children: [
            Text(
              'Новая сделка',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ],
        ),
      ),
      body: BlocListener<DealBloc, DealState>(
        listener: (context, state) {
          if (state is DealError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is DealSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, widget.leadId);

  // Добавьте это:
  context.read<LeadDealsBloc>().add(FetchLeadDeals(widget.leadId));
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: titleController,
                        hintText: 'Введите название',
                        label: 'Название',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Поле обязательно для заполнения';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      // Выбор статуса сделки
                      DealStatusWidget(
                        selectedDealStatus: selectedDealStatus,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedDealStatus = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      ManagerWidget(
                        selectedManager: selectedManager,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedManager = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      CurrencyWidget(
                        selectedCurrency: selectedCurrency,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedCurrency = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextFieldDate(
                        controller: startDateController,
                        label: 'Дата начало',
                        withTime: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Поле обязательно для заполнения';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextFieldDate(
                        controller: endDateController,
                        label: 'Дата окончание',
                        withTime: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Поле обязательно для заполнения';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: sumController,
                        hintText: 'Введите сумму',
                        label: 'Сумма',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Поле обязательно для заполнения';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: descriptionController,
                        hintText: 'Введите описание',
                        label: 'Описание',
                        maxLines: 5,
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: customFields.length,
                        itemBuilder: (context, index) {
                          return CustomFieldWidget(
                            fieldName: customFields[index].fieldName,
                            valueController: customFields[index].controller,
                            onRemove: () {
                              setState(() {
                                customFields.removeAt(index);
                              });
                            },
                          );
                        },
                      ),
                      CustomButton(
                        buttonText: 'Добавить поле',
                        buttonColor: Color(0xff1E2E52),
                        textColor: Colors.white,
                        onPressed: _showAddFieldDialog,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        buttonText: 'Отмена',
                        buttonColor: Color(0xffF4F7FD),
                        textColor: Colors.black,
                        onPressed: () {
                          Navigator.pop(context, widget.leadId);
                          context.read<DealBloc>().add(FetchDealStatuses());
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        buttonText: 'Добавить',
                        buttonColor: Color(0xff4759FF),
                        textColor: Colors.white,
                        onPressed: () {
                          if (_formKey.currentState!.validate() &&
                              selectedManager != null &&
                              selectedDealStatus != null) {
                            final String name = titleController.text;

                            // Остальная логика остается такой же
                            context.read<DealBloc>().add(CreateDeal(
                                  name: name,
                                  dealStatusId: int.parse(selectedDealStatus!),
                                  managerId: int.parse(selectedManager!),
                                  leadId: widget.leadId,
                                  currencyId: selectedCurrency != null
                                      ? int.parse(selectedCurrency!)
                                      : null,
                                  dealtypeId: 1,
                                  startDate: startDateController.text.isNotEmpty
                                      ? DateFormat('dd/MM/yyyy').parse(startDateController.text)
                                      : null,
                                  endDate: endDateController.text.isNotEmpty
                                      ? DateFormat('dd/MM/yyyy').parse(endDateController.text)
                                      : null,
                                  sum: sumController.text,
                                  description: descriptionController.text,
                                  customFields: [],
                                ));

                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

                          // context.read<LeadDealsBloc>().add(FetchLeadDeals(widget.leadId));
