import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_create_field.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DealAddScreen extends StatefulWidget {
  final int statusId;

  DealAddScreen({required this.statusId});

  @override
  _DealAddScreenState createState() => _DealAddScreenState();
}

class _DealAddScreenState extends State<DealAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController sumController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedManager;
  String? selectedLead;
  List<CustomField> customFields = [];
  bool isEndDateInvalid = false;

  @override
  void initState() {
    super.initState();
    _fetchAndAddCustomFields();

    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetAllLeadBloc>().add(GetAllLeadEv());
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

  void _fetchAndAddCustomFields() async {
    try {
      // Здесь предполагается, что getCustomFields определён в ApiService
      final data =
          await ApiService().getCustomFieldsdeal(); // Выполнить GET-запрос
      if (data['result'] != null) {
        data['result'].forEach((value) {
          setState(() {
            customFields.add(CustomField(fieldName: value));
          });
        });
      }
    } catch (e) {
      print('Ошибка!');
    }
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
            Navigator.pop(context, widget.statusId);
            context.read<DealBloc>().add(FetchDealStatuses());
          },
        ),
        title: Row(
          children: [
            Text(
              AppLocalizations.of(context)!.translate('new_deal'), 
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
                content: Text(
                  AppLocalizations.of(context)!.translate(state.message), // Локализация сообщения
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.red,
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: Duration(seconds: 3),
              ),
            );
          } else if (state is DealSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.translate(state.message), // Локализация сообщения
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.green,
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.pop(context, widget.statusId);
            context.read<DealBloc>().add(FetchDealStatuses());
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
                        hintText: AppLocalizations.of(context)!.translate('enter_name_list'), 
                        label: AppLocalizations.of(context)!.translate('name_list'), 
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.translate('field_required');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      LeadRadioGroupWidget(
                        selectedLead: selectedLead,
                        onSelectLead: (LeadData selectedRegionData) {
                          setState(() {
                            selectedLead = selectedRegionData.id.toString();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      ManagerRadioGroupWidget(
                        selectedManager: selectedManager,
                        onSelectManager: (ManagerData selectedManagerData) {
                          setState(() {
                            selectedManager = selectedManagerData.id.toString();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextFieldDate(
                        controller: startDateController,
                        label: AppLocalizations.of(context)!.translate('start_date'),
                        withTime: false,
                       
                      ),
                      const SizedBox(height: 8),
                      CustomTextFieldDate(
                        controller: endDateController,
                        label: AppLocalizations.of(context)!.translate('end_date'),
                        hasError: isEndDateInvalid,
                        withTime: false,
                        
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: sumController,
                        hintText: AppLocalizations.of(context)!.translate('enter_summ'),
                        label: AppLocalizations.of(context)!.translate('summ'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                           return AppLocalizations.of(context)!.translate('field_required');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: descriptionController,
                        hintText: AppLocalizations.of(context)!.translate('enter_description'),
                        label: AppLocalizations.of(context)!.translate('description_list'),
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
                        buttonText: AppLocalizations.of(context)!.translate('add_field'),
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
                        buttonText:  AppLocalizations.of(context)!.translate('cancel'),
                        buttonColor: Color(0xffF4F7FD),
                        textColor: Colors.black,
                        onPressed: () {
                          Navigator.pop(context, widget.statusId);
                          context.read<DealBloc>().add(FetchDealStatuses());
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BlocBuilder<DealBloc, DealState>(
                        builder: (context, state) {
                          if (state is DealLoading) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: Color(0xff1E2E52),
                              ),
                            );
                          } else {
                            return CustomButton(
                              buttonText:  AppLocalizations.of(context)!.translate('add'),
                                buttonColor: Color(0xff4759FF),
                                textColor: Colors.white,
                                onPressed: _submitForm);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() &&
        selectedManager != null &&
        selectedLead != null) {
      _createDeal();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('fill_required_fields'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.red,
          elevation: 3,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _createDeal() {
    final String name = titleController.text;

    final String? startDateString = startDateController.text.isEmpty ? null : startDateController.text;
    final String? endDateString = endDateController.text.isEmpty ? null : endDateController.text;

    final String sum = sumController.text;
    final String? description = descriptionController.text.isEmpty ? null : descriptionController.text;

    DateTime? startDate;
    if (startDateString != null && startDateString.isNotEmpty) {
      try {
        startDate = DateFormat('dd/MM/yyyy').parse(startDateString);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.translate('enter_valid_datetime'),),
          ),
        );
        return;
      }
    }
    DateTime? endDate;
    if (endDateString != null && endDateString.isNotEmpty) {
      try {
        endDate = DateFormat('dd/MM/yyyy').parse(endDateString);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.translate('enter_valid_datetime'),),
          ),
        );
        return;
      }
    }

    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      setState(() {
        isEndDateInvalid = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('start_date_after_end_date'),
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Создание сделки
    List<Map<String, String>> customFieldMap = [];
    for (var field in customFields) {
      String fieldName = field.fieldName.trim();
      String fieldValue = field.controller.text.trim();
      if (fieldName.isNotEmpty && fieldValue.isNotEmpty) {
        customFieldMap.add({fieldName: fieldValue});
      }
    }

    context.read<DealBloc>().add(CreateDeal(
          name: name,
          dealStatusId: widget.statusId,
          managerId: int.parse(selectedManager!),
          leadId: int.parse(selectedLead!),
          dealtypeId: 1,
          startDate: startDate,
          endDate: endDate,
          sum: sum,
          description: description,
          customFields: customFieldMap,
        ));
  }
}

class CustomField {
  final String fieldName;
  final TextEditingController controller = TextEditingController();

  CustomField({required this.fieldName});
}
