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
          print(
              'State updated: currentUserId = $currentUserId'); // Логируем обновление состояния
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
      _showSnackBar(
          AppLocalizations.of(context)!
              .translate('no_permession_to_access_contacts'),
          Colors.red);
    }
  }

  Future<void> _getContacts() async {
    try {
      List<Contact> fetchedContacts = await FlutterContacts.getContacts(
          withProperties: true, withPhoto: true);
      fetchedContacts = fetchedContacts.where((contact) {
        return (contact.displayName != null &&
                contact.displayName!.isNotEmpty) &&
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
              Text(
                AppLocalizations.of(context)!.translate('phones'),
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
                      Icon(
                        Icons.phone,
                        color: Color(0xff1E2E52),
                      ),
                      SizedBox(width: 8),
                      Text(
                        uniquePhone,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                );
              }).toSet(),
              SizedBox(height: 16),
              Text(
                'Emails:',
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
                      Icon(
                        Icons.email,
                        color: Color(0xff1E2E52),
                      ),
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
              Text(
                AppLocalizations.of(context)!.translate('address'),
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
                      Icon(
                        Icons.location_on,
                        color: Color(0xff1E2E52),
                      ),
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
          return contact.displayName
                  ?.toLowerCase()
                  .contains(query.toLowerCase()) ??
              false;
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

void _showFailedContactsDialog(
    List<Map<String, dynamic>> failedContacts, int totalContacts) {
  // Calculate successfully added contacts
  int successfulContacts = totalContacts - failedContacts.length;

  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color(0xff1E2E52).withOpacity(0.15),
                spreadRadius: 3,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff1E2E52), Color(0xff2C3E68)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                width: double.infinity,
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.translate('failed_contacts_title') ??
                        'Failed Contacts',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics card
                      Container(
                        margin: EdgeInsets.only(bottom: 20),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildStatRow(
                              context,
                              AppLocalizations.of(context)!.translate('total_contacts') ?? 'Total contacts',
                              totalContacts.toString(),
                              Color(0xff1E2E52),
                              Icons.people_alt_rounded,
                            ),
                            Divider(height: 20, thickness: 1, color: Color(0xffF4F7FD)),
                            _buildStatRow(
                              context,
                              AppLocalizations.of(context)!.translate('successfully_added') ?? 'Successfully added',
                              successfulContacts.toString(),
                              Colors.green.shade700,
                              Icons.check_circle_rounded,
                            ),
                            Divider(height: 20, thickness: 1, color: Color(0xffF4F7FD)),
                            _buildStatRow(
                              context,
                              AppLocalizations.of(context)!.translate('failed_to_add') ?? 'Failed to add',
                              failedContacts.length.toString(),
                              Colors.red.shade700,
                              Icons.error_rounded,
                            ),
                          ],
                        ),
                      ),

                      // Failed contacts section
                      if (failedContacts.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.only(bottom: 12, left: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xff1E2E52),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.translate('contacts_with_errors') ??
                                    'Contacts with errors:',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff1E2E52),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Failed contacts list
                        ListView.separated(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: failedContacts.length,
                          separatorBuilder: (context, index) => SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final contact = failedContacts[index];
                            final name = contact['name'] ?? '';
                            final errors = (contact['errors'] as List);

                            return Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color(0xffF8F9FC),
                                border: Border.all(color: Colors.red.shade100),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Color(0xff1E2E52).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontFamily: 'Gilroy',
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xff1E2E52),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  ...errors.map((error) => Padding(
                                    padding: EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.error_outline_rounded,
                                          color: Colors.red.shade700,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            error.toString(),
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontFamily: 'Gilroy',
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Action buttons
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // If at least one contact was added successfully, close the contacts screen
                          if (successfulContacts > 0) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff1E2E52),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.translate('ok') ?? 'OK',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Helper method to create statistic rows
Widget _buildStatRow(BuildContext context, String label, String value, Color color, IconData icon) {
  return Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: color,
        ),
      ),
    ],
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
                  hintText:
                      AppLocalizations.of(context)!.translate('search_appbar'),
                  border: InputBorder.none,
                ),
                onChanged: _filterContacts,
              )
            : Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('phone_contacts'),
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
              selectedContacts.length == contacts.length
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              color: selectedContacts.length == contacts.length
                  ? Color(0xff1E2E52)
                  : Colors.black,
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
                        AppLocalizations.of(context)
                                ?.translate('specify_lead_data') ??
                            'Filters',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                          fontSize: 16,
                        ),
                      ),
                      Icon(
                        isFiltersExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
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
              child: isFiltersExpanded
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          RegionRadioGroupWidget(
                            selectedRegion: selectedRegion,
                            onSelectRegion: (RegionData selectedRegionData) {
                              setState(() {
                                selectedRegion =
                                    selectedRegionData.id.toString();
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          ManagerRadioGroupWidget(
                            selectedManager: selectedManager,
                            currentUserId:
                                currentUserId, // Передаем currentUserId
                            onSelectManager: (ManagerData selectedManagerData) {
                              setState(() {
                                selectedManager =
                                    selectedManagerData.id.toString();
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
                    )
                  : SizedBox(),
            ),
            Expanded(
              child: contacts.isEmpty
                  ? Center(
                      child:
                          CircularProgressIndicator(color: Color(0xff1E2E52)))
                  : filteredContacts.isEmpty
                      ? Center(
                          child: Text(AppLocalizations.of(context)!
                              .translate('no_result')))
                      : ListView.builder(
                          itemCount: filteredContacts.length,
                          itemBuilder: (context, index) {
                            Contact contact = filteredContacts[index];
                            return Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
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
                                subtitle: Text(contact.phones.isNotEmpty
                                    ? contact.phones.first.number
                                    : AppLocalizations.of(context)!
                                        .translate('no_number')),
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
              // Replace the onPressed method of your FloatingActionButton with this:
              onPressed: () async {
                try {
                  // Создаем список контактов для отправки на сервер
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

                  // Store the total number of contacts we're trying to add
                  int totalContacts = contactsToSend.length;

                  // Call the API and get the response data
                  final responseData = await apiService.addLeadsFromContacts(
                      widget.statusId, contactsToSend);

                  // Check if there are errors in the result array
                  if (responseData.containsKey('result') &&
                      responseData['result'] is List) {
                    List<dynamic> results = responseData['result'];
                    List<Map<String, dynamic>> failedContacts = [];

                    // Filter contacts with errors
                    for (var item in results) {
                      if (item is Map<String, dynamic> &&
                          item.containsKey('errors') &&
                          item['errors'] is List &&
                          (item['errors'] as List).isNotEmpty) {
                        failedContacts.add(item);
                      }
                    }

                    if (failedContacts.isNotEmpty) {
                      // There are failed contacts, show the error dialog with summary
                      _showFailedContactsDialog(failedContacts, totalContacts);
                    } else {
                      // All contacts were processed successfully
                      _showSnackBar(
                          AppLocalizations.of(context)!
                              .translate('contacts_sent'),
                          Colors.green);

                      // Close the page after successful submission
                      Future.delayed(Duration(seconds: 1), () {
                        Navigator.of(context).pop();
                      });
                    }
                  } else {
                    // If response structure is unexpected, just show success and close the page
                    _showSnackBar(
                        AppLocalizations.of(context)!
                            .translate('contacts_sent'),
                        Colors.green);

                    // Close the page after successful submission
                    Future.delayed(Duration(seconds: 1), () {
                      Navigator.of(context).pop();
                    });
                  }
                } catch (e) {
                  // Handle exceptions
                  _showSnackBar(
                      AppLocalizations.of(context)!
                          .translate('error_contacts_sent'),
                      Colors.red);
                  print('Error sending contacts: $e');
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
