import 'package:crm_task_manager/bloc/currency/currency_bloc.dart';
import 'package:crm_task_manager/bloc/currency/currency_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/manager/manager_bloc.dart';
import 'package:crm_task_manager/bloc/manager/manager_event.dart';
import 'package:crm_task_manager/bloc/region/region_bloc.dart';
import 'package:crm_task_manager/bloc/region/region_event.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/currency_list.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_create_field.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/deal/tabBar/manager_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:intl/intl.dart';

class DealEditScreen extends StatefulWidget {
  final int dealId;
  final String dealName;
  // final String dealStatus;
  final String? manager;
  final String? currency;
  final String? lead;
  final String? startDate;
  final String? endDate;
  final String? description;
  final String? sum;
  final int statusId;
  final List<DealCustomFieldsById> dealCustomFields;

  DealEditScreen({
    required this.dealId,
    required this.dealName,
    // required this.dealStatus,
    required this.statusId,
    this.manager,
    this.currency,
    this.lead,
    this.startDate,
    this.endDate,
    this.description,
    this.sum,
    required this.dealCustomFields,
  });

  @override
  _DealEditScreenState createState() => _DealEditScreenState();
}

class _DealEditScreenState extends State<DealEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController sumController = TextEditingController();

  String? selectedManager;
  String? selectedCurrency;
  String? selectedLead;
  List<CustomField> customFields = [];

@override
void initState() {
  super.initState();

  titleController.text = widget.dealName;
  descriptionController.text = widget.description ?? '';
  selectedManager = widget.manager;
  selectedCurrency = widget.currency;
  selectedLead = widget.lead;
  startDateController.text = widget.startDate ?? '';
  endDateController.text = widget.endDate ?? '';
  sumController.text = widget.sum ?? '';

  for (var customField in widget.dealCustomFields) {
    customFields.add(CustomField(fieldName: customField.key)
      ..controller.text = customField.value);
  }

  context.read<RegionBloc>().add(FetchRegions());
  context.read<LeadBloc>().add(FetchAllLeads());
  context.read<ManagerBloc>().add(FetchManagers());
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Редактирование Сделки',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      body: BlocListener<DealBloc, DealState>(
        listener: (context, state) {
          if (state is DealError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is DealSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Сделка успешно обновлена'),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );
             Navigator.pop(context,true); 
            //  Navigator.pop(context, widget.statusId);
            // context.read<DealBloc>().add(FetchDeals(widget.statusId));
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
                        validator: (value) => value!.isEmpty
                            ? 'Поле обязательно для заполнения'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      LeadWidget(
                        selectedLead: selectedLead,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedLead = newValue;
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
                        label: 'Дата начала',
                        withTime: false,
                      ),
                      const SizedBox(height: 8),
                      CustomTextFieldDate(
                        controller: endDateController,
                        label: 'Дата окончания',
                        withTime: false,
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
                      const SizedBox(height: 20),
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
                        buttonColor: const Color(0xffF4F7FD),
                        textColor: Colors.black,
                        onPressed: () => Navigator.pop(context, null),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        buttonText: 'Сохранить',
                        buttonColor: const Color(0xff4759FF),
                        textColor: Colors.white,
                        onPressed: () {
                          if (_formKey.currentState!.validate() &&
                              selectedManager != null &&
                              selectedLead != null) {
                            DateTime? parsedStartDate;
                            DateTime? parsedEndDate;

                            if (startDateController.text.isNotEmpty) {
                              try {
                                parsedStartDate = DateFormat('dd/MM/yyyy')
                                    .parseStrict(startDateController.text);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Ошибка парсинга даты начала. Пожалуйста, используйте формат DD/MM/YYYY.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                            }
                            if (endDateController.text.isNotEmpty) {
                              try {
                                parsedEndDate = DateFormat('dd/MM/yyyy')
                                    .parseStrict(endDateController.text);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Ошибка парсинга даты окончания. Пожалуйста, используйте формат DD/MM/YYYY.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                            }

                            List<Map<String, String>> customFieldList = [];
                            for (var field in customFields) {
                              String fieldName = field.fieldName.trim();
                              String fieldValue = field.controller.text.trim();
                              if (fieldName.isNotEmpty &&
                                  fieldValue.isNotEmpty) {
                                customFieldList.add({fieldName: fieldValue});
                              }
                            }

                            context.read<DealBloc>().add(UpdateDeal(
                                  dealId: widget.dealId,
                                  name: titleController.text,
                                  dealStatusId: widget.statusId,
                                  managerId: selectedManager != null
                                      ? int.parse(selectedManager!)
                                      : null,
                                  leadId: selectedLead != null
                                      ? int.parse(selectedLead!)
                                      : null,
                                  currencyId: selectedCurrency != null
                                      ? int.parse(selectedCurrency!)
                                      : null,
                                  description: descriptionController.text,
                                  startDate: parsedStartDate,
                                  endDate: parsedEndDate,
                                  sum: sumController.text,
                                  dealtypeId: 1,
                                  customFields: customFieldList,
                                ));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Пожалуйста, заполните все обязательные поля.'),
                                backgroundColor: Colors.red,
                              ),
                            );
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
