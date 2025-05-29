import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_bloc.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_event.dart';
import 'package:crm_task_manager/bloc/main_field/main_field_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/directory_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_create_field.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/deal_name_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/custom_field_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_deal_status_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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
  bool _showAdditionalFields = false;

  @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<DealBloc>().add(FetchDealStatuses());
    _fetchAndAddCustomFields();
  }

  void _fetchAndAddCustomFields() async {
    try {
      print('Загрузка кастомных полей и справочников для сделки');
      // Получаем кастомные поля
      final customFieldsData = await ApiService().getCustomFieldsdeal();
      if (customFieldsData['result'] != null) {
        setState(() {
          customFields.addAll(customFieldsData['result'].map<CustomField>((value) {
            return CustomField(
              fieldName: value,
              controller: TextEditingController(),
              uniqueId: Uuid().v4(),
            );
          }).toList());
        });
      }

      // Получаем связанные справочники для сделки
      final directoryLinkData = await ApiService().getDealDirectoryLinks();
      if (directoryLinkData.data != null) {
        setState(() {
          customFields.addAll(directoryLinkData.data!.map<CustomField>((link) {
            return CustomField(
              fieldName: link.directory.name,
              controller: TextEditingController(),
              isDirectoryField: true,
              directoryId: link.directory.id,
              uniqueId: Uuid().v4(),
            );
          }).toList());
        });
      }
    } catch (e) {
      print('Ошибка при получении данных: $e');
    }
  }

  void _addCustomField(String fieldName, {bool isDirectory = false, int? directoryId}) {
    print('Добавление поля: $fieldName, isDirectory: $isDirectory, directoryId: $directoryId');
    if (isDirectory && directoryId != null) {
      // Проверяем, существует ли уже поле с таким directoryId
      bool directoryExists = customFields.any((field) => field.isDirectoryField && field.directoryId == directoryId);
      if (directoryExists) {
        print('Справочник с directoryId: $directoryId уже добавлен, пропускаем');
        return; // Игнорируем добавление, если справочник уже существует
      }
    }
    setState(() {
      customFields.add(CustomField(
        fieldName: fieldName,
        controller: TextEditingController(),
        isDirectoryField: isDirectory,
        directoryId: directoryId,
        uniqueId: Uuid().v4(),
      ));
    });
  }

  void _showAddFieldMenu() {
    print('Открытие меню добавления поля');
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(300, 650, 200, 300),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      color: Colors.white,
      items: [
        PopupMenuItem(
          value: 'manual',
          child: Text(
            AppLocalizations.of(context)!.translate('manual_input'),
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        PopupMenuItem(
          value: 'directory',
          child: Text(
            AppLocalizations.of(context)!.translate('directory'),
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
      ],
    ).then((value) {
      print('Выбрано значение в меню: $value');
      if (value == 'manual') {
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
      } else if (value == 'directory') {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AddCustomDirectoryDialog(
              onAddDirectory: (directory) {
                print('Выбран справочник: ${directory.name}, id: ${directory.id}');
                _addCustomField(directory.name, isDirectory: true, directoryId: directory.id);
                // Связываем справочник с моделью deal
                ApiService().linkDirectory(
                  directoryId: directory.id,
                  modelType: 'deal',
                  organizationId: ApiService().getSelectedOrganization().toString(),
                ).then((_) {
                  print('Справочник успешно связан с моделью deal');
                }).catchError((e) {
                  print('Ошибка при связывании справочника: $e');
                });
              },
            );
          },
        );
      }
    });
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
      body: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => MainFieldBloc()),
        ],
        child: BlocListener<DealBloc, DealState>(
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
                            hasError: isStartDateInvalid,
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
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
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
                          const SizedBox(height: 16),
                          if (!_showAdditionalFields)
                            CustomButton(
                              buttonText: AppLocalizations.of(context)!.translate('additionally'),
                              buttonColor: Color(0xff1E2E52),
                              textColor: Colors.white,
                              onPressed: () {
                                setState(() {
                                  _showAdditionalFields = true;
                                });
                              },
                            )
                          else ...[
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: customFields.length,
                              itemBuilder: (context, index) {
                                final field = customFields[index];
                                return Container(
                                  key: ValueKey(field.uniqueId),
                                  child: field.isDirectoryField && field.directoryId != null
                                      ? MainFieldDropdownWidget(
                                          directoryId: field.directoryId!,
                                          directoryName: field.fieldName,
                                          selectedField: null,
                                          onSelectField: (MainField selectedField) {
                                            setState(() {
                                              customFields[index] = field.copyWith(
                                                entryId: selectedField.id,
                                                controller: TextEditingController(text: selectedField.value),
                                              );
                                            });
                                          },
                                          controller: field.controller,
                                          onSelectEntryId: (int entryId) {
                                            setState(() {
                                              customFields[index] = field.copyWith(
                                                entryId: entryId,
                                              );
                                            });
                                          },
                                          onRemove: () {
                                            setState(() {
                                              customFields.removeAt(index);
                                            });
                                          },
                                        )
                                      : CustomFieldWidget(
                                          fieldName: field.fieldName,
                                          valueController: field.controller,
                                          onRemove: () {
                                            setState(() {
                                              customFields.removeAt(index);
                                            });
                                          },
                                        ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            CustomButton(
                              buttonText: AppLocalizations.of(context)!.translate('add_field'),
                              buttonColor: Color(0xff1E2E52),
                              textColor: Colors.white,
                              onPressed: _showAddFieldMenu,
                            ),
                          ],
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
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() &&
        titleController.text.isNotEmpty &&
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
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
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
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<Map<String, String>> customFieldMap = [];
    List<Map<String, int>> directoryValues = [];

    for (var field in customFields) {
      String fieldName = field.fieldName.trim();
      String fieldValue = field.controller.text.trim();

      if (field.isDirectoryField && field.directoryId != null && field.entryId != null) {
        directoryValues.add({
          'directory_id': field.directoryId!,
          'entry_id': field.entryId!,
        });
      } else if (fieldName.isNotEmpty && fieldValue.isNotEmpty) {
        customFieldMap.add({fieldName: fieldValue});
      }
    }

    final String name = titleController.text;
    final localizations = AppLocalizations.of(context)!;

    context.read<DealBloc>().add(CreateDeal(
      name: name,
      dealStatusId: int.parse(selectedDealStatus!),
      managerId: int.parse(selectedManager!),
      leadId: widget.leadId,
      dealtypeId: 1,
      startDate: startDate,
      endDate: endDate,
      sum: sumController.text,
      description: descriptionController.text.isEmpty ? null : descriptionController.text,
      customFields: customFieldMap,
      directoryValues: directoryValues,
      localizations: localizations,
    ));
  }
}