import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_for_edit.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/lead_status_list.dart';
import 'package:crm_task_manager/models/leadById_model.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_create_field.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_add_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/custom_field_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_status_list_edit.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/region_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/source_lead_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:crm_task_manager/models/directory_model.dart'
    as directory_model;

class LeadEditScreen extends StatefulWidget {
  final int leadId;
  final String leadName;
  final String? region;
  final String? manager;
  final String? sourceId;
  final String? birthday;
  final String? createAt;
  final String? instagram;
  final String? facebook;
  final String? telegram;
  final String? phone;
  final String? whatsApp;
  final String? email;
  final String? description;
  final int statusId;
  final List<LeadCustomFieldsById> leadCustomFields;
  final List<DirectoryValue> directoryValues; // Новое поле

  LeadEditScreen({
    required this.leadId,
    required this.leadName,
    required this.statusId,
    this.region,
    this.manager,
    this.sourceId,
    this.birthday,
    this.createAt,
    this.instagram,
    this.facebook,
    this.telegram,
    this.phone,
    this.whatsApp,
    this.email,
    this.description,
    required this.leadCustomFields,
    required this.directoryValues, // Добавляем в конструктор
  });

  @override
  _LeadEditScreenState createState() => _LeadEditScreenState();
}

class _LeadEditScreenState extends State<LeadEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController whatsAppController = TextEditingController();
  final TextEditingController instaLoginController = TextEditingController();
  final TextEditingController facebookLoginController = TextEditingController();
  final TextEditingController telegramController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController createdAtController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  int? _selectedStatuses;
  String? selectedRegion;
  String? selectedSource;

  String? selectedManager;
  String selectedDialCode = '+992';
  String selectedWhatsAppDialCode = '+992';
  bool _isPhoneEdited = false;
  bool _isWhatsAppEdited = false;

  List<CustomField> customFields = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    titleController.text = widget.leadName;
    _selectedStatuses = widget.statusId;

    if (widget.phone != null) {
      String phoneNumber = widget.phone!;
      for (var code in countryCodes) {
        if (phoneNumber.startsWith(code)) {
          setState(() {
            selectedDialCode = code;
            phoneController.text = phoneNumber.substring(code.length);
          });
          break;
        }
      }
      if (phoneController.text.isEmpty) {
        phoneController.text = phoneNumber;
      }

      _isPhoneEdited = false;
    }
    if (widget.whatsApp != null) {
      String phoneNumber = widget.whatsApp!;
      for (var code in countryCodes) {
        if (phoneNumber.startsWith(code)) {
          setState(() {
            selectedDialCode = code;
            whatsAppController.text = phoneNumber.substring(code.length);
          });
          break;
        }
      }
      if (whatsAppController.text.isEmpty) {
        whatsAppController.text = phoneNumber;
      }

      _isPhoneEdited = false;
    }
    if (widget.whatsApp != null) {
      String whatsAppNumber = widget.whatsApp!;
      for (var code in countryCodes) {
        if (whatsAppNumber.startsWith(code)) {
          setState(() {
            selectedWhatsAppDialCode = code;
            whatsAppController.text = whatsAppNumber.substring(code.length);
          });
          break;
        }
      }
      if (whatsAppController.text.isEmpty) {
        whatsAppController.text = whatsAppNumber;
      }
      _isWhatsAppEdited = false;
    }

    instaLoginController.text = widget.instagram ?? '';
    facebookLoginController.text = widget.facebook ?? '';
    telegramController.text = widget.telegram ?? '';
    birthdayController.text = widget.birthday ?? '';
    emailController.text = widget.email ?? '';
    descriptionController.text = widget.description ?? '';
    selectedRegion = widget.region;
    selectedSource = widget.sourceId;
    selectedManager = widget.manager;
    for (var customField in widget.leadCustomFields) {
      customFields.add(CustomField(
        fieldName: customField.key,
        controller: TextEditingController(),
        uniqueId: Uuid().v4(),
      )..controller.text = customField.value);
    }
    // Добавляем значения справочников
    for (var dirValue in widget.directoryValues) {
      customFields.add(CustomField(
        fieldName: dirValue.entry.directory.name,
        controller:
            TextEditingController(text: dirValue.entry.values['value'] ?? ''),
        isDirectoryField: true,
        directoryId: dirValue.entry.directory.id,
        entryId: dirValue.entry.id,
        uniqueId: Uuid().v4(),
      ));
    }
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetAllRegionBloc>().add(GetAllRegionEv());
    _fetchAndAddDirectoryFields();
  }

  void _fetchAndAddDirectoryFields() async {
    try {
      final directoryLinkData = await _apiService.getLeadDirectoryLinks();
      if (directoryLinkData.data != null) {
        setState(() {
          for (var link in directoryLinkData.data!) {
            // Проверяем, есть ли уже поле справочника с таким directoryId
            bool directoryExists = customFields.any((field) =>
                field.isDirectoryField &&
                field.directoryId == link.directory.id);
            if (!directoryExists) {
              // Ищем соответствующее значение в widget.directoryValues
              final existingValue = widget.directoryValues.firstWhere(
                (dirValue) => dirValue.entry.directory.id == link.directory.id,
                orElse: () => DirectoryValue(
                  id: 0,
                  entry: DirectoryEntry(
                    id: 0,
                    directory: Directory(
                        id: link.directory.id, name: link.directory.name),
                    values: {},
                    createdAt: '',
                  ),
                ),
              );
              // Добавляем поле справочника с учетом существующего значения
              customFields.add(CustomField(
                fieldName: link.directory.name,
                controller: TextEditingController(
                    text: existingValue.entry.values['value'] ?? ''),
                isDirectoryField: true,
                directoryId: link.directory.id,
                entryId:
                    existingValue.entry.id != 0 ? existingValue.entry.id : null,
                uniqueId: Uuid().v4(),
              ));
            }
          }
        });
      }
    } catch (e) {
      print('Ошибка при получении данных справочников: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!
                .translate('error_fetching_directories'),
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
    }
  }

  void _addCustomField(String fieldName,
      {bool isDirectory = false, int? directoryId}) {
    print(
        'Добавление поля: $fieldName, isDirectory: $isDirectory, directoryId: $directoryId');
    if (isDirectory && directoryId != null) {
      bool directoryExists = customFields.any((field) =>
          field.isDirectoryField && field.directoryId == directoryId);
      if (directoryExists) {
        print(
            'Справочник с directoryId: $directoryId уже добавлен, пропускаем');
        return;
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

  void _showAddFieldDialog() {
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
              onAddDirectory: (directory_model.Directory directory) {
                _addCustomField(directory.name,
                    isDirectory: true, directoryId: directory.id);
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
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        title: Transform.translate(
          offset: const Offset(-10, 0),
          child: Text(
            AppLocalizations.of(context)!.translate('edit_lead'),
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Transform.translate(
            offset: const Offset(0, -2),
            child: IconButton(
              icon: Image.asset(
                'assets/icons/arrow-left.png',
                width: 24,
                height: 24,
              ),
              onPressed: () => Navigator.pop(context, null),
            ),
          ),
        ),
        leadingWidth: 40,
      ),
      body: BlocListener<LeadBloc, LeadState>(
        listener: (context, state) {
          if (state is LeadError) {
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
          } else if (state is LeadSuccess) {
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
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          controller: titleController,
                          hintText: AppLocalizations.of(context)!
                              .translate('enter_name_list'),
                          label: AppLocalizations.of(context)!
                              .translate('name_list'),
                          validator: (value) => value!.isEmpty
                              ? AppLocalizations.of(context)!
                                  .translate('field_required')
                              : null,
                        ),
                        const SizedBox(height: 8),
                        LeadStatusEditpWidget(
                          selectedStatus: _selectedStatuses?.toString(),
                          onSelectStatus: (LeadStatus selectedStatusData) {
                            setState(() {
                              _selectedStatuses = selectedStatusData.id;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        CustomPhoneNumberInput(
                          controller: phoneController,
                          selectedDialCode: selectedDialCode,
                          onInputChanged: (String number) {
                            setState(() {
                              _isPhoneEdited = true;
                              selectedDialCode = number;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .translate('field_required');
                            }
                            return null;
                          },
                          label:
                              AppLocalizations.of(context)!.translate('phone'),
                        ),
                        const SizedBox(height: 8),
                        RegionRadioGroupWidget(
                          selectedRegion: selectedRegion,
                          onSelectRegion: (RegionData selectedRegionData) {
                            setState(() {
                              selectedRegion = selectedRegionData.id.toString();
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        ManagerRadioGroupWidget(
                          selectedManager: selectedManager,
                          onSelectManager: (ManagerData selectedManagerData) {
                            setState(() {
                              selectedManager =
                                  selectedManagerData.id.toString();
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        SourceLeadWidget(
                          selectedSourceLead: selectedSource,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedSource = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: instaLoginController,
                          hintText: AppLocalizations.of(context)!
                              .translate('enter_instagram_username'),
                          label: AppLocalizations.of(context)!
                              .translate('instagram'),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: facebookLoginController,
                          hintText: AppLocalizations.of(context)!
                              .translate('enter_facebook_username'),
                          label: AppLocalizations.of(context)!
                              .translate('Facebook'),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: telegramController,
                          hintText: AppLocalizations.of(context)!
                              .translate('enter_telegram_username'),
                          label: AppLocalizations.of(context)!
                              .translate('telegram'),
                        ),
                        const SizedBox(height: 8),
                        CustomPhoneNumberInput(
                          controller: whatsAppController,
                          selectedDialCode: selectedWhatsAppDialCode,
                          onInputChanged: (String number) {
                            setState(() {
                              _isWhatsAppEdited = true;
                              selectedWhatsAppDialCode = number;
                            });
                          },
                          label: 'WhatsApp',
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: emailController,
                          hintText: AppLocalizations.of(context)!
                              .translate('enter_email'),
                          label:
                              AppLocalizations.of(context)!.translate('email'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 8),
                        CustomTextFieldDate(
                          controller: birthdayController,
                          label: AppLocalizations.of(context)!
                              .translate('birth_date'),
                          withTime: false,
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: descriptionController,
                          hintText: AppLocalizations.of(context)!
                              .translate('description_details_lead_edit'),
                          label: AppLocalizations.of(context)!
                              .translate('description_details_lead_add'),
                          maxLines: 5,
                          keyboardType: TextInputType.multiline,
                        ),
                        const SizedBox(height: 20),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: customFields.length,
                          itemBuilder: (context, index) {
                            final field = customFields[index];
                            return Container(
                              key: ValueKey(field.uniqueId),
                              child: field.isDirectoryField &&
                                      field.directoryId != null
                                  ? MainFieldDropdownWidget(
                                      directoryId: field.directoryId!,
                                      directoryName: field.fieldName,
                                      selectedField: field.entryId != null
                                          ? MainField(
                                              id: field.entryId!,
                                              value: field.controller.text,
                                            )
                                          : null,
                                      onSelectField: (MainField selectedField) {
                                        setState(() {
                                          customFields[index] = field.copyWith(
                                            entryId: selectedField.id,
                                            controller: TextEditingController(
                                                text: selectedField.value),
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
                                      initialEntryId: field
                                          .entryId, // Передаем initialEntryId
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
                        CustomButton(
                          buttonText: AppLocalizations.of(context)!
                              .translate('add_field'),
                          buttonColor: Color(0xff1E2E52),
                          textColor: Colors.white,
                          onPressed: _showAddFieldDialog,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
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
                        buttonText:
                            AppLocalizations.of(context)!.translate('cancel'),
                        buttonColor: const Color(0xffF4F7FD),
                        textColor: Colors.black,
                        onPressed: () => Navigator.pop(context, null),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BlocBuilder<LeadBloc, LeadState>(
                        builder: (context, state) {
                          if (state is LeadLoading) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: Color(0xff1E2E52),
                              ),
                            );
                          } else {
                            return CustomButton(
                              buttonText: AppLocalizations.of(context)!
                                  .translate('add'),
                              buttonColor: const Color(0xff4759FF),
                              textColor: Colors.white,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  String phoneToSend;
                                  String whatsAppToSend;

                                  if (_isPhoneEdited) {
                                    phoneToSend = selectedDialCode;
                                  } else {
                                    phoneToSend =
                                        '$selectedDialCode${phoneController.text}';
                                  }
                                  if (_isWhatsAppEdited) {
                                    whatsAppToSend = selectedWhatsAppDialCode;
                                  } else {
                                    whatsAppToSend = whatsAppController
                                            .text.isNotEmpty
                                        ? '$selectedWhatsAppDialCode${whatsAppController.text}'
                                        : '';
                                  }
                                  DateTime? parsedBirthday;

                                  if (birthdayController.text.isNotEmpty) {
                                    try {
                                      parsedBirthday = DateFormat('dd/MM/yyyy')
                                          .parseStrict(birthdayController.text);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(context)!
                                                .translate(
                                                    'error_enter_birth_day'),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                  List<Map<String, String>> customFieldList =
                                      [];
                                  List<Map<String, int>> directoryValues = [];

                                  for (var field in customFields) {
                                    String fieldName = field.fieldName.trim();
                                    String fieldValue =
                                        field.controller.text.trim();

                                    if (field.isDirectoryField &&
                                        field.directoryId != null &&
                                        field.entryId != null) {
                                      directoryValues.add({
                                        'directory_id': field.directoryId!,
                                        'entry_id': field.entryId!,
                                      });
                                    } else if (fieldName.isNotEmpty &&
                                        fieldValue.isNotEmpty) {
                                      customFieldList
                                          .add({fieldName: fieldValue});
                                    }
                                  }
                                  bool isSystemManager =
                                      selectedManager == "-1" ||
                                          selectedManager == "0";
                                  final leadBloc = context.read<LeadBloc>();
                                  context
                                      .read<LeadBloc>()
                                      .add(FetchLeadStatuses());
                                  final localizations =
                                      AppLocalizations.of(context)!;
                                  leadBloc.add(UpdateLead(
                                    leadId: widget.leadId,
                                    name: titleController.text,
                                    phone: phoneToSend,
                                    waPhone: whatsAppToSend,
                                    regionId: selectedRegion != null
                                        ? int.tryParse(selectedRegion!)
                                        : null,
                                    managerId: selectedManager != null
                                        ? int.tryParse(selectedManager!)
                                        : null,
                                    sourseId: selectedSource != null
                                        ? int.tryParse(selectedSource!)
                                        : null,
                                    instaLogin: instaLoginController.text,
                                    facebookLogin: facebookLoginController.text,
                                    tgNick: telegramController.text,
                                    birthday: parsedBirthday,
                                    email: emailController.text,
                                    description: descriptionController.text,
                                    leadStatusId: _selectedStatuses!.toInt(),
                                    customFields: customFieldList,
                                    directoryValues: directoryValues,
                                    localizations: localizations,
                                    isSystemManager: isSystemManager,
                                  ));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context)!
                                            .translate('fill_required_fields'),
                                        style: TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Colors.red,
                                      elevation: 3,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
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
