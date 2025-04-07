import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_bloc.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_create_field.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/deal_name_list.dart'; // Added for DealNameSelectionWidget
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_deal_status_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? selectedDealStatus;
  List<CustomField> customFields = [];
  bool isStartDateInvalid = false;
  bool isEndDateInvalid = false;

  @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<DealBloc>().add(FetchDealStatuses());
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.translate(state.message),
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
            });
          } else if (state is DealSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.translate('deal_created_successfully'),
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
            Navigator.pop(context, widget.leadId);
            context.read<LeadDealsBloc>().add(FetchLeadDeals(widget.leadId));
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Added DealNameSelectionWidget for title selection
                        DealNameSelectionWidget(
                          selectedDealName: titleController.text,
                          onSelectDealName: (String dealName) {
                            setState(() {
                              titleController.text = dealName;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        DealStatusWidget(
                          selectedDealStatus: selectedDealStatus,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedDealStatus = newValue;
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
                          withTime: false,
                          hasError: isEndDateInvalid,
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
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: descriptionController,
                          hintText: AppLocalizations.of(context)!.translate('enter_description'),
                          label: AppLocalizations.of(context)!.translate('description_list'),
                          maxLines: 5,
                          keyboardType: TextInputType.multiline,
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
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        buttonText: AppLocalizations.of(context)!.translate('cancel'),
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
                              buttonText: AppLocalizations.of(context)!.translate('add'),
                              buttonColor: Color(0xff4759FF),
                              textColor: Colors.white,
                              onPressed: _submitForm,
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

  void _submitForm() {
    if (_formKey.currentState!.validate() &&
        titleController.text.isNotEmpty && // Check titleController instead of null
        selectedManager != null &&
        selectedDealStatus != null) {
      _createLeadDeal();
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

  void _createLeadDeal() {
    DateTime? startDate;
    DateTime? endDate;
    try {
      if (startDateController.text.isNotEmpty) {
        startDate = DateFormat('dd/MM/yyyy').parseStrict(startDateController.text);
      }
      if (endDateController.text.isNotEmpty) {
        endDate = DateFormat('dd/MM/yyyy').parseStrict(endDateController.text);
      }
    } catch (e) {
      setState(() {
        isStartDateInvalid = true;
        isEndDateInvalid = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('error_parsing_date'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      setState(() {
        isStartDateInvalid = true;
        isEndDateInvalid = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('start_date_after_end_date'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final String name = titleController.text;
    final localizations = AppLocalizations.of(context)!;

    context.read<DealBloc>().add(CreateDeal(
      name: name,
      dealStatusId: int.parse(selectedDealStatus!),
      managerId: int.parse(selectedManager!),
      leadId: widget.leadId,
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
      localizations: localizations,
    ));
  }
}

class CustomField {
  final String fieldName;
  final TextEditingController controller = TextEditingController();

  CustomField({required this.fieldName});
}