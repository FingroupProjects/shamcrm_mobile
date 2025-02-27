import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/region_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/source_lead_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ContactsScreen extends StatefulWidget {
  final int statusId;

  ContactsScreen({
    required this.statusId,
  });

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];
  Set<Contact> selectedContacts = Set();
  final apiService = ApiService();
  bool isSearching = false;
  bool isFiltersExpanded = false; // To track if filters section is expanded
  TextEditingController searchController = TextEditingController();
  bool _isLoading = true; // Добавлен флаг загрузки

  // Added state variables for the new fields
  String selectedRegion = "";
  String selectedManager = "";
  String? selectedSourceLead;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId().then((_) {
      // После загрузки currentUserId, обновляем состояние
      if (mounted) {
        setState(() {
          _isLoading = false; // Загрузка завершена
        });
      }
    });
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    _requestPermissionAndLoadContacts();
  }
  
  Future<void> _loadCurrentUserId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userID') ?? 'null';
      print('Loaded currentUserId: $userId'); // Логируем значение
      if (mounted) {
        setState(() {
          currentUserId = userId;
          print('State updated: currentUserId = $currentUserId'); // Логируем обновление состояния
        });
      }
    } catch (e) {
      print('Error loading current user ID: $e');
    }
  }
  
  Future<void> _requestPermissionAndLoadContacts() async {
    if (await FlutterContacts.requestPermission()) {
      _getContacts();
    } else {
      _showSnackBar(AppLocalizations.of(context)!.translate('no_permession_to_access_contacts'), Colors.red);
    }
  }

  Future<void> _getContacts() async {
    try {
      List<Contact> fetchedContacts = await FlutterContacts.getContacts(withProperties: true, withPhoto: true);
      fetchedContacts = fetchedContacts.where((contact) {
        return (contact.displayName != null && contact.displayName!.isNotEmpty) &&
            (contact.phones.isNotEmpty);
      }).toList();

      setState(() {
        contacts = fetchedContacts;
        filteredContacts = contacts;
      });
    } catch (e) {
      print("Ошибка при загрузке контактов: $e");
    }
  }

  void _showContactDetails(Contact contact) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black,
                  radius: 50,
                  backgroundImage: contact.photo != null
                      ? MemoryImage(contact.photo!)
                      : null,
                  child: contact.photo == null
                      ? Icon(Icons.person, size: 50, color: Colors.white) 
                      : null,
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  contact.displayName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700, 
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
              ),
              Divider(color: Color(0xff1E2E52)), 
              SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.translate('phones'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600, 
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              ...contact.phones.map((phone) {
                final uniquePhone = phone.number.replaceAll(RegExp(r'\s+'), '');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.phone, color: Color(0xff1E2E52),),
                      SizedBox(width: 8),
                      Text( uniquePhone,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                );
              }).toSet(),
              SizedBox(height: 16),
              Text('Emails:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              ...contact.emails.map((email) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.email, color: Color(0xff1E2E52),), 
                      SizedBox(width: 8),
                      Text(
                        email.address,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                );
              }).toList(),
              SizedBox(height: 16),
              Text( AppLocalizations.of(context)!.translate('address'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              ...contact.addresses.map((address) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Color(0xff1E2E52),),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address.street,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredContacts = contacts;
      } else {
        filteredContacts = contacts.where((contact) {
          return contact.displayName?.toLowerCase().contains(query.toLowerCase()) ?? false;
        }).toList();
      }
    });
  }

  void _toggleContactSelection(Contact contact) {
    setState(() {
      if (selectedContacts.contains(contact)) {
        selectedContacts.remove(contact);
      } else {
        selectedContacts.add(contact);
      }
    });
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
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
        backgroundColor: backgroundColor,
        elevation: 3,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Показываем индикатор загрузки, пока currentUserId загружается
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xff1E2E52)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        titleSpacing: 0,
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.translate('search_appbar'),
                  border: InputBorder.none,
                ),
                onChanged: _filterContacts,
              )
            : Row(
                children: [
                  Text(AppLocalizations.of(context)!.translate('phone_contacts'),
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 0),
            child: IconButton(
              icon: Image.asset(
                isSearching
                    ? 'assets/icons/AppBar/close.png'
                    : 'assets/icons/AppBar/search.png',
                width: 24,
                height: 24,
              ),
              onPressed: () {
                setState(() {
                  if (isSearching) {
                    isSearching = false;
                    searchController.clear();
                    _filterContacts('');
                  } else {
                    isSearching = true;
                  }
                });
              },
            ),
          ),
          IconButton(
            icon: Icon(
              selectedContacts.length == contacts.length ? Icons.check_box : Icons.check_box_outline_blank,
              color: selectedContacts.length == contacts.length ? Color(0xff1E2E52) : Colors.black,
            ),
            onPressed: () {
              setState(() {
                if (selectedContacts.length == contacts.length) {
                  selectedContacts.clear();
                } else {
                  selectedContacts.clear();
                  selectedContacts.addAll(contacts);
                }
              });
            },
          ),
        ],
        leading: Padding(
          padding: const EdgeInsets.only(right: 0),
          child: Transform.translate(
            offset: const Offset(0, -2),
            child: IconButton(
              icon: Image.asset(
                'assets/icons/arrow-left.png',
                width: 24,
                height: 24,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        leadingWidth: 50,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    isFiltersExpanded = !isFiltersExpanded;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xffF4F7FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.translate('specify_lead_data') ?? 'Filters',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                          fontSize: 16,
                        ),
                      ),
                      Icon(
                        isFiltersExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Color(0xff1E2E52),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: isFiltersExpanded ? null : 0,
              child: isFiltersExpanded ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      currentUserId: currentUserId, // Передаем currentUserId
                      onSelectManager: (ManagerData selectedManagerData) {
                        setState(() {
                          selectedManager = selectedManagerData.id.toString();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SourceLeadWidget(
                      selectedSourceLead: selectedSourceLead,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedSourceLead = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ) : SizedBox(),
            ),
            Expanded(
              child: contacts.isEmpty
                  ? Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)))
                  : filteredContacts.isEmpty
                      ? Center(child: Text(AppLocalizations.of(context)!.translate('no_result')))
                      : ListView.builder(
                          itemCount: filteredContacts.length,
                          itemBuilder: (context, index) {
                            Contact contact = filteredContacts[index];
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xffF4F7FD),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.black,
                                  backgroundImage: contact.photo != null
                                      ? MemoryImage(contact.photo!) 
                                      : null,
                                  child: contact.photo == null
                                      ? Icon(Icons.person, color: Colors.white) 
                                      : null,
                                ),
                                title: Text(
                                  contact.displayName,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(contact.phones.isNotEmpty ? contact.phones.first.number : AppLocalizations.of(context)!.translate('no_number')),
                                trailing: Transform.scale(
                                  scale: 1.1,
                                  child: Checkbox(
                                    activeColor: Color(0xff1E2E52),
                                    value: selectedContacts.contains(contact),
                                    onChanged: (bool? value) {
                                      _toggleContactSelection(contact);
                                    },
                                  ),
                                ),
                                onTap: () => _showContactDetails(contact),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: selectedContacts.isNotEmpty
          ? FloatingActionButton(
              onPressed: () async {
                try {
                  // Создаем список контактов для отправки на сервер и сохраняем их индексы
                  List<Map<String, dynamic>> contactsToSend = [];
                  List<Contact> orderedContacts = selectedContacts.toList();
                  
                  for (var contact in orderedContacts) {
                    if (contact.phones.isNotEmpty) {
                      contactsToSend.add({
                        'name': contact.displayName,
                        'phone': contact.phones.first.number,
                        'region_id': selectedRegion,
                        'manager_id': selectedManager,
                        'source_id': selectedSourceLead,
                        'lead_status_id': widget.statusId,
                      });
                    }
                  }
                  
                  try {
                    await apiService.addLeadsFromContacts(widget.statusId, contactsToSend);
                    _showSnackBar(AppLocalizations.of(context)!.translate('contacts_sent'), Colors.green);
                    setState(() {
                      selectedContacts.clear();
                    });
                  } catch (e) {
                    // Обработка ошибок сервера
                    if (e.toString().contains('response')) {
                      try {
                        // Извлекаем и парсим сообщение об ошибке из ответа сервера
                        String errorBody = e.toString();
                        // Находим начало и конец JSON в строке ошибки
                        int startIndex = errorBody.indexOf('{');
                        int endIndex = errorBody.lastIndexOf('}') + 1;
                        
                        if (startIndex != -1 && endIndex != -1) {
                          String jsonStr = errorBody.substring(startIndex, endIndex);
                          Map<String, dynamic> errorData = json.decode(jsonStr);
                          
                          if (errorData.containsKey('errors')) {
                            Map<String, dynamic> errors = errorData['errors'];
                            List<String> errorMessages = [];
                            
                            // Обработка каждой ошибки и нахождение соответствующего контакта
                            errors.forEach((key, value) {
                              // Извлекаем индекс из ключа, например, 'leads.0.phone' -> '0'
                              RegExp regExp = RegExp(r'leads\.(\d+)\.phone');
                              var match = regExp.firstMatch(key);
                              
                              if (match != null) {
                                int contactIndex = int.parse(match.group(1)!);
                                if (contactIndex < orderedContacts.length) {
                                  String contactName = orderedContacts[contactIndex].displayName;
                                  String errorMessage = value is List ? value.first : value.toString();
                                  errorMessages.add('$contactName: $errorMessage');
                                }
                              }
                            });
                            
                            if (errorMessages.isNotEmpty) {
                              _showSnackBar(
                                '${AppLocalizations.of(context)!.translate('error_contacts_sent')}\n${errorMessages.join('\n')}',
                                Colors.red
                              );
                              return;
                            }
                          }
                        }
                      } catch (parseError) {
                        print('Error parsing server response: $parseError');
                      }
                    }
                    
                    // Если не удалось обработать ошибку конкретно, показываем общее сообщение
                    _showSnackBar(AppLocalizations.of(context)!.translate('error_contacts_sent'), Colors.red);
                  }
                } catch (e) {
                  _showSnackBar(AppLocalizations.of(context)!.translate('error_contacts_sent'), Colors.red);
                }
              },
              backgroundColor: Color(0xff1E2E52),
              child: Icon(
                Icons.send,
                color: Colors.white,
                size: 26,
              ),
            )
          : null,
    );
  }
}