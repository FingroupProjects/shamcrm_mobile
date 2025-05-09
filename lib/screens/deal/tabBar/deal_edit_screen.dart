import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_create_field.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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
  final String? createdAt;
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
    this.createdAt,
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
  final TextEditingController authorController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController createdAtController = TextEditingController();
  final TextEditingController sumController = TextEditingController();

  String? selectedManager;
  String? selectedLead;
  List<CustomField> customFields = [];
  bool isEndDateInvalid = false;


  @override
  void initState() {
    super.initState();

    titleController.text = widget.dealName;
    descriptionController.text = widget.description ?? '';
    selectedManager = widget.manager;
    selectedLead = widget.lead;
    startDateController.text = widget.startDate ?? '';
    endDateController.text = widget.endDate ?? '';
    sumController.text = widget.sum ?? '';

    for (var customField in widget.dealCustomFields) {
      customFields.add(CustomField(fieldName: customField.key)
        ..controller.text = customField.value);
    }

    context.read<GetAllLeadBloc>().add(GetAllLeadEv());
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
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
        centerTitle: false,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.translate('edit_deal'),
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
                  AppLocalizations.of(context)!.translate('deal_updated_successfully'),
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
            Navigator.pop(context, true);
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
                        validator: (value) => value!.isEmpty
                            ? AppLocalizations.of(context)!.translate('field_required')
                            : null,
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
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //    return AppLocalizations.of(context)!.translate('field_required');
                        //   }
                        //   return null;
                        // },
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: descriptionController,
                        hintText: AppLocalizations.of(context)!.translate('enter_description'),
                        label: AppLocalizations.of(context)!.translate('description_list'),
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
                        buttonColor: const Color(0xffF4F7FD),
                        textColor: Colors.black,
                        onPressed: () => Navigator.pop(context, null),
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
                              buttonText:  AppLocalizations.of(context)!.translate('save'),
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
                                          .parseStrict(
                                              startDateController.text);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              AppLocalizations.of(context)!.translate('error_parsing_date'),),
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:  Text(
                                        AppLocalizations.of(context)!.translate('error_parsing_date'),), 
                                         backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                  }

                                 if (parsedStartDate != null && parsedEndDate != null &&  parsedStartDate.isAfter(parsedEndDate)) {
                                      setState(() {
                                        isEndDateInvalid=true;
                                      });
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(
                                       content: Text(AppLocalizations.of(context)!.translate('start_date_after_end_date'),),
                                       backgroundColor: Colors.red,
                                     ),
                                   );
                                   return;
                                 }
                                 List<Map<String, String>> customFieldList =
                                      [];
                                  for (var field in customFields) {
                                    String fieldName = field.fieldName.trim();
                                    String fieldValue =
                                        field.controller.text.trim();
                                    if (fieldName.isNotEmpty &&
                                        fieldValue.isNotEmpty) {
                                      customFieldList.add({fieldName: fieldValue});
                                    }
                                  }
                                  final localizations = AppLocalizations.of(context)!;
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
                                        description: descriptionController.text,
                                        startDate: parsedStartDate,
                                        endDate: parsedEndDate,
                                        sum: sumController.text,
                                        dealtypeId: 1,
                                        customFields: customFieldList,
                                        localizations: localizations,
                                      ));
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
                              },
                            );
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
}
